import 'dart:convert';

import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/project_view_management/project_responce.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_request.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

abstract class ProjectRemoteDataSource {
  Future<ApiResponse<ProjectResponse>> getProjects({
    required String clientId,
    ProjectFilterRequest? filters,
  });

  Future<ApiResponse<Project>> addProject(ProjectRequest request);

  Future<ApiResponse<UpdateProjectResponse>> updateProject(
    ProjectRequest request,
  );

  Future<ApiResponse<DeleteProjectResponse>> deleteProject(String projectId);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final ApiClient _apiClient;

  ProjectRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<ProjectResponse>> getProjects({
    required String clientId,
    ProjectFilterRequest? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{'clientId': clientId};

      // Add filters as JSON stringified and URL encoded query parameter
      // Fixed: Always send filters to match Web behavior
      final effectiveFilters =
          filters ?? ProjectFilterRequest(dateRange: DateRange());
      final filtersJson = effectiveFilters.toJson();
      queryParams['filters'] = Uri.encodeComponent(jsonEncode(filtersJson));

      return await _apiClient.request<ProjectResponse>(
        ApiEndpoints.getProjects,
        requiresProjectId: true,
        method: HttpMethod.get,
        queryParameters: queryParams,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            return ProjectResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<ProjectResponse>.error(
        'Failed to get projects: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<Project>> addProject(ProjectRequest request) async {
    try {
      return await _apiClient.request<Project>(
        requiresProjectId: true,
        ApiEndpoints.addProject,
        method: HttpMethod.post,
        requiresAuth: true,
        data: {
          'clientId': request.clientId ?? '',
          'projectName': request.projectName ?? '',
          'projectId': request.projectId ?? '',
          'location': request.location ?? '',
          'workSites': request.workSites ?? '',
          'description': request.description ?? '',
        },
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            return Project.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<Project>.error(
        'Failed to add project: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<UpdateProjectResponse>> updateProject(
    ProjectRequest request,
  ) async {
    try {
      return await _apiClient.request<UpdateProjectResponse>(
        ApiEndpoints.updateProject,
        method: HttpMethod.post,
        requiresProjectId: true,
        requiresAuth: true,
        data: {
          'clientId': request.clientId ?? '',
          'projectName': request.projectName ?? '',
          'projectId': request.projectId ?? '',
          'location': request.location ?? '',
          'workSites': request.workSites ?? '',
          'description': request.description ?? '',
        },
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            return UpdateProjectResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<UpdateProjectResponse>.error(
        'Failed to update project: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<DeleteProjectResponse>> deleteProject(
    String projectId,
  ) async {
    try {
      final endpoint = ApiEndpoints.deleteProject.replaceAll(
        '{projectId}',
        projectId,
      );

      return await _apiClient.request<DeleteProjectResponse>(
        endpoint,
        method: HttpMethod.delete,
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
            return DeleteProjectResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<DeleteProjectResponse>.error(
        'Failed to delete project: ${e.toString()}',
      );
    }
  }
}
