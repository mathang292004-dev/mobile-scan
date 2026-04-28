import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/project_view_management/project_responce.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_request.dart';
import 'package:emergex/data/remote_data_source/project_view_remote_data_source.dart';
import 'package:emergex/domain/repo/project_view_repo.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource _remoteDataSource;

  ProjectRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<ProjectResponse>> getProjects({
    required String clientId,
    ProjectFilterRequest? filters,
  }) async {
    try {
      return await _remoteDataSource.getProjects(
        clientId: clientId,
        filters: filters,
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
      return await _remoteDataSource.addProject(request);
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
      return await _remoteDataSource.updateProject(request);
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
      return await _remoteDataSource.deleteProject(projectId);
    } catch (e) {
      return ApiResponse<DeleteProjectResponse>.error(
        'Failed to delete project: ${e.toString()}',
      );
    }
  }
}

