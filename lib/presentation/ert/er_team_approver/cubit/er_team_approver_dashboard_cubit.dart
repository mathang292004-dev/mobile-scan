import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/er_team_approver/export_pdf_response.dart';
import 'package:emergex/data/model/er_team_approver/incident_tasks_response.dart';
import 'package:emergex/data/model/er_team_approver/verify_task_response.dart';
import 'package:emergex/presentation/ert/er_team_approver/use_cases/er_team_approver_dashboard_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:emergex/helpers/auth_guard.dart';

/// State for ER Team Approver Dashboard
class ErTeamApproverDashboardState extends Equatable {
  const ErTeamApproverDashboardState({
    this.data,
    this.filters,
    this.selectedMetricIndex = 0,
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.overallCounts,
    this.incidentTasksData,
    this.isLoadingTasks = false,
    this.tasksErrorMessage,
    this.isVerifyingTask = false,
    this.verifyTaskSuccess = false,
    this.verifyTaskErrorMessage,
    this.verifyTaskResponse,
    this.isExportingPdf = false,
    this.exportPdfSuccess = false,
    this.exportPdfErrorMessage,
    this.exportPdfResponse,
    this.viewType = DashboardViewType.graph,
  });

  final DashboardResponse? data;
  final DashboardFilters? filters;
  final int selectedMetricIndex;
  final ProcessState processState;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final StatusCount? overallCounts;
  final IncidentTasksResponse? incidentTasksData;
  final bool isLoadingTasks;
  final String? tasksErrorMessage;
  final bool isVerifyingTask;
  final bool verifyTaskSuccess;
  final String? verifyTaskErrorMessage;
  final VerifyTaskResponse? verifyTaskResponse;
  final bool isExportingPdf;
  final bool exportPdfSuccess;
  final String? exportPdfErrorMessage;
  final ExportPdfResponse? exportPdfResponse;
  final DashboardViewType viewType;

  factory ErTeamApproverDashboardState.initial() =>
      const ErTeamApproverDashboardState(
        processState: ProcessState.none,
        selectedMetricIndex: 0,
      );

  ErTeamApproverDashboardState copyWith({
    DashboardResponse? data,
    DashboardFilters? filters,
    int? selectedMetricIndex,
    ProcessState? processState,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
    StatusCount? overallCounts,
    IncidentTasksResponse? incidentTasksData,
    bool? isLoadingTasks,
    String? tasksErrorMessage,
    bool clearTasksError = false,
    bool? isVerifyingTask,
    bool? verifyTaskSuccess,
    String? verifyTaskErrorMessage,
    bool clearVerifyError = false,
    VerifyTaskResponse? verifyTaskResponse,
    bool? isExportingPdf,
    bool? exportPdfSuccess,
    String? exportPdfErrorMessage,
    bool clearExportPdfError = false,
    ExportPdfResponse? exportPdfResponse,
    DashboardViewType? viewType,
  }) {
    return ErTeamApproverDashboardState(
      data: data ?? this.data,
      filters: filters ?? this.filters,
      selectedMetricIndex: selectedMetricIndex ?? this.selectedMetricIndex,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      overallCounts: overallCounts ?? this.overallCounts,
      incidentTasksData: incidentTasksData ?? this.incidentTasksData,
      isLoadingTasks: isLoadingTasks ?? this.isLoadingTasks,
      tasksErrorMessage: clearTasksError
          ? null
          : (tasksErrorMessage ?? this.tasksErrorMessage),
      isVerifyingTask: isVerifyingTask ?? this.isVerifyingTask,
      verifyTaskSuccess: verifyTaskSuccess ?? this.verifyTaskSuccess,
      verifyTaskErrorMessage: clearVerifyError
          ? null
          : (verifyTaskErrorMessage ?? this.verifyTaskErrorMessage),
      verifyTaskResponse: verifyTaskResponse ?? this.verifyTaskResponse,
      isExportingPdf: isExportingPdf ?? this.isExportingPdf,
      exportPdfSuccess: exportPdfSuccess ?? this.exportPdfSuccess,
      exportPdfErrorMessage: clearExportPdfError
          ? null
          : (exportPdfErrorMessage ?? this.exportPdfErrorMessage),
      exportPdfResponse: exportPdfResponse ?? this.exportPdfResponse,
      viewType: viewType ?? this.viewType,
    );
  }

