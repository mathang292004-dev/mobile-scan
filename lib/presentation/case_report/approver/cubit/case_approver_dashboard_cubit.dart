import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/presentation/case_report/model/dashboard_request_payload.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_stats.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/auth_guard.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/presentation/case_report/approver/use_cases/case_approver_dashboard_use_case.dart';
import 'package:emergex/services/connectivity_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

// ──────────────────────────────────────────
// Case Approver Dashboard States
// ──────────────────────────────────────────

abstract class CaseApproverDashboardState extends Equatable {
  const CaseApproverDashboardState();
}

class CaseApproverDashboardInitial extends CaseApproverDashboardState {
  @override
  List<Object?> get props => [];
}

class CaseApproverDashboardLoading extends CaseApproverDashboardState {
  @override
  List<Object?> get props => [];
}

class CaseApproverDashboardLoaded extends CaseApproverDashboardState {
  final DashboardResponse response;
  final List<IncidentDetails> incidents;
  final StatusCount? statusCount;
  final DashboardStats? dashboardStats;
  final String? searchQuery;
  final int? currentPage;
  final int? itemsPerPage;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? incidentStatus;
  final String? selectedCaseType;
  final List<String> selectedSeverityLevels;
  final int selectedMetricIndex;
  final DateTime timestamp;
  final ProcessState processState;
  final String? errorMessage;
  final String? projectId;
  final DashboardViewType viewType;
  final bool isOnline;

  CaseApproverDashboardLoaded({
    required this.response,
    required this.incidents,
    this.statusCount,
    this.dashboardStats,
    this.searchQuery,
    this.currentPage = 1,
    this.itemsPerPage = 10,
    this.fromDate,
    this.toDate,
    this.incidentStatus,
    this.selectedCaseType,
    this.selectedSeverityLevels = const [],
    this.selectedMetricIndex = 0,
    DateTime? timestamp,
    this.processState = ProcessState.none,
    this.errorMessage,
    this.projectId,
    this.viewType = DashboardViewType.graph,
    this.isOnline = true,
  }) : timestamp = timestamp ?? DateTime.now();

  // UI compatibility — read straight from dashboardStats / statusCount.
  int get totalIncidents =>
      dashboardStats?.statusSummary?.totalEmergexCase ??
      statusCount?.total ??
      0;
  int get recoveryCount =>
      dashboardStats?.statusSummary?.closed ?? statusCount?.closed ?? 0;
  int get emergencyResponseTime =>
      dashboardStats?.statusSummary?.approvalPending ??
      statusCount?.ertToBeAssigned ??
      0;
  int get responseCount =>
      dashboardStats?.statusSummary?.inprogress ??
      statusCount?.inProgress ??
      0;

  CaseApproverDashboardLoaded copyWith({
    DashboardResponse? response,
    List<IncidentDetails>? incidents,
    StatusCount? statusCount,
    DashboardStats? dashboardStats,
    String? searchQuery,
    int? currentPage,
    int? itemsPerPage,
    DateTime? fromDate,
    DateTime? toDate,
    String? incidentStatus,
    String? selectedCaseType,
    List<String>? selectedSeverityLevels,
    int? selectedMetricIndex,
    DateTime? timestamp,
    ProcessState? processState,
    String? errorMessage,
    String? projectId,
    DashboardViewType? viewType,
    bool? isOnline,
  }) {
    return CaseApproverDashboardLoaded(
      response: response ?? this.response,
      incidents: incidents ?? this.incidents,
      statusCount: statusCount ?? this.statusCount,
      dashboardStats: dashboardStats ?? this.dashboardStats,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      incidentStatus: incidentStatus ?? this.incidentStatus,
      selectedCaseType: selectedCaseType ?? this.selectedCaseType,
      selectedSeverityLevels:
          selectedSeverityLevels ?? this.selectedSeverityLevels,
      selectedMetricIndex: selectedMetricIndex ?? this.selectedMetricIndex,
      timestamp: timestamp ?? DateTime.now(),
      processState: processState ?? this.processState,
      errorMessage: errorMessage ?? this.errorMessage,
      projectId: projectId ?? this.projectId,
      viewType: viewType ?? this.viewType,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
        response,
        incidents,
        statusCount,
        dashboardStats,
        searchQuery,
        currentPage,
        itemsPerPage,
        fromDate,
        toDate,
        incidentStatus,
        selectedCaseType,
        selectedSeverityLevels,
        selectedMetricIndex,
        timestamp,
        processState,
        errorMessage,
        projectId,
        viewType,
        isOnline,
      ];
}

class CaseApproverDashboardError extends CaseApproverDashboardState {
  final String message;
  const CaseApproverDashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// ──────────────────────────────────────────
// Cubit
// ──────────────────────────────────────────

class CaseApproverDashboardCubit extends Cubit<CaseApproverDashboardState> {
  final CaseApproverDashboardUseCase _useCase;
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySub;

