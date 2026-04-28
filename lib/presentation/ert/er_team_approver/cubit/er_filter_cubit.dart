import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ErApproverFilterState extends Equatable {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? department;
  final String? reportedBy;

  const ErApproverFilterState({
    this.fromDate,
    this.toDate,
    this.department,
    this.reportedBy,
  });

  factory ErApproverFilterState.initial() => const ErApproverFilterState();

  ErApproverFilterState copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? department,
    String? reportedBy,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearDepartment = false,
    bool clearReportedBy = false,
  }) {
    return ErApproverFilterState(
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      department: clearDepartment ? null : (department ?? this.department),
      reportedBy: clearReportedBy ? null : (reportedBy ?? this.reportedBy),
    );
  }

  @override
  List<Object?> get props => [
        fromDate,
        toDate,
        department,
        reportedBy,
      ];
}


class ErApproverFilterCubit extends Cubit<ErApproverFilterState> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController reportedCtrl = TextEditingController();

  late ErApproverFilterState _baselineState;

  ErApproverFilterCubit({ErApproverFilterState? initialState})
      : super(initialState ?? ErApproverFilterState.initial()) {
    _baselineState = initialState ?? ErApproverFilterState.initial();

    if (_baselineState.fromDate != null) {
      fromDateController.text = _formatDate(_baselineState.fromDate!);
    }
    if (_baselineState.toDate != null) {
      toDateController.text = _formatDate(_baselineState.toDate!);
    }
    if (_baselineState.reportedBy != null) {
      reportedCtrl.text = _baselineState.reportedBy!;
    }
  }
String formatApiDate(DateTime? date) {
  if (date == null) return '';
  return date.toIso8601String().split('T').first; // yyyy-MM-dd
}

  /// 🔹 Used for Apply button enable/disable
  bool hasChanges() {
    return state != _baselineState;
  }

  void markApplied() {
    _baselineState = state;
  }

  /// 🔹 Called on text change
  void markChanged() {
    final value = reportedCtrl.text.trim();

    emit(
      state.copyWith(
        reportedBy: value.isEmpty ? null : value,
        clearReportedBy: value.isEmpty,
      ),
    );
  }

  void setFromDate(DateTime date) {
    fromDateController.text = _formatDate(date);
    emit(state.copyWith(fromDate: date));
  }

  void setToDate(DateTime date) {
    toDateController.text = _formatDate(date);
    emit(state.copyWith(toDate: date));
  }

  /// 🔹 RESET LOGIC (FIXED)
 void reset(BuildContext context) {
  // ✅ Always clear UI
  fromDateController.clear();
  toDateController.clear();
  reportedCtrl.clear();

  // ✅ Reset state
  emit(ErApproverFilterState.initial());
  _baselineState = ErApproverFilterState.initial();

  final approverCubit = AppDI.erTeamApproverDashboardCubit;

  final currentSearch =
      _getSearchTextFromSearchBar(context) ??
      approverCubit.state.filters?.search;

  // ✅ Always trigger API on reset
  approverCubit.resetFilters();

  // (Optional) If search text exists, preserve it
  if (currentSearch?.trim().isNotEmpty ?? false) {
    approverCubit.loadDashboard(
      page: 0,
      limit: 10,
      search: currentSearch!.trim(),
    );
  }
}


  String? _getSearchTextFromSearchBar(BuildContext context) {
    try {
      final searchBarState =
          context.findAncestorStateOfType<SearchBarWidgetState>();
      return searchBarState?.getSearchBarText();
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  Future<void> close() {
    fromDateController.dispose();
    toDateController.dispose();
    reportedCtrl.dispose();
    return super.close();
  }
}
