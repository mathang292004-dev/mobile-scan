import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart';
import 'package:emergex/data/model/er_team_leader/update_task_request.dart';
import 'package:emergex/data/model/er_team_leader/update_task_response.dart';

/// Repository interface for My Task
abstract class MyTaskRepository {
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

