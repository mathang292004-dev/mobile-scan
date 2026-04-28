import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';

/// State for ER Leader Filter
class ErLeaderFilterState extends Equatable {
  const ErLeaderFilterState({
    this.project,
    this.title,
    this.selectedStatus,
    this.selectedSeverities = const {},
    this.selectedPriority,
    this.showSeverityList = false,
  });

  final String? project;
  final String? title;
  final String? selectedStatus;
  final Set<String> selectedSeverities;
  final String? selectedPriority;
  final bool showSeverityList;

  factory ErLeaderFilterState.initial() => const ErLeaderFilterState();

  /// Create state from dashboard filters
  factory ErLeaderFilterState.fromDashboardFilters(DashboardFilters? filters) {
    if (filters == null) {
      return ErLeaderFilterState.initial();
    }

    return ErLeaderFilterState(
      project: filters.project?.isNotEmpty == true ? filters.project : null,
      title: filters.title?.isNotEmpty == true ? filters.title : null,
      selectedStatus: filters.status?.isNotEmpty == true
          ? filters.status
          : null,
      selectedSeverities: filters.severityLevels?.isNotEmpty == true
          ? filters.severityLevels!.toSet()
          : const {},
      selectedPriority: filters.priority?.isNotEmpty == true
          ? filters.priority
          : null,
    );
  }

  ErLeaderFilterState copyWith({
    String? project,
    String? title,
    String? selectedStatus,
    Set<String>? selectedSeverities,
    String? selectedPriority,
    bool? showSeverityList,
    bool clearProject = false,
    bool clearTitle = false,
    bool clearStatus = false,
    bool clearSeverities = false,
    bool clearPriority = false,
  }) {
    return ErLeaderFilterState(
      project: clearProject ? null : (project ?? this.project),
      title: clearTitle ? null : (title ?? this.title),
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedSeverities: clearSeverities
          ? const {}
          : (selectedSeverities ?? this.selectedSeverities),
      selectedPriority: clearPriority
          ? null
          : (selectedPriority ?? this.selectedPriority),
      showSeverityList: showSeverityList ?? this.showSeverityList,
    );
  }

  /// Check if any filter is applied
  bool get hasActiveFilters {
    return (project != null && project!.trim().isNotEmpty) ||
        (title != null && title!.trim().isNotEmpty) ||
        selectedStatus != null ||
        selectedSeverities.isNotEmpty ||
        selectedPriority != null;
  }

  @override
  List<Object?> get props => [
    project,
    title,
    selectedStatus,
    selectedSeverities,
    selectedPriority,
    showSeverityList,
  ];
}

/// Cubit for managing ER Leader Filter state
class ErLeaderFilterCubit extends Cubit<ErLeaderFilterState> {
  final TextEditingController projectController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  final ErLeaderFilterState _initialState;

  ErLeaderFilterCubit({ErLeaderFilterState? initialState})
    : _initialState = initialState ?? ErLeaderFilterState.initial(),
      super(initialState ?? ErLeaderFilterState.initial()) {
    if (initialState?.project != null) {
      projectController.text = initialState!.project!;
    }
    if (initialState?.title != null) {
      titleController.text = initialState!.title!;
    }
  }

  /// Check if filters have changed from initial state
  bool hasChanges() {
    return state.project != _initialState.project ||
        state.title != _initialState.title ||
        state.selectedStatus != _initialState.selectedStatus ||
        !_setEquals(
          state.selectedSeverities,
          _initialState.selectedSeverities,
        ) ||
        state.selectedPriority != _initialState.selectedPriority;
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }

  /// Check if current state is empty (no filters applied)
  bool isCurrentStateEmpty() {
    return (state.project == null || state.project!.trim().isEmpty) &&
        (state.title == null || state.title!.trim().isEmpty) &&
        state.selectedStatus == null &&
        state.selectedSeverities.isEmpty &&
        state.selectedPriority == null;
  }

  /// Check if initial state is empty
  bool isInitialStateEmpty() {
    return (_initialState.project == null ||
            _initialState.project!.trim().isEmpty) &&
        (_initialState.title == null || _initialState.title!.trim().isEmpty) &&
        _initialState.selectedStatus == null &&
        _initialState.selectedSeverities.isEmpty &&
        _initialState.selectedPriority == null;
  }

  /// Determines if Apply button should be enabled.
  /// Returns true when:
  /// 1. Filters have changed from initial state (hasChanges), OR
  /// 2. Current state is empty but initial state had filters (user cleared filters)
  ///
  /// This ensures Apply button works correctly when clearing filters.
  bool shouldAllowApply() {
    // If there are any changes from initial state, allow apply
    if (hasChanges()) return true;

    // Edge case: If current state equals initial state,
    // but initial state was already empty, no need to apply
    // (nothing to change)
    return false;
  }

  /// Update project filter
  void setProject(String? project) {
    projectController.text = project ?? '';
    emit(state.copyWith(project: project));
  }

  /// Update title filter
  void setTitle(String? title) {
    titleController.text = title ?? '';
    emit(state.copyWith(title: title));
  }

  /// Update status filter
  void setStatus(String? status) {
    emit(state.copyWith(selectedStatus: status));
  }

  /// Toggle severity selection
  void toggleSeverity(String severity) {
    final newSeverities = Set<String>.from(state.selectedSeverities);
    if (newSeverities.contains(severity)) {
      newSeverities.remove(severity);
    } else {
      newSeverities.add(severity);
    }
    emit(state.copyWith(selectedSeverities: newSeverities));
  }

  /// Remove severity from selection
  void removeSeverity(String severity) {
    final newSeverities = Set<String>.from(state.selectedSeverities);
    newSeverities.remove(severity);
    emit(state.copyWith(selectedSeverities: newSeverities));
  }

  /// Update priority filter
  void setPriority(String? priority) {
    emit(state.copyWith(selectedPriority: priority));
  }

  /// Toggle severity list visibility
  void toggleSeverityList() {
    emit(state.copyWith(showSeverityList: !state.showSeverityList));
  }

  /// Reset all filters to empty state
  void reset() {
    projectController.clear();
    titleController.clear();
    emit(ErLeaderFilterState.initial());
  }

  @override
  Future<void> close() {
    projectController.dispose();
    titleController.dispose();
    return super.close();
  }
}
