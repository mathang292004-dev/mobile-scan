import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/project_view_management/project_responce.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_request.dart';

abstract class ProjectRepository {
  Future<ApiResponse<ProjectResponse>> getProjects({
    required String clientId,
    ProjectFilterRequest? filters,
  });

  Future<ApiResponse<Project>> addProject(ProjectRequest request);

  Future<ApiResponse<UpdateProjectResponse>> updateProject(ProjectRequest request);

  Future<ApiResponse<DeleteProjectResponse>> deleteProject(String projectId);
}

