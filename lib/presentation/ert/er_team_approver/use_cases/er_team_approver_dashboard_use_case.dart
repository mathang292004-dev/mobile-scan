import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/er_team_approver/export_pdf_response.dart';
import 'package:emergex/data/model/er_team_approver/incident_tasks_response.dart';
import 'package:emergex/data/model/er_team_approver/verify_task_response.dart';
import 'package:emergex/domain/repo/er_team_approver_dashboard_repo.dart';

/// Use case for ER Team Approver Dashboard
/// Encapsulates business logic for fetching dashboard data
class ErTeamApproverDashboardUseCase {
  final ErTeamApproverDashboardRepository _repository;

  ErTeamApproverDashboardUseCase(this._repository);

  /// Get approver dashboard with filters
  Future<ApiResponse<DashboardResponse>> getApproverDashboard(
    DashboardFilters filters,
  ) async {
    return await _repository.getApproverDashboard(filters);
  }

  /// Get incident tasks by incident ID and status
  Future<ApiResponse<IncidentTasksResponse>> getIncidentTasks(
    String incidentId,
    String status,
  ) async {
    try {
      return await _repository.getIncidentTasks(incidentId, status);
    } catch (e) {
      return ApiResponse<IncidentTasksResponse>.error(
        'Failed to get incident tasks: ${e.toString()}',
      );
    }
  }

  /// Verify or reject tasks
  Future<ApiResponse<VerifyTaskResponse>> verifyTask(
    VerifyTaskRequest request,
  ) async {
    try {
      return await _repository.verifyTask(request);
    } catch (e) {
      return ApiResponse<VerifyTaskResponse>.error(
        'Failed to verify task: ${e.toString()}',
      );
    }
  }

  /// Export incident as PDF
  Future<ApiResponse<ExportPdfResponse>> exportIncidentPdf(
    String incidentId,
  ) async {
    try {
      return await _repository.exportIncidentPdf(incidentId);
    } catch (e) {
      return ApiResponse<ExportPdfResponse>.error(
        'Failed to export PDF: ${e.toString()}',
      );
    }
  }
}
