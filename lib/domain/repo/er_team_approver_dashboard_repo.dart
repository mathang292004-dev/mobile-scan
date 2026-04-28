import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/er_team_approver/export_pdf_response.dart';
import 'package:emergex/data/model/er_team_approver/incident_tasks_response.dart';
import 'package:emergex/data/model/er_team_approver/verify_task_response.dart';

/// Repository interface for ER Team Approver Dashboard
abstract class ErTeamApproverDashboardRepository {
  Future<ApiResponse<DashboardResponse>> getApproverDashboard(
    DashboardFilters filters,
  );

  Future<ApiResponse<IncidentTasksResponse>> getIncidentTasks(
    String incidentId,
    String status,
  );

  Future<ApiResponse<VerifyTaskResponse>> verifyTask(
    VerifyTaskRequest request,
  );

  Future<ApiResponse<ExportPdfResponse>> exportIncidentPdf(String incidentId);
}
