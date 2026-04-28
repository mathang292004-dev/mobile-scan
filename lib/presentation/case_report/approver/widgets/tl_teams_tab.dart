import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/case_report/approver/utils/incident_teams_utils.dart';
import 'package:emergex/presentation/case_report/approver/widgets/tl_assignment_card.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Approver-specific Teams tab: shows ERT TL + Investigation TL cards.
/// Used directly by [IncidentApprovalWidget._buildTeamsTab].
class TlTeamsTab extends StatelessWidget {
  final IncidentDetails incident;

  const TlTeamsTab({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
      builder: (context, state) {
        final currentIncident =
            state is IncidentDetailsLoaded &&
                state.incident.incidentId == incident.incidentId
            ? state.incident
            : incident;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TlAssignmentCard(
              ertTl: getErtTlCard(currentIncident),
              investigationTl: getInvestigationTlCard(currentIncident),
              incident: currentIncident,
              onRefreshData: () {
                AppDI.incidentDetailsCubit.getIncidentById(
                  currentIncident.incidentId ?? '',
                );
              },
            ),
          ),
        );
      },
    );
  }
}
