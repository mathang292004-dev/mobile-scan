import 'package:equatable/equatable.dart';

/// My Task Response Model
class MyTaskResponse extends Equatable {
  final List<IncidentTaskGroup> data;
  final int totalTasks;

  const MyTaskResponse({required this.data, required this.totalTasks});

  factory MyTaskResponse.fromJson(Map<String, dynamic> json) {
    // Handle direct API structure: { tasks: [...], incidentIds: [...], totalTasks: n }
    if (json['tasks'] != null || json['totalTasks'] != null) {
      final tasksList = json['tasks'] as List<dynamic>? ?? [];
      final totalTasks = json['totalTasks'] as int? ?? 0;

      // Group tasks by their incidentId (singular) using fold
      final groupedTasks = tasksList
          .whereType<Map<String, dynamic>>()
          .fold<Map<String, List<Task>>>({}, (acc, taskJson) {
        final task = Task.fromJson(taskJson);
        // Each task has 'incidentId' (singular), not 'incidentIds' (plural)
        final incidentId = taskJson['incidentId'] as String?;
        final id = incidentId ?? 'Unknown';

        (acc[id] ??= []).add(task);
        return acc;
      });

      // Convert grouped map to list of IncidentTaskGroup
      final data = groupedTasks.entries
          .map((e) => IncidentTaskGroup(incidentId: e.key, tasks: e.value))
          .toList();

      return MyTaskResponse(data: data, totalTasks: totalTasks);
    }

    // Handle nested API structure: { data: { tasks: [...], incidentIds: [...], totalTasks: n } }
    final dynamic dataField = json['data'];
    if (dataField is Map<String, dynamic>) {
      final tasksList = dataField['tasks'] as List<dynamic>? ?? [];
      final totalTasks = dataField['totalTasks'] as int? ?? 0;

      // Group tasks by their incidentId (singular) using fold
      final groupedTasks = tasksList
          .whereType<Map<String, dynamic>>()
          .fold<Map<String, List<Task>>>({}, (acc, taskJson) {
        final task = Task.fromJson(taskJson);
        // Each task has 'incidentId' (singular), not 'incidentIds' (plural)
        final incidentId = taskJson['incidentId'] as String?;
        final id = incidentId ?? 'Unknown';

        (acc[id] ??= []).add(task);
        return acc;
      });

      // Convert grouped map to list of IncidentTaskGroup
      final data = groupedTasks.entries
          .map((e) => IncidentTaskGroup(incidentId: e.key, tasks: e.value))
          .toList();

      return MyTaskResponse(data: data, totalTasks: totalTasks);
    } else if (dataField is List) {
      // Legacy structure: data is already an array of IncidentTaskGroup
      return MyTaskResponse(
        data: (dataField)
            .whereType<Map<String, dynamic>>()
            .map((e) => IncidentTaskGroup.fromJson(e))
            .toList(),
        totalTasks: json['totalTasks'] as int? ?? 0,
      );
    }

    // Fallback for empty or unknown structure
    return MyTaskResponse(
      data: [],
      totalTasks: json['totalTasks'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'totalTasks': totalTasks,
    };
  }

  @override
  List<Object?> get props => [data, totalTasks];
}

/// Incident Task Group - groups tasks by incidentId
class IncidentTaskGroup extends Equatable {
  final String incidentId;
  final List<Task> tasks;

  const IncidentTaskGroup({required this.incidentId, required this.tasks});

