import 'dart:convert';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/model/er_team_approver/export_pdf_response.dart';
import 'package:emergex/data/model/er_team_approver/incident_tasks_response.dart';
import 'package:emergex/data/model/er_team_approver/verify_task_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

/// Remote data source for ER Team Approver Dashboard
abstract class ErTeamApproverDashboardRemoteDataSource {
  Future<ApiResponse<DashboardResponse>> getApproverDashboard(
    DashboardFilters filters,
  );

  Future<ApiResponse<IncidentTasksResponse>> getIncidentTasks(
    String incidentId,
    String status,
  );

  Future<ApiResponse<VerifyTaskResponse>> verifyTask(VerifyTaskRequest request);

  Future<ApiResponse<ExportPdfResponse>> exportIncidentPdf(String incidentId);
}

/// Implementation of ER Team Approver Dashboard Remote Data Source
class ErTeamApproverDashboardRemoteDataSourceImpl
    implements ErTeamApproverDashboardRemoteDataSource {
  final ApiClient _apiClient;

  ErTeamApproverDashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<DashboardResponse>> getApproverDashboard(
    DashboardFilters filters,
  ) async {
    try {
      // Match backend contract:
      //   GET /api/incident/approver-dashboard?type=admin&filters={...}
      // Dio will URL-encode the filters JSON automatically — do NOT pre-encode.
      final queryParams = <String, dynamic>{
        'type': 'ert',
        'filters': jsonEncode(filters.toErApproverJson()),
      };

      return await _apiClient.request<DashboardResponse>(
        ApiEndpoints.approverDashboard,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        queryParameters: queryParams,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            return DashboardResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<DashboardResponse>.error(
        'Failed to get Approver dashboard: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<IncidentTasksResponse>> getIncidentTasks(
    String incidentId,
    String status,
  ) async {
    try {
      final endpoint = ApiEndpoints.incidentTasks.replaceAll(
        '{incidentId}',
        incidentId,
      );

      final queryParams = <String, dynamic>{'status': status};

      return await _apiClient.request<IncidentTasksResponse>(
        endpoint,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        queryParameters: queryParams,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;

            // Handle response structure: data has { incidentId: "...", tasks: [...] }
            // where tasks is an array of { userId: "...", tasks: [...] }
            final userTasks = <UserTask>[];
            
            if (data['tasks'] is List) {
              final tasksList = data['tasks'] as List;
              // Each item in tasksList is already a UserTask structure
              userTasks.addAll(
                tasksList
                    .whereType<Map<String, dynamic>>()
                    .map((e) => UserTask.fromJson(e))
                    .toList(),
              );
            }

            return IncidentTasksResponse(
              incidentId: data['incidentId'] as String? ?? incidentId,
              emergexCaseSummary: data['emergexCaseSummary'] != null
                  ? EmergexCaseSummary.fromJson(
                      data['emergexCaseSummary'] as Map<String, dynamic>,
                    )
                  : null,
              timer: data['timer'] != null
                  ? IncidentTimer.fromJson(
                      data['timer'] as Map<String, dynamic>,
                    )
                  : null,
              tasks: userTasks,
            );
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<IncidentTasksResponse>.error(
        'Failed to get incident tasks: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<VerifyTaskResponse>> verifyTask(
    VerifyTaskRequest request,
  ) async {
    try {
      return await _apiClient.request<VerifyTaskResponse>(
        ApiEndpoints.verifyTask,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: request.toJson(),
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final responseData = json['data'] as Map<String, dynamic>;
            return VerifyTaskResponse.fromJson(responseData);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<VerifyTaskResponse>.error(
        'Failed to verify task: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<ExportPdfResponse>> exportIncidentPdf(
    String incidentId,
  ) async {
    try {
      final endpoint = ApiEndpoints.exportIncidentPdf.replaceAll(
        '{incidentId}',
        incidentId,
      );

      return await _apiClient.request<ExportPdfResponse>(
        endpoint,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            return ExportPdfResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<ExportPdfResponse>.error(
        'Failed to export PDF: ${e.toString()}',
      );
    }
  }
}