  CaseApproverDashboardCubit(this._useCase)
      : super(CaseApproverDashboardInitial()) {
    _connectivitySub = _connectivityService.connectivityStream.listen(
      (isConnected) => updateConnectivity(isConnected),
    );
  }

  bool get isOnline {
    if (state is CaseApproverDashboardLoaded) {
      return (state as CaseApproverDashboardLoaded).isOnline;
    }
    return _connectivityService.isConnected;
  }

  void updateConnectivity(bool isConnected) {
    if (state is CaseApproverDashboardLoaded) {
      emit((state as CaseApproverDashboardLoaded)
          .copyWith(isOnline: isConnected));
    }
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }

  void clearCache() {
    emit(CaseApproverDashboardInitial());
  }

  void toggleViewType() {
    if (state is CaseApproverDashboardLoaded) {
      final s = state as CaseApproverDashboardLoaded;
      final newType = s.viewType == DashboardViewType.graph
          ? DashboardViewType.normal
          : DashboardViewType.graph;
      emit(s.copyWith(viewType: newType));
    }
  }

  String formatDateForAPI(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}T00:00:00.000Z';

  String formatEndOfDayForAPI(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}T23:59:59.999Z';

  Future<void> loadInitialData() async {
    final currentState = state;
    if (currentState is CaseApproverDashboardLoaded) {
      Map<String, String>? daterange;
      if (currentState.fromDate != null && currentState.toDate != null) {
        daterange = {
          'from': formatDateForAPI(currentState.fromDate!),
          'to': formatEndOfDayForAPI(currentState.toDate!),
        };
      }
      await loadIncidents(
        page: 1,
        limit: 10,
        incidentStatus: currentState.incidentStatus,
        daterange: daterange,
        selectedMetricIndex: currentState.selectedMetricIndex,
      );
    } else {
      final today = DateTime.now();
      await loadIncidents(
        page: 1,
        limit: 10,
        selectedMetricIndex: 0,
        daterange: {
          'from': formatDateForAPI(today),
          'to': formatEndOfDayForAPI(today),
        },
      );
    }
  }

