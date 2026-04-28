import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/feedback/movable_floating_button.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/helpers/widgets/utils/timer_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/task_helper.dart';
import 'package:emergex/presentation/investigation/investigation_team_member/cubit/investigation_team_member_cubit.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/helpers/task_status_helper.dart';
import 'package:emergex/services/incident_recorder_service.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/ai_insights_widget.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart'
    as team_leader;
import 'package:flutter/material.dart';
import 'package:emergex/presentation/investigation/utils/task_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'dart:async';

class InvestigationTeamMemberTaskDetailsScreen extends StatefulWidget {
  final String? taskId;
  final String? incidentId;

  const InvestigationTeamMemberTaskDetailsScreen({
    super.key,
    this.taskId,
    this.incidentId,
  });

  @override
  State<InvestigationTeamMemberTaskDetailsScreen> createState() =>
      _InvestigationTeamMemberTaskDetailsScreenState();
}

class _InvestigationTeamMemberTaskDetailsScreenState
    extends State<InvestigationTeamMemberTaskDetailsScreen> {
  final TextEditingController _statusController = TextEditingController();
  String? _selectedStatus;

  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  final IncidentRecorderService _recorderService = IncidentRecorderService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _textBeforeRecording;

  bool get _hasStatusText => _statusController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _setupRecorderServiceCallbacks();
  }

  void _setupRecorderServiceCallbacks() {
    _recorderService.onTranscriptUpdate = (transcript) {
      if (mounted) {
        final currentText = _textBeforeRecording ?? '';
        _statusController.text = currentText + transcript;
        setState(() {}); // Update the hasStatusText dependency
      }
    };

    _recorderService.onRecordingStatusChange = (isRecording) {
      if (!isRecording && _isRecording) {
        _recordingTimer?.cancel();
        _recordingTimer = null;
        if (mounted) {
          setState(() {
            _isRecording = false;
            _recordingDuration = 0;
          });
        }
      }
    };
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final status = await _audioRecorder.hasPermission();
      if (!status) {
        if (mounted) {
          setState(() {
            _isRecording = false;
          });
        }
        return;
      }

      _textBeforeRecording = _statusController.text;

      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });
      }

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isRecording) {
          timer.cancel();
          return;
        }
        if (mounted) {
          setState(() {
            _recordingDuration++;
          });
        }
      });

      await _recorderService.startRecording();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDuration = 0;
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      await _recorderService.stopRecording();

      final finalTranscript = _recorderService.currentTranscript;
      if (finalTranscript.isNotEmpty) {
        final currentText = _textBeforeRecording ?? '';
        _statusController.text = currentText + finalTranscript;
      }

      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDuration = 0;
          _textBeforeRecording = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDuration = 0;
          _textBeforeRecording = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorderService.dispose();
    _audioRecorder.dispose();
    _statusController.dispose();
    super.dispose();
  }

  bool _isFinalState(String? status) {
    return TaskStatusHelper.isFinalState(status);
  }

  String _mapStatusToAPI(String uiStatus) {
    return TaskStatusHelper.getApiStatus(uiStatus);
  }

  String _formatAssignedBy(String assignedBy) {
    switch (assignedBy.toLowerCase()) {
      case 'assignedbyai':
        return 'AI System';
      case 'unknown':
        return 'Unknown';
      default:
        return assignedBy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<InvestigationTeamMemberCubit>(),
      child: BlocBuilder<InvestigationTeamMemberCubit, InvestigationTeamMemberState>(
        builder: (context, state) {
          InvestigationMemberTask? task = state.task;
          if (task == null && widget.taskId != null && state.tasks != null) {
            try {
              task = state.tasks!.firstWhere((t) => t.taskId == widget.taskId);
            } catch (e) {
              debugPrint(e.toString());
            }
          }

          if (task == null &&
              state.processState == ProcessState.none &&
              !state.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (widget.taskId != null) {
                try {
                  getIt<InvestigationTeamMemberCubit>().loadTaskDetails(
                    widget.taskId!,
                    incidentId: widget.incidentId,
                  );
                } catch (e) {
                  debugPrint(e.toString());
                }
              }
            });
          }

          if (state.isLoading && task == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.processState == ProcessState.error && task == null) {
            return Center(
              child: Text(state.errorMessage ?? 'Failed to load task'),
            );
          }

          if (task == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final finalTask = task;
          if (_selectedStatus == null) {
            _selectedStatus = finalTask.status;
            _statusController.text = finalTask.statusUpdate ?? '';
          }

          final bool canEditTask = PermissionHelper.hasEditPermission(
            moduleName: 'ERT Team Member',
          ); // TODO change to match investigation

          return Stack(
            children: [
              AppScaffold(
                useGradient: true,
                gradientBegin: Alignment.topCenter,
                gradientEnd: Alignment.bottomCenter,
                showDrawer: false,
                appBar: const AppBarWidget(hasNotifications: true),
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
                          Expanded(
                            child: Text(
                              'Task #${finalTask.taskId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: ColorHelper.black),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              context.push(
                                '${Routes.chatScreen}?incidentId=${widget.incidentId}',
                              );
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
                                        finalTask.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: ColorHelper.black,
                                              fontWeight: FontWeight.w400,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        finalTask.code,
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
                                _buildTimerWidget(context, finalTask),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Assigned by ${_formatAssignedBy(finalTask.assignedBy)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ColorHelper.black.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Task Details',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ColorHelper.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              finalTask.description,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ColorHelper.black.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 24),
                            if (canEditTask &&
                                !_isFinalState(
                                  _selectedStatus ?? finalTask.status,
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
                                            (_selectedStatus ??
                                                    finalTask.status)
                                                .toLowerCase();
                                        String validStatus = 'In Progress';

                                        if (currentStatus == 'paused' ||
                                            currentStatus == 'draft') {
                                          validStatus = 'Paused';
                                        } else if (currentStatus ==
                                                'inprogress' ||
                                            currentStatus == 'in progress') {
                                          validStatus = 'In Progress';
                                        }

                                        return Opacity(
                                          opacity: _hasStatusText ? 1.0 : 0.5,
                                          child: IgnorePointer(
                                            ignoring: !_hasStatusText,
                                            child: DropdownButton<String>(
                                              value: validStatus,
                                              icon: Icon(
                                                Icons.keyboard_arrow_down,
                                                color:
                                                    ColorHelper.inProgessColor,
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
                                              items: statusOptions.map((
                                                String value,
                                              ) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: !_hasStatusText
                                                  ? null
                                                  : (String? newValue) {
                                                      if (newValue == null)
                                                        return;
                                                      final currentStatus =
                                                          (_selectedStatus ??
                                                                  finalTask
                                                                      .status)
                                                              .toLowerCase();
                                                      final newStatus = newValue
                                                          .toLowerCase();
                                                      if (currentStatus ==
                                                          newStatus)
                                                        return;

                                                      setState(() {
                                                        _selectedStatus =
                                                            newValue;
                                                      });

                                                      final apiStatus =
                                                          _mapStatusToAPI(
                                                            newValue,
                                                          );
                                                      try {
                                                        getIt<
                                                              InvestigationTeamMemberCubit
                                                            >()
                                                            .updateTaskStatus(
                                                              widget.taskId ??
                                                                  finalTask
                                                                      .taskId,
                                                              apiStatus,
                                                              incidentId:
                                                                  widget
                                                                      .incidentId ??
                                                                  finalTask
                                                                      .incidentId,
                                                              statusUpdate:
                                                                  _statusController
                                                                      .text,
                                                            );
                                                      } catch (e) {
                                                        debugPrint(
                                                          e.toString(),
                                                        );
                                                      }
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
                                  controller: _statusController,
                                  hint: 'Enter status update...',
                                  maxLines: 4,
                                  minLines: 4,
                                  maxLength: 500,
                                  enabled:
                                      canEditTask &&
                                      !_isFinalState(
                                        _selectedStatus ?? finalTask.status,
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
                                  onChanged: (_) {
                                    setState(() {});
                                  },
                                ),
                                if (canEditTask &&
                                    !TaskStatusHelper.isFinalState(
                                      _selectedStatus ?? finalTask.status,
                                    ))
                                  Positioned(
                                    bottom: 5,
                                    right: 5,
                                    child: GestureDetector(
                                      onTap: _toggleRecording,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _isRecording
                                              ? ColorHelper.errorColor
                                              : ColorHelper.successColor,
                                        ),
                                        child: Icon(
                                          _isRecording ? Icons.stop : Icons.mic,
                                          color: ColorHelper.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_isRecording)
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: ColorHelper.white,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            TaskHelper.formatDuration(
                                              _recordingDuration,
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
                            Text(
                              'EmergeX case Attachments(Reporter)',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ColorHelper.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildAttachmentList(
                              context,
                              finalTask.attachments,
                              isReporter: true,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Investigation Attachments',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: ColorHelper.black,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                    ),
                                    Text(
                                      'Add your Photo/Video here.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: ColorHelper.black5
                                                .withValues(alpha: 0.6),
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    context
                                        .read<InvestigationTeamMemberCubit>()
                                        .pickAndUploadFiles();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5.59),
                                      border: Border.all(
                                        color: const Color(0xFF51AC3F),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Color(0xFF51AC3F),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Add Files',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: const Color(0xFF51AC3F),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Only support .jpg, .png and .svg. (Max: 30 MB)',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ColorHelper.black5.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontSize: 10,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildInvestigationAttachmentsList(context, state),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ColorHelper.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: EmergexButton(
                                text: 'Save',
                                colors: const [
                                  ColorHelper.white,
                                  ColorHelper.white,
                                ],
                                textColor: const Color(0xFF388E3C),
                                borderColor: const Color(0xFF388E3C),
                                buttonHeight: 45,
                                textSize: 11,
                                fontWeight: FontWeight.bold,
                                onPressed: _hasStatusText ? _saveDraft : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: EmergexButton(
                                text: 'Proceed to RCA',
                                colors: _hasStatusText
                                    ? const [
                                        Color(0xFF388E3C),
                                        Color(0xFF216830),
                                      ]
                                    : [
                                        const Color(
                                          0xFF388E3C,
                                        ).withValues(alpha: 0.4),
                                        const Color(
                                          0xFF216830,
                                        ).withValues(alpha: 0.4),
                                      ],
                                textColor: _hasStatusText
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                                borderColor: _hasStatusText
                                    ? const Color(0xFF388E3C)
                                    : const Color(
                                        0xFF388E3C,
                                      ).withValues(alpha: 0.4),
                                buttonHeight: 45,
                                textSize: 11,
                                fontWeight: FontWeight.bold,
                                onPressed: _proceedToRca,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              MovableFloatingButton(
                onPressed: () {
                  team_leader.AiAnalysis? mappedAiAnalysis;
                  if (finalTask.aiAnalysis != null) {
                    mappedAiAnalysis = team_leader.AiAnalysis(
                      aiSummary: finalTask.aiAnalysis!.aiSummary,
                      delayRiskDetected:
                          finalTask.aiAnalysis!.delayRiskDetected,
                      aiRecommendations:
                          finalTask.aiAnalysis!.aiRecommendations,
                    );
                  }
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: ColorHelper.transparent,
                    isScrollControlled: true,
                    builder: (context) => AiInsightsCard(
                      isTaskDetails: true,
                      taskAiAnalysis: mappedAiAnalysis,
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

  void _saveDraft() {
    if (_statusController.text.trim().isEmpty) return;
    try {
      getIt<InvestigationTeamMemberCubit>().updateTaskStatus(
        widget.taskId!,
        'Draft',
        statusUpdate: _statusController.text,
        incidentId: widget.incidentId,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _proceedToRca() {
    // if (_statusController.text.trim().isEmpty) return;
    // try {
    //   getIt<InvestigationTeamMemberCubit>().updateTaskStatus(
    //     widget.taskId!,
    //     'Completed', // assuming it completes the parent task when starting RCA
    //     statusUpdate: _statusController.text,
    //     incidentId: widget.incidentId,
    //   );
    // } catch (e) {
    //   debugPrint(e.toString());
    // }
    context.pushNamed(
      Routes.rcaWorkflowBoardScreen,
      extra: {'incidentId': widget.incidentId},
    );
  }

  Color _getTimeBadgeBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return const Color(0xFF005B8B);
      case 'paused':
        return ColorHelper.black;
      case 'completed':
        return const Color(0xFF3DA229);
      case 'rejected':
        return const Color(0xFFFF3C56);
      default:
        return const Color(0xFF005B8B);
    }
  }

  Widget _buildTimerWidget(BuildContext context, InvestigationMemberTask task) {
    final timerColor = _getTimeBadgeBorderColor(task.status);
    if (TaskStatusHelper.isFinalState(task.status)) {
      return _buildStaticTimer(context, '00:00:00', timerColor);
    }
    if (TaskStatusHelper.isPaused(task.status)) {
      return _buildStaticTimer(context, '00:00:00', timerColor);
    }
    if (TaskStatusHelper.isInProgress(task.status) && task.startedAt != null) {
      return TimerWidget(
        key: ValueKey('timer_${task.taskId}'),
        startDuration: Duration.zero,
        timerColor: timerColor,
        shouldRun: true,
        iconAsset: Assets.tasktime,
        iconSize: 10,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        borderRadius: 24,
        borderWidth: 1,
        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: timerColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return _buildStaticTimer(context, '00:00:00', timerColor);
  }

  Widget _buildStaticTimer(BuildContext context, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Assets.tasktime, width: 10, height: 10, color: color),
          const SizedBox(width: 5),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationAttachmentsList(
    BuildContext context,
    InvestigationTeamMemberState state,
  ) {
    return Column(
      children: [
        // Uploaded items
        ...state.investigationAttachments.map((fileName) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(Assets.jpgImage, width: 24, height: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorHelper.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context
                        .read<InvestigationTeamMemberCubit>()
                        .removeAttachment(fileName);
                  },
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFEF9A9A),
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        }),
        // Uploading items
        ...state.uploadingFiles.map((upload) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upload.fileName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploading ${(upload.progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorHelper.black5.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: upload.progress,
                    backgroundColor: ColorHelper.black5.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4CAF50),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAttachmentList(
    BuildContext context,
    List<String> attachments, {
    bool isReporter = false,
  }) {
    // Mock attachments for reporter if empty, matching the UI image
    final List<String> items = (attachments.isEmpty && isReporter)
        ? ['Incident Photo.jpg', 'Incident Photo.jpg', 'Incident Photo.jpg']
        : attachments;

    if (items.isEmpty) return const SizedBox();

    return Column(
      children: items.map((att) {
        final fileName = att.isNotEmpty ? att : 'Attachment';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                child: Image.asset(Assets.jpgImage, width: 24, height: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fileName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.open_in_new,
                color: ColorHelper.black5,
                size: 20,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
