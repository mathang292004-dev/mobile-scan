import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/feedback/movable_floating_button.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/date_time_formatter.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/status_color_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/helpers/widgets/utils/timer_widget.dart';
import 'package:emergex/helpers/task_status_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/ai_insights_widget.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/cubit/task_details_cubit.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/task_helper.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/widgets/attachment_item_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/widgets/ert_attachment_upload_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/presentation/chat/cubit/chat_cubit/chat_room_cubit.dart';

class ErTeamLeaderTaskDetailsScreen extends StatelessWidget {
  final Task? task;
  final String? incidentId;
  final String? taskId;
  final bool? isReadOnly;

  const ErTeamLeaderTaskDetailsScreen({
    super.key,
    this.task,
    this.incidentId,
    this.taskId,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TaskDetailsCubit(
            task: task,
            incidentId: incidentId,
            taskId: taskId,
            useCase: AppDI.myTaskUseCase,
          ),
        ),
        BlocProvider.value(value: getIt<ChatRoomCubit>()),
      ],
      child: BlocConsumer<TaskDetailsCubit, TaskDetailsState>(
        listener: (context, state) {
          if (state.processState == ProcessState.loading) {
            loaderService.showLoader();
          } else if (state.processState == ProcessState.done ||
              state.processState == ProcessState.error) {
            loaderService.hideLoader();

            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              showSnackBar(context, state.errorMessage!, isSuccess: false);
            } else if (state.processState == ProcessState.done) {
              showSnackBar(
                context,
                'Task updated successfully',
                isSuccess: true,
              );
            }
          }
        },
        builder: (context, state) {
          final bool canSaveAsDraft =
              (state.statusUpdate?.trim().isNotEmpty ?? false) ||
              state.hasStatusUpdateChanged;

          final bool hasStatusText =
              state.statusUpdate?.trim().isNotEmpty ?? false;

          return Stack(
            children: [
              AppScaffold(
                useGradient: true,
                gradientBegin: Alignment.topCenter,
                gradientEnd: Alignment.bottomCenter,
                showDrawer: false,
                appBar: AppBarWidget(hasNotifications: true),
                showBottomNav: false,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                              onPressed: () => back(),
                            ),
                          ),
                          Text(
                            incidentId != null && incidentId!.isNotEmpty
                                ? 'Task ${incidentId!.replaceFirst('#', '')}'
                                : 'Task',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: ColorHelper.black,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              loaderService.showLoader();
                              final cubit = context.read<ChatRoomCubit>();
                              await cubit.createChatGroup(incidentId ?? '');
                              loaderService.hideLoader();

                              final chatState = cubit.state;
                              if (chatState.processState ==
                                  ProcessState.done) {
                                if (context.mounted) {
                                  context.pushNamed(
                                    Routes.chatScreen,
                                    queryParameters: {
                                      'incidentId': incidentId ?? '',
                                    },
                                  );
                                }
                              } else if (chatState.processState ==
                                  ProcessState.error) {
                                if (context.mounted) {
                                  showSnackBar(
                                    context,
                                    chatState.errorMessage ?? 'Access Denied',
                                    isSuccess: false,
                                  );
                                }
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    ColorHelper.primaryColor,
                                    ColorHelper.buttonColor,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ColorHelper.primaryColor,
                                  width: 1,
                                ),
                              ),
                              child: Image.asset(
                                Assets.chat,
                                width: 18,
                                height: 18,
                                color: ColorHelper.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColorHelper.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.task?.taskName ??
                                            'Patient Assessment Protocol',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: ColorHelper.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        state.incidentId ??
                                            state.task?.taskId ??
                                            'BI-12-18995',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: ColorHelper.black,
                                              fontWeight: FontWeight.w400,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: _buildTimerWidget(context, state),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.task?.completedBy != null
                                  ? 'Completed by ${state.task!.completedBy}'
                                  : 'Unknown',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ColorHelper.black
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Task Details',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ColorHelper.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.task?.taskDetails ?? '',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ColorHelper.black
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Status Update',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ColorHelper.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (!(isReadOnly ?? false) &&
                                !_isCompleted(
                                  state.task?.status ?? state.selectedStatus,
                                ))
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Status Update',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: ColorHelper.black),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4E7FF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        const statusOptions = [
                                          'In Progress',
                                          'Paused',
                                        ];
                                        final currentStatus =
                                            (state.selectedStatus ??
                                                    state.task?.status ??
                                                    '')
                                                .toLowerCase();

                                        String validStatus = 'In Progress';
                                        if (currentStatus == 'paused' ||
                                            currentStatus == 'draft') {
                                          validStatus = 'Paused';
                                        }

                                        return Opacity(
                                          opacity: hasStatusText ? 1.0 : 0.5,
                                          child: IgnorePointer(
                                            ignoring: !hasStatusText,
                                            child: DropdownButton<String>(
                                              value: validStatus,
                                              icon: Icon(
                                                Icons.keyboard_arrow_down,
                                                color: ColorHelper
                                                    .inProgessColor,
                                                size: 20,
                                              ),
                                              underline: const SizedBox(),
                                              isDense: true,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: ColorHelper
                                                        .inProgessColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              items: statusOptions
                                                  .map(
                                                    (v) =>
                                                        DropdownMenuItem<String>(
                                                          value: v,
                                                          child: Text(v),
                                                        ),
                                                  )
                                                  .toList(),
                                              onChanged: !hasStatusText
                                                  ? null
                                                  : (String? newValue) {
                                                      if (newValue == null) {
                                                        return;
                                                      }
                                                      final cubit = context
                                                          .read<
                                                            TaskDetailsCubit
                                                          >();
                                                      final cs = cubit.state;
                                                      final currentNorm =
                                                          _normalizeStatus(
                                                            cs.selectedStatus ??
                                                                cs.task
                                                                    ?.status,
                                                          );
                                                      final newNorm =
                                                          _normalizeStatus(
                                                            newValue ==
                                                                    'In Progress'
                                                                ? 'Inprogress'
                                                                : newValue,
                                                          );
                                                      if (currentNorm ==
                                                          newNorm) { return; }
                                                      cubit.updateStatus(
                                                        newValue,
                                                      );
                                                      cubit.updateTask(
                                                        status: newNorm ==
                                                                'inprogress'
                                                            ? 'Inprogress'
                                                            : 'Paused',
                                                        statusUpdate:
                                                            cs.statusUpdate,
                                                      );
                                                    },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Stack(
                              children: [
                                AppTextField(
                                  controller: context
                                      .read<TaskDetailsCubit>()
                                      .statusController,
                                  hint: (isReadOnly ?? false)
                                      ? 'Task Status'
                                      : 'Enter status update...',
                                  maxLines: 4,
                                  minLines: 4,
                                  maxLength: 500,
                                  enabled: !(isReadOnly ?? false) &&
                                      !_isCompleted(
                                        state.task?.status ??
                                            state.selectedStatus,
                                      ),
                                  fillColor: ColorHelper.white,
                                  contentPadding: const EdgeInsets.only(
                                    top: 12,
                                    left: 24,
                                    right: 24,
                                    bottom: 44,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  onChanged: (value) {
                                    context
                                        .read<TaskDetailsCubit>()
                                        .updateStatusUpdate(value);
                                  },
                                ),
                                if (!(isReadOnly ?? false) &&
                                    !_isCompleted(
                                      state.task?.status ??
                                          state.selectedStatus,
                                    ))
                                  Positioned(
                                    bottom: 5,
                                    right: 5,
                                    child: GestureDetector(
                                      onTap: () {
                                        context
                                            .read<TaskDetailsCubit>()
                                            .toggleRecording();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: state.isRecording
                                              ? ColorHelper.errorColor
                                              : ColorHelper.successColor,
                                        ),
                                        child: Icon(
                                          state.isRecording
                                              ? Icons.stop
                                              : Icons.mic,
                                          color: ColorHelper.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (state.isRecording)
                                  Positioned(
                                    bottom: 5,
                                    left: 5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorHelper.errorColor
                                            .withValues(alpha: 0.8),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: ColorHelper.white,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            TaskHelper.formatDuration(
                                              state.recordingDuration,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: ColorHelper.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ── EmergeX case Attachments (Reporter) ──
                            Text(
                              TextHelper.incidentAttachments,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF525252),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final validAttachments = state
                                        .task?.attachments
                                        .where((a) => a.fileUrl.isNotEmpty)
                                        .toList() ??
                                    [];

                                if (validAttachments.isNotEmpty) {
                                  return Column(
                                    children: validAttachments.map((a) {
                                      final fileName = a.fileName.isNotEmpty
                                          ? a.fileName
                                          : 'Attachment';
                                      final isImage = ['.jpg', '.jpeg', '.png']
                                          .any((ext) => fileName
                                              .toLowerCase()
                                              .endsWith(ext));
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: AttachmentItemWidget(
                                          fileName: fileName,
                                          fileUrl: a.fileUrl,
                                          icon: isImage
                                              ? Icons.image
                                              : Icons.description,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }

                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: ColorHelper.white),
                                    borderRadius: BorderRadius.circular(12),
                                    color: ColorHelper.white
                                        .withValues(alpha: 0.4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No Attachments',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: ColorHelper.black4,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // ── ERT Attachments ──────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  TextHelper.ertAttachments,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF525252),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                if (!(isReadOnly ?? false) &&
                                    !_isCompleted(
                                      state.task?.status ??
                                          state.selectedStatus,
                                    ))
                                  GestureDetector(
                                    onTap: () => context
                                        .read<TaskDetailsCubit>()
                                        .pickAndUploadErtFiles(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: ColorHelper.successColor,
                                          width: 0.7,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            size: 12,
                                            color: ColorHelper.successColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            TextHelper.addFiles,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      ColorHelper.successColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (state.ertUploadItems.isEmpty &&
                                (isReadOnly ?? false))
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: ColorHelper.white),
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      ColorHelper.white.withValues(alpha: 0.4),
                                ),
                                child: Center(
                                  child: Text(
                                    'No ERT Attachments',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: ColorHelper.black4),
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: state.ertUploadItems
                                    .map(
                                      (item) => ErtAttachmentUploadWidget(
                                        key: ValueKey(item.id),
                                        item: item,
                                        onDelete: () => context
                                            .read<TaskDetailsCubit>()
                                            .removeErtUploadItem(item.id),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!(isReadOnly ?? false) &&
                          !_isCompleted(
                            state.task?.status ?? state.selectedStatus,
                          ))
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color:
                                ColorHelper.white.withValues(alpha: 0.15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              EmergexButton(
                                text: TextHelper.saveasdraft,
                                borderColor: canSaveAsDraft
                                    ? ColorHelper.primaryColor
                                    : ColorHelper.primaryColor
                                        .withValues(alpha: 0.4),
                                onPressed: canSaveAsDraft
                                    ? () async {
                                        await context
                                            .read<TaskDetailsCubit>()
                                            .updateTask(
                                              status: 'Draft',
                                              statusUpdate:
                                                  state.statusUpdate,
                                            );
                                        await Future.delayed(
                                          const Duration(milliseconds: 100),
                                        );
                                        if (context.mounted) {
                                          final cs = context
                                              .read<TaskDetailsCubit>()
                                              .state;
                                          if (cs.processState ==
                                                  ProcessState.done &&
                                              (cs.errorMessage == null ||
                                                  cs.errorMessage!.isEmpty)) {
                                            back();
                                          }
                                        }
                                      }
                                    : null,
                                textColor: canSaveAsDraft
                                    ? ColorHelper.primaryColor
                                    : ColorHelper.primaryColor
                                        .withValues(alpha: 0.4),
                                colors: [
                                  ColorHelper.white,
                                  ColorHelper.white,
                                ],
                              ),
                              const SizedBox(width: 16),
                              EmergexButton(
                                text: TextHelper.markascomplete,
                                onPressed: hasStatusText
                                    ? () async {
                                        await context
                                            .read<TaskDetailsCubit>()
                                            .updateTask(
                                              status: 'Completed',
                                              statusUpdate:
                                                  state.statusUpdate,
                                            );
                                        await Future.delayed(
                                          const Duration(milliseconds: 100),
                                        );
                                        if (context.mounted) {
                                          final cs = context
                                              .read<TaskDetailsCubit>()
                                              .state;
                                          if (cs.processState ==
                                                  ProcessState.done &&
                                              (cs.errorMessage == null ||
                                                  cs.errorMessage!.isEmpty)) {
                                            back();
                                          }
                                        }
                                      }
                                    : null,
                                textColor: hasStatusText
                                    ? ColorHelper.white
                                    : ColorHelper.white
                                        .withValues(alpha: 0.4),
                                colors: hasStatusText
                                    ? [
                                        ColorHelper.primaryColor,
                                        ColorHelper.buttonColor,
                                      ]
                                    : [
                                        ColorHelper.primaryColor
                                            .withValues(alpha: 0.4),
                                        ColorHelper.primaryColor
                                            .withValues(alpha: 0.4),
                                      ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (isReadOnly != null && !isReadOnly!)
                MovableFloatingButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: ColorHelper.transparent,
                      isScrollControlled: true,
                      builder: (context) => AiInsightsCard(
                        isTaskDetails: true,
                        taskAiAnalysis: state.task?.aiAnalysis,
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  String _normalizeStatus(String? status) {
    if (status == null) return '';
    return status.toLowerCase().replaceAll(' ', '').trim();
  }

  bool _isCompleted(String? status) =>
      TaskStatusHelper.isFinalState(status);

  Widget _buildTimerWidget(BuildContext context, TaskDetailsState state) {
    final task = state.task;
    final currentStatus = state.selectedStatus ?? task?.status;
    final timerColor = StatusColorHelper.getTaskTimerColor(currentStatus);

    if (TaskStatusHelper.isInProgress(currentStatus) &&
        task?.startedAt != null) {
      final initialDuration = DateTimeFormatter.calculateTaskDuration(
        startedAt: task?.startedAt,
        pausedAt: task?.pausedAt,
        completedAt: task?.completedAt,
        totalPausedTime: task?.totalPausedTime,
        status: currentStatus,
      );
      return TimerWidget(
        key: ValueKey('timer_${task?.taskId}'),
        startDuration: initialDuration,
        timerColor: timerColor,
        shouldRun: true,
        iconAsset: Assets.tasktime,
        iconSize: 10,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        borderRadius: 20,
        borderWidth: 1,
        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: timerColor,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Static timer for all non-in-progress states
    final formattedTime = DateTimeFormatter.formatTaskDuration(
      startedAt: task?.startedAt,
      pausedAt: task?.pausedAt ?? (TaskStatusHelper.isPaused(currentStatus) ||
              TaskStatusHelper.isDraft(currentStatus)
          ? DateTime.now()
          : null),
      completedAt: task?.completedAt,
      totalPausedTime: task?.totalPausedTime,
      status: currentStatus,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: timerColor),
      ),
      child: Row(
        children: [
          Image.asset(
            Assets.tasktime,
            width: 10,
            height: 10,
            color: timerColor,
          ),
          const SizedBox(width: 6),
          Text(
            formattedTime,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: timerColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