  Future<void> loadIncidents({
    int? page,
    int? limit,
    String? incidentStatus,
    String? search,
    Map<String, String>? daterange,
    int? selectedMetricIndex,
    String? caseType,
    List<String>? severityLevels,
    bool clearCaseType = false,
    bool clearSeverityLevels = false,
    bool clearDateRange = false,
    bool updateDashboardStats = true,
    bool? isInitial = false,
  }) async {
    if (!await AuthGuard.canProceed()) return;

    try {
      AppDI.incidentDetailsCubit.reset();
      AppDI.incidentFileHandleCubit.clear();

      final previousState = state is CaseApproverDashboardLoaded
          ? state as CaseApproverDashboardLoaded
          : null;

      final searchQuery = previousState?.searchQuery;
      final currentViewType =
          previousState?.viewType ?? DashboardViewType.graph;
      final currentProjectId = AppDI.emergexAppCubit.state.selectedProjectId;

      final nextCaseType =
          clearCaseType ? null : (caseType ?? previousState?.selectedCaseType);
      List<String> normalizeSeverity(List<String> levels) => levels
          .map((e) => e.toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final previousSeverityLevels =
          normalizeSeverity(previousState?.selectedSeverityLevels ?? const []);
      final nextSeverityLevels = clearSeverityLevels
          ? const <String>[]
          : normalizeSeverity(severityLevels ?? previousSeverityLevels);

      emit(
        CaseApproverDashboardLoaded(
          response: DashboardResponse(),
          incidents: const [],
          searchQuery: searchQuery,
          fromDate: (daterange != null && (daterange['from'] ?? '').isNotEmpty)
              ? DateTime.parse(daterange['from']!)
              : previousState?.fromDate,

          toDate: (daterange != null && (daterange['to'] ?? '').isNotEmpty)
              ? DateTime.parse(daterange['to']!)
              : previousState?.toDate,
          incidentStatus: previousState?.incidentStatus,
          selectedCaseType: nextCaseType,
          selectedSeverityLevels: nextSeverityLevels,
          selectedMetricIndex: previousState?.selectedMetricIndex ?? 0,
          statusCount: previousState?.statusCount,
          dashboardStats: previousState?.dashboardStats,
          processState: ProcessState.loading,
          projectId: currentProjectId,
          viewType: currentViewType,
        ),
      );

      final apiPage = page != null ? page - 1 : 0;
      final payload = DashboardRequestPayload(
        page: apiPage,
        limit: limit ?? 10,
        status: incidentStatus,
        search: searchQuery,
        daterange: daterange == null
            ? null
            : DashboardDateRange.fromMap(daterange),
        caseType: nextCaseType,
        severityLevel: nextSeverityLevels,
        isInitial: isInitial ?? false,
      );

      final response = await _useCase.getCases(payload);

      if (response.success == true && response.data != null) {
        final incidents = response.data?.result ?? [];
        final statusCount = response.data?.statusCount ??
            const StatusCount(total: 0, draft: 0);
        final dashboardStats = response.data?.dashboardStats;

        DateTime? fromDate = previousState?.fromDate;
        DateTime? toDate = previousState?.toDate;
        if (clearDateRange) {
          fromDate = null;
          toDate = null;
        } else if (daterange != null) {
          final fromRaw = daterange['from'] ?? '';
          final toRaw = daterange['to'] ?? '';
          if (fromRaw.isEmpty && toRaw.isEmpty) {
            fromDate = null;
            toDate = null;
          } else {
            fromDate = DateTime.tryParse(fromRaw) ??
                (fromRaw.length >= 10 ? DateTime.tryParse(fromRaw.substring(0, 10)) : null);
            toDate = DateTime.tryParse(toRaw) ??
                (toRaw.length >= 10 ? DateTime.tryParse(toRaw.substring(0, 10)) : null);
          }
        }

        final finalSelectedMetricIndex = selectedMetricIndex ??
            (state is CaseApproverDashboardLoaded
                ? (state as CaseApproverDashboardLoaded).selectedMetricIndex
                : 0);
        emit(
          CaseApproverDashboardLoaded(
            response: response.data!,
            incidents: incidents,
            statusCount: updateDashboardStats ? statusCount : previousState?.statusCount,
            dashboardStats:
                updateDashboardStats ? dashboardStats : previousState?.dashboardStats,
            searchQuery: searchQuery,
            currentPage: page ?? 1,
            itemsPerPage: limit ?? 10,
            fromDate: (daterange != null &&
                (daterange['from'] ?? '').isNotEmpty)
                ? DateTime.tryParse(daterange['from']!)
                : previousState?.fromDate,

            toDate: (daterange != null &&
                (daterange['to'] ?? '').isNotEmpty)
                ? DateTime.tryParse(daterange['to']!)
                : previousState?.toDate,
            incidentStatus: incidentStatus ?? previousState?.incidentStatus,
            selectedCaseType: nextCaseType,
            selectedSeverityLevels: nextSeverityLevels,
            selectedMetricIndex: finalSelectedMetricIndex,
            processState: ProcessState.done,
            projectId: currentProjectId,
            viewType: currentViewType,
          ),
        );
      } else {
        emit(
          CaseApproverDashboardLoaded(
            response: DashboardResponse(),
            incidents: const [],
            searchQuery: searchQuery,
            currentPage: page ?? 1,
            itemsPerPage: limit ?? 10,
            processState: ProcessState.done,
            errorMessage: response.error ??
                response.message ??
                'Failed to load approver dashboard',
            projectId: currentProjectId,
            viewType: currentViewType,
          ),
        );
      }
    } catch (e) {
      emit(CaseApproverDashboardError('Network error: ${e.toString()}'));
    }
  }

  void refreshIncidents() {
    if (state is CaseApproverDashboardLoaded) {
      final s = state as CaseApproverDashboardLoaded;
      Map<String, String>? daterange;
      if (s.fromDate != null && s.toDate != null) {
        daterange = {
          'from': formatDateForAPI(s.fromDate!),
          'to': formatEndOfDayForAPI(s.toDate!),
        };
      }
      loadIncidents(
        page: s.currentPage ?? 1,
        limit: s.itemsPerPage ?? 10,
        search: (s.searchQuery?.isNotEmpty == true) ? s.searchQuery : null,
        incidentStatus: s.incidentStatus,
        daterange: daterange,
        selectedMetricIndex: s.selectedMetricIndex,
      );
    } else {
      loadInitialData();
    }
  }

  void updateSearchQuery(String query) {
    if (state is CaseApproverDashboardLoaded) {
      emit((state as CaseApproverDashboardLoaded)
          .copyWith(searchQuery: query, currentPage: 1));
    }
  }

  void setSearchQuery(String searchQuery) {
    if (state is CaseApproverDashboardLoaded) {
      emit((state as CaseApproverDashboardLoaded)
          .copyWith(searchQuery: searchQuery));
    }
  }

  Future<void> changeItemsPerPage(int itemsPerPage) async {
    if (state is CaseApproverDashboardLoaded) {
      final s = state as CaseApproverDashboardLoaded;
      Map<String, String>? daterange;
      if (s.fromDate != null && s.toDate != null) {
        daterange = {
          'from': formatDateForAPI(s.fromDate!),
          'to': formatEndOfDayForAPI(s.toDate!),
        };
      }
      await loadIncidents(
        page: 1,
        limit: itemsPerPage,
        search: (s.searchQuery?.isNotEmpty == true) ? s.searchQuery : null,
        incidentStatus: s.incidentStatus,
        daterange: daterange,
        selectedMetricIndex: s.selectedMetricIndex,
      );
    } else {
      await loadInitialData();
    }
  }

  int getTotalPages() {
    if (state is! CaseApproverDashboardLoaded) return 0;
    final s = state as CaseApproverDashboardLoaded;
    final itemsPerPage = s.itemsPerPage ?? 10;
    final total = s.response.total ??
        s.dashboardStats?.statusSummary?.totalEmergexCase ??
        s.statusCount?.total ??
        0;
    if (total <= 0) return 0;
    return (total / itemsPerPage).ceil();
  }

  List<dynamic> get incidents {
    if (state is CaseApproverDashboardLoaded) {
      return (state as CaseApproverDashboardLoaded)
          .incidents
          .map((i) => _IncidentUIAdapter(i))
          .toList();
    }
    return const [];
  }
}

class _IncidentUIAdapter {
  final IncidentDetails _incident;
  _IncidentUIAdapter(this._incident);

  String get id => _incident.incidentId ?? '--';
  String get reportedBy => _incident.reportedBy ?? '--';
  String get dateReported => _formatDate(_incident.reportedDate);
  String get department => _incident.department ?? '--';
  String get country => _incident.country ?? '--';
  String get branch => _incident.branch ?? '--';
  String get severityLevel => _incident.incidentLevel?.value ?? '--';
  String get status => _incident.incidentStatus ?? '--';
  String get projectName => _incident.projectName ?? '--';
  String get type => _incident.type ?? '--';

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}
