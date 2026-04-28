import 'package:dio/dio.dart';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/incident/audit_log_response.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/data/remote_data_source/incident_remote_data_source.dart';
import 'package:emergex/domain/repo/incident_repo.dart';
import 'package:emergex/presentation/case_report/model/ai_summary_details.dart';

import '../../../presentation/case_report/approver/model/team_members_data_model.dart';
import '../../../presentation/case_report/approver/model/reassign_eligible_users_model.dart';
import 'package:emergex/data/model/incident/preliminary_report_model.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final IncidentRemoteDataSource _remoteDataSource;

  IncidentRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<IncidentDetails>> createIncidentFileByPath(
    String? filePath,
    String? incidentText,
    String? incidentInformations,
    String? projectId,
    AiSummaryResponse? aiSummaryResponse, {
    List<String>? immediateActionsTaken,
  }) async {
    try {
      return await _remoteDataSource.createIncidentFileByPath(
        filePath,
        incidentText,
        incidentInformations,
        projectId,
        aiSummaryResponse,
        immediateActionsTaken: immediateActionsTaken,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse> deleteFileFromServer(
    String publicId,
    String fileType,
    bool? isCancel,
  ) async {
    try {
      return await _remoteDataSource.deleteFileFromServer(
        publicId,
        fileType,
        isCancel,
      );
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> updateIncident(
    String incidentId,
    String? filePath,
    String? incidentText,
    String? incidentInformations,
    String? uuInfoId,
    String? projectId,
    AiSummaryResponse? aiSummaryResponse, {
    CancelToken? cancelToken,
    List<String>? immediateActionsTaken,
  }) async {
    try {
      return await _remoteDataSource.updateIncident(
        incidentId,
        filePath,
        incidentText,
        incidentInformations,
        uuInfoId,
        projectId,
        aiSummaryResponse,
        cancelToken: cancelToken,
        immediateActionsTaken: immediateActionsTaken,
      );
    } catch (e) {
      throw e is Exception ? e : Exception(e.toString());
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> getIncidentById(
    String incidentId,
  ) async {
    try {
      return await _remoteDataSource.getIncidentById(incidentId);
    } catch (e) {
      return ApiResponse.error('Failed to get incident by id: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<TeamMembersData>> fetchTeamMembers(
    String projectId, {
    String? incidentId,
  }) async {
    try {
      return await _remoteDataSource.fetchTeamMembers(
        projectId,
        incidentId: incidentId,
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch team members: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse> removeMemberTask(
    String incidentId,
    String roleId,
  ) async {
    try {
      return await _remoteDataSource.removeMemberTask(
        incidentId,
        roleId,
      );
    } catch (e) {
      return ApiResponse.error('Failed to remove member task: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse> addTaskToMember({
    required String caseId,
    required String userId,
    required String type,
    required String role,
    required List<String> selectedLibraryTaskIds,
    List<ManualTaskEntry> manualTasks = const [],
  }) async {
    try {
      return await _remoteDataSource.addTaskToMember(
        caseId: caseId,
        userId: userId,
        type: type,
        role: role,
        selectedLibraryTaskIds: selectedLibraryTaskIds,
        manualTasks: manualTasks,
      );
    } catch (e) {
      return ApiResponse.error('Failed to add task to member: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> reportIncident(String incidentId) async {
    try {
      return await _remoteDataSource.reportIncident(incidentId);
    } catch (e) {
      return ApiResponse.error('Failed to report incident: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse> deleteIncident(String incidentId) async {
    try {
      final response = await _remoteDataSource.deleteIncident(incidentId);
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to delete incident: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<String>> preSignedUrl(String key) async {
    return await _remoteDataSource.preSignedUrl(key);
  }

  @override
  Future<ApiResponse<IncidentDetails>> updateIncidentApproval(
    String incidentId,
    String type,
  ) async {
    try {
      return await _remoteDataSource.updateIncidentApproval(incidentId, type);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> incidentApproval(
    String incidentId,
    String type,
  ) async {
    try {
      return await _remoteDataSource.incidentApproval(incidentId, type);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<dynamic>> submitSetup(
    String incidentId,
    String type,
  ) async {
    try {
      return await _remoteDataSource.submitSetup(incidentId, type);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> updateReportFields(
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _remoteDataSource.updateReportFields(payload);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> updateMembers(
    String incidentId,
    List<Map<String, dynamic>> members,
  ) async {
    try {
      return await _remoteDataSource.updateMembers(incidentId, members);
    } catch (e) {
      return ApiResponse.error('Failed to update members: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<AuditLogResponse>> getAuditLogs(String incidentId) async {
    try {
      return await _remoteDataSource.getAuditLogs(incidentId);
    } catch (e) {
      return ApiResponse.error('Failed to fetch audit logs: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<PreliminaryReportData>> getPreliminaryReport(
    String incidentId,
  ) async {
    try {
      return await _remoteDataSource.getPreliminaryReport(incidentId);
    } catch (e) {
      return ApiResponse.error(
        'Failed to fetch preliminary report: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<ReassignEligibleUsersResponse>> getEligibleUsers({
    required String clientId,
    required String type,
    required String role,
    required String caseId,
  }) async {
    try {
      return await _remoteDataSource.getEligibleUsers(
        clientId: clientId,
        type: type,
        role: role,
        caseId: caseId,
      );
    } catch (e) {
      return ApiResponse.error(
        'Failed to fetch eligible users: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<PreliminaryReportData>> updatePreliminaryReport(
    String incidentId,
    String tab,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _remoteDataSource.updatePreliminaryReport(
        incidentId,
        tab,
        data,
      );
    } catch (e) {
      return ApiResponse.error(
        'Failed to save preliminary report: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<String>> exportPreliminaryReportPdf(
    String incidentId,
  ) async {
    try {
      return await _remoteDataSource.exportPreliminaryReportPdf(incidentId);
    } catch (e) {
      return ApiResponse.error(
        'Failed to export preliminary report PDF: ${e.toString()}',
      );
    }
  }
}
