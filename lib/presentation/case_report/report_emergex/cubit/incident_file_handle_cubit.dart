import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_observer.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/model/ai_summary_details.dart';
import 'package:emergex/presentation/case_report/model/upload_incident_request.dart';
import 'package:emergex/presentation/case_report/report_emergex/use_cases/upload_incident_use_case.dart';
import 'package:emergex/services/incident_recorder_service.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

enum RecordingStatus { idle, recording, paused, processing, error }

enum DialogStatus { open, closed }

enum WebSocketConnectionStatus { disconnected, connecting, connected, error }

class IncidentState extends Equatable {
  final List<IncidentDetails> data;
  final ProcessState processState;
  final ProcessState fileProcessState;
  final bool isLoading;
  final String? uuInfoId;
  final String? errorMessage;
  final String? incidentInformationTxt;
  final DialogStatus dialogStatus;
  final String? incidentText;
  final RecordingStatus recordingStatus;
  final int? recordingDuration;
  final String? currentlyPlayingId;
  final List<double> audioLevels; // Real-time audio levels for visualization
  final WebSocketConnectionStatus
  websocketConnectionStatus; // WebSocket connection status

  // WebSocket transcript and summary state
  final String currentTranscript;
  final String aiSummary;
  final List<String> questions;
  final List<String> examples;
  final int totalQuestionsLength;
  final int unansweredQuestionsLength;

  // File upload state for multiple files
  final Map<String, double> uploadProgress; // fileId -> progress (0.0 to 100.0)
  final Map<String, String> uploadingFileNames; // fileId -> fileName

  // Report submission progress state
  final double reportUploadProgress; // 0.0 to 100.0
  final bool isReportUploading;
  final String? projectId; // Selected project ID
  final List<String> immediateActionsTaken; // Optional immediate actions text

  const IncidentState({
    this.data = const [],
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.fileProcessState = ProcessState.none,
    this.errorMessage,
    this.incidentInformationTxt,
    this.dialogStatus = DialogStatus.closed,
    this.recordingStatus = RecordingStatus.idle,
    this.recordingDuration = 0,
    this.currentlyPlayingId,
    this.audioLevels = const [],
    this.websocketConnectionStatus = WebSocketConnectionStatus.disconnected,
    this.currentTranscript = "",
    this.aiSummary = "",
    this.questions = const [],
    this.examples = const [],
    this.totalQuestionsLength = 0,
    this.unansweredQuestionsLength = 0,
    this.uploadProgress = const {},
    this.uploadingFileNames = const {},
    this.incidentText = "",
    this.uuInfoId = "",
    this.reportUploadProgress = 0.0,
    this.isReportUploading = false,
    this.projectId,
    this.immediateActionsTaken = const [],
  });

  factory IncidentState.initial() =>
      const IncidentState(processState: ProcessState.none);

  IncidentState copyWith({
    List<IncidentDetails>? data,
    ProcessState? processState,
    ProcessState? fileProcessState,
    bool? isLoading = false,
    String? errorMessage,
    String? incidentInformationTxt,
    DialogStatus? dialogStatus,
    RecordingStatus? recordingStatus,
    int? recordingDuration,
    String? currentlyPlayingId,
    bool clearCurrentlyPlayingId = false,
    List<double>? audioLevels,
    WebSocketConnectionStatus? websocketConnectionStatus,
    String? currentTranscript,
    String? aiSummary,
    List<String>? questions,
    List<String>? examples,
    int? totalQuestionsLength,
    int? unansweredQuestionsLength,
    Map<String, double>? uploadProgress,
    Map<String, String>? uploadingFileNames,
    String? incidentText,
    String? uuInfoId,
    double? reportUploadProgress,
    bool? isReportUploading,
    String? projectId,
    List<String>? immediateActionsTaken,
  }) {
    return IncidentState(
      data: data ?? this.data,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      fileProcessState: fileProcessState ?? this.fileProcessState,
      errorMessage: errorMessage, // Don't carry over old errors
      incidentInformationTxt:
          incidentInformationTxt ?? this.incidentInformationTxt,
      dialogStatus: dialogStatus ?? this.dialogStatus,
      recordingStatus: recordingStatus ?? this.recordingStatus,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      currentlyPlayingId: clearCurrentlyPlayingId
          ? null
          : currentlyPlayingId ?? this.currentlyPlayingId,
      audioLevels: audioLevels ?? this.audioLevels,
      websocketConnectionStatus:
          websocketConnectionStatus ?? this.websocketConnectionStatus,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      aiSummary: aiSummary ?? this.aiSummary,
      questions: questions ?? this.questions,
      examples: examples ?? this.examples,
      totalQuestionsLength: totalQuestionsLength ?? this.totalQuestionsLength,
      unansweredQuestionsLength:
          unansweredQuestionsLength ?? this.unansweredQuestionsLength,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadingFileNames: uploadingFileNames ?? this.uploadingFileNames,
      incidentText: incidentText ?? this.incidentText,
      uuInfoId: uuInfoId ?? this.uuInfoId,
      reportUploadProgress: reportUploadProgress ?? this.reportUploadProgress,
      isReportUploading: isReportUploading ?? this.isReportUploading,
      projectId: projectId ?? this.projectId,
      immediateActionsTaken: immediateActionsTaken ?? this.immediateActionsTaken,
    );
  }

  @override
  List<Object?> get props => [
    data,
    processState,
    isLoading,
    fileProcessState,
    errorMessage,
    incidentInformationTxt,
    recordingStatus,
    recordingDuration,
    currentlyPlayingId,
    audioLevels,
    websocketConnectionStatus,
    currentTranscript,
    aiSummary,
    questions,
    examples,
    totalQuestionsLength,
    unansweredQuestionsLength,
    uploadProgress,
    uploadingFileNames,
    incidentText,
    uuInfoId,
    reportUploadProgress,
    isReportUploading,
    projectId,
    immediateActionsTaken,
  ];
}

