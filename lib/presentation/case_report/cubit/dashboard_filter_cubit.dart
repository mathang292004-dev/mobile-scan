import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardFilterState extends Equatable {
  final String? selectedStatus;
  final DateTime? fromDate;
  final DateTime? toDate;

  const DashboardFilterState({
    this.selectedStatus,
    this.fromDate,
    this.toDate,
  });

  factory DashboardFilterState.initial() => const DashboardFilterState();

  DashboardFilterState copyWith({
    String? selectedStatus,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearStatus = false,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) {
    return DashboardFilterState(
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
    );
  }

  @override
  List<Object?> get props => [selectedStatus, fromDate, toDate];
}

class DashboardFilterCubit extends Cubit<DashboardFilterState> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  late DashboardFilterState _baseline;

  DashboardFilterCubit({DashboardFilterState? initialState})
      : super(initialState ?? DashboardFilterState.initial()) {
    _baseline = initialState ?? DashboardFilterState.initial();

    if (_baseline.fromDate != null) {
      fromDateController.text = _formatDate(_baseline.fromDate!);
    }
    if (_baseline.toDate != null) {
      toDateController.text = _formatDate(_baseline.toDate!);
    }
  }

  void setStatus(String? status) {
    emit(state.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
    ));
  }

  void setFromDate(DateTime date) {
    fromDateController.text = _formatDate(date);
    emit(state.copyWith(fromDate: date));
  }

  void setToDate(DateTime date) {
    toDateController.text = _formatDate(date);
    emit(state.copyWith(toDate: date));
  }

  bool hasChanges() => state != _baseline;

  void markApplied() => _baseline = state;

  void reset() {
    fromDateController.clear();
    toDateController.clear();
    emit(DashboardFilterState.initial());
    _baseline = DashboardFilterState.initial();
  }

  Map<String, String>? get dateRangeMap {
    final from = state.fromDate;
    final to = state.toDate;
    if (from == null && to == null) return null;
    return {
      'from': from != null ? _formatForApi(from) : '',
      'to': to != null ? _formatEndOfDayForApi(to) : '',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}T00:00:00.000Z';
  }

  String _formatEndOfDayForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}T23:59:59.999Z';
  }

  @override
  Future<void> close() {
    fromDateController.dispose();
    toDateController.dispose();
    return super.close();
  }
}
