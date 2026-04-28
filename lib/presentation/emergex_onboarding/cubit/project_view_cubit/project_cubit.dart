import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/project_view_management/project_responce.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_request.dart';
import 'package:emergex/presentation/emergex_onboarding/use_cases/project_view_use_case/project_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:emergex/helpers/auth_guard.dart';

class ProjectState extends Equatable {
  final List<Project> projects;
  final ProcessState processState;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final ProjectResponse? response;
  final List<String> workSites;
  final List<String> locations;
  final ProjectFilterRequest? appliedFilters;
  final String? clientId;
  final String? clientName;
  final String? clientImage;

  const ProjectState({
    this.projects = const [],
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.response,
    this.workSites = const [],
    this.locations = const [],
    this.appliedFilters,
    this.clientId,
    this.clientName,
    this.clientImage,
  });

  factory ProjectState.initial() =>
      const ProjectState(processState: ProcessState.none);

  ProjectState copyWith({
    List<Project>? projects,
    ProcessState? processState,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    ProjectResponse? response,
    List<String>? workSites,
    List<String>? locations,
    ProjectFilterRequest? appliedFilters,
    String? clientId,
    String? clientName,
    String? clientImage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAppliedFilters = false,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      response: response ?? this.response,
      workSites: workSites ?? this.workSites,
      locations: locations ?? this.locations,
      appliedFilters: clearAppliedFilters
          ? null
          : (appliedFilters ?? this.appliedFilters),
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientImage: clientImage ?? this.clientImage,
    );
  }

  @override
  List<Object?> get props => [
    projects,
    processState,
    isLoading,
    errorMessage,
    successMessage,
    response,
    workSites,
    locations,
    appliedFilters,
    clientId,
    clientName,
    clientImage,
  ];
}

class ProjectCubit extends Cubit<ProjectState> {
  final ProjectUseCase _projectUseCase;

  ProjectCubit(this._projectUseCase) : super(ProjectState.initial());

  /// Clear cache and reset to initial state
  void clearCache() {
    emit(ProjectState.initial());
  }

  /// Fetch projects with optional filters
  Future<void> getProjects({
    required String clientId,
    ProjectFilterRequest? filters,
  }) async {
    if (!await AuthGuard.canProceed()) return;

    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          projects: [], // ✅ CLEAR OLD DATA
          workSites: [],
          locations: [],
          response: null,
          clientId: clientId,
          errorMessage: null,
          successMessage: null,
          clearError: true,
          clearSuccess: true,
        ),
      );

      final response = await _projectUseCase.getProjects(
        clientId: clientId,
        filters: filters,
      );

      if (response.success == true && response.data != null) {
        final projectResponse = response.data!;

        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            response: projectResponse,
            projects: projectResponse.projects ?? [],
            workSites: projectResponse.workSites ?? [],
            locations: projectResponse.locations ?? [],
            clientName: projectResponse.clientName,
            clientImage: projectResponse.clientImage,
            appliedFilters: filters,
            clearAppliedFilters: filters == null,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.done, // 👈 important
            isLoading: false,
            projects: [], // ✅ CLEAR
            workSites: [],
            locations: [],
            response: null,
            errorMessage:
                response.error ?? response.message ?? 'No projects found',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.done,
          isLoading: false,
          projects: [], // ✅ CLEAR
          workSites: [],
          locations: [],
          response: null,
          errorMessage: 'Failed to fetch projects',
        ),
      );
    }
  }

  /// Refresh projects with current filters
  Future<void> refreshProjects() async {
    if (state.clientId != null) {
      await getProjects(
        clientId: state.clientId!,
        filters: state.appliedFilters,
      );
    }
  }

  /// Clear error and success messages
  void clearError() {
    emit(state.copyWith(
      errorMessage: null,
      successMessage: null,
      clearError: true,
      clearSuccess: true,
    ));
  }

  /// Add new project
  Future<void> addProject(ProjectRequest request) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
          clearSuccess: true,
        ),
      );

      final response = await _projectUseCase.addProject(request);

      if (response.success == true && response.data != null) {
        // Emit success message before refreshing
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            successMessage: 'Project created successfully',
          ),
        );
        // Refresh projects list after successful add
        await refreshProjects();
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ?? response.message ?? 'Failed to add project',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to add project: ${e.toString()}',
        ),
      );
    }
  }

  /// Update existing project
  Future<void> updateProject(ProjectRequest request) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
          clearSuccess: true,
        ),
      );

      final response = await _projectUseCase.updateProject(request);

      if (response.success == true && response.data != null) {
        // Emit success message before refreshing
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            successMessage: 'Project updated successfully',
          ),
        );
        // Refresh projects list after successful update
        await refreshProjects();
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ??
                response.message ??
                'Failed to update project',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to update project: ${e.toString()}',
        ),
      );
    }
  }

  /// Delete project
  Future<void> deleteProject(String projectId) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
          clearSuccess: true,
        ),
      );

      final response = await _projectUseCase.deleteProject(projectId);

      if (response.success == true) {
        // Emit success message before refreshing
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            successMessage: 'Project deleted successfully',
          ),
        );
        // Refresh projects list after successful delete
        await refreshProjects();
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ??
                response.message ??
                'Failed to delete project',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to delete project: ${e.toString()}',
        ),
      );
    }
  }
}
