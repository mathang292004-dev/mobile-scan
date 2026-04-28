import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Model for a TL Investigation task with AI analysis
class TlInvestigationTask {
  final String taskId;
  final String taskName;
  final String taskDetails;
  final String status;
  final String timeTaken;
  final String completedBy;
  final String incidentId;
  final String aiSummary;
  final bool delayRiskDetected;
  final List<String> aiRecommendations;

  const TlInvestigationTask({
    required this.taskId,
    required this.taskName,
    required this.taskDetails,
    required this.status,
    required this.timeTaken,
    required this.completedBy,
    required this.incidentId,
    required this.aiSummary,
    required this.delayRiskDetected,
    required this.aiRecommendations,
  });
}

/// State for Investigation TL Task Dashboard
class InvestigationTlTaskState extends Equatable {
  const InvestigationTlTaskState({
    this.data,
    this.tasks = const [],
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
  final List<TlInvestigationTask> tasks;
  final int selectedMetricIndex;
  final ProcessState processState;
  final bool isLoading;
  final String? errorMessage;
  final DashboardViewType viewType;
  final int currentPage;
  final int totalPages;
  final String searchQuery;

  factory InvestigationTlTaskState.initial() =>
      const InvestigationTlTaskState(
        processState: ProcessState.none,
        selectedMetricIndex: 0,
        tasks: [],
      );

  InvestigationTlTaskState copyWith({
    DashboardResponse? data,
    List<TlInvestigationTask>? tasks,
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
    return InvestigationTlTaskState(
      data: data ?? this.data,
      tasks: tasks ?? this.tasks,
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
        tasks,
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

/// Cubit for managing Investigation TL Task Dashboard state — UI only with dummy data
class InvestigationTlTaskCubit extends Cubit<InvestigationTlTaskState> {
  InvestigationTlTaskCubit() : super(InvestigationTlTaskState.initial());

  void toggleViewType() {
    final newType = state.viewType == DashboardViewType.graph
        ? DashboardViewType.normal
        : DashboardViewType.graph;
    emit(state.copyWith(viewType: newType));
  }

  void clearCache() {
    emit(InvestigationTlTaskState.initial());
  }

  /// Load dummy dashboard data
  /// Metrics: 0=Total Tasks, 1=Assigned, 2=In Progress, 3=Completed
  Future<void> loadDashboard({int page = 1}) async {
    emit(state.copyWith(
      processState: ProcessState.loading,
      isLoading: true,
      clearError: true,
    ));

    await Future.delayed(const Duration(milliseconds: 500));

    final dummyData = DashboardResponse(
      page: page - 1,
      limit: 10,
      statusCount: StatusCount(
        total: 45,
        approved: 15,
        inProgress: 20,
        resolved: 10,
        ertToBeAssigned: 0,
        rejected: 0,
        draft: 0,
      ),
      result: _generateDummyIncidents(),
      startDate: DateTime(2024, 5, 20),
      endDate: DateTime(2025, 6, 20),
    );

    emit(state.copyWith(
      data: dummyData,
      tasks: _generateMockTasks(),
      processState: ProcessState.done,
      isLoading: false,
      currentPage: page,
      totalPages: 5,
      clearError: true,
    ));
  }

  List<IncidentDetails> _generateDummyIncidents() {
    final statuses = [
      'Assigned',
      'In Progress',
      'Completed',
      'Assigned',
      'In Progress',
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

  List<TlInvestigationTask> _generateMockTasks() {
    return const [
      TlInvestigationTask(
        taskId: 'BI-12-18995',
        taskName: 'Gather contact and situation details',
        taskDetails:
            'Collect all relevant contact information from witnesses and affected parties. Document the situation details including time, location, environmental conditions, and initial observations at the scene.',
        status: 'Completed',
        timeTaken: '02:15:30',
        completedBy: 'Dr. Adolfo Chan',
        incidentId: 'INC118',
        aiSummary:
            'Task completed successfully. Contact details gathered from 5 witnesses and 3 affected parties. All situational data documented with photographic evidence.',
        delayRiskDetected: false,
        aiRecommendations: [
          'Verify contact details with HR records for completeness.',
          'Cross-reference witness accounts to identify discrepancies.',
          'Ensure environmental data is timestamped accurately.',
        ],
      ),
      TlInvestigationTask(
        taskId: 'BI-12-18996',
        taskName: 'Debrief findings report',
        taskDetails:
            'Compile and present findings from the initial investigation phase. Include root cause analysis, contributing factors, and preliminary recommendations to the investigation committee.',
        status: 'Completed',
        timeTaken: '03:45:00',
        completedBy: 'Dr. Adolfo Chan',
        incidentId: 'INC118',
        aiSummary:
            'Findings report compiled with 12 key observations. Root cause identified as procedural non-compliance in safety zone entry protocol.',
        delayRiskDetected: true,
        aiRecommendations: [
          'Schedule follow-up meeting with safety committee within 48 hours.',
          'Update safety zone entry procedures based on findings.',
          'Implement immediate corrective action for identified procedural gaps.',
        ],
      ),
      TlInvestigationTask(
        taskId: 'BI-12-18997',
        taskName: 'H2S Training',
        taskDetails:
            'Conduct hydrogen sulfide (H2S) awareness and safety training for all personnel involved in the incident. Ensure compliance with OSHA 29 CFR 1910.1000 standards and document attendance.',
        status: 'Completed',
        timeTaken: '04:00:00',
        completedBy: 'Dr. Adolfo Chan',
        incidentId: 'INC118',
        aiSummary:
            'H2S training completed for 18 personnel. All participants passed the competency assessment with an average score of 87%. Training records updated in the compliance system.',
        delayRiskDetected: false,
        aiRecommendations: [
          'Schedule refresher training in 6 months as per compliance schedule.',
          'Update H2S emergency response equipment inspection checklist.',
          'Share training outcomes with the HSE department for record-keeping.',
        ],
      ),
    ];
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
