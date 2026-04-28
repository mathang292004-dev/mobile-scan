import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State for Primary Investigator Dashboard
class PrimaryInvestigatorState extends Equatable {
  const PrimaryInvestigatorState({
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

  factory PrimaryInvestigatorState.initial() =>
      const PrimaryInvestigatorState(
        processState: ProcessState.none,
        selectedMetricIndex: 0,
      );

  PrimaryInvestigatorState copyWith({
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
    return PrimaryInvestigatorState(
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

/// Cubit for managing Primary Investigator Dashboard state — UI only with dummy data
class PrimaryInvestigatorCubit extends Cubit<PrimaryInvestigatorState> {
  PrimaryInvestigatorCubit() : super(PrimaryInvestigatorState.initial());

  void toggleViewType() {
    final newType = state.viewType == DashboardViewType.graph
        ? DashboardViewType.normal
        : DashboardViewType.graph;
    emit(state.copyWith(viewType: newType));
  }

  void clearCache() {
    emit(PrimaryInvestigatorState.initial());
  }

  /// Load dummy dashboard data
  /// Metrics: 0=Total Cases, 1=Under Investigation, 2=Findings Submitted, 3=Awaiting Approval
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
        total: 38,
        inProgress: 15,
        approved: 13,
        ertToBeAssigned: 10,
        resolved: 0,
        rejected: 0,
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
      totalPages: 4,
      clearError: true,
    ));
  }

  List<IncidentDetails> _generateDummyIncidents() {
    final statuses = [
      'Under Investigation',
      'Findings Submitted',
      'Awaiting Approval',
      'Under Investigation',
      'Findings Submitted',
      'Awaiting Approval',
      'Under Investigation',
      'Under Investigation',
      'Findings Submitted',
      'Awaiting Approval',
    ];
    final types = [
      'Incident',
      'Incident',
      'Observation',
      'Nearmiss',
      'Incident',
      'Incident',
      'Nearmiss',
      'Observation',
      'Incident',
      'Incident',
    ];
    final severities = [
      'High',
      'Medium',
      'Low',
      'High',
      'Medium',
      'High',
      'Low',
      'Medium',
      'High',
      'Low',
    ];
    final dates = [
      '2025-01-15T10:30:00.000Z',
      '2025-01-16T14:20:00.000Z',
      '2025-01-17T09:15:00.000Z',
      '2025-01-18T16:45:00.000Z',
      '2025-01-19T11:00:00.000Z',
      '2025-01-20T13:30:00.000Z',
      '2025-01-21T08:50:00.000Z',
      '2025-01-22T15:10:00.000Z',
      '2025-01-23T10:05:00.000Z',
      '2025-01-24T12:40:00.000Z',
    ];

    return List.generate(10, (i) {
      return IncidentDetails(
        incidentId: 'EX-${(i + 101).toString()}',
        incidentStatus: statuses[i],
        type: types[i],
        reportedDate: dates[i],
        incidentLevel: IncidentLevel(value: severities[i]),
        task: [],
      );
    });
  }

  void onSearchChanged(String query) {
    emit(state.copyWith(searchQuery: query));
    loadDashboard(page: 1);
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
