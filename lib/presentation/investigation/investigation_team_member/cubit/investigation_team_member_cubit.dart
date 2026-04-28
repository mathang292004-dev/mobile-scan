import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart' show AiAnalysis;
import 'package:emergex/data/model/investigation/member_incident_timer.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../repository/investigation_team_member_repository.dart';

class FileUploadInfo extends Equatable {
  final String id;
  final String fileName;
  final double progress;
  final String? size;

  const FileUploadInfo({
    required this.id,
    required this.fileName,
    required this.progress,
    this.size,
  });

  FileUploadInfo copyWith({double? progress}) {
    return FileUploadInfo(
      id: id,
      fileName: fileName,
      progress: progress ?? this.progress,
      size: size,
    );
  }

  @override
  List<Object?> get props => [id, fileName, progress, size];
}

class InvestigationMemberIncident {
  final String id;
  final String title;
  final String projectId;
  final String status;
  final String severity;
  final String priority;

  const InvestigationMemberIncident({
    required this.id,
    required this.title,
    required this.projectId,
    required this.status,
    required this.severity,
    required this.priority,
  });
}

class InvestigationMemberTask {
  final String id;
  final String taskId;
  final String incidentId;
  final String title;
  final String code;
  final String date;
  final String description;
  final String status;
  final String assignedBy;
  final List<String> attachments;
  final String? statusUpdate;
  final AiAnalysis? aiAnalysis;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final String? timeTaken;
  final int? totalPausedTime;

  const InvestigationMemberTask({
    required this.id,
    required this.taskId,
    required this.incidentId,
    required this.title,
    required this.code,
    required this.date,
    required this.description,
    required this.status,
    required this.assignedBy,
    required this.attachments,
    this.statusUpdate,
    this.aiAnalysis,
    this.startedAt,
    this.pausedAt,
    this.completedAt,
    this.timeTaken,
    this.totalPausedTime,
  });

  InvestigationMemberTask copyWith({
    String? id,
    String? taskId,
    String? incidentId,
    String? title,
    String? code,
    String? date,
    String? description,
    String? status,
    String? assignedBy,
    List<String>? attachments,
    String? statusUpdate,
  }) {
    return InvestigationMemberTask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      incidentId: incidentId ?? this.incidentId,
      title: title ?? this.title,
      code: code ?? this.code,
      date: date ?? this.date,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedBy: assignedBy ?? this.assignedBy,
      attachments: attachments ?? this.attachments,
      statusUpdate: statusUpdate ?? this.statusUpdate,
      aiAnalysis: aiAnalysis,
      startedAt: startedAt,
      pausedAt: pausedAt,
      completedAt: completedAt,
      timeTaken: timeTaken,
      totalPausedTime: totalPausedTime,
    );
  }
}

class InvestigationTeamMemberState extends Equatable {
  const InvestigationTeamMemberState({
    this.totalActive,
    this.inProgress,
    this.resolved,
    this.incidents,
    this.tasks,
    this.task,
    this.incidentTimer,
    this.selectedMetricIndex = 0,
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.filters,
    this.currentPage = 0,
    this.totalPages = 0,
    this.uploadingFiles = const [],
    this.investigationAttachments = const [],
  });

  final int? totalActive;
  final int? inProgress;
  final int? resolved;
  final List<InvestigationMemberIncident>? incidents;
  final List<InvestigationMemberTask>? tasks;
  final InvestigationMemberTask? task;
  final MemberIncidentTimer? incidentTimer;
  final int selectedMetricIndex;
  final ProcessState processState;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final DashboardFilters? filters;
  final int currentPage;
  final int totalPages;
  final List<FileUploadInfo> uploadingFiles;
  final List<String> investigationAttachments;

  DateTime? get fromDate {
    final from = filters?.daterange?['from'];
    return from != null ? DateTime.tryParse(from) : null;
  }

  DateTime? get toDate {
    final to = filters?.daterange?['to'];
    return to != null ? DateTime.tryParse(to) : null;
  }

