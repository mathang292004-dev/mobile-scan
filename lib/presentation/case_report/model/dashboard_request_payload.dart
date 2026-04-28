/// Typed query payload sent to both the member and approver dashboard
/// endpoints. The data sources serialize this with [toJson] and pass it
/// as the URL-encoded `filters` query parameter (Dio handles the encoding).
///
/// Member endpoint: `GET /api/incident/member-dashboard?filters=<json>`
/// Approver endpoint: `GET /api/incident/approver-dashboard?type=admin&filters=<json>`
///
/// Both endpoints return the same shape, parsed by `DashboardResponse`.
class DashboardRequestPayload {
  final int page;
  final int limit;
  final String? status;
  final String? search;
  final DashboardDateRange? daterange;
  final String? caseType;
  final List<String> severityLevel;
  final bool isInitial;

  const DashboardRequestPayload({
    this.page = 0,
    this.limit = 10,
    this.status,
    this.search,
    this.daterange,
    this.caseType,
    this.severityLevel = const [],
    this.isInitial = false,
  });

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'status': status,
        'search': search,
        'daterange': daterange?.toJson() ?? const {'from': '', 'to': ''},
        'caseType': caseType ?? '',
        'severityLevel': severityLevel,
        'isInitial': isInitial,
      };

  DashboardRequestPayload copyWith({
    int? page,
    int? limit,
    String? status,
    String? search,
    DashboardDateRange? daterange,
    String? caseType,
    List<String>? severityLevel,
    bool? isInitial,
  }) {
    return DashboardRequestPayload(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      status: status ?? this.status,
      search: search ?? this.search,
      daterange: daterange ?? this.daterange,
      caseType: caseType ?? this.caseType,
      severityLevel: severityLevel ?? this.severityLevel,
      isInitial: isInitial ?? this.isInitial,
    );
  }
}

class DashboardDateRange {
  final String from;
  final String to;

  const DashboardDateRange({required this.from, required this.to});

  factory DashboardDateRange.fromMap(Map<String, String>? map) {
    return DashboardDateRange(
      from: map?['from'] ?? '',
      to: map?['to'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'from': from, 'to': to};
}
