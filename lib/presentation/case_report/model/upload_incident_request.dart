import 'package:dio/dio.dart';
import 'package:emergex/presentation/case_report/model/ai_summary_details.dart';

/// Request model for creating a new incident report.
class CreateIncidentRequest {
  final String? filePath;
  final String? incidentText;
  final String? incidentInformations;
  final String? projectId;
  final AiSummaryResponse? aiSummaryResponse;
  final List<String>? immediateActionsTaken;

  const CreateIncidentRequest({
    this.filePath,
    this.incidentText,
    this.incidentInformations,
    this.projectId,
    this.aiSummaryResponse,
    this.immediateActionsTaken,
  });
}

/// Request model for updating an existing incident.
class UpdateIncidentRequest {
  final String incidentId;
  final String? filePath;
  final String? incidentText;
  final String? incidentInformations;
  final String? uuInfoId;
  final String? projectId;
  final AiSummaryResponse? aiSummaryResponse;
  final List<String>? immediateActionsTaken;
  final CancelToken? cancelToken;

  const UpdateIncidentRequest({
    required this.incidentId,
    this.filePath,
    this.incidentText,
    this.incidentInformations,
    this.uuInfoId,
    this.projectId,
    this.aiSummaryResponse,
    this.immediateActionsTaken,
    this.cancelToken,
  });
}

/// Request model for deleting a file from the server.
class DeleteFileRequest {
  final String publicId;
  final String fileType;
  final bool? isCancel;

  const DeleteFileRequest({
    required this.publicId,
    required this.fileType,
    this.isCancel,
  });
}
