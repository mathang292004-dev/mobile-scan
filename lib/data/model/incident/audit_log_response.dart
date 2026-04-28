class AuditLogResponse {
  final String? caseType;
  final Map<String, TimelineStage>? timeline;
  final List<ActivityLogEntry>? activityLog;

  AuditLogResponse({
    this.caseType,
    this.timeline,
    this.activityLog,
  });

  factory AuditLogResponse.fromJson(Map<String, dynamic> json) {
    return AuditLogResponse(
      caseType: json['caseType'] as String?,
      timeline: (json['timeline'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, TimelineStage.fromJson(value as Map<String, dynamic>)),
      ),
      activityLog: (json['activityLog'] as List<dynamic>?)
          ?.map((e) => ActivityLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TimelineStage {
  final bool completed;
  final String? completedAt;
  final UserInfo? completedBy;
  final String? description;

  TimelineStage({
    required this.completed,
    this.completedAt,
    this.completedBy,
    this.description,
  });

  factory TimelineStage.fromJson(Map<String, dynamic> json) {
    return TimelineStage(
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'] as String?,
      completedBy: json['completedBy'] != null
          ? UserInfo.fromJson(json['completedBy'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
    );
  }
}

class ActivityLogEntry {
  final String action;
  final String description;
  final UserInfo? performedBy;
  final String timestamp;

  ActivityLogEntry({
    required this.action,
    required this.description,
    this.performedBy,
    required this.timestamp,
  });

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntry(
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      performedBy: json['performedBy'] != null
          ? UserInfo.fromJson(json['performedBy'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class UserInfo {
  final String? userId;
  final String? name;

  UserInfo({
    this.userId,
    this.name,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] as String?,
      name: json['name'] as String?,
    );
  }
}
