/// Request model for verifying/rejecting tasks
class VerifyTaskRequest {
  final String incidentId;
  final List<String> taskIds;
  final String status; // 'Verified' or 'Rejected'

  VerifyTaskRequest({
    required this.incidentId,
    required this.taskIds,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'incidentId': incidentId,
      'taskIds': taskIds,
      'status': status,
    };
  }
}

/// Response model for verify task API
class VerifyTaskResponse {
  final int updatedCount;
  final String incidentId;
  final List<String> taskIds;
  final String status;

  VerifyTaskResponse({
    required this.updatedCount,
    required this.incidentId,
    required this.taskIds,
    required this.status,
  });

  factory VerifyTaskResponse.fromJson(Map<String, dynamic> json) {
    return VerifyTaskResponse(
      updatedCount: json['updatedCount'] as int? ?? 0,
      incidentId: json['incidentId'] as String? ?? '',
      taskIds: (json['taskIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatedCount': updatedCount,
      'incidentId': incidentId,
      'taskIds': taskIds,
      'status': status,
    };
  }
}
