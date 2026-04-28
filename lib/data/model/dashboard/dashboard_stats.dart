// Models for the `dashboardStats` block returned by the member dashboard API.

class CaseOverviewEntry {
  final String caseType;
  final int pending;
  final int inprogress;
  final int closed;

  const CaseOverviewEntry({
    required this.caseType,
    required this.pending,
    required this.inprogress,
    required this.closed,
  });

  factory CaseOverviewEntry.fromJson(Map<String, dynamic> json) {
    return CaseOverviewEntry(
      caseType: json['caseType'] as String? ?? '',
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      inprogress: (json['inprogress'] as num?)?.toInt() ?? 0,
      closed: (json['closed'] as num?)?.toInt() ?? 0,
    );
  }
}

class StatusSummary {
  final int totalEmergexCase;
  final int inprogress;
  final int approvalPending;
  final int closed;
  final int pending;   // ERT Team Assigned count (TL/Member API)
  final int resolved;  // ERT Task Completed count (TL/Member API)

  const StatusSummary({
    required this.totalEmergexCase,
    required this.inprogress,
    required this.approvalPending,
    required this.closed,
    this.pending = 0,
    this.resolved = 0,
  });

  factory StatusSummary.fromJson(Map<String, dynamic> json) {
    return StatusSummary(
      totalEmergexCase: (json['totalEmergexCase'] as num?)?.toInt() ?? 0,
      inprogress: (json['inprogress'] as num?)?.toInt() ?? 0,
      approvalPending: (json['approvalPending'] as num?)?.toInt() ?? 0,
      closed: (json['closed'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      resolved: (json['resolved'] as num?)?.toInt() ?? 0,
    );
  }
}

class HighRiskCasesData {
  final int percentage;
  final int immediateActionRequired;

  const HighRiskCasesData({
    required this.percentage,
    required this.immediateActionRequired,
  });

  factory HighRiskCasesData.fromJson(Map<String, dynamic> json) {
    return HighRiskCasesData(
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      immediateActionRequired:
          (json['immediateActionRequired'] as num?)?.toInt() ?? 0,
    );
  }
}

class SeverityStats {
  final int percentage;
  final int count;

  const SeverityStats({required this.percentage, required this.count});

  factory SeverityStats.fromJson(Map<String, dynamic> json) {
    return SeverityStats(
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CaseSeverityAnalysis {
  final SeverityStats low;
  final SeverityStats medium;
  final SeverityStats high;

  const CaseSeverityAnalysis({
    required this.low,
    required this.medium,
    required this.high,
  });

  factory CaseSeverityAnalysis.fromJson(Map<String, dynamic> json) {
    return CaseSeverityAnalysis(
      low: json['low'] != null
          ? SeverityStats.fromJson(json['low'] as Map<String, dynamic>)
          : const SeverityStats(percentage: 0, count: 0),
      medium: json['medium'] != null
          ? SeverityStats.fromJson(json['medium'] as Map<String, dynamic>)
          : const SeverityStats(percentage: 0, count: 0),
      high: json['high'] != null
          ? SeverityStats.fromJson(json['high'] as Map<String, dynamic>)
          : const SeverityStats(percentage: 0, count: 0),
    );
  }
}

class DashboardStats {
  final List<CaseOverviewEntry> caseOverview;
  final StatusSummary? statusSummary;
  final HighRiskCasesData? highRiskCases;
  final int casesIncreasedThisMonth;
  final CaseSeverityAnalysis? caseSeverityAnalysis;

  const DashboardStats({
    required this.caseOverview,
    this.statusSummary,
    this.highRiskCases,
    this.casesIncreasedThisMonth = 0,
    this.caseSeverityAnalysis,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      caseOverview: json['caseOverview'] is List
          ? (json['caseOverview'] as List)
              .whereType<Map<String, dynamic>>()
              .map(CaseOverviewEntry.fromJson)
              .toList()
          : [],
      statusSummary: json['statusSummary'] != null
          ? StatusSummary.fromJson(
              json['statusSummary'] as Map<String, dynamic>)
          : null,
      highRiskCases: json['highRiskCases'] != null
          ? HighRiskCasesData.fromJson(
              json['highRiskCases'] as Map<String, dynamic>)
          : null,
      casesIncreasedThisMonth:
          (json['casesIncreasedThisMonth'] as num?)?.toInt() ?? 0,
      caseSeverityAnalysis: json['caseSeverityAnalysis'] != null
          ? CaseSeverityAnalysis.fromJson(
              json['caseSeverityAnalysis'] as Map<String, dynamic>)
          : null,
    );
  }
}
