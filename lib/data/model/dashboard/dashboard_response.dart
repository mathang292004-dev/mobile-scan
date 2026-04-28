import 'package:emergex/data/model/dashboard/dashboard_stats.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:equatable/equatable.dart';

/// Main Dashboard Response
class DashboardResponse extends Equatable {
  final int? page;
  final int? limit;
  final int? total;
  final StatusCount? statusCount;
  final List<IncidentDetails>? result;
  final DashboardStats? dashboardStats;
  final DateTime? startDate;
  final DateTime? endDate;

  const DashboardResponse({
    this.page,
    this.limit,
    this.total,
    this.statusCount,
    this.result,
    this.dashboardStats,
    this.startDate,
    this.endDate,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    // Parse dashboardStats — accept either a nested `dashboardStats` object
    // or the stats fields (caseOverview, statusSummary, etc.) at the root level.
    DashboardStats? stats;
    if (json['dashboardStats'] != null) {
      stats = DashboardStats.fromJson(
          json['dashboardStats'] as Map<String, dynamic>);
    } else if (json['caseOverview'] != null) {
      stats = DashboardStats.fromJson(json);
    }

    // Build StatusCount from statusSummary (new API) or legacy 'counts' key
    StatusCount? statusCount;
    if (stats?.statusSummary != null) {
      statusCount = StatusCount.fromStatusSummary(stats!.statusSummary!);
    } else if (json['counts'] != null) {
      statusCount =
          StatusCount.fromJson(json['counts'] as Map<String, dynamic>);
    }

    return DashboardResponse(
      page: (json['page'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      statusCount: statusCount,
      result: json['cases'] is List
          ? (json['cases'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => IncidentDetails.fromJson(e))
              .toList()
          : json['result'] is List
              ? (json['result'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map((e) => IncidentDetails.fromJson(e))
                  .toList()
              : null,
      dashboardStats: stats,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'counts': statusCount?.toJson(),
      'cases': result?.map((e) => e.toJson()).toList(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [page, limit, total, statusCount, result, dashboardStats, startDate, endDate];
}

/// Unified Dashboard Filters - supports all dashboard types
class DashboardFilters extends Equatable {
  final int? page;
  final int? limit;
  final String? project;
  final String? title;
  final String? status;
  final List<String>? severityLevels;
  final String? priority;
  final String? search;
  final Map<String, String>? daterange;
  final String? incidentId;
  final String? sortBy;
  final String? sortOrder;
  final String? reportedBy; // ER Team Approver only
  final String? department; // ER Team Approver only

  const DashboardFilters({
    this.page,
    this.limit,
    this.project,
    this.title,
    this.status,
    this.severityLevels,
    this.priority,
    this.search,
    this.daterange,
    this.incidentId,
    this.sortBy,
    this.sortOrder,
    this.reportedBy,
    this.department,
  });

  factory DashboardFilters.fromJson(Map<String, dynamic> json) {
    return DashboardFilters(
      page: (json['page'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      project: json['project'] as String?,
      title: json['title'] as String?,
      status: json['status'] as String?,
      severityLevels: (json['severityLevels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      priority: json['priority'] as String?,
      search: json['search'] as String?,
      daterange: (json['daterange'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      incidentId: json['incidentId'] as String?,
      sortBy: json['sortBy'] as String?,
      sortOrder: json['sortOrder'] as String?,
    );
  }

  /// Converts filters to JSON format matching backend API expectations
  /// IMPORTANT: ALL fields must be present in the payload, even if empty
  Map<String, dynamic> toJson() {
    return {
      'page': page ?? 0,
      'limit': limit ?? 10,
      'incidentId': incidentId ?? '',
      'projectName': project ?? '', // Map 'project' to 'projectName' for API
      'status': status ?? '',
      'daterange': daterange ?? {'from': '', 'to': ''},
      'severityLevel':
          severityLevels ?? [], // Map 'severityLevels' to 'severityLevel'
      'priority': priority ?? '',
      'search': search ?? '',
      'sortBy': sortBy ?? '',
      'sortOrder': sortOrder ?? 'asc',
    };
  }

  /// Converts filters to JSON format for ER Team Approver Dashboard API
  /// Matches the expected payload format exactly:
  /// {
  ///   "page": 0, "limit": 10, "status": [], "search": "",
  ///   "daterange": {"from": "YYYY-MM-DD", "to": "YYYY-MM-DD"},
  ///   "reportedBy": "string", "severityLevel": [], "priority": [],
  ///   "sortBy": "", "sortOrder": "asc"
  /// }
  Map<String, dynamic> toErApproverJson() {
  // Status → array
  List<String> statusArray = [];
  if (status != null && status!.isNotEmpty) {
    statusArray = [status!];
  }

  // Priority → array
  List<String> priorityArray = [];
  if (priority != null && priority!.isNotEmpty) {
    priorityArray = [priority!];
  }
assert(
  daterange == null ||
      (daterange!.containsKey('from') && daterange!.containsKey('to')),
  'daterange must contain both from and to',
);

  return {
    'page': page ?? 0,
    'limit': limit ?? 10,
    if (statusArray.isNotEmpty) 'status': statusArray,
    'search': search ?? '',
   'daterange': {
      'from': daterange?['from']?.split('T').first ?? '',
      'to': daterange?['to']?.split('T').first ?? '',
    },


    'reportedBy': reportedBy ?? '',
    'severityLevel': severityLevels ?? [],
    'priority': priorityArray,
    'sortBy': sortBy ?? '',
    'sortOrder': sortOrder ?? 'asc',
  };
}


  DashboardFilters copyWith({
    int? page,
    int? limit,
    String? project,
    String? title,
    String? status,
    List<String>? severityLevels,
    String? priority,
    String? search,
    Map<String, String>? daterange,
    String? incidentId,
    String? sortBy,
    String? sortOrder,
    String? reportedBy,
    String? department,
    bool clearProject = false,
    bool clearTitle = false,
    bool clearStatus = false,
    bool clearSeverityLevels = false,
    bool clearPriority = false,
    bool clearSearch = false,
    bool clearDaterange = false,
    bool clearIncidentId = false,
    bool clearSortBy = false,
    bool clearSortOrder = false,
    bool clearReportedBy = false,
    bool clearDepartment = false,
  }) {
    return DashboardFilters(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      project: clearProject ? null : (project ?? this.project),
      title: clearTitle ? null : (title ?? this.title),
      status: clearStatus ? null : (status ?? this.status),
      severityLevels: clearSeverityLevels
          ? null
          : (severityLevels ?? this.severityLevels),
      priority: clearPriority ? null : (priority ?? this.priority),
      search: clearSearch ? null : (search ?? this.search),
      daterange: clearDaterange ? null : (daterange ?? this.daterange),
      incidentId: clearIncidentId ? null : (incidentId ?? this.incidentId),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      sortOrder: clearSortOrder ? null : (sortOrder ?? this.sortOrder),
      reportedBy: clearReportedBy ? null : (reportedBy ?? this.reportedBy),
      department: clearDepartment ? null : (department ?? this.department),
    );
  }

  @override
  List<Object?> get props => [
    page,
    limit,
    project,
    title,
    status,
    severityLevels,
    priority,
    search,
    daterange,
    incidentId,
    sortBy,
    sortOrder,
    reportedBy,
    department,
  ];
}

/// Unified Status counts - supports all dashboard types
class StatusCount extends Equatable {
  // Common fields
  final int? total;

  // Dashboard fields
  final int? draft;
  final int? inProgress;
  final int? resolved;
  final int? ertToBeAssigned;
  final int? nullCount; // for the "null" key
  final int? inProgressAlt; // for "In Progress" key
  final int? incident;
  final int? intervention;
  final int? observation;
  final int? nearMiss;

  // ER Team Approver fields
  final int? verified;
  final int? notVerified;
  final int? rejected;
  final int? closed; // closed means verified

  // ER Team Leader/Member fields
  final int? approved;
  final int? reported; // ER Team Member only
  final int? ertTeamAssigned; // "ERT Team Assigned" count (from statusSummary.pending)

  const StatusCount({
    this.total,
    this.draft,
    this.inProgress,
    this.resolved,
    this.ertToBeAssigned,
    this.incident,
    this.nullCount,
    this.inProgressAlt,
    this.intervention,
    this.observation,
    this.nearMiss,
    this.verified,
    this.notVerified,
    this.rejected,
    this.closed,
    this.approved,
    this.reported,
    this.ertTeamAssigned,
  });

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(
      total: (json['total'] as num?)?.toInt(),
      // Dashboard fields
      draft: (json['Draft'] as num?)?.toInt(),
      inProgress:
          (json['inprogress'] as num?)?.toInt() ??
          (json['inProgress'] as num?)?.toInt() ??
          (json['Inprogress'] as num?)?.toInt(),
      resolved: (json['resolved'] as num?)?.toInt(),
      ertToBeAssigned: (json['ertToBeAssigned'] as num?)?.toInt(),
      nullCount: (json['null'] as num?)?.toInt(),
      inProgressAlt: (json['In Progress'] as num?)?.toInt(),
      intervention: (json['intervention'] as num?)?.toInt(),
      observation: (json['observation'] as num?)?.toInt(),
      nearMiss:
          (json['nearMiss'] as num?)?.toInt() ??
          (json['other'] as num?)?.toInt(),
      incident: (json['incident'] as num?)?.toInt(),
      // ER Team Approver fields
      verified: (json['verified'] as num?)?.toInt() ??
          (json['closed'] as num?)?.toInt(), // Check verified first, fallback to closed (closed means verified)
      notVerified:
          (json['notVerified'] as num?)?.toInt() ??
          (json['pending'] as num?)?.toInt(), // Backend may use "pending"
      rejected:
          (json['rejected'] as num?)?.toInt() ??
          (json['closed'] as num?)?.toInt(), // Check rejected first, fallback to closed
      closed: (json['closed'] as num?)?.toInt(), // closed field from API
      // ER Team Leader/Member fields
      approved: (json['Approved'] as num?)?.toInt(),
      reported: (json['Reported'] as num?)?.toInt(),
      ertTeamAssigned: (json['ertTeamAssigned'] as num?)?.toInt() ??
          (json['pending'] as num?)?.toInt(),
    );
  }

  /// Build a StatusCount from the new `statusSummary` block in dashboardStats.
  factory StatusCount.fromStatusSummary(StatusSummary summary) {
    return StatusCount(
      total: summary.totalEmergexCase,
      inProgress: summary.inprogress,
      ertToBeAssigned: summary.approvalPending,
      closed: summary.closed,
      ertTeamAssigned: summary.pending,
      resolved: summary.resolved,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (total != null) json['total'] = total;
    if (draft != null) json['Draft'] = draft;
    if (inProgress != null) json['inProgress'] = inProgress;
    if (incident != null) json['incident'] = incident;
    if (resolved != null) json['resolved'] = resolved;
    if (ertToBeAssigned != null) json['ertToBeAssigned'] = ertToBeAssigned;
    if (nullCount != null) json['null'] = nullCount;
    if (inProgressAlt != null) json['In Progress'] = inProgressAlt;
    if (intervention != null) json['intervention'] = intervention;
    if (observation != null) json['observation'] = observation;
    if (nearMiss != null) json['nearMiss'] = nearMiss;
    if (verified != null) json['verified'] = verified;
    if (notVerified != null) json['notVerified'] = notVerified;
    if (rejected != null) json['rejected'] = rejected;
    if (closed != null) json['closed'] = closed;
    if (approved != null) json['Approved'] = approved;
    if (reported != null) json['Reported'] = reported;
    if (ertTeamAssigned != null) json['ertTeamAssigned'] = ertTeamAssigned;
    return json;
  }

  @override
  List<Object?> get props => [
    total,
    draft,
    inProgress,
    resolved,
    ertToBeAssigned,
    nullCount,
    inProgressAlt,
    intervention,
    observation,
    incident,
    nearMiss,
    verified,
    notVerified,
    rejected,
    closed,
    approved,
    reported,
    ertTeamAssigned,
  ];
}
