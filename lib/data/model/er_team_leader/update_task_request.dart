import 'package:equatable/equatable.dart';

/// Attachment payload included when an ERT file has been uploaded
class UpdateTaskAttachmentRequest extends Equatable {
  final String fileUrl;
  final String fileType;
  final String fileName;
  final int fileSize;

  const UpdateTaskAttachmentRequest({
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() => {
    'fileUrl': fileUrl,
    'fileType': fileType,
    'fileName': fileName,
    'fileSize': fileSize,
  };

  @override
  List<Object?> get props => [fileUrl, fileType, fileName, fileSize];
}

/// Request body for PATCH /incident/my-tasks/{incidentId}?type=ert
class UpdateTaskRequest extends Equatable {
  final String taskId;
  final String role;

  /// API action value: 'inprogress' | 'paused' | 'completed' | 'draft'
  final String action;

  final String? statusDescription;
  final List<UpdateTaskAttachmentRequest> attachments;

  const UpdateTaskRequest({
    required this.taskId,
    required this.action,
    this.role = 'tl',
    this.statusDescription,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'taskId': taskId,
      'role': role,
      'action': action,
    };
    if (statusDescription != null && statusDescription!.isNotEmpty) {
      map['statusDescription'] = statusDescription;
    }
    if (attachments.isNotEmpty) {
      map['attachments'] = attachments.map((a) => a.toJson()).toList();
    }
    return map;
  }

  @override
  List<Object?> get props => [taskId, role, action, statusDescription, attachments];
}
