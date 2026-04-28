import 'dart:async';
import 'dart:io';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart';
import 'package:emergex/data/model/er_team_approver/incident_tasks_response.dart';
import 'package:emergex/data/model/er_team_leader/update_task_request.dart';
import 'package:emergex/data/remote_data_source/upload_doc_remote_data_source.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/case_report/model/file_upload_item.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/use_cases/my_task_use_case.dart';
import 'package:emergex/services/incident_recorder_service.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class TaskDetailsState extends Equatable {
  const TaskDetailsState({
    this.task,
    this.incidentId,
    this.selectedStatus,
    this.statusUpdate,
    this.originalStatusUpdate,
    this.hasStatusUpdateChanged = false,
    this.isRecording = false,
    this.recordingDuration = 0,
    this.textBeforeRecording,
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.errorMessage,
    this.ertUploadItems = const [],
  });

  final Task? task;
  final String? incidentId;
  final String? selectedStatus;
  final String? statusUpdate;
  final String? originalStatusUpdate;
  final bool hasStatusUpdateChanged;
  final bool isRecording;
  final int recordingDuration;
  final String?
  textBeforeRecording; // Text that existed before recording started
  final ProcessState processState;
  final bool isLoading;
  final String? errorMessage;
  final List<FileUploadItem> ertUploadItems;

  factory TaskDetailsState.initial({Task? task, String? incidentId}) {
    // Map API status to UI status for initial state
    String? initialStatus = task?.status;
    if (initialStatus != null) {
      final lowerStatus = initialStatus.toLowerCase();
      if (lowerStatus == 'inprogress') {
        initialStatus = 'In Progress';
      } else if (lowerStatus == 'paused') {
        initialStatus = 'Paused';
      } else if (lowerStatus == 'completed') {
        initialStatus = 'Completed';
      }
    }

    return TaskDetailsState(
      task: task,
      incidentId: incidentId,
      selectedStatus: initialStatus ?? 'In Progress',
      statusUpdate: task?.statusUpdate ?? '',
      originalStatusUpdate: task?.statusUpdate ?? '',
      hasStatusUpdateChanged: false,
      isRecording: false,
      recordingDuration: 0,
      textBeforeRecording: null,
      processState: ProcessState.none,
      isLoading: false,
      errorMessage: null,
      ertUploadItems: const [],
    );
  }

  TaskDetailsState copyWith({
    Task? task,
    String? incidentId,
    String? selectedStatus,
    String? statusUpdate,
    String? originalStatusUpdate,
    bool? hasStatusUpdateChanged,
    bool? isRecording,
    int? recordingDuration,
    String? textBeforeRecording,
    ProcessState? processState,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<FileUploadItem>? ertUploadItems,
  }) {
    return TaskDetailsState(
      task: task ?? this.task,
      incidentId: incidentId ?? this.incidentId,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      statusUpdate: statusUpdate ?? this.statusUpdate,
      originalStatusUpdate: originalStatusUpdate ?? this.originalStatusUpdate,
      hasStatusUpdateChanged:
          hasStatusUpdateChanged ?? this.hasStatusUpdateChanged,
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      textBeforeRecording: textBeforeRecording ?? this.textBeforeRecording,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      ertUploadItems: ertUploadItems ?? this.ertUploadItems,
    );
  }

  @override
  List<Object?> get props => [
    task,
    incidentId,
    selectedStatus,
    statusUpdate,
    isRecording,
    recordingDuration,
    textBeforeRecording,
    processState,
    isLoading,
    errorMessage,
    ertUploadItems,
  ];
}

/// Cubit for managing Task Details state
class TaskDetailsCubit extends Cubit<TaskDetailsState> {
  Timer? _recordingTimer;
  final IncidentRecorderService _recorderService = IncidentRecorderService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final MyTaskUseCase _useCase;
  late final TextEditingController statusController;
  StreamSubscription<String>? _transcriptSubscription;

  TaskDetailsCubit({
    Task? task,
    String? incidentId,
    String? taskId,
    required MyTaskUseCase useCase,
  }) : _useCase = useCase,
       super(TaskDetailsState.initial(task: task, incidentId: incidentId)) {
    statusController = TextEditingController(text: state.statusUpdate ?? '');

    _setupRecorderServiceStreams();

    // If task is null but taskId is provided, load the task
    if (task == null && taskId != null && taskId.isNotEmpty) {
      loadTask(taskId);
    }
  }