  @override
  List<Object?> get props => [
    data,
    filters,
    selectedMetricIndex,
    processState,
    isLoading,
    isLoadingMore,
    hasMore,
    errorMessage,
    overallCounts,
    incidentTasksData,
    isLoadingTasks,
    tasksErrorMessage,
    isVerifyingTask,
    verifyTaskSuccess,
    verifyTaskErrorMessage,
    verifyTaskResponse,
    isExportingPdf,
    exportPdfSuccess,
    exportPdfErrorMessage,
    exportPdfResponse,
    viewType,
  ];
}

/// Cubit for managing ER Team Approver Dashboard state
class ErTeamApproverDashboardCubit extends Cubit<ErTeamApproverDashboardState> {
  final ErTeamApproverDashboardUseCase _useCase;

  ErTeamApproverDashboardCubit(this._useCase)
    : super(ErTeamApproverDashboardState.initial());

  /// Toggle between graph and normal view
  void toggleViewType() {
    final newType = state.viewType == DashboardViewType.graph
        ? DashboardViewType.normal
        : DashboardViewType.graph;
    emit(state.copyWith(viewType: newType));
  }

  /// Clear cache and reset to initial state
  void clearCache() {
    emit(ErTeamApproverDashboardState.initial());
  }

  /// Load dashboard data with filters
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
    String? reportedBy,
    String? department,
    bool loadMore = false,
  }) async {
    // Check if user is logged in before making API calls
    if (!await AuthGuard.canProceed()) return;

    final currentState = state;

    if (loadMore) {
      // Loading more - append to existing data
      emit(
        currentState.copyWith(
          isLoadingMore: true,
          errorMessage: null,
          clearError: true,
        ),
      );
    } else {
      // Initial load or refresh - replace data
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
        reportedBy: reportedBy,
        department: department,
      );

      final response = await _useCase.getApproverDashboard(filters);

      if (response.success == true && response.data != null) {
        final newIncidents = response.data!.result ?? [];
        final currentIncidents = currentState.data?.result ?? [];

        // Determine if there are more pages
        final hasMore = newIncidents.length >= limit;

        if (loadMore) {
          // Append new incidents to existing ones
          final updatedData = DashboardResponse(
            page: response.data!.page,
            limit: response.data!.limit,
            statusCount: response.data!.statusCount,
            result: [...currentIncidents, ...newIncidents],
            startDate: response.data!.startDate,
            endDate: response.data!.endDate,
          );

          emit(
            currentState.copyWith(
              data: updatedData,
              filters: filters,
              processState: ProcessState.done,
              isLoading: false,
              isLoadingMore: false,
              hasMore: hasMore,
              clearError: true,
            ),
          );
        } else {
          // Replace with new data
          // Metrics always use response.data.statusCount (current filtered results)
          emit(
            currentState.copyWith(
              data: response.data,
              filters: filters,
              processState: ProcessState.done,
              isLoading: false,
              isLoadingMore: false,
              hasMore: hasMore,
              clearError: true,
            ),
          );
        }
      } else {
        emit(
          currentState.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            isLoadingMore: false,
            errorMessage: response.error ?? 'Failed to load dashboard',
          ),
        );
      }
    } catch (e) {
      emit(
        currentState.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          isLoadingMore: false,
          errorMessage: 'Error: ${e.toString()}',
        ),
      );
    }
  }

  /// Apply filters and reload dashboard
  /// Pass explicit values to update specific filters
  /// Omit parameter to preserve current value from state
  Future<void> applyFilters({
    String? project,
    String? title,
    String? status,
    List<String>? severityLevels,
    String? priority,
    String? search,
    Map<String, String>? daterange,
    String? reportedBy,
    String? department,
    // Clear flags to distinguish between "preserve" and "clear to null"
    bool clearProject = false,
    bool clearTitle = false,
    bool clearStatus = false,
    bool clearSeverityLevels = false,
    bool clearPriority = false,
    bool clearSearch = false,
    bool clearDaterange = false,
    bool clearReportedBy = false,
    bool clearDepartment = false,
  }) async {
    final currentFilters = state.filters;

    await loadDashboard(
      page: 0, // Always reset page when filters change
      limit: currentFilters?.limit ?? 10,
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
      reportedBy: clearReportedBy
          ? null
          : (reportedBy ?? currentFilters?.reportedBy),
      department: clearDepartment
          ? null
          : (department ?? currentFilters?.department),
      loadMore: false,
    );
  }

  /// Apply date range filter
  Future<void> applyDateRange(
    Map<String, String>? dateRange,
    String? searchText,
  ) async {
    final currentFilters = state.filters;
    await loadDashboard(
      page: 0,
      limit: currentFilters?.limit ?? 10,
      project: currentFilters?.project,
      title: currentFilters?.title,
      status: currentFilters?.status,
      severityLevels: currentFilters?.severityLevels,
      priority: currentFilters?.priority,
      search: searchText,
      daterange: dateRange,
      reportedBy: currentFilters?.reportedBy,
      department: currentFilters?.department,
      loadMore: false,
    );
  }

  /// Handle search text changes
  Future<void> onSearchChanged(String searchText) async {
    final currentFilters = state.filters;
    final trimmedSearch = searchText.trim();

    await loadDashboard(
      page: 0,
      limit: currentFilters?.limit ?? 10,
      project: currentFilters?.project,
      title: currentFilters?.title,
      status: currentFilters?.status,
      severityLevels: currentFilters?.severityLevels,
      priority: currentFilters?.priority,
      search: trimmedSearch.isEmpty ? null : trimmedSearch,
      daterange: currentFilters?.daterange,
      reportedBy: currentFilters?.reportedBy,
      department: currentFilters?.department,
      loadMore: false,
    );
  }

  /// Load more incidents (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final currentFilters = state.filters;
    final currentPage = state.data?.page ?? 0;

    await loadDashboard(
      page: currentPage + 1,
      limit: currentFilters?.limit ?? 10,
      project: currentFilters?.project,
      title: currentFilters?.title,
      status: currentFilters?.status,
      severityLevels: currentFilters?.severityLevels,
      priority: currentFilters?.priority,
      search: currentFilters?.search,
      daterange: currentFilters?.daterange,
      reportedBy: currentFilters?.reportedBy,
      department: currentFilters?.department,
      loadMore: true,
    );
  }

  /// Reset all filters
  Future<void> resetFilters() async {
    await loadDashboard(
      page: 0,
      limit: state.filters?.limit ?? 10,
      loadMore: false,
    );
  }

  /// Handle metric tap - filter by status and preserve ALL other filters
  Future<void> handleMetricTap(int metricIndex, String? statusFilter) async {
    emit(state.copyWith(selectedMetricIndex: metricIndex));

    final currentFilters = state.filters;
    await loadDashboard(
      page: 0,
      limit: currentFilters?.limit ?? 10,
      project: currentFilters?.project,
      title: currentFilters?.title,
      status: statusFilter,
      severityLevels: currentFilters?.severityLevels,
      priority: currentFilters?.priority,
      search: currentFilters?.search,
      daterange: currentFilters?.daterange,
      reportedBy: currentFilters?.reportedBy,
      department: currentFilters?.department,
      loadMore: false,
    );
  }

  /// Get total pages for pagination
  int getTotalPages() {
    if (state.data == null || state.data!.statusCount == null) return 0;

    final counts = state.data!.statusCount!;
    final limit = state.filters?.limit ?? 10;

    // Determine which count to use based on the selected metric and current filter status
    int total;

    // Check if a status filter is applied
    final currentStatus = state.filters?.status;

    if (currentStatus == null || state.selectedMetricIndex == 0) {
      // No status filter or "Total Active" metric selected
      total = counts.total ?? 0;
    } else if (currentStatus == 'Inprogress' &&
        state.selectedMetricIndex == 1) {
      // "In Progress" metric selected
      total = counts.inProgress ?? 0;
    } else if (currentStatus == 'Resolved' && state.selectedMetricIndex == 2) {
      // "Resolved" metric selected
      total = counts.resolved ?? 0;
    } else {
      // Fallback to total count
      total = counts.total ?? 0;
    }

    if (total <= 0 || limit <= 0) return 0;

    return (total / limit).ceil();
  }

  /// Navigate to specific page
  Future<void> goToPage(int page) async {
    final currentFilters = state.filters;
    await loadDashboard(
      page: page,
      limit: currentFilters?.limit ?? 10,
      project: currentFilters?.project,
      title: currentFilters?.title,
      status: currentFilters?.status,
      severityLevels: currentFilters?.severityLevels,
      priority: currentFilters?.priority,
      search: currentFilters?.search,
      daterange: currentFilters?.daterange,
      reportedBy: currentFilters?.reportedBy,
      department: currentFilters?.department,
      loadMore: false,
    );
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null, clearError: true));
  }

  /// Load incident tasks for a specific incident
  Future<void> loadIncidentTasks({
    required String incidentId,
    String status = 'all',
  }) async {
    emit(
      state.copyWith(
        isLoadingTasks: true,
        tasksErrorMessage: null,
        clearTasksError: true,
      ),
    );

    try {
      final response = await _useCase.getIncidentTasks(incidentId, status);

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            incidentTasksData: response.data,
            isLoadingTasks: false,
            clearTasksError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoadingTasks: false,
            tasksErrorMessage:
                response.error ?? 'Failed to load incident tasks',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingTasks: false,
          tasksErrorMessage: 'Error: ${e.toString()}',
        ),
      );
    }
  }

  /// Clear incident tasks data
  void clearIncidentTasks() {
    emit(
      state.copyWith(
        incidentTasksData: null,
        tasksErrorMessage: null,
        clearTasksError: true,
      ),
    );
  }

  /// Verify or reject a task
  Future<void> verifyTask({
    required String incidentId,
    required List<String> taskIds,
    required String status,
  }) async {
    emit(
      state.copyWith(
        isVerifyingTask: true,
        verifyTaskSuccess: false,
        verifyTaskErrorMessage: null,
        clearVerifyError: true,
      ),
    );

    try {
      final request = VerifyTaskRequest(
        incidentId: incidentId,
        taskIds: taskIds,
        status: status,
      );

      final response = await _useCase.verifyTask(request);

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            isVerifyingTask: false,
            verifyTaskSuccess: true,
            verifyTaskResponse: response.data,
            clearVerifyError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isVerifyingTask: false,
            verifyTaskSuccess: false,
            verifyTaskErrorMessage: response.error ?? 'Failed to verify task',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isVerifyingTask: false,
          verifyTaskSuccess: false,
          verifyTaskErrorMessage: 'Error: ${e.toString()}',
        ),
      );
    }
  }

  /// Clear verify task state
  void clearVerifyTaskState() {
    emit(
      state.copyWith(
        verifyTaskSuccess: false,
        verifyTaskErrorMessage: null,
        clearVerifyError: true,
        verifyTaskResponse: null,
      ),
    );
  }

  /// Export incident as PDF
  Future<void> exportIncidentPdf({required String incidentId}) async {
    emit(
      state.copyWith(
        isExportingPdf: true,
        exportPdfSuccess: false,
        exportPdfErrorMessage: null,
        clearExportPdfError: true,
      ),
    );

    try {
      final response = await _useCase.exportIncidentPdf(incidentId);

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            isExportingPdf: false,
            exportPdfSuccess: true,
            exportPdfResponse: response.data,
            clearExportPdfError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isExportingPdf: false,
            exportPdfSuccess: false,
            exportPdfErrorMessage: response.error ?? 'Failed to export PDF',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isExportingPdf: false,
          exportPdfSuccess: false,
          exportPdfErrorMessage: 'Error: ${e.toString()}',
        ),
      );
    }
  }

  /// Clear export PDF state
  void clearExportPdfState() {
    emit(
      state.copyWith(
        exportPdfSuccess: false,
        exportPdfErrorMessage: null,
        clearExportPdfError: true,
        exportPdfResponse: null,
      ),
    );
  }
}
