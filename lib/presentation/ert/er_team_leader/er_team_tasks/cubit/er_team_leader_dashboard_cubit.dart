import 'dart:async';

import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/use_cases/er_team_leader_dashboard_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/helpers/auth_guard.dart';

class ErTeamLeaderDashboardState extends Equatable {
  const ErTeamLeaderDashboardState({
    this.data,
    this.filters,
    this.selectedMetricIndex = 0,
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.overallCounts,
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
  final DashboardViewType viewType;

  factory ErTeamLeaderDashboardState.initial() =>
      const ErTeamLeaderDashboardState(
        processState: ProcessState.none,
        selectedMetricIndex: 0,
        filters: DashboardFilters(page: 0, limit: 10),
      );

  ErTeamLeaderDashboardState copyWith({
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
    DashboardViewType? viewType,
  }) {
    return ErTeamLeaderDashboardState(
      data: data ?? this.data,
      filters: filters ?? this.filters,
      selectedMetricIndex: selectedMetricIndex ?? this.selectedMetricIndex,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      overallCounts: overallCounts ?? this.overallCounts,
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
    viewType,
  ];
}

class ErTeamLeaderDashboardCubit extends Cubit<ErTeamLeaderDashboardState> {
  final ErTeamLeaderDashboardUseCase _useCase;
  Timer? _searchDebounce;

  ErTeamLeaderDashboardCubit(this._useCase)
    : super(ErTeamLeaderDashboardState.initial());

  void clearCache() {
    emit(ErTeamLeaderDashboardState.initial());
  }

  /// Toggle between graph and normal view
  void toggleViewType() {
    final newType = state.viewType == DashboardViewType.graph
        ? DashboardViewType.normal
        : DashboardViewType.graph;
    emit(state.copyWith(viewType: newType));
  }

  void onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      loadDashboard(
        search: query.trim().isEmpty ? '' : query.trim(),
        page: 0,
        isRefresh: true,
      );
    });
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> loadDashboard({
    int? page,
    int? limit,
    String? project,
    String? title,
    String? status,
    List<String>? severityLevels,
    String? priority,
    String? search,
    Map<String, String>? daterange,
    bool loadMore = false,
    bool isRefresh = false,
    bool clearStatus = false,
    bool clearAllFilters = false,
  }) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.processState == ProcessState.error && !isRefresh) return;
    if (!await AuthGuard.canProceed()) return;

    final currentState = state;
    final currentFilters = currentState.filters;

    final targetPage = page ?? (loadMore ? (currentFilters?.page ?? 0) : 0);
    final targetLimit = limit ?? currentFilters?.limit ?? 10;
    String? targetStatus;
    if (clearStatus) {
      targetStatus = null;
    } else {
      targetStatus =
          status ??
          (isRefresh ? currentFilters?.status : currentFilters?.status);
    }
    final targetSearch = isRefresh
        ? currentFilters?.search
        : (search ?? currentFilters?.search);

