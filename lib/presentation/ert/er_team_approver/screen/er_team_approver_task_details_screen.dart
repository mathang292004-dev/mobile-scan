import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/helpers/widgets/feedback/movable_floating_button.dart';
import 'package:emergex/helpers/widgets/utils/timer_widget.dart';
import 'package:emergex/presentation/ert/er_team_approver/cubit/er_team_approver_dashboard_cubit.dart';
import 'package:emergex/data/model/er_team_approver/incident_tasks_response.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/ai_insights_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/date_time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:go_router/go_router.dart';

/// ER Team Approver Task Details Screen
/// Displays detailed information about a specific task
class ErTeamApproverTaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final String incidentId;

  const ErTeamApproverTaskDetailsScreen({
    super.key,
    required this.taskId,
    required this.incidentId,
  });

  @override
  State<ErTeamApproverTaskDetailsScreen> createState() =>
      _ErTeamApproverTaskDetailsScreenState();
}

class _ErTeamApproverTaskDetailsScreenState
    extends State<ErTeamApproverTaskDetailsScreen> {
  late final ErTeamApproverDashboardCubit _cubit;
  TaskItem? _task;
  String? _incidentId;

  @override
  void initState() {
    super.initState();
    _cubit = AppDI.erTeamApproverDashboardCubit;
    _loadTaskData();
  }

  void _loadTaskData() {
    // Load incident tasks if not already loaded
    final state = _cubit.state;
    if (state.incidentTasksData == null ||
        state.incidentTasksData!.incidentId != widget.incidentId) {
      _cubit.loadIncidentTasks(incidentId: widget.incidentId);
    } else {
      _extractTaskFromState();
    }
  }

  void _extractTaskFromState() {
    final state = _cubit.state;
    if (state.incidentTasksData != null) {
      _incidentId = state.incidentTasksData!.incidentId;
      for (final userTask in state.incidentTasksData!.tasks) {
        for (final task in userTask.tasks) {
          if (task.taskId == widget.taskId) {
            setState(() {
              _task = task;
            });
            return;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      ErTeamApproverDashboardCubit,
      ErTeamApproverDashboardState
    >(
      bloc: _cubit,
      listener: (context, state) {
        if (state.incidentTasksData != null) {
          _extractTaskFromState();
        }
      },
      child: Stack(
        children: [
          AppScaffold(
            useGradient: true,
            gradientBegin: Alignment.topCenter,
            gradientEnd: Alignment.bottomCenter,
            showDrawer: false,
            appBar: const AppBarWidget(showNotificationIcon: false),
            showBottomNav: false,
            child:
                BlocBuilder<
                  ErTeamApproverDashboardCubit,
                  ErTeamApproverDashboardState
                >(
                  bloc: _cubit,
                  builder: (context, state) {
                    if (state.isLoadingTasks && _task == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (state.tasksErrorMessage != null && _task == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            state.tasksErrorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    if (_task == null) {
                      // 🔥 silently go back, nothing shown
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          context.goNamed(Routes.notificationsScreen);
                        }
                      });
                      return const SizedBox.shrink();
                    }

                    return _buildContent();
                  },
                ),
          ),
          MovableFloatingButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                isDismissible: true,
                enableDrag: true,
                builder: (context) {
                  return AiInsightsCard(
                    // showIncidentInsights: true,
                    incident: null,
                    // showAlternateContent: true,
                    isTaskDetails: true,
                    taskAiAnalysis: _task?.aiAnalysis,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getTimerColor(TaskItem task) {
    final status = task.status.toLowerCase().trim();

    if (status == 'verified' || status == 'closed') {
      return ColorHelper.primaryColor; // ✅ green
    }

    if (status == 'rejected') {
      return ColorHelper.rejectedTimerColor; // ✅ red
    }

    return ColorHelper.notVerifiedTimerColor; // ✅ default (grey/black)
  }

  Widget _buildContent() {
    final task = _task!;
    final incidentId = _incidentId ?? widget.incidentId;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with Back Button, Title, and Options Menu
          _buildHeaderSection(incidentId),
          const SizedBox(height: 16),

          // Main Content Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorHelper.surfaceColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Title and Timer Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.taskName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: ColorHelper.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            incidentId,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: ColorHelper.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildTimerWidget(context, task),
                  ],
                ),
                const SizedBox(height: 24),

                // Task Details Section
                Text(
                  'Task Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColorHelper.textPrimary,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  task.taskDetails,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.black4,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 24),

                // Task Status Section
                Text(
                  'Task Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColorHelper.textPrimary,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ColorHelper.primaryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    task.statusUpdate ?? 'No status update available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorHelper.importantNoteDescription,
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Attachments Section
                if (task.attachments.isNotEmpty) ...[
                  Text(
                    'Attachments',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ColorHelper.textPrimary,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...task.attachments.map((attachment) {
                    return _buildAttachmentItem(attachment);
                  }),
                ],
                SizedBox(height: 20),
                if (PermissionHelper.hasEditPermission(
                  moduleName: "ER Team Approval",
                  featureName: "Status of Report & Report Download",
                ))
                  _buildActionButtons(task),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Buttons
        ],
      ),
    );
  }

  Widget _buildHeaderSection(String incidentId) {
    return Row(
      children: [
        // Back Button
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: ColorHelper.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: ColorHelper.white, width: 1),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: ColorHelper.black,
            ),
            padding: EdgeInsets.zero,
            onPressed: () => back(),
          ),
        ),
        const SizedBox(width: 10),

        // Title
        Expanded(
          child: Text(
            'Task #$incidentId',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: ColorHelper.organizationStructure,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentItem(TaskAttachment attachment) {
    final fileName = attachment.fileName?.trim().isNotEmpty == true
        ? attachment.fileName
        : 'Incident Photo.jpg';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle attachment tap - could open file viewer
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColorHelper.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Image.asset(Assets.jpgImage, height: 30, width: 24),
                // File Icon with colored background
                const SizedBox(width: 12),
                // File Name
                Expanded(
                  child: Text(
                    fileName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorHelper.appBarblur,
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(TaskItem task) {
    // Don't show action buttons if task is already verified or rejected
    final isCompleted = task.status == 'Verified' || task.status == 'Rejected';

    if (isCompleted) {
      return const SizedBox.shrink();
    }

    return BlocConsumer<
      ErTeamApproverDashboardCubit,
      ErTeamApproverDashboardState
    >(
      bloc: _cubit,
      listenWhen: (previous, current) =>
          previous.isVerifyingTask != current.isVerifyingTask ||
          previous.verifyTaskSuccess != current.verifyTaskSuccess ||
          previous.verifyTaskErrorMessage != current.verifyTaskErrorMessage,
      listener: (context, state) {
        if (state.verifyTaskSuccess) {
          final status = state.verifyTaskResponse?.status ?? '';

          if (status == 'Verified') {
            _cubit.clearVerifyTaskState();

            // 👉 Navigate to Approver screen
            // 👉 Navigate to Approver screen
            context.pushReplacementNamed(
              Routes.erTeamApproverDetailScreen,
              extra: {'incidentId': widget.incidentId},
              queryParameters: {'showDialog': 'true'},
            );
          } else {
            // ❌ KEEP SNACKBAR FOR REJECTION
            showSnackBar(
              context,
              'Task rejected successfully',
              isSuccess: true,
            );

            _cubit.clearVerifyTaskState();
            _cubit.loadIncidentTasks(incidentId: widget.incidentId);
            back();
          }
        } else if (state.verifyTaskErrorMessage != null) {
          showSnackBar(
            context,
            state.verifyTaskErrorMessage!,
            isSuccess: false,
          );
          _cubit.clearVerifyTaskState();
        }
      },
      builder: (context, state) {
        final isLoading = state.isVerifyingTask;

        if (isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reject Button
            Expanded(
              child: EmergexButton(
                colors: [ColorHelper.surfaceColor, ColorHelper.surfaceColor],
                text: TextHelper.reject,
                textColor: ColorHelper.primaryColor2,
                borderColor: Color(0xFF3CA128),
                disabled: isLoading,
                onPressed: () => _handleVerifyOrReject(task, 'Rejected'),
              ),
            ),
            const SizedBox(width: 10),

            // Verify Button
            Expanded(
              child: EmergexButton(
                text: TextHelper.verify,
                disabled: isLoading,
                onPressed: () => _handleVerifyOrReject(task, 'Verified'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleVerifyOrReject(TaskItem task, String status) {
    final incidentId = _incidentId ?? widget.incidentId;
    _cubit.verifyTask(
      incidentId: incidentId,
      taskIds: [task.taskId],
      status: status,
    );
  }

  /// Check if task status is Completed or Verified
  bool _isCompleted(String? status) {
    if (status == null) return false;
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'completed' || lowerStatus == 'verified';
  }

  /// Build timer widget based on task status
  Widget _buildTimerWidget(BuildContext context, TaskItem task) {
    Color timerColor = _getTimerColor(task);

    DateTime? startedAtDateTime;
    if (task.startedAt != null) {
      try {
        startedAtDateTime = DateTime.parse(task.startedAt!);
      } catch (_) {}
    }

    // ✅ Completed / Verified - Use timeTaken (seconds) to show duration
    if (_isCompleted(task.status) && task.timeTaken != null) {
      final formattedDuration = DateTimeFormatter.formatTimeTakenAsDuration(
        task.timeTaken,
      );
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Assets.tasktime,
            width: 10,
            height: 10,
            color: timerColor,
          ),
          const SizedBox(width: 6),
          Text(
            formattedDuration,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: timerColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // ✅ Running timer - task is in progress with no timeTaken yet
    final status = task.status.toLowerCase();
    if ((status == 'inprogress' || status == 'in progress') &&
        startedAtDateTime != null) {
      return TimerWidget(
        key: ValueKey('timer_${task.taskId}'),
        startDuration: DateTime.now().difference(startedAtDateTime),
        timerColor: timerColor,
        iconAsset: Assets.tasktime,
        iconSize: 10,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: timerColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      );
    }

    // ✅ Static timeTaken - format as duration (HH:MM:SS)
    if (task.timeTaken != null) {
      final formattedDuration = DateTimeFormatter.formatTimeTakenAsDuration(
        task.timeTaken,
      );
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Assets.tasktime,
            width: 10,
            height: 10,
            color: timerColor,
          ),
          const SizedBox(width: 6),
          Text(
            formattedDuration,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: timerColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    // ✅ Not started
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(Assets.tasktime, width: 10, height: 10, color: timerColor),
        const SizedBox(width: 6),
        Text(
          'Not started',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: timerColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
