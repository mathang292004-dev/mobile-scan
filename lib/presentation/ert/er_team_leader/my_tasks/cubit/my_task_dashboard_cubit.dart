import 'dart:async';

import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/remote_data_source/my_task_dashboard_remote_data_source.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/helpers/auth_guard.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ---------------------------------------------------------------------------
// Use Case (thin wrapper — no extra repo layer needed for read-only dashboard)
// ---------------------------------------------------------------------------
class MyTaskDashboardUseCase {
  final MyTaskDashboardRemoteDataSource _dataSource;

  MyTaskDashboardUseCase(this._dataSource);

  Future<ApiResponse<DashboardResponse>> execute(
    DashboardFilters filters, {
    String role = 'tl',
  }) =>
      _dataSource.getMyTaskDashboard(filters, role: role);
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class MyTaskDashboardState extends Equatable {
  const MyTaskDashboardState({
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

  factory MyTaskDashboardState.initial() => const MyTaskDashboardState(
        processState: ProcessState.none,
        selectedMetricIndex: 0,
        filters: DashboardFilters(page: 0, limit: 10),
      );

  MyTaskDashboardState copyWith({
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
    return MyTaskDashboardState(
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

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------
class MyTaskDashboardCubit extends Cubit<MyTaskDashboardState> {
  final MyTaskDashboardUseCase _useCase;
  final String role;
  Timer? _searchDebounce;

  MyTaskDashboardCubit(this._useCase, {this.role = 'tl'})
      : super(MyTaskDashboardState.initial());

  void clearCache() {
    emit(MyTaskDashboardState.initial());
  }

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
    String? status,
    String? search,
    Map<String, String>? daterange,
    bool isRefresh = false,
    bool clearStatus = false,
  }) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.processState == ProcessState.error && !isRefresh) return;
    if (!await AuthGuard.canProceed()) return;

    final currentFilters = state.filters;
    final targetPage = page ?? 0;
    final targetLimit = limit ?? currentFilters?.limit ?? 10;
    final targetStatus = clearStatus
        ? null
        : (status ?? (isRefresh ? currentFilters?.status : currentFilters?.status));
    final targetSearch = isRefresh
        ? currentFilters?.search
        : (search ?? currentFilters?.search);

    emit(
      state.copyWith(
        processState: ProcessState.loading,
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final filters = DashboardFilters(
        page: targetPage,
        limit: targetLimit,
        status: targetStatus,
        search: targetSearch,
        daterange: daterange ?? currentFilters?.daterange,
      );

      final response = await _useCase.execute(filters, role: role);

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
    String? project,
    String? title,
    String? status,
    List<String>? severityLevels,
    String? priority,
  }) async {
    await loadDashboard(page: 0, status: status, isRefresh: true);
  }

  int getTotalPages() {
    if (state.data == null || state.data!.statusCount == null) return 0;
    final counts = state.data!.statusCount!;
    final limit = state.filters?.limit ?? 10;
    final total = counts.total ?? 0;
    if (total <= 0 || limit <= 0) return 0;
    return (total / limit).ceil();
  }
}
