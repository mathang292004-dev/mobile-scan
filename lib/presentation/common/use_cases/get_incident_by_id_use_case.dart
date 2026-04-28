import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/incident/audit_log_response.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/domain/repo/incident_repo.dart';

import 'package:emergex/presentation/case_report/approver/model/team_members_data_model.dart';
import 'package:emergex/presentation/case_report/approver/model/reassign_eligible_users_model.dart';
import 'package:emergex/data/model/incident/preliminary_report_model.dart';

class GetIncidentByIdUseCase {
  final IncidentRepository _incidentRepository;

  GetIncidentByIdUseCase(this._incidentRepository);

  Future<ApiResponse<IncidentDetails>> execute(String incidentId) async {
    try {
      final response = await _incidentRepository.getIncidentById(incidentId);
      if (response.success == true) {
        return response;
      } else {
        return ApiResponse.error('Failed to get incident: ${response.error}');
      }
    } catch (e) {
      return ApiResponse.error('Failed to get incident: ${e.toString()}');
    }
  }

  Future<ApiResponse<IncidentDetails>> updateIncidentApproval(
    String incidentId,
    String type,
  ) async {
    try {
      final response = await _incidentRepository.updateIncidentApproval(
        incidentId,
        type,
      );
      if (response.success == true) {
        return response;
      } else {
        return ApiResponse.error(
          'Failed to update incident: ${response.error}',
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<IncidentDetails>> incidentApproval(
    String incidentId,
    String type,
  ) async {
    try {
      final response = await _incidentRepository.incidentApproval(
        incidentId,
        type,
      );
      if (response.success == true) {
        return response;
      } else {
        return ApiResponse.error(
          'Failed to approve incident: ${response.error}',
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<dynamic>> submitSetup(
    String incidentId,
    String type,
  ) async {
    try {
      return await _incidentRepository.submitSetup(incidentId, type);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<IncidentDetails>> updateReportFields(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _incidentRepository.updateReportFields(
        payload,
      );
      if (response.success == true) {
        return response;
      } else {
        return ApiResponse.error(
          'Failed to updateReportFields: ${response.error}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to update Report Fields: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> addTaskToMember({
    required String caseId,
    required String userId,
    required String type,
    required String role,
    required List<String> selectedLibraryTaskIds,
    List<ManualTaskEntry> manualTasks = const [],
  }) async {
    try {
      final response = await _incidentRepository.addTaskToMember(
        caseId: caseId,
        userId: userId,
        type: type,
        role: role,
        selectedLibraryTaskIds: selectedLibraryTaskIds,
        manualTasks: manualTasks,
      );
      if (response.success == true) {
        return response;
      } else {
        return ApiResponse.error(
          'Failed to add task to member: ${response.error}',
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to add task to member: ${e.toString()}');
    }
  }

  Future<ApiResponse<TeamMembersData>> fetchTeamMembers(
    String projectId, {
    String? incidentId,
  }) async {
    try {
      final response = await _incidentRepository.fetchTeamMembers(
        projectId,
        incidentId: incidentId,
      );
      if (response.success == true) {
        return response;
      } else {
        return ApiResponse.error(
          'Failed to fetch team members: ${response.error}',
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch team members: ${e.toString()}');
    }
  }

  Future<ApiResponse> removeMemberTask(
    String incidentId,
    String roleId,
  ) async {
    try {
      final response = await _incidentRepository.removeMemberTask(
        incidentId,
        roleId,
      );
      if (response.success == true) {
        return response;
      } else {
        return ApiResponse.error(
          'Failed to remove member task: ${response.error}',
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to remove member task: ${e.toString()}');
    }
  }

  Future<ApiResponse<AuditLogResponse>> getAuditLogs(String caseId) async {
    try {
      final response = await _incidentRepository.getAuditLogs(caseId);
      if (response.success == true) {
        return response;
      }
      return ApiResponse.error(
        'Failed to fetch audit logs: ${response.error}',
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch audit logs: ${e.toString()}');
    }
  }

  Future<ApiResponse<IncidentDetails>> updateMembers(
    String incidentId,
    List<Map<String, dynamic>> members,
  ) async {
    try {
      final response = await _incidentRepository.updateMembers(
        incidentId,
        members,
      );
      if (response.success == true) {
        return response;
      } else {
        return ApiResponse.error(
          'Failed to update members: ${response.error}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to update members: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<PreliminaryReportData>> getPreliminaryReport(
    String incidentId,
  ) async {
    try {
      final response = await _incidentRepository.getPreliminaryReport(incidentId);
      if (response.success == true) return response;
      return ApiResponse.error(
        'Failed to get preliminary report: ${response.error}',
      );
    } catch (e) {
      return ApiResponse.error(
        'Failed to get preliminary report: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<PreliminaryReportData>> updatePreliminaryReport(
    String incidentId,
    String tab,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _incidentRepository.updatePreliminaryReport(
        incidentId,
        tab,
        data,
      );
      if (response.success == true) return response;
      return ApiResponse.error(
        'Failed to save preliminary report: ${response.error}',
      );
    } catch (e) {
      return ApiResponse.error(
        'Failed to save preliminary report: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<String>> exportPreliminaryReportPdf(
    String incidentId,
  ) async {
    try {
      final response =
          await _incidentRepository.exportPreliminaryReportPdf(incidentId);
      if (response.success == true) return response;
      return ApiResponse.error(
        'Failed to export PDF: ${response.error}',
      );
    } catch (e) {
      return ApiResponse.error('Failed to export PDF: ${e.toString()}');
    }
  }

  Future<ApiResponse<ReassignEligibleUsersResponse>> getEligibleUsers({
    required String clientId,
    required String type,
    required String role,
    required String caseId,
  }) async {
    try {
      return await _incidentRepository.getEligibleUsers(
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
}
