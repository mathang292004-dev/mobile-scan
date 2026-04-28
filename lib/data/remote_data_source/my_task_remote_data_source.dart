import 'dart:convert';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart';
import 'package:emergex/data/model/er_team_leader/update_task_request.dart';
import 'package:emergex/data/model/er_team_leader/update_task_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

/// Remote data source interface for My Task
abstract class MyTaskRemoteDataSource {
  Future<ApiResponse<MyTaskResponse>> getMyTasks({
    List<String>? statuses,
    String? fromDate,
    String? toDate,
  });
  Future<ApiResponse<MyTaskResponse>> getTasksByIncidentId(
    String incidentId, {
    String role = 'tl',
  });
  Future<ApiResponse<UpdateTaskResponse>> updateTask({
    required String incidentId,
    required UpdateTaskRequest request,
  });
}

/// Remote data source implementation for My Task
class MyTaskRemoteDataSourceImpl implements MyTaskRemoteDataSource {
  final ApiClient _apiClient;

  MyTaskRemoteDataSourceImpl(this._apiClient);

  /// Format date string (YYYY-MM-DD) to ISO format for API

  @override
  Future<ApiResponse<MyTaskResponse>> getMyTasks({
    List<String>? statuses,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final Map<String, dynamic> filters = {};

      if (statuses != null && statuses.isNotEmpty) {
        filters['status'] = statuses;
      }

      if (fromDate != null &&
          fromDate.isNotEmpty &&
          toDate != null &&
          toDate.isNotEmpty) {
        filters['daterange'] = {
          'from': fromDate, // yyyy-MM-dd
          'to': toDate,
        };
      }
      // Build query parameters
      final queryParams = <String, dynamic>{
        'filters': Uri.encodeComponent(jsonEncode(filters)),
      };

      return await _apiClient.request<MyTaskResponse>(
        ApiEndpoints.myTask,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        queryParameters: queryParams,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic>) {
            // Handle wrapped response: { status: 'success', data: {...} }
            if (json['status'] == 'success' && json['data'] != null) {
              final data = json['data'] as Map<String, dynamic>;
              return MyTaskResponse.fromJson(data);
            }
            // Handle direct response: { tasks: [...], incidentIds: [...], totalTasks: n }
            else if (json['tasks'] != null || json['totalTasks'] != null) {
              return MyTaskResponse.fromJson(json);
            } else {
              throw Exception(
                'Invalid response format from server: missing tasks or totalTasks',
              );
            }
          } else {
            throw Exception(
              'Invalid response format from server: expected Map',
            );
          }
        },
      );
    } catch (e) {
      return ApiResponse<MyTaskResponse>.error(
        'Failed to get my tasks: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<MyTaskResponse>> getTasksByIncidentId(
    String incidentId, {
    String role = 'tl',
  }) async {
    try {
      return await _apiClient.request<MyTaskResponse>(
        '/incident/my-tasks/$incidentId',
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        queryParameters: <String, dynamic>{'type': 'ert', 'role': role},
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            final tasksList = data['tasks'] as List<dynamic>? ?? [];
            final tasks = tasksList
                .whereType<Map<String, dynamic>>()
                .map(Task.fromJson)
                .toList();
            return MyTaskResponse(
              data: [IncidentTaskGroup(incidentId: incidentId, tasks: tasks)],
              totalTasks: tasks.length,
            );
          }
          throw Exception('Invalid response format from server');
        },
      );
    } catch (e) {
      return ApiResponse<MyTaskResponse>.error(
        'Failed to get tasks: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<UpdateTaskResponse>> updateTask({
    required String incidentId,
    required UpdateTaskRequest request,
  }) async {
    try {
      final endpoint = '${ApiEndpoints.updateMyTask}/$incidentId';
      return await _apiClient.request<UpdateTaskResponse>(
        endpoint,
        method: HttpMethod.patch,
        requiresAuth: true,
        requiresProjectId: true,
        queryParameters: <String, dynamic>{'type': 'ert'},
        data: request.toJson(),
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          if (json is Map<String, dynamic>) {
            final data = json['data'];
            if (data is Map<String, dynamic>) {
              return UpdateTaskResponse.fromJson(data['data'] is Map<String, dynamic>
                  ? data['data'] as Map<String, dynamic>
                  : data);
            }
          }
          throw Exception('Invalid response format from server');
        },
      );
    } catch (e) {
      return ApiResponse<UpdateTaskResponse>.error(
        'Failed to update task: ${e.toString()}',
      );
    }
  }
}
