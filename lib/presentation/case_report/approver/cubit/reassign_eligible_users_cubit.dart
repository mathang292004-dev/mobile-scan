import 'package:emergex/presentation/case_report/approver/model/reassign_eligible_users_model.dart';
import 'package:emergex/presentation/common/use_cases/get_incident_by_id_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ───────────────────────────────────────────────────────────────────

abstract class ReassignEligibleUsersState extends Equatable {
  const ReassignEligibleUsersState();

  @override
  List<Object?> get props => [];
}

class ReassignEligibleUsersInitial extends ReassignEligibleUsersState {
  const ReassignEligibleUsersInitial();
}

class ReassignEligibleUsersLoading extends ReassignEligibleUsersState {
  const ReassignEligibleUsersLoading();
}

class ReassignEligibleUsersLoaded extends ReassignEligibleUsersState {
  final List<EligibleUserModel> users;
  final List<EligibleTaskModel> tasks;
  final List<TaskCategoryModel> categoryTasks;
  final Set<String> assignedTaskLibraryIds;
  final EligibleUserModel? selectedUser;
  final Set<String> selectedTaskIds;
  final List<ManualTaskEntry> manualTasks;

  const ReassignEligibleUsersLoaded({
    required this.users,
    required this.tasks,
    required this.categoryTasks,
    this.assignedTaskLibraryIds = const {},
    this.selectedUser,
    this.selectedTaskIds = const {},
    this.manualTasks = const [],
  });

  ReassignEligibleUsersLoaded copyWith({
    List<EligibleUserModel>? users,
    List<EligibleTaskModel>? tasks,
    List<TaskCategoryModel>? categoryTasks,
    Set<String>? assignedTaskLibraryIds,
    EligibleUserModel? selectedUser,
    bool clearSelectedUser = false,
    Set<String>? selectedTaskIds,
    List<ManualTaskEntry>? manualTasks,
  }) {
    return ReassignEligibleUsersLoaded(
      users: users ?? this.users,
      tasks: tasks ?? this.tasks,
      categoryTasks: categoryTasks ?? this.categoryTasks,
      assignedTaskLibraryIds:
          assignedTaskLibraryIds ?? this.assignedTaskLibraryIds,
      selectedUser:
          clearSelectedUser ? null : (selectedUser ?? this.selectedUser),
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      manualTasks: manualTasks ?? this.manualTasks,
    );
  }

  @override
  List<Object?> get props => [
    users,
    tasks,
    categoryTasks,
    assignedTaskLibraryIds,
    selectedUser,
    selectedTaskIds,
    manualTasks,
  ];
}

class ReassignEligibleUsersError extends ReassignEligibleUsersState {
  final String message;

  const ReassignEligibleUsersError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Cubit ───────────────────────────────────────────────────────────────────

class ReassignEligibleUsersCubit extends Cubit<ReassignEligibleUsersState> {
  final GetIncidentByIdUseCase _useCase;

  ReassignEligibleUsersCubit(this._useCase)
    : super(const ReassignEligibleUsersInitial());

  Future<void> fetchEligibleUsers({
    required String clientId,
    required String type,
    required String role,
    required String caseId,
  }) async {
    emit(const ReassignEligibleUsersLoading());

    final response = await _useCase.getEligibleUsers(
      clientId: clientId,
      type: type,
      role: role,
      caseId: caseId,
    );

    if (response.success == true && response.data != null) {
      final data = response.data!;
      final assignedIds =
          data.assignedTasks
              .map((t) => t.libraryTaskId)
              .where((id) => id.isNotEmpty)
              .toSet();

      emit(
        ReassignEligibleUsersLoaded(
          users: data.users,
          tasks: data.tasks,
          categoryTasks: data.categoryTasks,
          assignedTaskLibraryIds: assignedIds,
        ),
      );
    } else {
      emit(
        ReassignEligibleUsersError(
          response.error ?? 'Failed to load eligible users',
        ),
      );
    }
  }

  /// Selects [user] and pre-populates task selection from previously assigned tasks.
  void selectUser(EligibleUserModel user) {
    final current = state;
    if (current is! ReassignEligibleUsersLoaded) return;

    emit(
      current.copyWith(
        selectedUser: user,
        selectedTaskIds: Set<String>.from(current.assignedTaskLibraryIds),
        manualTasks: [],
      ),
    );
  }

  /// Adds a manually-entered task to the separate manualTasks list.
  void addManualTask(String title, String details) {
    final current = state;
    if (current is! ReassignEligibleUsersLoaded) return;

    final entry = ManualTaskEntry(taskTitle: title, taskDetails: details);
    emit(current.copyWith(manualTasks: [...current.manualTasks, entry]));
  }

  /// Toggles [taskId] (libraryTaskId) in/out of the selection set.
  void toggleTask(String taskId) {
    final current = state;
    if (current is! ReassignEligibleUsersLoaded) return;

    final updated = Set<String>.from(current.selectedTaskIds);
    if (updated.contains(taskId)) {
      updated.remove(taskId);
    } else {
      updated.add(taskId);
    }

    emit(current.copyWith(selectedTaskIds: updated));
  }

  /// Submits the add-task-to-member API call.
  Future<bool> submitReassign({
    required String incidentId,
    required String type,
    required String role,
  }) async {
    final current = state;
    if (current is! ReassignEligibleUsersLoaded) return false;
    final selectedUser = current.selectedUser;
    if (selectedUser == null) return false;

    final result = await _useCase.addTaskToMember(
      caseId: incidentId,
      userId: selectedUser.userId,
      type: type,
      role: role,
      selectedLibraryTaskIds: current.selectedTaskIds.toList(),
      manualTasks: current.manualTasks,
    );

    return result.success == true;
  }
}
