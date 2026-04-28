import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/case_report/utils/case_report_navigation_utils.dart';
import 'package:flutter/material.dart';

class IncidentActionButtons extends StatelessWidget {
  final String? incidentId;
  final String selectedView;
  final IncidentDetails? incidentDetails;
  const IncidentActionButtons({
    super.key,
    required this.incidentId,
    required this.selectedView,
    this.incidentDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        color: ColorHelper.surfaceColor.withValues(alpha: 0.15),
      ),
      child: Column(
        children: [
          // View Preliminary Report Button
          EmergexButton(
            onPressed: () {
              openScreen(
                Routes.preliminaryReportScreen,
                args: {'incidentId': incidentId},
              );
            },
            text: TextHelper.viewPreliminaryReport,
            colors: [ColorHelper.white, ColorHelper.white],
            textColor: ColorHelper.primaryColor,
            borderColor: ColorHelper.white,
            borderWidth: 0,
            borderRadius: 34,
            buttonHeight: 49,
            textSize: 14,
            fontWeight: FontWeight.w600,
            boxShadow: [
              BoxShadow(
                color: ColorHelper.black.withValues(alpha: 0.08),
                offset: const Offset(0, 1),
                blurRadius: 7.6,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: EmergexButton(
                  onPressed: () => CaseReportNavigationUtils.handleActionCancel(context),
                  text: TextHelper.cancel,
                  colors: [ColorHelper.white, ColorHelper.white],
                  textColor: ColorHelper.primaryColor,
                  borderColor: ColorHelper.primaryColor,
                  borderRadius: 8,
                  textSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EmergexButton(
                  onPressed: () => CaseReportNavigationUtils.handleActionSubmit(
                    context,
                    incidentId: incidentId,
                    selectedView: selectedView,
                    incidentDetails: incidentDetails,
                  ),
                  text: TextHelper.submit,
                  colors: [ColorHelper.primaryColor, ColorHelper.buttonColor],
                  textColor: ColorHelper.white,
                  borderColor: ColorHelper.transparent,
                  borderRadius: 8,
                  textSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
