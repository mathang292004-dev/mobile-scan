import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/presentation/case_report/model/dashboard_request_payload.dart';
import 'package:emergex/data/model/dashboard/dashboard_stats.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/presentation/case_report/member/use_cases/dashboard_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/model/dashboard/dashboard_response.dart';
import 'package:emergex/helpers/auth_guard.dart';
import 'package:emergex/services/connectivity_service.dart';
import 'dart:async';

// ──────────────────────────────────────────
// Dashboard States
// ──────────────────────────────────────────

abstract class DashboardState extends Equatable {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {
  @override
  List<Object?> get props => [];
}

class DashboardLoaded extends DashboardState {
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

  DashboardLoaded({
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

  // UI compatibility properties — prefer new dashboardStats, fall back to statusCount
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
  int get incident => statusCount?.incident ?? 0;
  int get intervention => statusCount?.intervention ?? 0;
  int get observation => statusCount?.observation ?? 0;
  int get nearMiss => statusCount?.nearMiss ?? 0;

  DashboardLoaded copyWith({
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
    return DashboardLoaded(
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

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// ──────────────────────────────────────────
// Dashboard Cubit
// ──────────────────────────────────────────

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardUseCase _dashboardUseCase;
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySub;

  DashboardCubit(this._dashboardUseCase) : super(DashboardInitial()) {
    _connectivitySub = _connectivityService.connectivityStream.listen(
      (isConnected) => updateConnectivity(isConnected),
    );
  }

  bool get isOnline {
    if (state is DashboardLoaded) return (state as DashboardLoaded).isOnline;
    return _connectivityService.isConnected;
  }

  void updateConnectivity(bool isConnected) {
    if (state is DashboardLoaded) {
      emit((state as DashboardLoaded).copyWith(isOnline: isConnected));
    }
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }

  void clearCache() {
    emit(DashboardInitial());
  }

  void toggleViewType() {
    if (state is DashboardLoaded) {
      final s = state as DashboardLoaded;
      final newType = s.viewType == DashboardViewType.graph
          ? DashboardViewType.normal
          : DashboardViewType.graph;
      emit(s.copyWith(viewType: newType));
    }
  }

  Future<void> loadInitialData() async {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      Map<String, String>? daterange;
      if (currentState.fromDate != null && currentState.toDate != null) {
        daterange = {
          'from':
              '${currentState.fromDate!.year}-${currentState.fromDate!.month.toString().padLeft(2, '0')}-${currentState.fromDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z',
          'to':
              '${currentState.toDate!.year}-${currentState.toDate!.month.toString().padLeft(2, '0')}-${currentState.toDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z',
        };
      }

      loadIncidents(
        page: 1,
        limit: 10,
        incidentStatus: currentState.incidentStatus,
        daterange: daterange,
        selectedMetricIndex: currentState.selectedMetricIndex,
      );
    } else {
      final today = DateTime.now();
      final dateRange = {
        'from': _formatDateForAPI(today),
        'to': _formatDateForAPI(today),
      };
      loadIncidents(
        page: 1,
        limit: 10,
        selectedMetricIndex: 0,
        daterange: dateRange,
      );
    }
  }

  String _formatDateForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}T00:00:00.000Z';
  }

  String _formatEndOfDayForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}T23:59:59.999Z';
  }

  Future<void> refreshWithTodayDate(bool? isInitial) async {
    final today = DateTime.now();
    final dateRange = {
      'from': _formatDateForAPI(today),
      'to': _formatEndOfDayForAPI(today),
    };

    await loadIncidents(
      page: 1,
      limit: 10,
      daterange: dateRange,
      isInitial: isInitial,
    );
  }

  void setSearchQuery(String searchQuery) {
    emit((state as DashboardLoaded).copyWith(searchQuery: searchQuery));
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
      final previousState = state is DashboardLoaded ? state as DashboardLoaded : null;

      String? searchQuery = previousState?.searchQuery;
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
        DashboardLoaded(
          response: DashboardResponse(),
          incidents: [],
          searchQuery: searchQuery,
          fromDate: previousState?.fromDate,
          toDate: previousState?.toDate,
          incidentStatus: previousState?.incidentStatus,
          selectedCaseType: nextCaseType,
          selectedSeverityLevels: nextSeverityLevels,
          selectedMetricIndex: previousState?.selectedMetricIndex ?? 0,
          statusCount: previousState?.statusCount,
          dashboardStats: previousState?.dashboardStats,
          processState: ProcessState.loading,
          errorMessage: null,
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
      final response = await _dashboardUseCase.getIncidentsList(payload);

      if (response.success == true && response.data != null) {
        final incidents = response.data?.result ?? [];
        final statusCount =
            response.data?.statusCount ?? const StatusCount(total: 0, draft: 0);
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

        final finalSelectedMetricIndex =
            selectedMetricIndex ??
            (state is DashboardLoaded
                ? (state as DashboardLoaded).selectedMetricIndex
                : 0);

        emit(
          DashboardLoaded(
            response: response.data!,
            incidents: incidents,
            statusCount: updateDashboardStats ? statusCount : previousState?.statusCount,
            dashboardStats:
                updateDashboardStats ? dashboardStats : previousState?.dashboardStats,
            searchQuery: searchQuery,
            currentPage: page ?? 1,
            itemsPerPage: limit ?? 10,
            fromDate:
                fromDate ??
                (state is DashboardLoaded
                    ? (state as DashboardLoaded).fromDate
                    : null),
            toDate:
                toDate ??
                (state is DashboardLoaded
                    ? (state as DashboardLoaded).toDate
                    : null),
            incidentStatus: incidentStatus ?? previousState?.incidentStatus,
            selectedCaseType: nextCaseType,
            selectedSeverityLevels: nextSeverityLevels,
            selectedMetricIndex: finalSelectedMetricIndex,
            processState: ProcessState.done,
            errorMessage: null,
            projectId: currentProjectId,
            viewType: currentViewType,
          ),
        );
      } else {
        if (state is DashboardLoaded) {
          emit(
            (state as DashboardLoaded).copyWith(
              processState: ProcessState.done,
              errorMessage:
                  response.error ??
                  response.message ??
                  'Failed to load dashboard data',
              projectId: currentProjectId,
            ),
          );
        } else {
          emit(
            DashboardLoaded(
              response: DashboardResponse(),
              incidents: [],
              searchQuery: searchQuery,
              currentPage: page ?? 1,
              itemsPerPage: limit ?? 10,
              processState: ProcessState.done,
              errorMessage:
                  response.error ??
                  response.message ??
                  'Failed to load dashboard data',
              projectId: currentProjectId,
              viewType: currentViewType,
            ),
          );
        }
      }
    } catch (e) {
      emit(DashboardError('Network error: ${e.toString()}'));
    }
  }