class IncidentFileHandleCubit extends Cubit<IncidentState> {
  final UploadIncidentUseCase _uploadIncidentUseCase;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final IncidentRecorderService _websocketService = IncidentRecorderService();
  Timer? _recordingTimer;
  final Map<String, Timer?> _progressTimers = {}; // fileId -> Timer
  Timer? _fallbackAnimationTimer;
  Timer? _aiSummaryDebounceTimer;
  Timer? _reportProgressTimer; // Timer for report upload progress animation
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  bool _isCancelDialogOpen = false;
  final Map<String, bool> _isFileUploadCancelled = {}; // fileId -> isCancelled
  final Map<String, CancelToken?> _uploadCancelTokens =
      {}; // fileId -> CancelToken
  final Map<String, Timer> _fileProgressTimers = {}; // fileId -> Timer
  final Map<String, Stopwatch> _fileStopwatches = {}; // fileId -> Stopwatch
  final Map<String, String> _fileInfoIds =
      {}; // fileId -> infoId (v1Id) for delete API

  // Report screen state (kept outside Equatable to avoid unnecessary rebuilds)
  final TextEditingController incidentInfoController = TextEditingController();
  RecordingStatus? _previousRecordingStatus;
  bool allowPop = false;
  bool isDialogShowing = false;

