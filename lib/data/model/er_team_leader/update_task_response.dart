import 'package:equatable/equatable.dart';

/// Timer data for an updated task
class UpdateTaskTimerData extends Equatable {
  final String? startedAt;
  final String? pausedAt;
  final int? totalPausedTime;
  final String? completedAt;
  final int? timeTaken;

  const UpdateTaskTimerData({
    this.startedAt,
    this.pausedAt,
    this.totalPausedTime,
    this.completedAt,
    this.timeTaken,
  });

  factory UpdateTaskTimerData.fromJson(Map<String, dynamic> json) {
    return UpdateTaskTimerData(
      startedAt: json['startedAt'] as String?,
      pausedAt: json['pausedAt'] as String?,
      totalPausedTime: json['totalPausedTime'] as int?,
      completedAt: json['completedAt'] as String?,
      timeTaken: json['timeTaken'] as int?,
    );
  }

  @override
  List<Object?> get props => [startedAt, pausedAt, totalPausedTime, completedAt, timeTaken];
}

/// Attachment entry in the updated task response
class UpdateTaskResponseAttachment extends Equatable {
  final String fileUrl;
  final String fileType;
  final String fileName;
  final int fileSize;
  final String? uploadedAt;

  const UpdateTaskResponseAttachment({
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
    required this.fileSize,
    this.uploadedAt,
  });

  factory UpdateTaskResponseAttachment.fromJson(Map<String, dynamic> json) {
    return UpdateTaskResponseAttachment(
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      uploadedAt: json['uploadedAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [fileUrl, fileType, fileName, fileSize, uploadedAt];
}

/// Response body for PATCH /incident/my-tasks/{incidentId}?type=ert
class UpdateTaskResponse extends Equatable {
  final String? caseId;
  final String? taskId;
  final String? status;
  final String? statusDescription;
  final UpdateTaskTimerData? timer;
  final List<UpdateTaskResponseAttachment> attachments;
  final String? overAllTaskStatus;

  const UpdateTaskResponse({
    this.caseId,
    this.taskId,
    this.status,
    this.statusDescription,
    this.timer,
    this.attachments = const [],
    this.overAllTaskStatus,
  });

  factory UpdateTaskResponse.fromJson(Map<String, dynamic> json) {
    final attachmentsList = json['attachments'] as List<dynamic>? ?? [];
    return UpdateTaskResponse(
      caseId: json['caseId'] as String?,
      taskId: json['taskId'] as String?,
      status: json['status'] as String?,
      statusDescription: json['statusDescription'] as String?,
      timer: json['timer'] is Map<String, dynamic>
          ? UpdateTaskTimerData.fromJson(json['timer'] as Map<String, dynamic>)
          : null,
      attachments: attachmentsList
          .whereType<Map<String, dynamic>>()
          .map(UpdateTaskResponseAttachment.fromJson)
          .toList(),
      overAllTaskStatus: json['overAllTaskStatus'] as String?,
    );
  }

  @override
  List<Object?> get props => [caseId, taskId, status, statusDescription, timer, attachments, overAllTaskStatus];
}
