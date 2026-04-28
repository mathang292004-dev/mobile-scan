import 'package:emergex/presentation/case_report/approver/model/team_members_data_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddTeamMemberState {
  final UserDetail? selectedMember;
  final bool isDropdownOpen;
  final List<bool> selectedTasks;
  final List<String> manualTasks;
  final List<bool> selectedManualTasks;
  final String? selectedTaskCategory;
  final bool showAddTaskSections;

  const AddTeamMemberState({
    this.selectedMember,
    this.isDropdownOpen = false,
    this.selectedTasks = const [],
    this.manualTasks = const [],
    this.selectedManualTasks = const [],
    this.selectedTaskCategory,
    this.showAddTaskSections = false,
  });

  AddTeamMemberState copyWith({
    UserDetail? selectedMember,
    bool? isDropdownOpen,
    List<bool>? selectedTasks,
    List<String>? manualTasks,
    List<bool>? selectedManualTasks,
    String? selectedTaskCategory,
    bool? showAddTaskSections,
    bool clearMember = false,
  }) {
    return AddTeamMemberState(
      selectedMember: clearMember ? null : (selectedMember ?? this.selectedMember),
      isDropdownOpen: isDropdownOpen ?? this.isDropdownOpen,
      selectedTasks: selectedTasks ?? this.selectedTasks,
      manualTasks: manualTasks ?? this.manualTasks,
      selectedManualTasks: selectedManualTasks ?? this.selectedManualTasks,
      selectedTaskCategory: selectedTaskCategory ?? this.selectedTaskCategory,
      showAddTaskSections: showAddTaskSections ?? this.showAddTaskSections,
    );
  }
}

class AddTeamMemberCubit extends Cubit<AddTeamMemberState> {
  AddTeamMemberCubit() : super(const AddTeamMemberState());

  void selectMember(UserDetail member) {
    emit(state.copyWith(
      selectedMember: member,
      isDropdownOpen: false,
    ));
  }

  void toggleDropdown() {
    emit(state.copyWith(isDropdownOpen: !state.isDropdownOpen));
  }

  void toggleTask(
    int index, {
    Map<String, int>? taskAssignmentCounts,
    List<String>? currentMemberTaskIds,
    String? taskId,
  }) {
    if (index >= state.selectedTasks.length) return;

    final assignmentCount = taskAssignmentCounts?[taskId] ?? 0;
    final isCurrentMemberTask = currentMemberTaskIds?.contains(taskId) ?? false;

    // Prevent if at max capacity and not current member's task
    if (!state.selectedTasks[index] && assignmentCount >= 2 && !isCurrentMemberTask) {
      return;
    }

    final updated = List<bool>.from(state.selectedTasks);
    updated[index] = !updated[index];
    emit(state.copyWith(selectedTasks: updated));
  }

  void toggleManualTask(int index) {
    if (index >= state.selectedManualTasks.length) return;
    final updated = List<bool>.from(state.selectedManualTasks);
    updated[index] = !updated[index];
    emit(state.copyWith(selectedManualTasks: updated));
  }

  void addManualTask(String name) {
    if (name.trim().isEmpty) return;
    final tasks = List<String>.from(state.manualTasks)..add(name.trim());
    final selected = List<bool>.from(state.selectedManualTasks)..add(false);
    emit(state.copyWith(manualTasks: tasks, selectedManualTasks: selected));
  }

  void setTaskCategory(String? category) {
    emit(state.copyWith(selectedTaskCategory: category));
  }

  void toggleAddTaskSections() {
    emit(state.copyWith(showAddTaskSections: !state.showAddTaskSections));
  }

  void initializeFromExisting(List<String>? currentMemberTaskIds, int taskCount) {
    final tasks = List<bool>.generate(taskCount, (_) => false);

    if (currentMemberTaskIds != null) {
      // Pre-select will be handled when task data is available
    }

    emit(state.copyWith(selectedTasks: tasks));
  }

  void initializeTaskSelection(List<Task> tasks, List<String>? currentMemberTaskIds) {
    final selected = List<bool>.generate(tasks.length, (i) {
      if (currentMemberTaskIds == null) return false;
      return currentMemberTaskIds.contains(tasks[i].taskId);
    });
    emit(state.copyWith(selectedTasks: selected));
  }

  bool get hasSelectedTasks {
    final hasOriginal = state.selectedTasks.any((s) => s);
    final hasManual = state.selectedManualTasks.any((s) => s);
    return hasOriginal || hasManual;
  }

  List<String> getSelectedTaskIds(List<Task> tasks) {
    final ids = <String>[];
    for (int i = 0; i < tasks.length; i++) {
      if (i < state.selectedTasks.length && state.selectedTasks[i]) {
        ids.add(tasks[i].taskId);
      }
    }
    return ids;
  }

  void reset() {
    emit(const AddTeamMemberState());
  }
}