  factory InvestigationTeamMemberState.initial() =>
      const InvestigationTeamMemberState(
        processState: ProcessState.none,
        selectedMetricIndex: 0,
        uploadingFiles: [],
        investigationAttachments: [],
      );

  InvestigationTeamMemberState copyWith({
    int? totalActive,
    int? inProgress,
    int? resolved,
    List<InvestigationMemberIncident>? incidents,
    List<InvestigationMemberTask>? tasks,
    InvestigationMemberTask? task,
    MemberIncidentTimer? incidentTimer,
    int? selectedMetricIndex,
    ProcessState? processState,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
    DashboardFilters? filters,
    int? currentPage,
    int? totalPages,
    List<FileUploadInfo>? uploadingFiles,
    List<String>? investigationAttachments,
  }) {
    return InvestigationTeamMemberState(
      totalActive: totalActive ?? this.totalActive,
      inProgress: inProgress ?? this.inProgress,
      resolved: resolved ?? this.resolved,
      incidents: incidents ?? this.incidents,
      tasks: tasks ?? this.tasks,
      task: task ?? this.task,
      incidentTimer: incidentTimer ?? this.incidentTimer,
      selectedMetricIndex: selectedMetricIndex ?? this.selectedMetricIndex,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filters: filters ?? this.filters,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      uploadingFiles: uploadingFiles ?? this.uploadingFiles,
      investigationAttachments:
          investigationAttachments ?? this.investigationAttachments,
    );
  }

  @override
  List<Object?> get props => [
    totalActive,
    inProgress,
    resolved,
    incidents,
    tasks,
    task,
    incidentTimer,
    selectedMetricIndex,
    processState,
    isLoading,
    isLoadingMore,
    hasMore,
    errorMessage,
    filters,
    currentPage,
    totalPages,
    uploadingFiles,
    investigationAttachments,
  ];
}

class InvestigationTeamMemberCubit extends Cubit<InvestigationTeamMemberState> {
  final InvestigationTeamMemberRepository repository;

  InvestigationTeamMemberCubit({required this.repository})
    : super(InvestigationTeamMemberState.initial());

  Future<void> loadDashboard({
    int page = 0,
    int limit = 10,
    String? project,
    String? title,
    String? status,
    List<String>? severityLevels,
    String? priority,
    String? search,
    Map<String, String>? daterange,
    bool loadMore = false,
  }) async {
    final currentState = state;

    if (loadMore) {
      emit(
        currentState.copyWith(
          isLoadingMore: true,
          errorMessage: null,
          clearError: true,
        ),
      );
    } else {
      emit(
        currentState.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          isLoadingMore: false,
          errorMessage: null,
          clearError: true,
        ),
      );
    }

