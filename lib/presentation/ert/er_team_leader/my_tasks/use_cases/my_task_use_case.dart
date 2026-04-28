import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart';
import 'package:emergex/data/model/er_team_leader/update_task_request.dart';
import 'package:emergex/data/model/er_team_leader/update_task_response.dart';
import 'package:emergex/domain/repo/my_task_repo.dart';

/// Use case for My Task
class MyTaskUseCase {
  final MyTaskRepository _repository;

  MyTaskUseCase(this._repository);

  Future<ApiResponse<MyTaskResponse>> getMyTasks({
    List<String>? statuses,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      return await _repository.getMyTasks(
        statuses: statuses,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      return ApiResponse<MyTaskResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<MyTaskResponse>> getTasksByIncidentId(
    String incidentId, {
    String role = 'tl',
  }) async {
    try {
      return await _repository.getTasksByIncidentId(incidentId, role: role);
    } catch (e) {
      return ApiResponse<MyTaskResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<UpdateTaskResponse>> updateTask({
    required String incidentId,
    required UpdateTaskRequest request,
  }) async {
    try {
      return await _repository.updateTask(
        incidentId: incidentId,
        request: request,
      );
    } catch (e) {
      return ApiResponse<UpdateTaskResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }
}

