import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ──────────────────────────────────────────────────────────────────

class ApprovalViewManagerState {
  final String selectedView;
  final Set<String> initializedViews;
  final bool isInitializing;

  const ApprovalViewManagerState({
    this.selectedView = 'approval',
    this.initializedViews = const {},
    this.isInitializing = false,
  });

  ApprovalViewManagerState copyWith({
    String? selectedView,
    Set<String>? initializedViews,
    bool? isInitializing,
  }) {
    return ApprovalViewManagerState(
      selectedView: selectedView ?? this.selectedView,
      initializedViews: initializedViews ?? this.initializedViews,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

// ── Cubit ──────────────────────────────────────────────────────────────────

class ApprovalViewManagerCubit extends Cubit<ApprovalViewManagerState> {
  ApprovalViewManagerCubit() : super(const ApprovalViewManagerState());

  /// Initialize the selected view from the dropdown value passed in navigation.
  void initializeFromDropdownValue(String? initialDropdownValue) {
    if (initialDropdownValue == null) return;

    final normalized = initialDropdownValue.trim().toLowerCase();
    String view;
    if (normalized == TextHelper.intervention.trim().toLowerCase()) {
      view = 'intervention';
    } else if (normalized == TextHelper.observation.trim().toLowerCase()) {
      view = 'observation';
    } else {
      view = 'approval';
    }
    emit(state.copyWith(selectedView: view));
  }

  /// Switches to [targetView], initializing it first if needed.
  ///
  /// Returns `true` if the view switch succeeded.
  Future<bool> switchView(
    String targetView, {
    required String? incidentId,
    required IncidentDetailsState currentState,
    bool isEditRequired = true,
  }) async {
    if (!isEditRequired) {
      emit(state.copyWith(selectedView: targetView));
      return true;
    }

    final canShow = await _initializeViewIfNeeded(
      targetView,
      incidentId: incidentId,
      currentState: currentState,
    );

    if (canShow) {
      emit(state.copyWith(selectedView: targetView));
    }
    return canShow;
  }

  /// Sets the selected view directly (e.g. after async initialization).
  void setSelectedView(String view) {
    emit(state.copyWith(selectedView: view));
  }

  /// Initializes a view if it hasn't been initialized yet.
  ///
  /// For intervention/observation views, creates the report section if it's null.
  Future<bool> initializeCurrentView({
    required String? incidentId,
    required IncidentDetailsState currentState,
    bool isEditRequired = true,
  }) async {
    if (!isEditRequired) return true;

    final canShow = await _initializeViewIfNeeded(
      state.selectedView,
      incidentId: incidentId,
      currentState: currentState,
    );

    // Fallback to approval if initialization failed
    if (!canShow &&
        (state.selectedView == 'intervention' ||
            state.selectedView == 'observation')) {
      emit(state.copyWith(selectedView: 'approval'));
    }
    return canShow;
  }

  Future<bool> _initializeViewIfNeeded(
    String view, {
    required String? incidentId,
    required IncidentDetailsState currentState,
  }) async {
    if (state.initializedViews.contains(view)) return true;
    if (currentState is! IncidentDetailsLoaded) return true;
    if (currentState.incident.adminStatus != 'Inprogress') return true;

    bool shouldInitialize = false;
    if (view == 'intervention' &&
        currentState.incident.intervention == null) {
      shouldInitialize = true;
    } else if (view == 'observation' &&
        currentState.incident.observation == null) {
      shouldInitialize = true;
    }

    if (shouldInitialize && incidentId != null) {
      emit(state.copyWith(isInitializing: true));
      final success = await AppDI.incidentDetailsCubit.updateReport(
        incidentId,
        view,
      );
      emit(state.copyWith(isInitializing: false));

      if (success) {
        final updated = Set<String>.from(state.initializedViews)..add(view);
        emit(state.copyWith(initializedViews: updated));
        return true;
      }
      return false;
    }

    return true;
  }

  /// Returns the dropdown label for the currently selected view.
  static String getCurrentDropdownValue(String selectedView) {
    switch (selectedView) {
      case 'intervention':
        return TextHelper.intervention;
      case 'observation':
        return TextHelper.observation;
      case 'approval':
      default:
        return TextHelper.incident;
    }
  }

  void reset() {
    emit(const ApprovalViewManagerState());
  }
}
