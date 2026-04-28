import 'package:emergex/di/app_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_filter_request.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';

class FilterState extends Equatable {
  final String? selectedStatus;
  final Set<String> selectedIndustries;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? location;
  final String? search;
  final bool showIndustries;
  const FilterState({
    this.selectedStatus,
    this.selectedIndustries = const {},
    this.fromDate,
    this.toDate,
    this.location,
    this.search,
    this.showIndustries = false,
  });

  factory FilterState.initial() => const FilterState();

  FilterState copyWith({
    String? selectedStatus,
    Set<String>? selectedIndustries,
    DateTime? fromDate,
    DateTime? toDate,
    String? location,
    bool? showIndustries,
    bool clearStatus = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearLocation = false,
    String? search = "",
  }) {
    return FilterState(
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedIndustries: selectedIndustries ?? this.selectedIndustries,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      location: clearLocation ? null : (location ?? this.location),
      showIndustries: showIndustries ?? this.showIndustries,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [
    selectedStatus,
    selectedIndustries,
    fromDate,
    toDate,
    location,
    search,
    showIndustries,
  ];
}

class FilterCubit extends Cubit<FilterState> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final FilterState _initialState;

  FilterCubit({FilterState? initialState})
    : _initialState = initialState ?? FilterState.initial(),
      super(initialState ?? FilterState.initial()) {
    if (initialState?.fromDate != null) {
      fromDateController.text = _formatDate(initialState!.fromDate!);
    }
    if (initialState?.toDate != null) {
      toDateController.text = _formatDate(initialState!.toDate!);
    }
  }

  bool hasChanges() {
    return state.selectedStatus != _initialState.selectedStatus ||
        !_areSetsEqual(
          state.selectedIndustries,
          _initialState.selectedIndustries,
        ) ||
        state.fromDate != _initialState.fromDate ||
        state.toDate != _initialState.toDate ||
        state.location != _initialState.location;
  }

  bool isInitialStateEmpty() {
    return _initialState.selectedStatus == null &&
        _initialState.selectedIndustries.isEmpty &&
        _initialState.fromDate == null &&
        _initialState.toDate == null &&
        _initialState.location == null;
  }

  bool _areSetsEqual(Set<String> set1, Set<String> set2) {
    if (set1.length != set2.length) return false;
    for (var item in set1) {
      if (!set2.contains(item)) return false;
    }
    return true;
  }

  void setStatus(String? status) {
    emit(state.copyWith(selectedStatus: status));
  }

  void toggleIndustry(String industry, bool selected) {
    final updatedIndustries = Set<String>.from(state.selectedIndustries);
    if (selected) {
      updatedIndustries.add(industry);
    } else {
      updatedIndustries.remove(industry);
    }
    emit(state.copyWith(selectedIndustries: updatedIndustries));
  }

  void removeIndustry(String industry) {
    final updatedIndustries = Set<String>.from(state.selectedIndustries);
    updatedIndustries.remove(industry);
    emit(state.copyWith(selectedIndustries: updatedIndustries));
  }

  void toggleIndustriesList() {
    emit(state.copyWith(showIndustries: !state.showIndustries));
  }

  void setFromDate(DateTime date) {
    fromDateController.text = _formatDate(date);
    emit(state.copyWith(fromDate: date));
  }

  void setToDate(DateTime date) {
    toDateController.text = _formatDate(date);
    emit(state.copyWith(toDate: date));
  }

  void setLocation(String? location) {
    emit(state.copyWith(location: location));
  }

  void reset([BuildContext? context]) {
    fromDateController.clear();
    toDateController.clear();
    
    String? currentSearch;
    if (context != null) {
      currentSearch = _getSearchTextFromSearchBar(context);
    }
    
    if (currentSearch?.trim().isEmpty ?? true) {
      currentSearch = AppDI.clientCubit.state.appliedFilters?.search;
    }
    
    emit(FilterState.initial());

    if (currentSearch?.trim().isNotEmpty ?? false) {
      AppDI.clientCubit.getClients(
        filters: ClientFilterRequest(search: currentSearch!.trim()),
      );
    } else {
      AppDI.clientCubit.getClients(filters: null);
    }
  }

  String? _getSearchTextFromSearchBar(BuildContext context) {
    try {
      final searchBarState = context.findAncestorStateOfType<SearchBarWidgetState>();
      final searchText = searchBarState?.getSearchBarText();
      if (searchText?.isNotEmpty ?? false) {
        return searchText;
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Future<void> close() {
    fromDateController.dispose();
    toDateController.dispose();
    return super.close();
  }
}