  /// Load task details by ID
  Future<void> loadTask(String taskId) async {
    if (isClosed) return;

    emit(
      state.copyWith(
        processState: ProcessState.loading,
        isLoading: true,
        errorMessage: null,
      ),
    );

    try {
      // 1. Try to fetch from My Tasks (assigned tasks)
      final response = await _useCase.getMyTasks();

      Task? foundTask;
      String? foundIncidentId;

      if (response.success == true && response.data != null) {
        final groups = response.data!.data;
        for (final group in groups) {
          for (final t in group.tasks) {
            if (t.taskId == taskId) {
              foundTask = t;
              foundIncidentId = group.incidentId;
              break;
            }
          }
          if (foundTask != null) break;
        }
      }

      // 2. If not found, try to fetch from Incident Tasks (approver/team view)
      if (foundTask == null) {
        try {
          // Use AppDI directly to avoid constructor changes - fallback mechanism
          final approverUseCase = AppDI.erTeamApproverDashboardUseCase;

          final searchIncidentId = state.incidentId;

          if (searchIncidentId != null && searchIncidentId.isNotEmpty) {
            final incidentResponse = await approverUseCase.getIncidentTasks(
              searchIncidentId,
              'all',
            );
            if (incidentResponse.success == true &&
                incidentResponse.data != null) {
              final incidentData = incidentResponse.data!;
              foundIncidentId = incidentData.incidentId;

              // Search in incident tasks
              for (final userTask in incidentData.tasks) {
                for (final t in userTask.tasks) {
                  if (t.taskId == taskId) {
                    // Map TaskItem (Approver) to Task (Leader)
                    foundTask = _mapTaskItemToTask(t, searchIncidentId);
                    break;
                  }
                }
                if (foundTask != null) break;
              }
            }
          }
        } catch (e) {
          debugPrint('Fallback search in Incident Tasks failed: $e');
        }
      }

      if (foundTask != null) {
        // Initialize status controller with the found task's update
        statusController.text = foundTask.statusUpdate ?? '';

        emit(
          state.copyWith(
            task: foundTask,
            incidentId: foundIncidentId ?? state.incidentId,
            selectedStatus: _mapApiStatusToUI(foundTask.status ?? ''),
            statusUpdate: foundTask.statusUpdate ?? '',
            originalStatusUpdate: foundTask.statusUpdate ?? '',
            processState: ProcessState.none,
            isLoading: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage: 'Task not found',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to load task: ${e.toString()}',
        ),
      );
    }
  }

  /// Helper to map TaskItem to Task
  Task _mapTaskItemToTask(TaskItem item, String incidentId) {
    return Task(
      taskId: item.taskId,
      projectId: '', // Not available in TaskItem
      taskName: item.taskName,
      taskDetails: item.taskDetails,
      attachments: item.attachments
          .map(
            (a) => Attachment(
              fileUrl: a.fileUrl,
              fileName: a.fileName,
              key: a.key,
            ),
          )
          .toList(),
      isDeleted: false,
      status: item.status,
      statusUpdate: item.statusUpdate,
      completedBy: item.completedBy,
      startedAt: item.startedAt != null
          ? DateTime.tryParse(item.startedAt!)
          : null,
      completedAt: item.completedAt != null
          ? DateTime.tryParse(item.completedAt!)
          : null,
      timeTaken: item.timeTaken,
      incidentIds: [incidentId],
      aiAnalysis: item.aiAnalysis,
    );
  }

  // ── ERT File Upload ───────────────────────────────────────────────────────

  /// Opens file picker and uploads each selected file with progress tracking
  Future<void> pickAndUploadErtFiles() async {
    if (isClosed) return;
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    for (final picked in result.files) {
      if (picked.path == null) continue;
      final id = const Uuid().v4();
      final item = FileUploadItem(
        id: id,
        fileName: picked.name,
        filePath: picked.path!,
        fileSize: picked.size,
        status: UploadStatus.uploading,
        progress: 0,
      );
      if (isClosed) return;
      emit(state.copyWith(ertUploadItems: [...state.ertUploadItems, item]));
      unawaited(_uploadErtFile(id, picked));
    }
  }

  Future<void> _uploadErtFile(String id, PlatformFile picked) async {
    // Simulate progress: ramp to 90% while upload runs
    Timer? progressTimer;
    int tick = 0;
    progressTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (isClosed) { progressTimer?.cancel(); return; }
      tick++;
      double target;
      if (tick < 10) {
        target = tick * 4.0; // 0 → 40 in first 3s
      } else {
        target = 40 + (tick - 10) * 2.5; // 40 → 90 slowly
      }
      if (target >= 90) { progressTimer?.cancel(); target = 90; }
      _updateErtItem(id, (f) { f.progress = target; return f; });
    });

