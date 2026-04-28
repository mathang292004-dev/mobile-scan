import 'package:emergex/presentation/case_report/approver/cubit/approval_view_manager_cubit.dart';
import 'package:emergex/presentation/case_report/approver/screens/approval_full_widget.dart';
import 'package:emergex/presentation/case_report/approver/screens/intervention_view.dart';
import 'package:emergex/presentation/case_report/approver/screens/observation_view.dart';
import 'package:emergex/presentation/case_report/member/widgets/incident_error_state.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Body widget for the Incident Approval screen.
///
/// The screen ([IncidentApprovalScreen]) owns the `AppScaffold`, `AppBarWidget`,
/// `PopScope`, dropdown handling and `BlocProvider`s. This widget is just
/// responsible for picking the right view (approval / intervention / observation)
/// based on the [ApprovalViewManagerCubit] state.
class IncidentApprovalViewManager extends StatelessWidget {
  final String? incidentId;
  final IncidentDetailsState state;
  final String? initialDropdownValue;
  final bool isEditRequired;
  final String selectedView;

  const IncidentApprovalViewManager({
    super.key,
    required this.incidentId,
    required this.state,
    required this.selectedView,
    this.initialDropdownValue,
    this.isEditRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    // Trigger first-frame initialization of the view manager cubit so the
    // currently-selected view matches the loaded incident state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<ApprovalViewManagerCubit>().initializeCurrentView(
            incidentId: incidentId,
            currentState: state,
            isEditRequired: isEditRequired,
          );
    });

    return _buildContentView();
  }

  Widget _buildContentView() {
    if (state is IncidentDetailsError) {
      return IncidentErrorState(
        incidentId: incidentId,
        errorMessage: (state as IncidentDetailsError).message,
      );
    }

    if (state is IncidentDetailsLoaded) {
      final loadedState = state as IncidentDetailsLoaded;
      switch (selectedView) {
        case 'intervention':
          return InterventionView(
            key: const ValueKey('intervention'),
            state: loadedState,
            incidentId: incidentId,
            selectedView: selectedView,
            isEditRequired: isEditRequired,
          );
        case 'observation':
          return ObservationView(
            key: const ValueKey('observation'),
            state: loadedState,
            incidentId: incidentId,
            selectedView: selectedView,
            isEditRequired: isEditRequired,
          );
        case 'approval':
        default:
          return ApprovalView(
            key: const ValueKey('approval'),
            state: loadedState,
            incidentId: incidentId,
            selectedView: selectedView,
            isEditRequired: isEditRequired,
          );
      }
    }

    return const Center(child: SizedBox.shrink());
  }
}
