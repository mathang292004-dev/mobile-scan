import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:emergex/presentation/case_report/approver/screens/incident_action_buttons.dart';
import 'package:emergex/presentation/case_report/approver/widgets/additional_comments.dart';
import 'package:emergex/presentation/case_report/approver/widgets/behavioural_full_widget.dart';
import 'package:emergex/presentation/case_report/approver/widgets/behavioural_safety_assessment.dart';
import 'package:emergex/presentation/case_report/approver/widgets/feed_back_widget.dart';
import 'package:flutter/material.dart';

class InterventionView extends StatelessWidget {
  final IncidentDetailsLoaded state;
  final String? incidentId;
  final String selectedView;
  final bool isEditRequired;
  const InterventionView({
    super.key,
    required this.state,
    this.incidentId,
    required this.selectedView,
    this.isEditRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
        AppDI.incidentDetailsCubit.clearCache();
        if (incidentId != null && incidentId!.isNotEmpty) {
          await AppDI.incidentDetailsCubit.getIncidentById(incidentId!);
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),

        // padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Column(
          children: [
            BehaviouralSafetyAssessment(
              key: const Key('behavioural_safety_assessment'),
              incident: state.incident,
              incidentOverview: state.incident.intervention is Map
                  ? getValueCaseInsensitive(
                      state.incident.intervention,
                      'behaviouralSafetyAssessment',
                    )
                  : null,
              dataPath: DataPath(
                parentKey: 'intervention',
                childKey: 'behaviouralSafetyAssessment',
              ),
              isEditRequired: isEditRequired,
            ),
            const SizedBox(height: 16),
            BehaviouralFullWidget(
              incidentMap: state.incident.intervention is Map
                  ? state.incident.intervention as Map<String, dynamic>
                  : {},
              topKey: 'criticalSafetyBehaviour',
              title: TextHelper.criticalSafetyBehaviours,
              isEditOption: true,
              incidentDetails: state.incident,
              parentPath: 'intervention',
              isEditRequired: isEditRequired,
            ),

            const SizedBox(height: 16),
            FeedbackWidget(
              feedback: state.incident.intervention is Map
                  ? getValueCaseInsensitive(
                      state.incident.intervention,
                      'feedback',
                    )
                  : null,
              title: TextHelper.feedback,
              incidentDetails: state.incident,
              parentPath: 'intervention',
              feedbackKey: 'feedback',
              isExpandable: true,
              isEditRequired:
                  (state.incident.adminStatus != 'ERT Assigned' &&
                  isEditRequired),
            ),
            const SizedBox(height: 16),
            AdditionalComments(state: state, isEditRequired: isEditRequired),
            const SizedBox(height: 24),
            if (state.incident.adminStatus != 'ERT Assigned' &&
                state.incident.adminStatus != 'Resolved' &&
                state.incident.adminStatus != 'Closed' &&
                isEditRequired)
              IncidentActionButtons(
                incidentId: state.incident.incidentId,
                selectedView: selectedView,
              ),
          ],
        ),
      ),
    );
  }
}