  void refreshIncidents() {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;

      Map<String, String>? daterange;
      if (currentState.fromDate != null && currentState.toDate != null) {
        daterange = {
          'from': _formatDateForAPI(currentState.fromDate!),
          'to': _formatEndOfDayForAPI(currentState.toDate!),
        };
      }

      loadIncidents(
        page: currentState.currentPage ?? 1,
        limit: currentState.itemsPerPage ?? 10,
        search: (currentState.searchQuery?.isNotEmpty == true)
            ? currentState.searchQuery
            : null,
        incidentStatus: currentState.incidentStatus,
        daterange: daterange,
        selectedMetricIndex: currentState.selectedMetricIndex,
      );
    } else {
      loadInitialData();
    }
  }

  void updateSearchQuery(String query) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(currentState.copyWith(searchQuery: query, currentPage: 1));
    }
  }

  void updateSelectedMetricIndex(int index) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(currentState.copyWith(selectedMetricIndex: index));
    }
  }

  Future<void> changeItemsPerPage(int itemsPerPage) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;

      Map<String, String>? daterange;
      if (currentState.fromDate != null && currentState.toDate != null) {
        daterange = {
          'from': _formatDateForAPI(currentState.fromDate!),
          'to': _formatEndOfDayForAPI(currentState.toDate!),
        };
      }

      await loadIncidents(
        page: 1,
        limit: itemsPerPage,
        search: (currentState.searchQuery?.isNotEmpty == true)
            ? currentState.searchQuery
            : null,
        incidentStatus: currentState.incidentStatus,
        daterange: daterange,
        selectedMetricIndex: currentState.selectedMetricIndex,
      );
    } else {
      await loadInitialData();
    }
  }

  int getTotalPages() {
    if (state is! DashboardLoaded) return 0;

    final currentState = state as DashboardLoaded;

    try {
      final itemsPerPage = currentState.itemsPerPage ?? 10;
      final total = currentState.response.total ??
          currentState.dashboardStats?.statusSummary?.totalEmergexCase ??
          currentState.statusCount?.total ??
          0;
      if (total <= 0) return 0;
      return (total / itemsPerPage).ceil();
    } catch (_) {
      return 0;
    }
  }

  int get totalCount => state is DashboardLoaded
      ? (state as DashboardLoaded).statusCount?.total ?? 0
      : 0;

  int get resolvedCount => state is DashboardLoaded
      ? (state as DashboardLoaded).statusCount?.resolved ?? 0
      : 0;

  int get pendingCount => state is DashboardLoaded
      ? (state as DashboardLoaded).statusCount?.ertToBeAssigned ?? 0
      : 0;

  int get approvedCount => state is DashboardLoaded
      ? (state as DashboardLoaded).statusCount?.inProgress ?? 0
      : 0;

  List<dynamic> get incidents {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      final incidentsList = currentState.incidents
          .map((incident) => _IncidentUIAdapter(incident))
          .toList();
      return incidentsList;
    }
    return [];
  }

  bool get isLoading => state is DashboardLoading;
  bool get hasError => state is DashboardError;
  String get errorMessage =>
      state is DashboardError ? (state as DashboardError).message : '';

  int get currentPage => state is DashboardLoaded
      ? (state as DashboardLoaded).currentPage ?? 1
      : 1;

  int get itemsPerPage => state is DashboardLoaded
      ? (state as DashboardLoaded).itemsPerPage ?? 10
      : 10;

  int get totalCountFromAPI => state is DashboardLoaded
      ? (state as DashboardLoaded).statusCount?.total ?? 0
      : 0;
  String get searchQuery => state is DashboardLoaded
      ? (state as DashboardLoaded).searchQuery ?? ''
      : '';
  String get incidentStatus => state is DashboardLoaded
      ? (state as DashboardLoaded).incidentStatus ?? ''
      : '';
}

// UI Adapter to maintain compatibility with existing UI
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
    } catch (e) {
      return dateString;
    }
  }
}
