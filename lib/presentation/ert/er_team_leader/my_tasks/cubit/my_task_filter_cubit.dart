import 'package:emergex/di/app_di.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State for My Task Filter
class MyTaskFilterState extends Equatable {
  const MyTaskFilterState({
    this.selectedStatus,
    this.fromDate,
    this.toDate,
    this.showStatusList = false,
  });

  final String? selectedStatus;
  final String? fromDate;
  final String? toDate;
  final bool showStatusList;

  factory MyTaskFilterState.initial() => const MyTaskFilterState();

  MyTaskFilterState copyWith({
    String? selectedStatus,
    String? fromDate,
    String? toDate,
    bool clearStatus = false,
    bool clearDates = false,
    bool? showStatusList,
  }) {
    return MyTaskFilterState(
        selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
      showStatusList: showStatusList ?? this.showStatusList,
    );
  }

  @override
  List<Object?> get props => [
        selectedStatus,
        fromDate,
        toDate,
        showStatusList
      ];
}

/// Cubit for managing My Task Filter state
class MyTaskFilterCubit extends Cubit<MyTaskFilterState> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final MyTaskFilterState _initialState;
  MyTaskFilterCubit({MyTaskFilterState? initialState})
      : _initialState = initialState ?? MyTaskFilterState.initial(),
        super(initialState ?? MyTaskFilterState.initial()) {
    if (initialState?.fromDate != null) {
      fromDateController.text = initialState!.fromDate!;
    }
    if (initialState?.toDate != null) {
      toDateController.text = initialState!.toDate!;
    }
  }

  // Inside MyTaskFilterCubit
  void setStatus(String? status) {
    emit(
      status == null
          ? state.copyWith(clearStatus: true)
          : state.copyWith(selectedStatus: status),
    );
  }

  bool hasChanges() {
    final currentStatus = (state.selectedStatus ?? "").trim();
    final initialStatus = (_initialState.selectedStatus ?? "").trim();

    final currentFrom = state.fromDate ?? "";
    final initialFrom = _initialState.fromDate ?? "";

    final currentTo = state.toDate ?? "";
    final initialTo = _initialState.toDate ?? "";

    return currentStatus != initialStatus ||
        currentFrom != initialFrom ||
        currentTo != initialTo;
  }

  /// Check if initial state is empty (no filters applied)
  bool isInitialStateEmpty() {
    return _initialState.selectedStatus == null &&
        (_initialState.fromDate == null || _initialState.fromDate!.isEmpty) &&
        (_initialState.toDate == null || _initialState.toDate!.isEmpty);
  }
  void toggleStatusVisibility() {
    emit(state.copyWith(showStatusList: !state.showStatusList));
  }

  List<String>? getApiStatuses() {
    if (state.selectedStatus == null || state.selectedStatus!.isEmpty) {
      return null;
    }

    return state.selectedStatus!
        .split(',')
        .map((s) {
      switch (s.trim()) {
        case 'In Progress':
          return 'inprogress';
        case 'Completed':
          return 'completed';
        case 'Pause':
          return 'paused';
        case 'Draft':
          return 'draft';
        default:
          return s.toLowerCase().replaceAll(' ', '');
      }
    })
        .toList();
  }

  /// Update from date
  void setFromDate(String? date) {
    fromDateController.text = date ?? '';
    emit(state.copyWith(fromDate: date));
  }

  /// Update to date
  void setToDate(String? date) {
    toDateController.text = date ?? '';
    emit(state.copyWith(toDate: date));
  }

  /// Reset all filters
  void reset() {
    fromDateController.clear();
    toDateController.clear();
    emit(MyTaskFilterState.initial());
    
    // Clear applied filters in MyTaskCubit and reload tasks without filters
    AppDI.myTaskCubit.clearAppliedFilters();
    AppDI.myTaskCubit.loadMyTasks();
  }


  @override
  Future<void> close() {
    fromDateController.dispose();
    toDateController.dispose();
    return super.close();
  }
}