    try {
      final remoteDS = getIt<OnboardingOrganizationStructureRemoteDataSource>();
      final response = await remoteDS.uploadOrganizationStructureFiles(
        [File(picked.path!)],
      );
      progressTimer.cancel();
      if (isClosed) return;

      if (response.success == true && response.data != null &&
          response.data!.files.isNotEmpty) {
        final uploaded = response.data!.files.first;
        _updateErtItem(id, (f) {
          f.status = UploadStatus.completed;
          f.progress = 100;
          f.fileUrl = uploaded.fileUrl;
          f.infoId = uploaded.key;
          return f;
        });
      } else {
        _updateErtItem(id, (f) {
          f.status = UploadStatus.failed;
          f.errorMessage = response.error ?? 'Upload failed';
          return f;
        });
      }
    } catch (e) {
      progressTimer.cancel();
      if (isClosed) return;
      _updateErtItem(id, (f) {
        f.status = UploadStatus.failed;
        f.errorMessage = e.toString();
        return f;
      });
    }
  }

  void _updateErtItem(String id, FileUploadItem Function(FileUploadItem) update) {
    if (isClosed) return;
    final updated = state.ertUploadItems.map((f) {
      if (f.id == id) return update(f);
      return f;
    }).toList();
    emit(state.copyWith(ertUploadItems: updated));
  }

  void removeErtUploadItem(String id) {
    if (isClosed) return;
    emit(state.copyWith(
      ertUploadItems: state.ertUploadItems.where((f) => f.id != id).toList(),
    ));
  }

  // ── Recording ────────────────────────────────────────────────────────────

  void _setupRecorderServiceStreams() {
    // Listen to transcript stream instead of using callbacks
    // This allows multiple screens to listen simultaneously without interfering
    _transcriptSubscription = _recorderService.transcriptStream.listen((
      transcript,
    ) {
      if (isClosed) return;
      debugPrint('Transcript update received from stream: $transcript');
      // Update status update text field with transcribed text
      updateTranscriptText(transcript);
    });
  }

  @override
  Future<void> close() async {
    // Cancel stream subscription - this doesn't affect other screens
    await _transcriptSubscription?.cancel();
    _transcriptSubscription = null;

    // Stop recording if active in this screen
    if (state.isRecording) {
      try {
        await _recorderService.stopRecording();
      } catch (e) {
        debugPrint('Error stopping recording during close: $e');
      }
    }

    statusController.dispose();
    _recordingTimer?.cancel();

    // Dispose the recorder service as it's now owned by this cubit instance
    _recorderService.dispose();
    _audioRecorder.dispose();

    return super.close();
  }

  /// Update selected status
  void updateStatus(String status) {
    if (isClosed) return;
    emit(
      state.copyWith(selectedStatus: status, processState: ProcessState.none),
    );
  }

  void updateStatusUpdate(String value) {
    if (isClosed) return;

    final trimmedValue = value.trim();
    final trimmedOriginal = (state.originalStatusUpdate ?? '').trim();

    final bool hasChanged =
        trimmedValue.isNotEmpty && trimmedValue != trimmedOriginal;

    emit(
      state.copyWith(
        statusUpdate: value,
        hasStatusUpdateChanged: hasChanged,
        processState: ProcessState.none,
      ),
    );
  }

  /// Update task data locally
  void updateTaskData(Task? task) {
    if (isClosed) return;
    emit(state.copyWith(task: task, processState: ProcessState.none));
  }

  /// Toggle recording state
  Future<void> toggleRecording() async {
    if (isClosed) {
      debugPrint('Cannot toggle recording: cubit is closed');
      return;
    }

    if (state.isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  /// Start recording
  Future<void> startRecording() async {
    if (isClosed) {
      debugPrint('Cannot start recording: cubit is closed');
      return;
    }

    try {
      // Check microphone permission
      if (!await _audioRecorder.hasPermission()) {
        if (!isClosed) {
          emit(state.copyWith(isRecording: false));
        }
        debugPrint('Microphone permission not granted');
        return;
      }

      // Store current text before recording starts
      final currentText = state.statusUpdate ?? '';

      // Update state to show recording started
      if (!isClosed) {
        emit(
          state.copyWith(
            isRecording: true,
            recordingDuration: 0,
            textBeforeRecording: currentText,
          ),
        );
      }

      // Start timer to update recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (isClosed || !state.isRecording) {
          timer.cancel();
          return;
        }
        emit(state.copyWith(recordingDuration: state.recordingDuration + 1));
      });

      // Start recording with WebSocket service
      await _recorderService.startRecording();
      debugPrint('Recording started successfully');
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      _recordingTimer?.cancel();
      _recordingTimer = null;
      if (!isClosed) {
        emit(state.copyWith(isRecording: false, recordingDuration: 0));
      }
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (isClosed) {
      debugPrint('Cannot stop recording: cubit is closed');
      return;
    }

    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Stop recording with WebSocket service
      await _recorderService.stopRecording();

      // Get final transcript if available
      final finalTranscript = _recorderService.currentTranscript;
      if (finalTranscript.isNotEmpty) {
        // Update with final transcript (preserving text before recording)
        updateTranscriptText(finalTranscript);
      }

      emit(
        state.copyWith(
          isRecording: false,
          recordingDuration: 0,
          textBeforeRecording: null,
        ),
      );

      debugPrint('Recording stopped successfully');
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      _recordingTimer?.cancel();
      _recordingTimer = null;
      emit(
        state.copyWith(
          isRecording: false,
          recordingDuration: 0,
          textBeforeRecording: null,
        ),
      );
    }
  }

  void updateTranscriptText(String transcript) {
    if (isClosed || transcript.isEmpty) return;

    final textBeforeRecording = state.textBeforeRecording ?? '';
    final newText = textBeforeRecording.isEmpty
        ? transcript
        : '$textBeforeRecording $transcript';

    statusController.text = newText.trim();
    statusController.selection = TextSelection.fromPosition(
      TextPosition(offset: statusController.text.length),
    );

    updateStatusUpdate(statusController.text);
  }

  /// Append transcribed text to status update (legacy method, kept for compatibility)
  void appendTranscribedText(String text) {
    updateTranscriptText(text);
  }

  /// Map API status to UI status
  String _mapApiStatusToUI(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'inprogress':
        return 'In Progress';
      case 'paused':
        return 'Paused';
      case 'completed':
        return 'Completed';
      case 'draft':
        return 'Draft';
      default:
        return apiStatus;
    }
  }

  /// Map UI/API status string to new API action value (lowercase)
  String _toAction(String status) {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'inprogress':
        return 'inprogress';
      case 'paused':
        return 'paused';
      case 'completed':
        return 'completed';
      case 'draft':
        return 'draft';
      default:
        return status.toLowerCase();
    }
  }

  /// Returns all completed ERT upload items as typed attachment requests
  List<UpdateTaskAttachmentRequest> _completedAttachments() {
    return state.ertUploadItems
        .where((f) => f.status == UploadStatus.completed && f.fileUrl != null)
        .map((item) {
          final ext = item.fileName.contains('.')
              ? item.fileName.split('.').last
              : '';
          return UpdateTaskAttachmentRequest(
            fileUrl: item.fileUrl!,
            fileType: item.fileType ?? ext,
            fileName: item.fileName,
            fileSize: item.fileSize ?? 0,
          );
        })
        .toList();
  }

  /// Update task via API — PATCH /incident/my-tasks/{incidentId}?type=ert
  Future<void> updateTask({
    required String status,
    String? statusUpdate,
  }) async {
    if (isClosed) {
      debugPrint('Cannot update task: cubit is closed');
      return;
    }

    final taskId = state.task?.taskId;
    final incidentId = state.incidentId;

    if (taskId == null || taskId.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Task ID is missing',
        processState: ProcessState.error,
      ));
      return;
    }

    emit(state.copyWith(
      processState: ProcessState.loading,
      isLoading: true,
      errorMessage: null,
      clearError: true,
    ));

    try {
      final response = await _useCase.updateTask(
        incidentId: incidentId ?? taskId,
        request: UpdateTaskRequest(
          taskId: taskId,
          action: _toAction(status),
          statusDescription: statusUpdate ?? state.statusUpdate,
          attachments: _completedAttachments(),
        ),
      );

      if (response.success == true) {
        final uiStatus = _mapApiStatusToUI(status);
        final currentTask = state.task;
        final updatedTask = currentTask != null
            ? Task(
                id: currentTask.id,
                taskId: currentTask.taskId,
                projectId: currentTask.projectId,
                taskName: currentTask.taskName,
                taskDetails: currentTask.taskDetails,
                attachments: currentTask.attachments,
                isDeleted: currentTask.isDeleted,
                createdAt: currentTask.createdAt,
                updatedAt: currentTask.updatedAt,
                status: status,
                statusUpdate: statusUpdate ?? state.statusUpdate,
                completedBy: currentTask.completedBy,
                startedAt: currentTask.startedAt,
                completedAt: currentTask.completedAt,
                timeTaken: currentTask.timeTaken,
                aiAnalysis: currentTask.aiAnalysis,
              )
            : null;

        emit(state.copyWith(
          task: updatedTask,
          selectedStatus: uiStatus,
          statusUpdate: statusUpdate ?? state.statusUpdate,
          originalStatusUpdate: statusUpdate ?? state.statusUpdate,
          hasStatusUpdateChanged: false,
          processState: ProcessState.done,
          isLoading: false,
          errorMessage: null,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: response.error ?? 'Failed to update task',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        processState: ProcessState.error,
        isLoading: false,
        errorMessage: 'Failed to update task: ${e.toString()}',
      ));
    }
  }
}
