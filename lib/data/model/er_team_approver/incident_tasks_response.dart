import 'package:equatable/equatable.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart'
    show AiAnalysis;

/// Response model for incident tasks API
class IncidentTasksResponse extends Equatable {
  final String incidentId;
  final EmergexCaseSummary? emergexCaseSummary;
  final IncidentTimer? timer;
  final List<UserTask> tasks;

  const IncidentTasksResponse({
    required this.incidentId,
    this.emergexCaseSummary,
    this.timer,
    required this.tasks,
  });

  factory IncidentTasksResponse.fromJson(Map<String, dynamic> json) {
    return IncidentTasksResponse(
      incidentId: json['incidentId'] as String? ?? '',
      emergexCaseSummary: json['emergexCaseSummary'] != null
          ? EmergexCaseSummary.fromJson(
              json['emergexCaseSummary'] as Map<String, dynamic>)
          : null,
      timer: json['timer'] != null
          ? IncidentTimer.fromJson(json['timer'] as Map<String, dynamic>)
          : null,
      tasks: json['tasks'] is List
          ? (json['tasks'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => UserTask.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incidentId': incidentId,
      'emergexCaseSummary': emergexCaseSummary?.toJson(),
      'timer': timer?.toJson(),
      'tasks': tasks.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [incidentId, emergexCaseSummary, timer, tasks];
}

/// Model for incident timer
class IncidentTimer extends Equatable {
  final String? startTime;
  final String? endTime;
  final int? timeTaken;

  const IncidentTimer({
    this.startTime,
    this.endTime,
    this.timeTaken,
  });

  factory IncidentTimer.fromJson(Map<String, dynamic> json) {
    return IncidentTimer(
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      timeTaken: json['timeTaken'] is int
          ? json['timeTaken'] as int
          : int.tryParse(json['timeTaken']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'timeTaken': timeTaken,
    };
  }

  @override
  List<Object?> get props => [startTime, endTime, timeTaken];
}

/// Model for Emergex Case Summary
class EmergexCaseSummary extends Equatable {
  final List<String> summary;
  final String category;
  final String classification;
  final String location;
  final String dateTime;
  final String actionTaken;

  const EmergexCaseSummary({
    required this.summary,
    required this.category,
    required this.classification,
    required this.location,
    required this.dateTime,
    required this.actionTaken,
  });

  factory EmergexCaseSummary.fromJson(Map<String, dynamic> json) {
    return EmergexCaseSummary(
      summary: json['summary'] is List
          ? (json['summary'] as List).map((e) => e.toString()).toList()
          : [],
      category: json['category'] as String? ?? 'Not specified',
      classification: json['classification'] as String? ?? 'Not specified',
      location: json['location'] as String? ?? 'Not specified',
      dateTime: json['dateTime'] as String? ?? 'Not specified',
      actionTaken: json['actionTaken'] as String? ?? 'No action was taken',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'category': category,
      'classification': classification,
      'location': location,
      'dateTime': dateTime,
      'actionTaken': actionTaken,
    };
  }

  @override
  List<Object?> get props =>
      [summary, category, classification, location, dateTime, actionTaken];
}

/// Model for user tasks
class UserTask extends Equatable {
  final String userId;
  final List<TaskItem> tasks;

  const UserTask({
    required this.userId,
    required this.tasks,
  });

  factory UserTask.fromJson(Map<String, dynamic> json) {
    return UserTask(
      userId: json['userId'] as String? ?? '',
      tasks: json['tasks'] is List
          ? (json['tasks'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => TaskItem.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'tasks': tasks.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [userId, tasks];
}

/// Model for individual task item
class TaskItem extends Equatable {
  final String taskId;
  final String status;
  final String? statusUpdate;
  final String? completedBy;
  final String? startedAt;
  final String? completedAt;
  final String? timeTaken;
  final String taskName;
  final String taskDetails;
  final List<TaskAttachment> attachments;
  final AiAnalysis? aiAnalysis;

  const TaskItem({
    required this.taskId,
    required this.status,
    this.statusUpdate,
    this.completedBy,
    this.startedAt,
    this.completedAt,
    this.timeTaken,
    required this.taskName,
    required this.taskDetails,
    required this.attachments,
    this.aiAnalysis,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    // Handle timeTaken as int or String
    String? timeTakenStr;
    if (json['timeTaken'] != null) {
      if (json['timeTaken'] is int) {
        timeTakenStr = json['timeTaken'].toString();
      } else if (json['timeTaken'] is String) {
        timeTakenStr = json['timeTaken'] as String;
      }
    }

    return TaskItem(
      taskId: json['taskId'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      statusUpdate: json['statusUpdate'] as String?,
      completedBy: json['completedBy'] as String?,
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      timeTaken: timeTakenStr,
      taskName: json['taskName'] as String? ?? '',
      taskDetails: json['taskDetails'] as String? ?? '',
      attachments: json['attachments'] is List
          ? (json['attachments'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => TaskAttachment.fromJson(e))
              .toList()
          : [],
      aiAnalysis: json['aiAnalysis'] != null
          ? AiAnalysis.fromJson(json['aiAnalysis'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'status': status,
      'statusUpdate': statusUpdate,
      'completedBy': completedBy,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'timeTaken': timeTaken,
      'taskName': taskName,
      'taskDetails': taskDetails,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'aiAnalysis': aiAnalysis?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        taskId,
        status,
        statusUpdate,
        completedBy,
        startedAt,
        completedAt,
        timeTaken,
        taskName,
        taskDetails,
        attachments,
        aiAnalysis,
      ];
}

/// Model for task attachments
class TaskAttachment extends Equatable {
  final String fileUrl;
  final String fileName;
  final String key;
  final String? id;

  const TaskAttachment({
    required this.fileUrl,
    required this.fileName,
    required this.key,
    this.id,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      key: json['key'] as String? ?? '',
      id: json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileUrl': fileUrl,
      'fileName': fileName,
      'key': key,
      if (id != null) '_id': id,
    };
  }

  @override
  List<Object?> get props => [fileUrl, fileName, key, id];
}