  IncidentFileHandleCubit(this._uploadIncidentUseCase)
    : super(IncidentState.initial()) {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (state.currentlyPlayingId != null) {
        emit(state.copyWith(currentlyPlayingId: null));
      }
    });

    // Set up websocket service callbacks
    _websocketService.onTranscriptUpdate = (transcript) {
      debugPrint('Transcript update received in cubit: $transcript');
      emit(
        state.copyWith(
          currentTranscript: transcript,
          incidentInformationTxt: transcript,
        ),
      );
      debugPrint('Transcript updated in state: ${state.currentTranscript}');
    };

    _websocketService.onSummaryUpdate = (summary) {
      debugPrint('AI Summary update received in cubit: $summary');
      updateAiSummary(summary);
      debugPrint('AI Summary updated in state: ${state.aiSummary}');
    };

    _websocketService.onSummaryApiUpdate = (summaryRes) {
      debugPrint(
        'AI Summary API update received in cubit: ${summaryRes.toString()}',
      );
      final List<String> questions = summaryRes.unansweredQuestions
          .map((q) => q.question)
          .toList();
      final List<String> examples = summaryRes.unansweredQuestions
          .map((q) => q.example)
          .toList();
      emit(
        state.copyWith(
          processState: ProcessState.done,
          aiSummary: summaryRes.summary,
          incidentInformationTxt: summaryRes.summary,
          questions: questions,
          examples: examples,
          totalQuestionsLength: summaryRes.totalQuestionsLength,
          unansweredQuestionsLength: summaryRes.unansweredQuestionsLength,
        ),
      );
    };

    _websocketService.onQuestionsUpdate = (questions) {
      emit(state.copyWith(questions: questions));
      debugPrint('Questions updated in state: ${state.questions}');
    };
    _websocketService.onExamplesUpdate = (examples) {
      emit(state.copyWith(examples: examples));
      debugPrint('Examples updated in state: ${state.examples}');
    };
    _websocketService.onTotalQuestionsLengthUpdate = (totalQuestionsLength) {
      emit(state.copyWith(totalQuestionsLength: totalQuestionsLength));
    };
    _websocketService
        .onUnansweredQuestionsLengthUpdate = (unansweredQuestionsLength) {
      emit(
        state.copyWith(unansweredQuestionsLength: unansweredQuestionsLength),
      );
    };

    _websocketService.onAudioLevelsUpdate = (audioLevels) {
      emit(state.copyWith(audioLevels: audioLevels));
    };

    _websocketService.onConnectionStatusChange = (isConnected) {
      emit(
        state.copyWith(
          websocketConnectionStatus: isConnected
              ? WebSocketConnectionStatus.connected
              : WebSocketConnectionStatus.disconnected,
        ),
      );
    };

    _websocketService.onRecordingStatusChange = (isRecording) {};
  }
  Future<void> setDialogOpen(bool isOpen) async {
    emit(
      state.copyWith(
        dialogStatus: isOpen ? DialogStatus.open : DialogStatus.closed,
      ),
    );
  }

  bool getDialogOpen() => state.dialogStatus == DialogStatus.open;

  void setCancelDialogOpen(bool isOpen) {
    _isCancelDialogOpen = isOpen;
    if (isOpen) {
      // Cancel any pending AI summary timer when dialog opens
      _aiSummaryDebounceTimer?.cancel();
      _websocketService.cancelAISummary();
    }
  }

  void clearAisummaryIncident() {
    _websocketService.cancelAISummary();

    emit(
      state.copyWith(
        aiSummary: "",
        incidentInformationTxt: "",
        currentTranscript: "",
        incidentText: "",
        questions: [],
        examples: [],
        totalQuestionsLength: 0,
        unansweredQuestionsLength: 0,
        processState: ProcessState.none,
      ),
    );
  }

  void updateImmediateActions(String text) {
    emit(state.copyWith(immediateActionsTaken: text.isEmpty ? [] : [text]));
  }

  void updateIncidentText(String text) {
    if (text.isEmpty) {
      emit(
        state.copyWith(
          incidentText: "",
          aiSummary: "",
          questions: [],
          examples: [],
          totalQuestionsLength: 0,
          unansweredQuestionsLength: 0,
          processState: ProcessState.none,
        ),
      );
    } else {
      emit(
        state.copyWith(
          incidentText: text,
          aiSummary: "",
          questions: [],
          examples: [],
          totalQuestionsLength: 0,
          unansweredQuestionsLength: 0,
        ),
      );
    }
  }

  void setProjectId(String? projectId) {
    emit(state.copyWith(projectId: projectId));
  }

  void updateIncidentInformation(String infoTxt, BuildContext context) {
    _aiSummaryDebounceTimer?.cancel();
    _aiSummaryDebounceTimer = Timer(const Duration(seconds: 3), () {
      emit(
        state.copyWith(
          incidentInformationTxt: infoTxt,
          currentTranscript: infoTxt,
        ),
      );

      // Don't call AI summary if cancel dialog is open

      if (!_isCancelDialogOpen &&
          state.recordingStatus != RecordingStatus.recording &&
          infoTxt.trim().isNotEmpty) {
        FocusScope.of(context).unfocus();
        _callDebouncedAiSummary(infoTxt);
      }
    });
  }

  Future<void> startRecording(BuildContext context) async {
    try {
      _aiSummaryDebounceTimer?.cancel();
      if (!await _recorder.hasPermission() && context.mounted) {
        showErrorDialog(
          context,
          () {
            back();
            openAppSettings();
          },
          () {
            back();
          },
          TextHelper.microphonePermissionNotGranted,
          '',
          TextHelper.settings,
          TextHelper.goBack,
        );
        return;
      }

      // Set connection status to connecting
      emit(
        state.copyWith(
          websocketConnectionStatus: WebSocketConnectionStatus.connecting,
        ),
      );

      await _websocketService.startRecording();

      emit(
        state.copyWith(
          recordingStatus: RecordingStatus.recording,
          recordingDuration: 0,
          audioLevels: List.filled(12, 0.0),
          currentTranscript: "",
          errorMessage: null,
        ),
      );
      _startRecordingTimer();
    } catch (e) {
      debugPrint('Recording error details: $e');
      emit(
        state.copyWith(
          recordingStatus: RecordingStatus.error,
          websocketConnectionStatus: WebSocketConnectionStatus.error,
          errorMessage: 'Failed to start recording: ${e.toString()}',
        ),
      );
    }
  }

  void updateAiSummary(String summary) {
    if (summary.isNotEmpty) {
      emit(state.copyWith(aiSummary: summary));
    }
  }

  /// Call AI summary API with debounced text input
  Future<void> _callDebouncedAiSummary(String infoTxt) async {
    try {
      debugPrint('Calling debounced AI summary for text: $infoTxt');
      emit(state.copyWith(processState: ProcessState.loading));
      final incidentId = state.data.isNotEmpty
          ? state.data.first.incidentId
          : null;
      await _websocketService.getAISummary(infoTxt, incidentId: incidentId);
    } catch (e) {
      debugPrint('Error calling debounced AI summary: $e');
    } finally {
      emit(state.copyWith(processState: ProcessState.done));
    }
  }

  Future<void> stopRecording() async {
    try {
      _recordingTimer?.cancel();

      // Stop websocket recording
      final path = await _websocketService.stopRecording();

      emit(
        state.copyWith(
          processState: ProcessState.loading,
          recordingStatus: RecordingStatus.idle,
          recordingDuration: 0,
          audioLevels: const [],
        ),
      );

      if (path != null) {
        final incidentId = state.data.isNotEmpty
            ? state.data.first.incidentId
            : null;
        if (incidentId == null || incidentId.isEmpty) {
          var uuid = Uuid();
          String v1Id = uuid.v1();
          emit(state.copyWith(uuInfoId: v1Id));
          await createIncident(path, state.aiSummary, state.currentTranscript);
        } else {
          await updateIncident(
            incidentId,
            path,
            state.aiSummary,
            state.currentTranscript,
          );
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          recordingStatus: RecordingStatus.error,
          errorMessage: 'Failed to stop recording: $e',
        ),
      );
    }
  }

  Future<void> pauseResumeRecording() async {
    try {
      debugPrint(
        'pauseResumeRecording called in cubit - current status: ${state.recordingStatus}',
      );

      if (state.recordingStatus == RecordingStatus.recording) {
        debugPrint('Pausing recording from cubit...');
        emit(
          state.copyWith(isLoading: true, processState: ProcessState.loading),
        );
        _recordingTimer?.cancel();
        await _websocketService.pauseResumeRecording(
          state.incidentInformationTxt ?? '',
        );
        emit(
          state.copyWith(
            recordingStatus: RecordingStatus.paused,
            isLoading: false,
            processState: ProcessState.done,
            incidentText: state.currentTranscript,
          ),
        );
        debugPrint('Recording paused successfully');
      } else if (state.recordingStatus == RecordingStatus.paused) {
        debugPrint('Resuming recording from cubit...');
        await _websocketService.pauseResumeRecording(
          state.incidentInformationTxt ?? '',
        );
        _startRecordingTimer();
        emit(state.copyWith(recordingStatus: RecordingStatus.recording));
        debugPrint('Recording resumed successfully');
      } else {
        emit(state.copyWith(processState: ProcessState.none));
        debugPrint(
          'pauseResumeRecording called but not in recording/paused state',
        );
      }
    } catch (e) {
      debugPrint('Error in pauseResumeRecording: $e');
      emit(
        state.copyWith(
          recordingStatus: RecordingStatus.error,
          errorMessage: 'Failed to pause/resume recording: $e',
          isLoading: false,
          processState: ProcessState.error,
        ),
      );
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.recordingStatus == RecordingStatus.recording) {
        emit(
          state.copyWith(recordingDuration: (state.recordingDuration ?? 0) + 1),
        );
      }
    });
  }

  void _stopAudioLevelMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _fallbackAnimationTimer?.cancel();
    _fallbackAnimationTimer = null;
  }

  // --- Audio Playback Logic ---
  Future<void> playAudio(String? fileUrl, String recordingId) async {
    try {
      if (state.currentlyPlayingId == recordingId) {
        await _audioPlayer.stop();
        emit(state.copyWith(currentlyPlayingId: null));
      } else {
        if (fileUrl == null || fileUrl.isEmpty) {
          throw Exception('No valid audio source found');
        }
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(fileUrl));
        emit(state.copyWith(currentlyPlayingId: recordingId));
      }
    } catch (e) {
      emit(
        state.copyWith(
          recordingStatus: RecordingStatus.error,
          errorMessage: 'Failed to play recording.',
        ),
      );
    }
  }

  void stopAudio() {
    _audioPlayer.stop();
    emit(state.copyWith(currentlyPlayingId: null));
  }

  void cancelUpload() {
    // Cancel all file uploads
    for (var fileId in _uploadCancelTokens.keys.toList()) {
      cancelFileUpload(fileId);
    }
  }

  Future<void> cancelFileUpload(String fileId) async {
    // Get the infoId before removing from maps
    final infoId = _fileInfoIds[fileId];

    // Mark file as cancelled
    _isFileUploadCancelled[fileId] = true;

    // Cancel progress timer
    _progressTimers[fileId]?.cancel();
    _progressTimers.remove(fileId);

    // Cancel file-specific timers
    _fileProgressTimers[fileId]?.cancel();
    _fileProgressTimers.remove(fileId);
    _fileStopwatches[fileId]?.stop();
    _fileStopwatches.remove(fileId);

    // Cancel the ongoing Dio upload request for this file
    _uploadCancelTokens[fileId]?.cancel('Upload cancelled by user');
    _uploadCancelTokens.remove(fileId);

    // Remove infoId mapping
    _fileInfoIds.remove(fileId);

    // Remove from state immediately for UI feedback
    final newProgress = Map<String, double>.from(state.uploadProgress);
    final newFileNames = Map<String, String>.from(state.uploadingFileNames);
    newProgress.remove(fileId);
    newFileNames.remove(fileId);

    // Update state to remove cancelled file from UI
    emit(
      state.copyWith(
        uploadProgress: newProgress,
        uploadingFileNames: newFileNames,
        fileProcessState: newProgress.isEmpty
            ? ProcessState.none
            : ProcessState.loading,
      ),
    );

    // Call delete API with isCalncel=true if infoId exists
    if (infoId != null && infoId.isNotEmpty) {
      try {
        await _uploadIncidentUseCase.deleteFile(DeleteFileRequest(
          publicId: infoId,
          fileType: 'file',
          isCancel: true,
        ));
        debugPrint('File deleted from server after cancellation: $infoId');
      } catch (e) {
        debugPrint('Failed to delete cancelled file from server: $e');
        // Don't show error to user as the file was already cancelled
      }
    }
  }

  Future<void> resetRecording() async {
    try {
      _recordingTimer?.cancel();

      // Cancel any pending AI summary API call
      _websocketService.cancelAISummary();
      // _websocketService.dispose();
      emit(
        state.copyWith(
          recordingStatus: RecordingStatus.idle,
          recordingDuration: 0,
          audioLevels: const [],
          currentTranscript: "",
          aiSummary: "",
          incidentInformationTxt: "",
          examples: [],
          questions: [],
          incidentText: "",
          totalQuestionsLength: 0,
          unansweredQuestionsLength: 0,
        ),
      );

      // Stop websocket recording
      _websocketService.stopRecording();
    } catch (e) {
      emit(
        state.copyWith(
          recordingStatus: RecordingStatus.error,
          errorMessage: 'Failed to reset recording: $e',
        ),
      );
    }
  }

  Future<void> pickAndUploadFiles() async {
    try {
      final incidentId = state.data.isNotEmpty
          ? state.data.first.incidentId
          : null;
      if (incidentId == null) {
        emit(
          state.copyWith(
            errorMessage: 'Please record audio before adding files.',
          ),
        );
        return;
      }
      await _pickAndUploadFilesForIncident(incidentId);
    } catch (e) {
      // Cancel all progress timers
      for (var timer in _progressTimers.values) {
        timer?.cancel();
      }
      _progressTimers.clear();
      emit(
        state.copyWith(
          fileProcessState: ProcessState.error,
          uploadProgress: {},
          uploadingFileNames: {},
        ),
      );
    }
  }

  Future<void> pickAndUploadFilesForExistingIncident(String incidentId) async {
    try {
      await _pickAndUploadFilesForIncident(incidentId);
    } catch (e) {
      // Cancel all progress timers
      for (var timer in _progressTimers.values) {
        timer?.cancel();
      }
      _progressTimers.clear();
      emit(
        state.copyWith(
          fileProcessState: ProcessState.error,
          uploadProgress: {},
          uploadingFileNames: {},
        ),
      );
    }
  }

  /// Upload a single file with individual progress tracking
  Future<void> _uploadSingleFile(
    PlatformFile platformFile,
    String incidentId,
    String fileId,
  ) async {
    final filePath = platformFile.path;
    if (filePath == null) return;

    // Create cancel token for this file
    final cancelToken = CancelToken();
    _uploadCancelTokens[fileId] = cancelToken;

    // Initialize progress and file name in state
    final updatedProgress = Map<String, double>.from(state.uploadProgress)
      ..[fileId] = 0.0;
    final updatedFileNames = Map<String, String>.from(state.uploadingFileNames)
      ..[fileId] = platformFile.name;

    emit(
      state.copyWith(
        uploadProgress: updatedProgress,
        uploadingFileNames: updatedFileNames,
        fileProcessState: ProcessState.loading,
      ),
    );

    // Start progress simulation
    final stopwatch = Stopwatch()..start();
    _fileStopwatches[fileId] = stopwatch;

    final progressTimer = Timer.periodic(const Duration(milliseconds: 300), (
      timer,
    ) {
      // Check if file was cancelled
      if (!_uploadCancelTokens.containsKey(fileId) || cancelToken.isCancelled) {
        timer.cancel();
        return;
      }

      final elapsed = stopwatch.elapsedMilliseconds / 5000.0; // 5 seconds total
      double progress;

      // Mimic 40% → 80% → 90% → 98% pattern
      if (elapsed < 0.4) {
        progress = elapsed * 1.0; // fast: 0-40%
      } else if (elapsed < 0.8) {
        progress = 0.4 + (elapsed - 0.4) * 0.5; // medium: 40-80%
      } else if (elapsed < 0.9) {
        progress = 0.9 * elapsed; // slow: 80-90%
      } else {
        progress = min(elapsed, 0.98); // very slow: stop at 98%
      }

      // Update progress for this specific file
      final currentProgress = Map<String, double>.from(state.uploadProgress)
        ..[fileId] = (progress * 100).clamp(0.0, 99.0);
      emit(state.copyWith(uploadProgress: currentProgress));
    });
    _fileProgressTimers[fileId] = progressTimer;

    try {
      var uuid = Uuid();
      String v1Id = uuid.v1();
      emit(state.copyWith(uuInfoId: v1Id));

      // Store the infoId for this file (for cancellation cleanup)
      _fileInfoIds[fileId] = v1Id;

      // Upload single file
      final response = await _uploadIncidentUseCase.updateIncident(
        UpdateIncidentRequest(
          incidentId: incidentId,
          filePath: filePath,
          uuInfoId: v1Id,
          projectId: state.projectId,
          cancelToken: cancelToken,
        ),
      );

      // Cancel progress timer
      progressTimer.cancel();
      stopwatch.stop();
      _fileProgressTimers.remove(fileId);
      _fileStopwatches.remove(fileId);
      _uploadCancelTokens.remove(fileId);
      _fileInfoIds.remove(fileId); // Clean up infoId mapping

      if (response.success == true && response.data != null) {
        // Set incident overview if not present
        if (response.data?.incident == null) {
          response.data?.incident = {
            'incidentOverview': response.data?.emergexCaseSummary,
          };
        }

        // Remove this file from progress tracking
        final finalProgress = Map<String, double>.from(state.uploadProgress)
          ..remove(fileId);
        final finalFileNames = Map<String, String>.from(
          state.uploadingFileNames,
        )..remove(fileId);

        emit(
          state.copyWith(
            data: [response.data!],
            uploadProgress: finalProgress,
            uploadingFileNames: finalFileNames,
            fileProcessState: finalProgress.isEmpty
                ? ProcessState.done
                : ProcessState.loading,
          ),
        );
      } else {
        // Remove from progress tracking on error
        final finalProgress = Map<String, double>.from(state.uploadProgress)
          ..remove(fileId);
        final finalFileNames = Map<String, String>.from(
          state.uploadingFileNames,
        )..remove(fileId);

        emit(
          state.copyWith(
            uploadProgress: finalProgress,
            uploadingFileNames: finalFileNames,
            fileProcessState: finalProgress.isEmpty
                ? ProcessState.error
                : ProcessState.loading,
            errorMessage: 'Failed to upload file: ${platformFile.name}',
          ),
        );
      }
    } catch (e) {
      // Cancel progress timer on error
      progressTimer.cancel();
      stopwatch.stop();
      _fileProgressTimers.remove(fileId);
      _fileStopwatches.remove(fileId);
      _uploadCancelTokens.remove(fileId);
      _fileInfoIds.remove(fileId); // Clean up infoId mapping

      // Check if error is due to cancellation
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // Remove from progress tracking
        final finalProgress = Map<String, double>.from(state.uploadProgress)
          ..remove(fileId);
        final finalFileNames = Map<String, String>.from(
          state.uploadingFileNames,
        )..remove(fileId);

        emit(
          state.copyWith(
            uploadProgress: finalProgress,
            uploadingFileNames: finalFileNames,
            fileProcessState: finalProgress.isEmpty
                ? ProcessState.none
                : ProcessState.loading,
          ),
        );
      } else {
        // Remove from progress tracking on error
        final finalProgress = Map<String, double>.from(state.uploadProgress)
          ..remove(fileId);
        final finalFileNames = Map<String, String>.from(
          state.uploadingFileNames,
        )..remove(fileId);

        emit(
          state.copyWith(
            uploadProgress: finalProgress,
            uploadingFileNames: finalFileNames,
            fileProcessState: finalProgress.isEmpty
                ? ProcessState.error
                : ProcessState.loading,
            errorMessage:
                'Failed to upload file ${platformFile.name}: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFilesForIncident(String incidentId) async {
    try {
      // Set loading state before opening file picker
      emit(state.copyWith(fileProcessState: ProcessState.loading));

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['png', 'jpeg', 'gif', 'webp'],
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled file picker or no files selected
        emit(
          state.copyWith(
            fileProcessState: ProcessState.none,
            uploadProgress: {},
            uploadingFileNames: {},
          ),
        );
        return;
      }

      const maxFileSize = 15 * 1024 * 1024; // 15 MB in bytes
      final validFiles = <PlatformFile>[];
      final invalidFiles = <String>[];

      // Validate file sizes
      for (var file in result.files) {
        if (file.size > maxFileSize) {
          invalidFiles.add(file.name);
        } else {
          validFiles.add(file);
        }
      }

      // Show snackbar for invalid files but continue with valid ones
      if (invalidFiles.isNotEmpty) {
        final invalidFilesList = invalidFiles.join(", ");
        final message = invalidFiles.length == 1
            ? '$invalidFilesList exceeds 15 MB limit. Skipping this file.'
            : 'These files exceed 15 MB limit: $invalidFilesList. Skipping these files.';

        // Show snackbar if context is available
        final context = NavObserver.context;
        if (context != null && context.mounted) {
          showSnackBar(context, message, isSuccess: false);
        }
      }

      // If no valid files, return early
      if (validFiles.isEmpty) {
        emit(
          state.copyWith(
            fileProcessState: ProcessState.none,
            uploadProgress: {},
            uploadingFileNames: {},
            errorMessage: invalidFiles.isNotEmpty
                ? 'All selected files exceed 15 MB limit. Please choose smaller files.'
                : null,
          ),
        );
        return;
      }

      // Upload all files in parallel using Future.wait
      await Future.wait(
        validFiles.map((platformFile) {
          var uuid = Uuid();
          String fileId = uuid.v1();
          return _uploadSingleFile(platformFile, incidentId, fileId);
        }),
        eagerError: false, // Continue uploading other files even if one fails
      );
    } catch (e) {
      // Handle any errors during file picking
      emit(
        state.copyWith(
          fileProcessState: state.uploadProgress.isEmpty
              ? ProcessState.error
              : ProcessState.loading,
          errorMessage: 'Failed to pick files: ${e.toString()}',
        ),
      );
    }
  }

  // --- Core API Methods ---
  Future<void> createIncident(
    String? filePath,
    String? incidentText,
    String? incidentInformations,
  ) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          uploadProgress: {},
          uploadingFileNames: {},
          incidentText: incidentText ?? "",
        ),
      );

      final response = await _uploadIncidentUseCase.createIncident(
        CreateIncidentRequest(
          filePath: filePath,
          incidentText: incidentText,
          incidentInformations: incidentInformations,
          projectId: state.projectId,
          aiSummaryResponse: AiSummaryResponse(
            summary: state.aiSummary,
            unansweredQuestions: state.questions
                .map(
                  (question) => Question(
                    question: question,
                    example: state.examples[state.questions.indexOf(question)],
                  ),
                )
                .toList(),
            totalQuestionsLength: state.totalQuestionsLength,
            unansweredQuestionsLength: state.unansweredQuestionsLength,
          ),
          immediateActionsTaken: state.immediateActionsTaken.isNotEmpty
              ? state.immediateActionsTaken
              : null,
        ),
      );

      if (response.success == true && response.data != null) {
        response.data?.incident = {
          'incidentOverview': response.data?.emergexCaseSummary,
        };
        final qData = response.data!.questionsData;
        final serverQ =
            qData != null ? AiSummaryResponse.fromJson(qData) : null;
        emit(
          state.copyWith(
            processState: ProcessState.done,
            data: [response.data!],
            uploadProgress: {},
            uploadingFileNames: {},
            aiSummary: serverQ?.summary ?? '',
            incidentInformationTxt: '',
            questions: serverQ?.unansweredQuestions
                    .map((q) => q.question)
                    .toList() ??
                [],
            examples: serverQ?.unansweredQuestions
                    .map((q) => q.example)
                    .toList() ??
                [],
            totalQuestionsLength: serverQ?.totalQuestionsLength ?? 0,
            unansweredQuestionsLength:
                serverQ?.unansweredQuestionsLength ?? 0,
            incidentText: "",
            currentTranscript: "",
            immediateActionsTaken: [],
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            uploadProgress: {},
            uploadingFileNames: {},
            aiSummary: '',
            incidentInformationTxt: '',
            currentTranscript: '',
            questions: [],
            examples: [],
            totalQuestionsLength: 0,
            unansweredQuestionsLength: 0,
            incidentText: "",
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          uploadProgress: {},
          uploadingFileNames: {},
          errorMessage: e.toString(),
          aiSummary: '',
          incidentInformationTxt: '',
          questions: [],
          examples: [],
          totalQuestionsLength: 0,
          unansweredQuestionsLength: 0,
          incidentText: "",
        ),
      );
    }
  }

  Future<void> updateIncident(
    String incidentId,
    String? filePath,
    String? incidentText,
    String? incidentInformations,
  ) async {
    try {
      var uuid = Uuid();
      String v1Id = uuid.v1();
      emit(state.copyWith(uuInfoId: v1Id));
      final response = await _uploadIncidentUseCase.updateIncident(
        UpdateIncidentRequest(
          incidentId: incidentId,
          filePath: filePath,
          incidentText: incidentText,
          incidentInformations: incidentInformations,
          uuInfoId: v1Id,
          projectId: state.projectId,
          aiSummaryResponse: AiSummaryResponse(
            summary: state.aiSummary,
            unansweredQuestions: state.questions
                .map(
                  (question) => Question(
                    question: question,
                    example: state.examples[state.questions.indexOf(question)],
                  ),
                )
                .toList(),
            totalQuestionsLength: state.totalQuestionsLength,
            unansweredQuestionsLength: state.unansweredQuestionsLength,
          ),
          immediateActionsTaken: state.immediateActionsTaken.isNotEmpty
              ? state.immediateActionsTaken
              : null,
        ),
      );

      emit(state.copyWith(processState: ProcessState.loading));

      if (response.success == true && response.data != null) {
        response.data?.incident = {
          'incidentOverview': response.data?.emergexCaseSummary,
        };
        final qData = response.data!.questionsData;
        final serverQ =
            qData != null ? AiSummaryResponse.fromJson(qData) : null;
        emit(
          state.copyWith(
            processState: ProcessState.done,
            data: [response.data!],
            aiSummary: '',
            incidentInformationTxt: '',
            questions: [],
            examples: [],
            totalQuestionsLength: 0,
            unansweredQuestionsLength: 0,
            incidentText: "",
            currentTranscript: "",
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            errorMessage:
                'Incident update failed. ${response.error?.toString() ?? ''}'
                    .trim(),
            aiSummary: '',
            incidentInformationTxt: '',
            questions: [],
            examples: [],
            totalQuestionsLength: 0,
            unansweredQuestionsLength: 0,
            incidentText: "",
          ),
        );
        throw Exception('Failed to update incident with file: $filePath');
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          errorMessage: 'Incident update failed. ${e.toString()}',
          aiSummary: '',
          incidentInformationTxt: '',
          questions: [],
          examples: [],
          totalQuestionsLength: 0,
          unansweredQuestionsLength: 0,
          incidentText: "",
        ),
      );
      rethrow;
    }
  }

  Future<bool> deleteFileFromServer(
    String publicId,
    String fileType,
    bool? isCalncel,
  ) async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));
      final response = await _uploadIncidentUseCase.deleteFile(
        DeleteFileRequest(
          publicId: publicId,
          fileType: fileType,
          isCancel: isCalncel ?? false,
        ),
      );
      if (response.success == true) {
        if (state.data.isNotEmpty && state.data.first.incidentId != null) {
          await _refreshIncidentData(state.data.first.incidentId!);
        } else {
          emit(state.copyWith(processState: ProcessState.done));
        }
        return true;
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            errorMessage: 'Failed to delete file.',
          ),
        );
        return false;
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          errorMessage: 'Failed to delete file.',
        ),
      );
      return false;
    }
  }

  Future<void> _refreshIncidentData(String incidentId) async {
    try {
      emit(state.copyWith(processState: ProcessState.loading));
      final response = await _uploadIncidentUseCase.getIncidentById(incidentId);

      if (response.success == true && response.data != null) {
        if (response.data?.incident == null) {
          response.data?.incident = {
            'incidentOverview': response.data?.emergexCaseSummary,
          };
        }
        emit(
          state.copyWith(
            processState: ProcessState.done,
            data: [response.data!],
          ),
        );
      } else {
        emit(state.copyWith(processState: ProcessState.error));
      }
    } catch (e) {
      emit(state.copyWith(processState: ProcessState.error));
    }
  }

  Future<void> reportIncident(String incidentId, BuildContext context) async {
    try {
      // Initialize progress
      emit(
        state.copyWith(
          isReportUploading: true,
          reportUploadProgress: 0.0,
          processState: ProcessState.loading,
        ),
      );

      // Start animation
      _startReportProgressAnimation();

      final response = await _uploadIncidentUseCase.reportIncident(incidentId);

      // Cancel progress timer
      _reportProgressTimer?.cancel();

      if (response.success == true) {
        // Set to 100% before showing success
        emit(
          state.copyWith(
            reportUploadProgress: 100.0,
            processState: ProcessState.done,
          ),
        );

        // Small delay to show 100%
        await Future.delayed(const Duration(milliseconds: 500));

        // Clean up
        emit(
          state.copyWith(isReportUploading: false, reportUploadProgress: 0.0),
        );
        showSuccessDialog(NavObserver.context!, () {
          clear();
          if (response.data?.type?.trim().toLowerCase() == "incident" &&
              !(PermissionHelper.hasFullAccessPermission(
                moduleName: "Incident Reporting & Monitoring",
                featureName: "Approval of EmergeX Case",
              ))) {
            openScreen(
              Routes.incidentReportDetails,
              args: {'incidentId': incidentId},
              clearOldStacks: true,
            );
          } else if ((response.data?.type?.trim().toLowerCase() ==
                      "observation" ||
                  response.data?.type?.trim().toLowerCase() == "intervention" ||
                  response.data?.type?.trim().toLowerCase() == "incident") &&
              (PermissionHelper.hasFullAccessPermission(
                moduleName: "Incident Reporting & Monitoring",
                featureName: "Approval of EmergeX Case",
              ))) {
            openScreen(
              Routes.incidentApproval,
              args: {
                'incidentId': incidentId,
                'initialDropdownValue': response.data?.type ?? "Incident",
                'isEditRequired': true,
              },
              clearOldStacks: true,
            );
          } else if ((response.data?.type?.trim().toLowerCase() ==
                      "observation" ||
                  response.data?.type?.trim().toLowerCase() ==
                      "intervention") &&
              !(PermissionHelper.hasFullAccessPermission(
                moduleName: "Incident Reporting & Monitoring",
                featureName: "Approval of EmergeX Case",
              ))) {
            openScreen(
              Routes.incidentApproval,
              args: {
                'incidentId': incidentId,
                'initialDropdownValue': response.data?.type ?? "Incident",
                'isEditRequired': false,
              },
              clearOldStacks: true,
            );
            clear();
            AppDI.dashboardCubit.refreshIncidents();
            openScreen(Routes.homeScreen, clearOldStacks: true);
          }
          back();
        }, incidentId);
      } else {
        // Clean up on error
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isReportUploading: false,
            reportUploadProgress: 0.0,
          ),
        );
        showErrorDialog(
          NavObserver.context!,
          () {
            reportIncident(incidentId, context);
            back();
          },
          () {
            clear();
            openScreen(Routes.homeScreen, clearOldStacks: true);
            back();
          },
          TextHelper.reportCreationFailed,
          response.error?.toString() ?? TextHelper.reportCreationFailedMessage,
          TextHelper.tryAgainText,
          TextHelper.startOverText,
        );
      }
    } catch (e) {
      // Clean up on exception
      _reportProgressTimer?.cancel();
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isReportUploading: false,
          reportUploadProgress: 0.0,
        ),
      );
    }
  }

  /// Start report progress animation
  /// Progress pattern: 0-40% (fast), 40-80% (medium), 80-90% (slow), 90-95% (hold), 100% (on success)
  void _startReportProgressAnimation() {
    double currentProgress = 0.0;

    // Phase 1: 0-40% in 2 seconds (fast)
    _reportProgressTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (currentProgress < 40) {
        currentProgress += 2.0; // 2% per 100ms = 40% in 2 seconds
        emit(
          state.copyWith(
            reportUploadProgress: currentProgress.clamp(0.0, 100.0),
          ),
        );
      } else {
        timer.cancel();
        _startPhase2();
      }
    });
  }

  void _startPhase2() {
    double currentProgress = 40.0;

    // Phase 2: 40-80% in 2 seconds (medium)
    _reportProgressTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (currentProgress < 80) {
        currentProgress += 2.0; // 2% per 100ms = 40% in 2 seconds
        emit(
          state.copyWith(
            reportUploadProgress: currentProgress.clamp(0.0, 100.0),
          ),
        );
      } else {
        timer.cancel();
        _startPhase3();
      }
    });
  }

  void _startPhase3() {
    double currentProgress = 80.0;

    // Phase 3: 80-90% in 2 seconds (slow)
    _reportProgressTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      if (currentProgress < 90) {
        currentProgress += 1.0; // 1% per 200ms = 10% in 2 seconds
        emit(
          state.copyWith(
            reportUploadProgress: currentProgress.clamp(0.0, 100.0),
          ),
        );
      } else {
        timer.cancel();
        _startPhase4();
      }
    });
  }

  void _startPhase4() {
    double currentProgress = 90.0;

    // Phase 4: 90-95% and hold until API completes
    _reportProgressTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (currentProgress < 95) {
        currentProgress += 1.0; // 1% per 500ms = 5% in 2.5 seconds
        emit(
          state.copyWith(
            reportUploadProgress: currentProgress.clamp(0.0, 100.0),
          ),
        );
      } else {
        // Hold at 95% until API call completes
        timer.cancel();
      }
    });
  }

  Future<void> deleteIncident(String incidentId) async {
    try {
      // emit(state.copyWith(processState: ProcessState.loading));
      final response = await _uploadIncidentUseCase.deleteIncident(incidentId);
      if (response.success == true) {
        // Reset dialog and AI summary debounce to allow new summaries after deletion
        setCancelDialogOpen(false);
        _aiSummaryDebounceTimer?.cancel();
        emit(
          state.copyWith(
            processState: ProcessState.done,
            recordingStatus: RecordingStatus.idle,
          ),
        );

        // Refresh dashboard data to reflect the deletion
        AppDI.dashboardCubit.refreshIncidents();
      } else {
        setCancelDialogOpen(false);
        _aiSummaryDebounceTimer?.cancel();
        emit(state.copyWith(processState: ProcessState.error));
      }
    } catch (e) {
      setCancelDialogOpen(false);
      _aiSummaryDebounceTimer?.cancel();
      emit(state.copyWith(processState: ProcessState.error));
    }
  }

  void clear() {
    // Cancel any pending AI summary API call
    _websocketService.cancelAISummary();
    emit(state.copyWith(incidentText: ""));
    emit(IncidentState.initial());
  }

  Future<void> fetchIncidentById(String incidentId) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          recordingStatus: RecordingStatus.idle,
          errorMessage: null,
        ),
      );
      await _refreshIncidentData(incidentId);
      emit(state.copyWith(processState: ProcessState.done));
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          errorMessage: 'Error loading incident: $e',
        ),
      );
    }
  }

  Future<String> preSignedUrl(String key) async {
    emit(state.copyWith(processState: ProcessState.loading));
    final response = await _uploadIncidentUseCase.preSignedUrl(key);
    if (response.success == true && response.data != null) {
      emit(state.copyWith(processState: ProcessState.done));
      return response.data!;
    } else {
      emit(state.copyWith(processState: ProcessState.error));
      return '';
    }
  }

  void addLoader() {
    emit(state.copyWith(processState: ProcessState.loading));
  }

  /// Initialize the report screen — call from addPostFrameCallback
  void initReportScreen(String? incidentId) {
    allowPop = false;
    isDialogShowing = false;
    _previousRecordingStatus = null;
    incidentInfoController.clear();
    clearAisummaryIncident();
    clear();

    final appCubit = AppDI.emergexAppCubit;
    final selectedProjectId = appCubit.state.selectedProjectId;
    final projects = appCubit.state.userPermissions?.projects ?? [];
    final firstProjectId =
        projects.isNotEmpty ? projects.first.projectId : null;
    final projectIdToUse = selectedProjectId?.isNotEmpty == true
        ? selectedProjectId
        : firstProjectId;

    if (projectIdToUse != null) {
      setProjectId(projectIdToUse);
    }

    if (incidentId != null) {
      fetchIncidentById(incidentId);
    } else {
      clear();
    }
  }

  /// Request microphone + storage permissions
  Future<void> requestPermissions() async {
    final micGranted = await Permission.microphone.isGranted;
    if (!micGranted) {
      await Permission.microphone.request();
    }
    await Permission.storage.request();
  }

  /// Sync text controller with transcript during recording.
  /// Returns true if a reset was detected (controller should be cleared).
  bool syncControllerWithState(IncidentState st) {
    final isReset = (_previousRecordingStatus == RecordingStatus.recording ||
            _previousRecordingStatus == RecordingStatus.paused) &&
        st.recordingStatus == RecordingStatus.idle &&
        (st.incidentInformationTxt?.isEmpty ?? true) &&
        st.currentTranscript.isEmpty &&
        (st.incidentText?.isEmpty ?? true) &&
        st.recordingDuration == 0;

    if (isReset && incidentInfoController.text.isNotEmpty) {
      incidentInfoController.clear();
    }

    _previousRecordingStatus = st.recordingStatus;
    return isReset;
  }

  /// Handle back navigation — returns true if navigation should proceed
  void handleBackNavigation(BuildContext context, IncidentState st) {
    if (isDialogShowing) return;

    if (st.data.isNotEmpty) {
      if (st.recordingStatus == RecordingStatus.recording) {
        isDialogShowing = true;
        showErrorDialog(
          context,
          () {
            Navigator.of(context, rootNavigator: true).pop();
            isDialogShowing = false;
            allowPop = true;
            resetRecording();
            clear();
            AppDI.dashboardCubit.loadInitialData();
            openScreen(Routes.homeScreen, clearOldStacks: true);
          },
          () {
            Navigator.of(context, rootNavigator: true).pop();
            isDialogShowing = false;
          },
          TextHelper.areYouSure,
          TextHelper.cancelReportConfirmation,
          TextHelper.yesCancel,
          TextHelper.goBack,
        );
      } else {
        clear();
        AppDI.dashboardCubit.loadInitialData();
        openScreen(Routes.homeScreen, clearOldStacks: true);
      }
      return;
    }

    final hasUnsavedData = st.currentTranscript.isNotEmpty ||
        st.recordingStatus == RecordingStatus.recording ||
        st.recordingStatus == RecordingStatus.paused ||
        st.incidentText?.isNotEmpty == true;

    if (hasUnsavedData) {
      isDialogShowing = true;
      showErrorDialog(
        context,
        () {
          Navigator.of(context, rootNavigator: true).pop();
          isDialogShowing = false;
          allowPop = true;
          resetRecording();
          clear();
          AppDI.dashboardCubit.loadInitialData();
          openScreen(Routes.homeScreen, clearOldStacks: true);
        },
        () {
          Navigator.of(context, rootNavigator: true).pop();
          isDialogShowing = false;
        },
        TextHelper.areYouSure,
        TextHelper.cancelReportConfirmation,
        TextHelper.yesCancel,
        TextHelper.goBack,
      );
      return;
    }

    AppDI.dashboardCubit.loadInitialData();
    openScreen(Routes.homeScreen, clearOldStacks: true);
  }

  /// Handle back button tap when incident data is showing
  void handleBackButtonTap(BuildContext context, IncidentState st) {
    if (st.recordingStatus == RecordingStatus.recording) {
      showErrorDialog(
        context,
        () {
          stopRecording();
          clear();
          openScreen(Routes.homeScreen, clearOldStacks: true);
        },
        () {},
        TextHelper.areYouSure,
        TextHelper.cancelReportConfirmation,
        TextHelper.yesCancel,
        TextHelper.goBack,
      );
    } else {
      clear();
      AppDI.dashboardCubit.loadInitialData();
      openScreen(Routes.homeScreen, clearOldStacks: true);
    }
  }

  @override
  Future<void> close() {
    incidentInfoController.dispose();
    // Cancel all file uploads
    for (var fileId in _uploadCancelTokens.keys.toList()) {
      cancelFileUpload(fileId);
    }
    // Cancel all file progress timers and stopwatches
    for (var timer in _fileProgressTimers.values) {
      timer.cancel();
    }
    _fileProgressTimers.clear();
    for (var stopwatch in _fileStopwatches.values) {
      stopwatch.stop();
    }
    _fileStopwatches.clear();
    _fileInfoIds.clear();
    // Cancel all progress timers
    for (var timer in _progressTimers.values) {
      timer?.cancel();
    }
    _progressTimers.clear();
    // Cancel report progress timer
    _reportProgressTimer?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    _aiSummaryDebounceTimer?.cancel();
    _stopAudioLevelMonitoring();
    _websocketService.cancelAISummary();
    _websocketService.dispose();
    return super.close();
  }
}
