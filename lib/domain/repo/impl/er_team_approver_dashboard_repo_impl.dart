import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/er_team_approver/export_pdf_response.dart';
import 'package:emergex/data/model/er_team_approver/incident_tasks_response.dart';
import 'package:emergex/data/model/er_team_approver/verify_task_response.dart';
import 'package:emergex/data/remote_data_source/er_team_approver_dashboard_remote_data_source.dart';
import 'package:emergex/domain/repo/er_team_approver_dashboard_repo.dart';

/// Repository implementation for ER Team Approver Dashboard
class ErTeamApproverDashboardRepositoryImpl
    implements ErTeamApproverDashboardRepository {
  final ErTeamApproverDashboardRemoteDataSource _remoteDataSource;

  ErTeamApproverDashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<DashboardResponse>> getApproverDashboard(
    DashboardFilters filters,
  ) async {
    return await _remoteDataSource.getApproverDashboard(filters);
  }

  @override
  Future<ApiResponse<IncidentTasksResponse>> getIncidentTasks(
    String incidentId,
    String status,
  ) async {
    return await _remoteDataSource.getIncidentTasks(incidentId, status);
  }

  @override
  Future<ApiResponse<VerifyTaskResponse>> verifyTask(
    VerifyTaskRequest request,
  ) async {
    return await _remoteDataSource.verifyTask(request);
  }

  @override
  Future<ApiResponse<ExportPdfResponse>> exportIncidentPdf(
    String incidentId,
  ) async {
    return await _remoteDataSource.exportIncidentPdf(incidentId);
  }
}
