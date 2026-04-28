import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State for HSE Dashboard
class HseDashboardState extends Equatable {
  const HseDashboardState({
    this.data,
    this.selectedMetricIndex = 0,
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.errorMessage,
    this.viewType = DashboardViewType.graph,
    this.currentPage = 1,
    this.totalPages = 1,
    this.searchQuery = '',
  });

  final DashboardResponse? data;
  final int selectedMetricIndex;
  final ProcessState processState;
  final bool isLoading;
  final String? errorMessage;
  final DashboardViewType viewType;
  final int currentPage;
  final int totalPages;
  final String searchQuery;

  factory HseDashboardState.initial() => const HseDashboardState(
        processState: ProcessState.none,
        selectedMetricIndex: 0,
      );

  HseDashboardState copyWith({
    DashboardResponse? data,
    int? selectedMetricIndex,
    ProcessState? processState,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    DashboardViewType? viewType,
    int? currentPage,
    int? totalPages,
    String? searchQuery,
  }) {
    return HseDashboardState(
      data: data ?? this.data,
      selectedMetricIndex: selectedMetricIndex ?? this.selectedMetricIndex,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      viewType: viewType ?? this.viewType,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        data,
        selectedMetricIndex,
        processState,
        isLoading,
        errorMessage,
        viewType,
        currentPage,
        totalPages,
        searchQuery,
      ];
}

/// Cubit for managing HSE Dashboard state — UI only with dummy data
class HseDashboardCubit extends Cubit<HseDashboardState> {
  HseDashboardCubit() : super(HseDashboardState.initial());

  void toggleViewType() {
    final newType = state.viewType == DashboardViewType.graph
        ? DashboardViewType.normal
        : DashboardViewType.graph;
    emit(state.copyWith(viewType: newType));
  }

  void clearCache() {
    emit(HseDashboardState.initial());
  }

  /// Load dummy dashboard data
  Future<void> loadDashboard({int page = 1}) async {
    emit(state.copyWith(
      processState: ProcessState.loading,
      isLoading: true,
      clearError: true,
    ));

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final dummyData = DashboardResponse(
      page: page - 1,
      limit: 10,
      statusCount: StatusCount(
        total: 203,
        approved: 105,
        ertToBeAssigned: 165,
        rejected: 203,
        inProgress: 105,
        resolved: 0,
        draft: 0,
      ),
      result: _generateDummyIncidents(),
      startDate: DateTime(2024, 5, 20),
      endDate: DateTime(2025, 6, 20),
    );

    emit(state.copyWith(
      data: dummyData,
      processState: ProcessState.done,
      isLoading: false,
      currentPage: page,
      totalPages: 11,
      clearError: true,
    ));
  }

  List<IncidentDetails> _generateDummyIncidents() {
    final statuses = [
      'Team Assigned',
      'Investigation Inprogress',
      'Investigation Inprogress',
      'Team Assigned',
      'Investigation Inprogress',
    ];
    final types = ['Incident', 'Incident', 'Observation', 'Nearmiss', 'Incident'];

    return List.generate(5, (i) {
      return IncidentDetails(
        incidentId: 'EX-${(i + 1).toString().padLeft(3, '0')}',
        incidentStatus: statuses[i],
        type: types[i],
        reportedDate: '2020-07-29T00:00:00.000Z',
        incidentLevel: IncidentLevel(value: i % 2 == 0 ? 'Medium' : 'High'),
        task: [],
      );
    });
  }

  void onSearchChanged(String query) {
    emit(state.copyWith(searchQuery: query));
    loadDashboard(page: 1);
  }

  Future<void> applyDateRange(
    Map<String, String>? dateRange,
    String? searchText,
  ) async {
    await loadDashboard(page: 1);
  }

  Future<void> refreshDashboard() async {
    await loadDashboard(page: 1);
  }

  void onMetricTap(int index) {
    emit(state.copyWith(selectedMetricIndex: index));
    loadDashboard(page: 1);
  }

  int getTotalPages() => state.totalPages;

  void goToPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      loadDashboard(page: page);
    }
  }
}
