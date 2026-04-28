/// Task detail for emergency response card display.
class TaskDetails {
  final String taskName;
  final String status;
  final String taskId;
  final bool isAssigned;

  TaskDetails({
    required this.taskName,
    required this.status,
    required this.taskId,
    required this.isAssigned,
  });
}

/// Uploaded file information for emergency response cards.
class UploadedFile {
  final String fileName;
  final String format;
  final String uploadedAt;

  UploadedFile({
    required this.fileName,
    required this.format,
    required this.uploadedAt,
  });
}

/// User detail for emergency response cards.
class UserDetails {
  final String userName;
  final String userRole;
  final String roleId;
  final String taskStatus;
  final String avatarUrl;

  UserDetails({
    required this.userName,
    required this.userRole,
    required this.roleId,
    required this.taskStatus,
    required this.avatarUrl,
  });
}

/// Emergency response team tasks card data.
class EmergencyResponseTeamTasks {
  final UserDetails userDetails;
  final String incidentID;
  final String incident;
  final List<TaskDetails> taskDetails;
  final List<UploadedFile> uploadedFiles;

  EmergencyResponseTeamTasks({
    required this.userDetails,
    required this.incidentID,
    required this.incident,
    required this.taskDetails,
    required this.uploadedFiles,
  });
}