    try {
      final filters = DashboardFilters(
        page: page,
        limit: limit,
        project: project,
        title: title,
        status: status,
        severityLevels: severityLevels,
        priority: priority,
        search: search,
        daterange: daterange,
      );

      final dummyIncidents = await repository.fetchDummyIncidents();

      var filtered = dummyIncidents;
      if (status != null && status.isNotEmpty) {
        filtered = filtered
            .where((i) => i.status.toLowerCase() == status.toLowerCase())
            .toList();
      }
      if (search != null && search.isNotEmpty) {
        filtered = filtered
            .where(
              (i) =>
                  i.id.contains(search) ||
                  i.title.toLowerCase().contains(search.toLowerCase()),
            )
            .toList();
      }

      final hasMore = filtered.length > (page + 1) * limit;
      final paginated = filtered.skip(page * limit).take(limit).toList();

      final currentIncidents = currentState.incidents ?? [];
      final totalActive = 10;
      final inProgress = 6;
      final resolved = 4;

      if (loadMore) {
        emit(
          state.copyWith(
            totalActive: totalActive,
            inProgress: inProgress,
            resolved: resolved,
            incidents: [...currentIncidents, ...paginated],
            filters: filters,
            processState: ProcessState.done,
            isLoading: false,
            isLoadingMore: false,
            hasMore: hasMore,
            currentPage: page,
          ),
        );
      } else {
        emit(
          state.copyWith(
            totalActive: totalActive,
            inProgress: inProgress,
            resolved: resolved,
            incidents: paginated,
            filters: filters,
            processState: ProcessState.done,
            isLoading: false,
            isLoadingMore: false,
            hasMore: hasMore,
            currentPage: page,
          ),
        );
      }
      emit(state.copyWith(totalPages: getTotalPages()));
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          isLoadingMore: false,
          errorMessage: 'Failed to load dashboard: $e',
          clearError: false,
        ),
      );
    }
  }

  Future<void> loadTasks({required String incidentId}) async {
    emit(
      state.copyWith(
        processState: ProcessState.loading,
        isLoading: true,
        errorMessage: null,
        clearError: true,
      ),
    );
    try {
      final tasks = await repository.fetchDummyTasks(incidentId);
      emit(
        state.copyWith(
          tasks: tasks,
          processState: ProcessState.done,
          isLoading: false,
          errorMessage: null,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to load tasks: $e',
          clearError: false,
        ),
      );
    }
  }

  Future<void> loadTaskDetails(String taskId, {String? incidentId}) async {
    final shouldClearTask = state.task?.taskId != taskId;
    emit(
      state.copyWith(
        processState: ProcessState.loading,
        isLoading: true,
        errorMessage: null,
        clearError: true,
        task: shouldClearTask ? null : state.task,
      ),
    );

    try {
      if (state.tasks != null) {
        try {
          final existingTask = state.tasks!.firstWhere(
            (t) => t.taskId == taskId,
          );
          emit(
            state.copyWith(
              task: existingTask,
              processState: ProcessState.done,
              isLoading: false,
              errorMessage: null,
              clearError: true,
            ),
          );
          return;
        } catch (e) {}
      }

      final task = await repository.fetchDummyTaskDetails(taskId);
      emit(
        state.copyWith(
          task: task,
          processState: ProcessState.done,
          isLoading: false,
          errorMessage: null,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to load task details: $e',
          clearError: false,
        ),
      );
    }
  }

  Future<void> updateTaskStatus(
    String taskId,
    String status, {
    String? incidentId,
    String? statusUpdate,
  }) async {
    emit(
      state.copyWith(
        processState: ProcessState.loading,
        isLoading: true,
        errorMessage: null,
        clearError: true,
      ),
    );
    try {
      await repository.updateDummyTaskStatus(taskId, status, statusUpdate);
      if (state.task != null) {
        final updatedTask = state.task!.copyWith(
          status: status,
          statusUpdate: statusUpdate ?? state.task!.statusUpdate,
        );
        emit(
          state.copyWith(
            task: updatedTask,
            processState: ProcessState.done,
            isLoading: false,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            errorMessage: null,
            clearError: true,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to update task: $e',
          clearError: false,
        ),
      );
    }
  }

  Future<void> applyFilters({
    int? page,
    int? limit,
    String? project,
    String? title,
    String? status,
    List<String>? severityLevels,
    String? priority,
    String? search,
    Map<String, String>? daterange,
    bool clearProject = false,
    bool clearTitle = false,
    bool clearStatus = false,
    bool clearSeverityLevels = false,
    bool clearPriority = false,
    bool clearSearch = false,
    bool clearDaterange = false,
  }) async {
    final currentFilters = state.filters;
    await loadDashboard(
      page: page ?? 0,
      limit: limit ?? currentFilters?.limit ?? 10,
      project: clearProject ? null : (project ?? currentFilters?.project),
      title: clearTitle ? null : (title ?? currentFilters?.title),
      status: clearStatus ? null : (status ?? currentFilters?.status),
      severityLevels: clearSeverityLevels
          ? null
          : (severityLevels ?? currentFilters?.severityLevels),
      priority: clearPriority ? null : (priority ?? currentFilters?.priority),
      search: clearSearch ? null : (search ?? currentFilters?.search),
      daterange: clearDaterange
          ? null
          : (daterange ?? currentFilters?.daterange),
      loadMore: false,
    );
  }

  Future<void> refreshDashboard() async {
    final currentFilters = state.filters;
    await loadDashboard(
      page: 0,
      limit: currentFilters?.limit ?? 10,
      project: currentFilters?.project,
      title: currentFilters?.title,
      status: currentFilters?.status,
      severityLevels: currentFilters?.severityLevels,
      priority: currentFilters?.priority,
      search: currentFilters?.search,
      daterange: currentFilters?.daterange,
      loadMore: false,
    );
  }

  void updateSelectedMetricIndex(int index) {
    emit(state.copyWith(selectedMetricIndex: index));
  }

  int getTotalPages() {
    if (state.totalActive == null) return 0;
    final limit = state.filters?.limit ?? 10;
    int total;
    final currentStatus = state.filters?.status;
    if (currentStatus == null || state.selectedMetricIndex == 0) {
      total = state.totalActive ?? 0;
    } else if (currentStatus == 'Inprogress' &&
        state.selectedMetricIndex == 1) {
      total = state.inProgress ?? 0;
    } else if (currentStatus == 'Resolved' && state.selectedMetricIndex == 2) {
      total = state.resolved ?? 0;
    } else {
      total = state.totalActive ?? 0;
    }
    if (total <= 0 || limit <= 0) return 0;
    return (total / limit).ceil();
  }

  /// Pick and upload files
  Future<void> pickAndUploadFiles() async {
    if (isClosed) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'svg'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null) {
            _startSimulatedUpload(file.name, file.size);
          }
        }
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to pick files: $e'));
    }
  }

  void _startSimulatedUpload(String fileName, int sizeBytes) {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final String sizeStr =
        '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';

    final newFileUpload = FileUploadInfo(
      id: id,
      fileName: fileName,
      progress: 0.0,
      size: sizeStr,
    );

    final updatedUploading = List<FileUploadInfo>.from(state.uploadingFiles)
      ..add(newFileUpload);
    emit(state.copyWith(uploadingFiles: updatedUploading));

    // Simulate progress
    double currentProgress = 0.0;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }

      currentProgress += 0.1;
      if (currentProgress >= 1.0) {
        currentProgress = 1.0;
        timer.cancel();
        _finalizeUpload(id);
      } else {
        _updateProgress(id, currentProgress);
      }
    });
  }

  void _updateProgress(String id, double progress) {
    final updatedList = state.uploadingFiles.map((f) {
      if (f.id == id) {
        return f.copyWith(progress: progress);
      }
      return f;
    }).toList();
    emit(state.copyWith(uploadingFiles: updatedList));
  }

  void _finalizeUpload(String id) {
    final uploadedInfo = state.uploadingFiles.firstWhere((f) => f.id == id);

    // Remove from uploading list
    final updatedUploading = state.uploadingFiles
        .where((f) => f.id != id)
        .toList();

    // Add to attachments (just strings in this model)
    final newAttachment = uploadedInfo.fileName;
    final updatedAttachments = List<String>.from(state.investigationAttachments)
      ..add(newAttachment);

    emit(
      state.copyWith(
        uploadingFiles: updatedUploading,
        investigationAttachments: updatedAttachments,
      ),
    );
  }

  void removeAttachment(String idOrName) {
    // Check if it's in uploading files (by id)
    if (state.uploadingFiles.any((f) => f.id == idOrName)) {
      final updatedUploading = state.uploadingFiles
          .where((f) => f.id != idOrName)
          .toList();
      emit(state.copyWith(uploadingFiles: updatedUploading));
      return;
    }

    // Check if it's in investigation attachments (by fileName string)
    final updatedAttachments = state.investigationAttachments
        .where((f) => f != idOrName)
        .toList();
    emit(state.copyWith(investigationAttachments: updatedAttachments));
  }
}
