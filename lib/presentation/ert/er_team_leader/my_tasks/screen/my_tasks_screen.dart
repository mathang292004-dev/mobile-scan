import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/cubit/my_task_cubit.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/screens/task_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/widgets/er_leader_custom_dialog_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/widgets/task_card_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/task_helper.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/model/ui_task_model.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/date_time_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class InProgressPage extends StatefulWidget {
  final String? incidentId;
  final String role;
  final String? caseType;
  final String? reportedDate;

  const InProgressPage({
    super.key,
    this.incidentId,
    this.role = 'tl',
    this.caseType,
    this.reportedDate,
  });

  @override
  State<InProgressPage> createState() => _InProgressPageState();
}

class _InProgressPageState extends State<InProgressPage> {
  MyTaskCubit get _cubit =>
      widget.role == 'member' ? AppDI.memberTaskCubit : AppDI.myTaskCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = _cubit;
      if (cubit.state.isLoading) return;
      if (cubit.state.processState == ProcessState.error) return;
      if (widget.incidentId != null && widget.incidentId!.isNotEmpty) {
        cubit.loadTasksByIncidentId(widget.incidentId!);
        return;
      }
      cubit.loadMyTasks(
        statuses: cubit.state.appliedStatuses,
        fromDate: cubit.state.appliedFromDate,
        toDate: cubit.state.appliedToDate,
      );
    });
  }

  void _refreshOnBack() {
    if (!mounted) return;
    final cubit = _cubit;
    if (cubit.state.isLoading) return;
    if (widget.incidentId != null && widget.incidentId!.isNotEmpty) {
      cubit.loadTasksByIncidentId(widget.incidentId!);
    } else {
      cubit.loadMyTasks(
        statuses: cubit.state.appliedStatuses,
        fromDate: cubit.state.appliedFromDate,
        toDate: cubit.state.appliedToDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        appBar: const AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child: BlocConsumer<MyTaskCubit, MyTaskState>(
          listener: (context, state) {
            if (state.processState == ProcessState.loading) {
              loaderService.showLoader();
            } else if (state.processState == ProcessState.done ||
                state.processState == ProcessState.error) {
              loaderService.hideLoader();

              if (state.errorMessage != null &&
                  state.errorMessage!.isNotEmpty) {
                showSnackBar(context, state.errorMessage!, isSuccess: false);
              }
            }
          },
          builder: (context, state) {
            if (state.processState == ProcessState.error &&
                state.data == null) {
              return Center(
                child: Text(
                  'Error: ${state.errorMessage ?? "Failed to load tasks"}',
                ),
              );
            }

            final cubit = context.read<MyTaskCubit>();
            final filteredTasks = cubit.getFilteredTasks();

            final completedCount = filteredTasks
                .where((t) => t.status?.toLowerCase() == 'completed')
                .length;
            final totalCount = filteredTasks.length;
            final progress =
                totalCount > 0 ? completedCount / totalCount : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 35,
                        decoration: BoxDecoration(
                          color: ColorHelper.white.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorHelper.white,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: ColorHelper.black,
                            size: 18,
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.goNamed(Routes.homeScreen);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.incidentId != null && widget.incidentId!.isNotEmpty
                              ? 'EmergeX Case ID-${widget.incidentId}'
                              : TextHelper.myTaskErTeam,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: ColorHelper.black,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.reportedDate != null && widget.reportedDate!.isNotEmpty ||
                      widget.caseType != null && widget.caseType!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (widget.reportedDate != null &&
                            widget.reportedDate!.isNotEmpty) ...[
                          _CaseDurationBadge(reportedDate: widget.reportedDate!),
                          const SizedBox(width: 8),
                        ],
                        if (widget.caseType != null && widget.caseType!.isNotEmpty)
                          _CaseTypeBadge(caseType: widget.caseType!),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TextHelper.selectTaskList,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ColorHelper.black,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ErLeaderCustomDialogWidget.show(context);
                        },
                        icon: Image.asset(
                          Assets.filter,
                          height: 20,
                          width: 20,
                          color: ColorHelper.white,
                        ),
                        label: const Text(
                          'Filter',
                          style: TextStyle(color: ColorHelper.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorHelper.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: ColorHelper.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ColorHelper.white),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              TextHelper.totalTaskCompleted,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith( color: ColorHelper.black,
                                    fontWeight: FontWeight.w600,),
                            ),
                            Text(
                              '${completedCount.toString().padLeft(2, '0')}/${totalCount.toString().padLeft(2, '0')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: ColorHelper.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor:
                                ColorHelper.progressBackgroundColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              ColorHelper.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: RefreshIndicator(
                      color: ColorHelper.primaryColor,
                      onRefresh: () async {
                        final c = context.read<MyTaskCubit>();
                        if (widget.incidentId != null && widget.incidentId!.isNotEmpty) {
                          await c.loadTasksByIncidentId(widget.incidentId!);
                        } else {
                          await c.loadMyTasks(
                            statuses: c.state.appliedStatuses,
                            fromDate: c.state.appliedFromDate,
                            toDate: c.state.appliedToDate,
                          );
                        }
                      },
                      child: filteredTasks.isNotEmpty
                        ? ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];

                              // Always use the dashboard-selected incidentId
                              // (the case the user tapped), not the task's own incidentIds
                              String? formattedStartedAt;
                              if (task.startedAt != null) {
                                formattedStartedAt = DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(task.startedAt!);
                              }

                              final uiTask = UiTaskModel(
                                title: task.taskName,
                                code: widget.incidentId ?? task.taskId,
                                date: TaskHelper.formatTaskDate(task.createdAt),
                                description: task.taskDetails,
                                timer: DateTimeFormatter.formatTaskDuration(
                                  startedAt: task.startedAt,
                                  pausedAt: task.pausedAt,
                                  completedAt: task.completedAt,
                                  totalPausedTime: task.totalPausedTime,
                                  status: task.status,
                                ),
                                timerStyle: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                status: task.status ?? 'Draft',
                                statusColor: TaskHelper.getStatusColor(
                                  task.status,
                                ),
                                statusBg: TaskHelper.getStatusBackgroundColor(
                                  task.status,
                                ),
                                timerColor: TaskHelper.getStatusTimerColor(
                                  task.status,
                                ),
                                startedAt: formattedStartedAt,
                                startedAtDateTime: task.startedAt,
                                pausedAtDateTime: task.pausedAt,
                                completedAtDateTime: task.completedAt,
                                totalPausedTime: task.totalPausedTime,
                              );

                              return GestureDetector(
                                key: ValueKey(task.taskId),
                                onTap: () {
                                  if (widget.role == 'member') {
                                    context.pushNamed(
                                      Routes.erTeamMemberTaskDetailsScreen,
                                      extra: {
                                        'task': task,
                                        'incidentId': widget.incidentId,
                                      },
                                    ).then((_) => _refreshOnBack());
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ErTeamLeaderTaskDetailsScreen(
                                              task: task,
                                              incidentId: widget.incidentId,
                                            ),
                                      ),
                                    ).then((_) => _refreshOnBack());
                                  }
                                },
                                child: TaskCardWidget(
                                  key: ValueKey('${task.taskId}_card'),
                                  task: uiTask,
                                ),
                              );
                            },
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Text(
                                    'No tasks found',
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(color: ColorHelper.black5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CaseDurationBadge extends StatefulWidget {
  final String reportedDate;
  const _CaseDurationBadge({required this.reportedDate});

  @override
  State<_CaseDurationBadge> createState() => _CaseDurationBadgeState();
}

class _CaseDurationBadgeState extends State<_CaseDurationBadge> {
  late final DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.tryParse(widget.reportedDate);
  }

  String get _elapsed {
    if (_startTime == null) return '--:--:--';
    final diff = DateTime.now().difference(_startTime);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorHelper.timeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${TextHelper.caseDuration} - ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColorHelper.timeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Icon(Icons.access_time, size: 12, color: ColorHelper.timeColor),
          const SizedBox(width: 3),
          Text(
            _elapsed,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColorHelper.timeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseTypeBadge extends StatelessWidget {
  final String caseType;
  const _CaseTypeBadge({required this.caseType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: ColorHelper.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        caseType,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ColorHelper.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
