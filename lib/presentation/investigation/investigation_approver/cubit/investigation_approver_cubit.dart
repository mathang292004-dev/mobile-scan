import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State for Investigation Approver Dashboard
class InvestigationApproverState extends Equatable {
  const InvestigationApproverState({
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

  factory InvestigationApproverState.initial() =>
      const InvestigationApproverState(
        processState: ProcessState.none,
        selectedMetricIndex: 0,
      );

  InvestigationApproverState copyWith({
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
    return InvestigationApproverState(
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

/// Cubit for managing Investigation Approver Dashboard state — UI only with dummy data
class InvestigationApproverCubit extends Cubit<InvestigationApproverState> {
  InvestigationApproverCubit()
      : super(InvestigationApproverState.initial());

  void toggleViewType() {
    final newType = state.viewType == DashboardViewType.graph
        ? DashboardViewType.normal
        : DashboardViewType.graph;
    emit(state.copyWith(viewType: newType));
  }

  void clearCache() {
    emit(InvestigationApproverState.initial());
  }

  /// Load dummy dashboard data
  /// Metrics: 0=Total, 1=Pending Review, 2=Approved, 3=Rejected
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
        total: 42,
        ertToBeAssigned: 18,
        approved: 15,
        rejected: 9,
        inProgress: 0,
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
      totalPages: 5,
      clearError: true,
    ));
  }

  List<IncidentDetails> _generateDummyIncidents() {
    final statuses = [
      'Pending Review',
      'Approved',
      'Rejected',
      'Pending Review',
      'Approved',
    ];
    final types = [
      'Incident',
      'Incident',
      'Observation',
      'Nearmiss',
      'Incident',
    ];

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
