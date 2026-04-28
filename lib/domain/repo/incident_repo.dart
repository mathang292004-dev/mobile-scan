import 'package:dio/dio.dart';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/incident/audit_log_response.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/presentation/case_report/model/ai_summary_details.dart';

import '../../presentation/case_report/approver/model/team_members_data_model.dart';
import '../../presentation/case_report/approver/model/reassign_eligible_users_model.dart';
import 'package:emergex/data/model/incident/preliminary_report_model.dart';

abstract class IncidentRepository {
  Future<ApiResponse<IncidentDetails>> createIncidentFileByPath(
    String? filePath,
    String? incidentText,
    String? incidentInformations,
    String? projectId,
    AiSummaryResponse? aiSummaryResponse, {
    List<String>? immediateActionsTaken,
  });
  Future<ApiResponse> deleteFileFromServer(
    String publicId,
    String fileType,
    bool? isCancel,
  );
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
  });

  Future<ApiResponse<IncidentDetails>> getIncidentById(String incidentId);

  Future<ApiResponse<TeamMembersData>> fetchTeamMembers(
    String projectId, {
    String? incidentId,
  });

  Future<ApiResponse> removeMemberTask(
    String incidentId,
    String roleId,
  );

  Future<ApiResponse> addTaskToMember({
    required String caseId,
    required String userId,
    required String type,
    required String role,
    required List<String> selectedLibraryTaskIds,
    List<ManualTaskEntry> manualTasks = const [],
  });

  Future<ApiResponse<IncidentDetails>> updateIncidentApproval(
    String incidentId,
    String type,
  );
  Future<ApiResponse<IncidentDetails>> incidentApproval(
    String incidentId,
    String type,
  );
  Future<ApiResponse<dynamic>> submitSetup(String incidentId, String type);
  Future<ApiResponse<IncidentDetails>> reportIncident(String incidentId);
  Future<ApiResponse> deleteIncident(String incidentId);
  Future<ApiResponse<String>> preSignedUrl(String key);
  Future<ApiResponse<IncidentDetails>> updateReportFields(
    Map<String, dynamic> payload,
  );
  Future<ApiResponse<IncidentDetails>> updateMembers(
    String incidentId,
    List<Map<String, dynamic>> members,
  );
  Future<ApiResponse<AuditLogResponse>> getAuditLogs(String incidentId);

  Future<ApiResponse<ReassignEligibleUsersResponse>> getEligibleUsers({
    required String clientId,
    required String type,
    required String role,
    required String caseId,
  });

  Future<ApiResponse<PreliminaryReportData>> getPreliminaryReport(
    String incidentId,
  );

  Future<ApiResponse<PreliminaryReportData>> updatePreliminaryReport(
    String incidentId,
    String tab,
    Map<String, dynamic> data,
  );

  Future<ApiResponse<String>> exportPreliminaryReportPdf(String incidentId);
}