    if (loadMore) {
      emit(currentState.copyWith(isLoadingMore: true, clearError: true));
    } else {
      emit(
        currentState.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          clearError: true,
        ),
      );
    }

    try {
      final filters = DashboardFilters(
        page: targetPage,
        limit: targetLimit,
        project: clearAllFilters ? null : (project ?? currentFilters?.project),
        title: clearAllFilters ? null : (title ?? currentFilters?.title),
        status: clearAllFilters ? null : targetStatus,
        severityLevels: clearAllFilters
            ? null
            : (severityLevels ?? currentFilters?.severityLevels),
        priority: clearAllFilters
            ? null
            : (priority ?? currentFilters?.priority),
        search: targetSearch,
        daterange: daterange ?? currentFilters?.daterange,
      );

      // check permission for Member Management
      PermissionHelper.hasViewPermission(
        moduleName: "ERT Team Leader",
        featureName: "Member Management",
      );

      final response = await _useCase.getTlDashboard(filters);

      if (response.success == true && response.data != null) {
        final newIncidents = response.data!.result ?? [];
        final hasMore = newIncidents.length >= targetLimit;

        emit(
          state.copyWith(
            data: response.data!,
            filters: filters,
            processState: ProcessState.done,
            isLoading: false,
            isLoadingMore: false,
            hasMore: hasMore,
            errorMessage: null,
            clearError: true,
            overallCounts: response.data!.statusCount,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            isLoadingMore: false,
            errorMessage: response.error ?? 'Failed to load dashboard',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          isLoadingMore: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> handleMetricTap(int index, String? statusFilter) async {
    emit(state.copyWith(selectedMetricIndex: index));
    await loadDashboard(
      page: 0,
      status: statusFilter,
      clearStatus: index == 0,
      isRefresh: true,
    );
  }

  Future<void> applyFilters({
    int? page,
    String? project,
    String? title,
    String? status,
    List<String>? severityLevels,
    String? priority,
    String? search,
  }) async {
    await loadDashboard(
      page: page ?? 0,
      project: project,
      title: title,
      status: status,
      severityLevels: severityLevels,
      priority: priority,
      search: search,
      isRefresh: true,
    );
  }

  /// Apply filters explicitly - this method ensures all values are set.
  /// Use this when applying from the filter dialog to ensure cleared filters
  /// are properly removed (not falling back to previous values).
  Future<void> applyFiltersExplicit({
    String? project,
    String? title,
    String? status,
    List<String>? severityLevels,
    String? priority,
  }) async {
    if (state.isLoading || state.isLoadingMore) return;
    final currentFilters = state.filters;

    emit(
      state.copyWith(
        processState: ProcessState.loading,
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      // Create filters with explicit values - no fallback to previous values
      final filters = DashboardFilters(
        page: 0,
        limit: currentFilters?.limit ?? 10,
        project: project, // Explicitly set (can be null to clear)
        title: title, // Explicitly set (can be null to clear)
        status: status, // Explicitly set (can be null to clear)
        severityLevels:
            severityLevels, // Explicitly set (can be null/empty to clear)
        priority: priority, // Explicitly set (can be null to clear)
        search: currentFilters?.search, // Keep search as-is
        daterange: currentFilters?.daterange, // Keep daterange as-is
      );

      // check permission for Member Management
      final hasMemberMgmt = PermissionHelper.hasViewPermission(
        moduleName: "ERT Team Leader",
        featureName: "Task Management",
      );

      if (!hasMemberMgmt) {
        // Case 2: Task Management ONLY (or no Member Management)
        emit(
          state.copyWith(
            data: const DashboardResponse(
              result: [],
              statusCount: StatusCount(total: 0, inProgress: 0, resolved: 0),
            ),
            filters: filters,
            processState: ProcessState.done,
            isLoading: false,
            isLoadingMore: false,
            hasMore: false,
            errorMessage: null,
            clearError: true,
            overallCounts: const StatusCount(
              total: 0,
              inProgress: 0,
              resolved: 0,
            ),
          ),
        );
        return;
      }

      final response = await _useCase.getTlDashboard(filters);

      if (response.success == true && response.data != null) {
        final newIncidents = response.data!.result ?? [];
        final limit = currentFilters?.limit ?? 10;
        final hasMore = newIncidents.length >= limit;

        emit(
          state.copyWith(
            data: response.data!,
            filters: filters,
            processState: ProcessState.done,
            isLoading: false,
            isLoadingMore: false,
            hasMore: hasMore,
            errorMessage: null,
            clearError: true,
            overallCounts: response.data!.statusCount,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            isLoadingMore: false,
            errorMessage: response.error ?? 'Failed to load dashboard',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          isLoadingMore: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// REQUIRED BY PAGINATION CONTROLS
  int getTotalPages() {
    if (state.data == null || state.data!.statusCount == null) return 0;
    final counts = state.data!.statusCount!;
    final limit = state.filters?.limit ?? 10;
    int total = counts.total ?? 0;
    if (total <= 0 || limit <= 0) return 0;
    return (total / limit).ceil();
  }

  /// REQUIRED BY FILTER DIALOG
  void resetFiltersOnly() {
    loadDashboard(page: 0, clearAllFilters: true, isRefresh: true);
  }
}
