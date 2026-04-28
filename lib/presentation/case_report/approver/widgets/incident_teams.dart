import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/case_report/approver/utils/incident_teams_utils.dart';
import 'package:emergex/presentation/case_report/approver/widgets/emergency_card.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/presentation/case_report/approver/cubit/teams_tab_data_cubit.dart';
import 'add_team_member.dart';

class MemberAssignCard extends StatelessWidget {
  final IncidentDetails incident;
  final bool isEditMode;

  const MemberAssignCard({
    super.key,
    required this.incident,
    this.isEditMode = false,
  });

  void _loadTeamData(BuildContext context) {
    final projectId = incident.projectId ?? '';
    if (projectId.isNotEmpty) {
      context.read<TeamsTabDataCubit>().loadTeamsData(
        projectId,
        incidentId: incident.incidentId,
      );
    }
  }

  Future<void> _handleAddMember(BuildContext context) async {
    final incidentId = incident.incidentId ?? '';
    if (incidentId.isEmpty) return;

    final clientId = incident.projectId ?? '';
    if (clientId.isEmpty) return;

    final bool? wasSuccessful = await AddTeamMember.show(
      context,
      incidentId: incidentId,
      clientId: clientId,
      type: 'ert',
      role: 'member',
    );

    if (wasSuccessful == true) {
      if (context.mounted) _loadTeamData(context);
      AppDI.incidentDetailsCubit.getIncidentById(incidentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTeamData(context));

    return BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
      builder: (context, state) {
        final currentIncident =
            state is IncidentDetailsLoaded &&
                state.incident.incidentId == incident.incidentId
            ? state.incident
            : incident;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DynamicEmergencyResponseContainer(
            emergencyData: mapIncidentToEmergencyDataErt(currentIncident),
            onAddMember: () => _handleAddMember(context),
            onRefreshTeamData: () => _loadTeamData(context),
            incident: currentIncident,
            isEditMode: isEditMode,
          ),
        );
      },
    );
  }
}
