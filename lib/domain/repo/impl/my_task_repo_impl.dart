import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart';
import 'package:emergex/data/model/er_team_leader/update_task_request.dart';
import 'package:emergex/data/model/er_team_leader/update_task_response.dart';
import 'package:emergex/data/remote_data_source/my_task_remote_data_source.dart';
import 'package:emergex/domain/repo/my_task_repo.dart';

/// Repository implementation for My Task
class MyTaskRepositoryImpl implements MyTaskRepository {
  final MyTaskRemoteDataSource _remoteDataSource;

  MyTaskRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<MyTaskResponse>> getMyTasks({
    List<String>? statuses,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      return await _remoteDataSource.getMyTasks(
        statuses: statuses,
        fromDate: fromDate,
        toDate: toDate,
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
      return await _remoteDataSource.getTasksByIncidentId(incidentId, role: role);
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
      return await _remoteDataSource.updateTask(
        incidentId: incidentId,
        request: request,
      );
    } catch (e) {
      return ApiResponse<UpdateTaskResponse>.error(
        'Failed to update task: ${e.toString()}',
      );
    }
  }
}

