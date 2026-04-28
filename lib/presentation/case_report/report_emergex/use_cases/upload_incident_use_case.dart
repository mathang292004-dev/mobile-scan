import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/domain/repo/incident_repo.dart';
import 'package:emergex/presentation/case_report/model/upload_incident_request.dart';

class UploadIncidentUseCase {
  final IncidentRepository _incidentRepository;

  UploadIncidentUseCase(this._incidentRepository);

  Future<ApiResponse<IncidentDetails>> createIncident(
    CreateIncidentRequest request,
  ) async {
    try {
      final response = await _incidentRepository.createIncidentFileByPath(
        request.filePath,
        request.incidentText,
        request.incidentInformations,
        request.projectId,
        request.aiSummaryResponse,
        immediateActionsTaken: request.immediateActionsTaken,
      );
      if (response.success == true) {
        return response;
      } else {
        throw Exception(response.error);
      }
    } catch (e) {
      throw e is Exception ? e : Exception(e.toString());
    }
  }

  Future<ApiResponse> deleteFile(DeleteFileRequest request) async {
    try {
      final response = await _incidentRepository.deleteFileFromServer(
        request.publicId,
        request.fileType,
        request.isCancel,
      );
      if (response.success == true) {
        return response;
      } else {
        throw Exception('Failed to delete file: ${response.error}');
      }
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  Future<ApiResponse<IncidentDetails>> updateIncident(
    UpdateIncidentRequest request,
  ) async {
    try {
      return await _incidentRepository.updateIncident(
        request.incidentId,
        request.filePath,
        request.incidentText,
        request.incidentInformations,
        request.uuInfoId,
        request.projectId,
        request.aiSummaryResponse,
        cancelToken: request.cancelToken,
        immediateActionsTaken: request.immediateActionsTaken,
      );
    } catch (e) {
      throw e is Exception ? e : Exception(e.toString());
    }
  }

  /// These methods take ≤ 2 params — direct params allowed per convention.
  Future<ApiResponse<IncidentDetails>> getIncidentById(
    String incidentId,
  ) async {
    try {
      final response = await _incidentRepository.getIncidentById(incidentId);
      if (response.success == true && response.data != null) {
        return response;
      } else {
        throw Exception('Failed to get incident: ${response.error}');
      }
    } catch (e) {
      throw Exception('Failed to get incident: ${e.toString()}');
    }
  }

  Future<ApiResponse<IncidentDetails>> reportIncident(
    String incidentId,
  ) async {
    try {
      return await _incidentRepository.reportIncident(incidentId);
    } catch (e) {
      throw Exception('Failed to report incident: ${e.toString()}');
    }
  }

  Future<ApiResponse> deleteIncident(String incidentId) async {
    try {
      return await _incidentRepository.deleteIncident(incidentId);
    } catch (e) {
      throw Exception('Failed to delete incident: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> preSignedUrl(String key) async {
    return await _incidentRepository.preSignedUrl(key);
  }
}