  factory IncidentTaskGroup.fromJson(Map<String, dynamic> json) {
    return IncidentTaskGroup(
      incidentId: json['incidentId'] as String? ?? '',
      tasks: json['tasks'] is List
          ? (json['tasks'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Task.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incidentId': incidentId,
      'tasks': tasks.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [incidentId, tasks];
}

/// Task Model
class Task extends Equatable {
  final String? id;
  final String taskId;
  final String projectId;
  final String taskName;
  final String taskDetails;
  final List<Attachment> attachments;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? status;
  final String? statusUpdate;
  final String? completedBy;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final String? timeTaken;
  final int? totalPausedTime;
  final AiAnalysis? aiAnalysis;
  final List<String> incidentIds;

  const Task({
    this.id,
    required this.taskId,
    required this.projectId,
    required this.taskName,
    required this.taskDetails,
    required this.attachments,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.statusUpdate,
    this.completedBy,
    this.startedAt,
    this.pausedAt,
    this.completedAt,
    this.timeTaken,
    this.totalPausedTime,
    this.aiAnalysis,
    this.incidentIds = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Support both flat timer fields (old API) and nested timer object (new API)
    final timerMap = json['timer'] as Map<String, dynamic>?;

    DateTime? _parseDate(dynamic flat, dynamic nested) {
      final s = (flat ?? nested)?.toString();
      return s != null ? DateTime.tryParse(s) : null;
    }

    return Task(
      id: json['_id'] as String?,
      taskId: json['taskId'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      // Support taskTitle (new API) as fallback to taskName (old API)
      taskName: json['taskName'] as String? ?? json['taskTitle'] as String? ?? '',
      taskDetails: json['taskDetails'] as String? ?? '',
      attachments: json['attachments'] is List
          ? (json['attachments'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Attachment.fromJson(e))
                .toList()
          : [],
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      status: json['status'] as String?,
      statusUpdate: json['statusUpdate'] as String?,
      completedBy: json['completedBy'] as String?,
      startedAt: _parseDate(json['startedAt'], timerMap?['startedAt']),
      pausedAt: _parseDate(json['pausedAt'], timerMap?['pausedAt']),
      completedAt: _parseDate(json['completedAt'], timerMap?['completedAt']),
      timeTaken: json['timeTaken']?.toString() ?? timerMap?['timeTaken']?.toString(),
      totalPausedTime: json['totalPausedTime'] as int? ??
          timerMap?['totalPausedTime'] as int?,
      aiAnalysis: json['aiAnalysis'] != null
          ? AiAnalysis.fromJson(json['aiAnalysis'] as Map<String, dynamic>)
          : null,
      incidentIds: json['incidentId'] != null
          ? [json['incidentId'].toString()]
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'taskId': taskId,
      'projectId': projectId,
      'taskName': taskName,
      'taskDetails': taskDetails,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status,
      'statusUpdate': statusUpdate,
      'completedBy': completedBy,
      'startedAt': startedAt?.toIso8601String(),
      'pausedAt': pausedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeTaken': timeTaken,
      'totalPausedTime': totalPausedTime,
      'aiAnalysis': aiAnalysis?.toJson(),
      'incidentIds': incidentIds,
    };
  }

  @override
  List<Object?> get props => [
    id,
    taskId,
    projectId,
    taskName,
    taskDetails,
    attachments,
    isDeleted,
    createdAt,
    updatedAt,
    status,
    statusUpdate,
    completedBy,
    startedAt,
    pausedAt,
    completedAt,
    timeTaken,
    totalPausedTime,
    aiAnalysis,
    incidentIds,
  ];
}

/// Attachment Model
class Attachment extends Equatable {
  final String? id;
  final String fileUrl;
  final String fileName;
  final String key;

  const Attachment({
    this.id,
    required this.fileUrl,
    required this.fileName,
    required this.key,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['_id'] as String?,
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      key: json['key'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'fileUrl': fileUrl, 'fileName': fileName, 'key': key};
  }

  @override
  List<Object?> get props => [id, fileUrl, fileName, key];
}

/// AI Analysis Model
class AiAnalysis extends Equatable {
  final String aiSummary;
  final String delayRiskDetected;
  final String aiRecommendations;
  final int completenessScore;
  final int timelinessScore;
  final int documentationScore;

  const AiAnalysis({
    required this.aiSummary,
    required this.delayRiskDetected,
    required this.aiRecommendations,
    this.completenessScore = 0,
    this.timelinessScore = 0,
    this.documentationScore = 0,
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      aiSummary: json['aiSummary'] as String? ?? '',
      delayRiskDetected: json['delayRiskDetected'] as String? ?? '',
      aiRecommendations: json['aiRecommendations'] as String? ?? '',
      completenessScore: json['completenessScore'] as int? ?? 0,
      timelinessScore: json['timelinessScore'] as int? ?? 0,
      documentationScore: json['documentationScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aiSummary': aiSummary,
      'delayRiskDetected': delayRiskDetected,
      'aiRecommendations': aiRecommendations,
      'completenessScore': completenessScore,
      'timelinessScore': timelinessScore,
      'documentationScore': documentationScore,
    };
  }

  @override
  List<Object?> get props => [
    aiSummary,
    delayRiskDetected,
    aiRecommendations,
    completenessScore,
    timelinessScore,
    documentationScore,
  ];
}
