import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/use_cases/my_task_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyTaskState extends Equatable {
  const MyTaskState({
    this.data,
    this.processState = ProcessState.none,
    this.showStatusList = false,
    this.isLoading = false,
    this.errorMessage,
    this.selectedStatus,
    this.selectedIncidentId,
    this.appliedStatuses,
    this.appliedFromDate,
    this.appliedToDate,
  });

  final MyTaskResponse? data;
  final ProcessState processState;
  final bool isLoading;
  final bool showStatusList;
  final String? errorMessage;
  final String? selectedStatus;
  final String? selectedIncidentId;
  final List<String>? appliedStatuses;
  final String? appliedFromDate;
  final String? appliedToDate;

  factory MyTaskState.initial() =>
      const MyTaskState(processState: ProcessState.none);

  MyTaskState copyWith({
    MyTaskResponse? data,
    ProcessState? processState,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? selectedIncidentId,
    List<String>? appliedStatuses,
    String? appliedFromDate,
    String? appliedToDate,
    String? selectedStatus,
    bool? showStatusList,
    bool clearAppliedFilters = false,
  }) {
    return MyTaskState(
      data: data ?? this.data,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedIncidentId: selectedIncidentId ?? this.selectedIncidentId,
      appliedStatuses: clearAppliedFilters
          ? null
          : (appliedStatuses ?? this.appliedStatuses),
      appliedFromDate: clearAppliedFilters
          ? null
          : (appliedFromDate ?? this.appliedFromDate),
      appliedToDate: clearAppliedFilters
          ? null
          : (appliedToDate ?? this.appliedToDate),
      selectedStatus: selectedStatus ?? this.selectedStatus,
      showStatusList: showStatusList ?? this.showStatusList,
    );
  }

  @override
  List<Object?> get props => [
    data,
    processState,
    isLoading,
    errorMessage,
    selectedIncidentId,
    appliedStatuses,
    appliedFromDate,
    appliedToDate,
    selectedStatus,
    showStatusList,
  ];
}

/// Cubit for managing My Task state
class MyTaskCubit extends Cubit<MyTaskState> {
  final MyTaskUseCase _useCase;
  final String role;

  MyTaskCubit(this._useCase, {this.role = 'tl'}) : super(MyTaskState.initial());

  /// Load my tasks
  Future<void> loadMyTasks({
    List<String>? statuses,
    String? fromDate,
    String? toDate,
  }) async {
    emit(
      state.copyWith(
        processState: ProcessState.loading,
        isLoading: true,
        errorMessage: null,
        clearError: true,
        selectedIncidentId: null, // Reset dropdown filter on load
      ),
    );

    try {
      final response = await _useCase.getMyTasks(
        statuses: statuses,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            data: response.data!,
            processState: ProcessState.done,
            isLoading: false,
            errorMessage: null,
            clearError: true,
            appliedStatuses: statuses,
            appliedFromDate: fromDate,
            appliedToDate: toDate,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage: response.error ?? 'Failed to load tasks',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to load tasks: $e',
          clearError: false,
        ),
      );
    }
  }

  /// Load tasks for a specific incident via GET /incident/my-tasks/{incidentId}
  Future<void> loadTasksByIncidentId(String incidentId) async {
    emit(
      state.copyWith(
        processState: ProcessState.loading,
        isLoading: true,
        clearError: true,
        selectedIncidentId: null,
      ),
    );

    try {
      final response = await _useCase.getTasksByIncidentId(incidentId, role: role);

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            data: response.data!,
            processState: ProcessState.done,
            isLoading: false,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage: response.error ?? 'Failed to load tasks',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to load tasks: $e',
        ),
      );
    }
  }

  /// Update selected incident ID filter
  void updateSelectedIncidentId(String? incidentId) {
    emit(state.copyWith(selectedIncidentId: incidentId));
  }

  // In my_task_filter_cubit.dart
  void toggleStatusVisibility() {
    emit(state.copyWith(showStatusList: !state.showStatusList));
  }

  void setStatus(String? status) {
    emit(state.copyWith(selectedStatus: status));
  }

  /// Get filtered tasks based on selected incident
  List<Task> getFilteredTasks() {
    if (state.data == null) return [];

    final allTasks = <Task>[];
    for (final group in state.data!.data) {
      if (state.selectedIncidentId == null ||
          state.selectedIncidentId == 'All Incidents' ||
          group.incidentId == state.selectedIncidentId) {
        allTasks.addAll(group.tasks);
      }
    }
    return allTasks;
  }

  /// Get list of incident IDs for dropdown
  List<String> getIncidentIds() {
    if (state.data == null) return [];
    return state.data!.data.map((group) => group.incidentId).toList();
  }

  /// Reset state
  void reset() {
    emit(MyTaskState.initial());
  }

  /// Clear applied filters
  void clearAppliedFilters() {
    emit(state.copyWith(clearAppliedFilters: true));
  }
}
