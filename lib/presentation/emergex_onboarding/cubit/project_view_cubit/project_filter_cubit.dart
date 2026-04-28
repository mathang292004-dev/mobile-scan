import 'package:emergex/di/app_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_filter_request.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';

class ProjectFilterState extends Equatable {
  final String? selectedStatus;
  final String? selectedWorkSite;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? location;
  final String? projectId;

  const ProjectFilterState({
    this.selectedStatus,
    this.selectedWorkSite,
    this.fromDate,
    this.toDate,
    this.location,
    this.projectId,
  });

  factory ProjectFilterState.initial() => const ProjectFilterState();

  ProjectFilterState copyWith({
    String? selectedStatus,
    String? selectedWorkSite,
    DateTime? fromDate,
    DateTime? toDate,
    String? location,
    String? projectId,
    bool clearStatus = false,
    bool clearWorkSite = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearLocation = false,
    bool clearProjectId = false,
  }) {
    return ProjectFilterState(
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedWorkSite: clearWorkSite
          ? null
          : (selectedWorkSite ?? this.selectedWorkSite),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      location: clearLocation ? null : (location ?? this.location),
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
    );
  }

  @override
  List<Object?> get props => [
    selectedStatus,
    selectedWorkSite,
    fromDate,
    toDate,
    location,
    projectId,
  ];
}

class ProjectFilterCubit extends Cubit<ProjectFilterState> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController projectIdController = TextEditingController();
  final ProjectFilterState _initialState;

  ProjectFilterCubit({ProjectFilterState? initialState})
    : _initialState = initialState ?? ProjectFilterState.initial(),
      super(initialState ?? ProjectFilterState.initial()) {
    if (initialState?.fromDate != null) {
      fromDateController.text = _formatDate(initialState!.fromDate!);
    }
    if (initialState?.toDate != null) {
      toDateController.text = _formatDate(initialState!.toDate!);
    }
    if (initialState?.projectId != null) {
      projectIdController.text = initialState!.projectId!;
    }
  }

  bool hasChanges() {
    return state.selectedStatus != _initialState.selectedStatus ||
        state.selectedWorkSite != _initialState.selectedWorkSite ||
        state.fromDate != _initialState.fromDate ||
        state.toDate != _initialState.toDate ||
        state.location != _initialState.location ||
        state.projectId != _initialState.projectId;
  }

  bool isInitialStateEmpty() {
    return _initialState.selectedStatus == null &&
        _initialState.selectedWorkSite == null &&
        _initialState.fromDate == null &&
        _initialState.toDate == null &&
        _initialState.location == null &&
        _initialState.projectId == null;
  }

  void setStatus(String? status) {
    emit(state.copyWith(selectedStatus: status));
  }

  void setWorkSite(String? workSite) {
    emit(state.copyWith(selectedWorkSite: workSite));
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

  void setProjectId(String? projectId) {
    projectIdController.text = projectId ?? '';
    emit(state.copyWith(projectId: projectId));
  }

  void reset([BuildContext? context]) {
    fromDateController.clear();
    toDateController.clear();
    projectIdController.clear();

    String? currentSearch;
    if (context != null) {
      currentSearch = _getSearchTextFromSearchBar(context);
    }
    
    final projectCubit = AppDI.projectCubit;
    if (currentSearch?.trim().isEmpty ?? true) {
      currentSearch = projectCubit.state.appliedFilters?.search;
    }
    
    final clientId = projectCubit.state.clientId ?? '';
    emit(ProjectFilterState.initial());

    if (clientId.isNotEmpty) {
      if (currentSearch?.trim().isNotEmpty ?? false) {
        projectCubit.getProjects(
          clientId: clientId,
          filters: ProjectFilterRequest(
            search: currentSearch!.trim(),
            projectId: '',
            projectName: '',
          ),
        );
      } else {
        projectCubit.getProjects(clientId: clientId, filters: null);
      }
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
    projectIdController.dispose();
    return super.close();
  }
}
