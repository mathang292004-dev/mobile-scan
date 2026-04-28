import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:emergex/presentation/case_report/approver/widgets/incident_approval_widget.dart';
import 'package:emergex/presentation/case_report/approver/screens/incident_action_buttons.dart';
import 'package:emergex/presentation/case_report/approver/widgets/incident_overview_details.dart';
import 'package:flutter/material.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/widgets/utils/unfocus_on_scroll_wrapper.dart';

class ApprovalView extends StatelessWidget {
  final IncidentDetailsLoaded state;
  final String? incidentId;
  final String selectedView;
  final bool isEditRequired;

  const ApprovalView({
    super.key,
    required this.state,
    required this.incidentId,
    required this.selectedView,
    this.isEditRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return UnfocusOnScrollWrapper(
      child: RefreshIndicator(
        onRefresh: () async {
          bool hasChanged = await AppDI.incidentDetailsCubit.checkDataChanged();
          if (hasChanged && context.mounted) {
            showErrorDialog(
              context,
              () async {
                back();
                AppDI.incidentDetailsCubit.clearCache();
                if (incidentId != null && incidentId!.isNotEmpty) {
                  await AppDI.incidentDetailsCubit.getIncidentById(incidentId!);
                }
              },
              () {
                back();
              },
              TextHelper.areYouSureYouWantToCancelEditedText,
              '',
              TextHelper.yesCancel,
              TextHelper.goBack,
            );
            return;
          }
          final cubit = AppDI.incidentDetailsCubit;
          cubit.clearCache();
          if (incidentId != null && incidentId!.isNotEmpty) {
            await cubit.getIncidentById(incidentId!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IncidentOverviewDetails(
                incident: state.incident,
                isEditRequired: isEditRequired,
              ),
              const SizedBox(height: 16),
              SizedBox(child: IncidentApprovalWidget(incident: state.incident)),
              const SizedBox(height: 24),
              if (state.incident.adminStatus != 'ERT Assigned' &&
                  state.incident.adminStatus != 'Resolved' &&
                  state.incident.adminStatus != 'Closed' &&
                  isEditRequired)
                IncidentActionButtons(
                  incidentId: incidentId,
                  selectedView: selectedView,
                  incidentDetails: state.incident,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
