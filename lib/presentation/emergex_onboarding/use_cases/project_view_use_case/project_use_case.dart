import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/project_view_management/project_responce.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_request.dart';
import 'package:emergex/domain/repo/project_view_repo.dart';

class ProjectUseCase {
  final ProjectRepository _projectRepository;

  ProjectUseCase(this._projectRepository);

  Future<ApiResponse<ProjectResponse>> getProjects({
    required String clientId,
    ProjectFilterRequest? filters,
  }) async {
    try {
      return await _projectRepository.getProjects(
        clientId: clientId,
        filters: filters,
      );
    } catch (e) {
      return ApiResponse<ProjectResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<Project>> addProject(ProjectRequest request) async {
    try {
      return await _projectRepository.addProject(request);
    } catch (e) {
      return ApiResponse<Project>.error('Use case error: ${e.toString()}');
    }
  }

  Future<ApiResponse<UpdateProjectResponse>> updateProject(
    ProjectRequest request,
  ) async {
    try {
      return await _projectRepository.updateProject(request);
    } catch (e) {
      return ApiResponse<UpdateProjectResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<DeleteProjectResponse>> deleteProject(
    String projectId,
  ) async {
    try {
      return await _projectRepository.deleteProject(projectId);
    } catch (e) {
      return ApiResponse<DeleteProjectResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }
}

