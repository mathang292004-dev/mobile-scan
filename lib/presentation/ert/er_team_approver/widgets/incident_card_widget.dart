import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/ert/er_team_approver/model/er_incident_model.dart';
import 'package:emergex/presentation/ert/er_team_approver/widgets/custom_checkbox_widget.dart';
import 'package:emergex/presentation/ert/er_team_approver/widgets/status_badge_widget.dart';
import 'package:emergex/presentation/ert/er_team_approver/widgets/timer_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Incident Card Widget
/// Displays individual incident information with selection capability
class IncidentCardWidget extends StatelessWidget {
  final ErIncidentModel incident;
  final ValueChanged<bool>? onSelectionChanged;

  const IncidentCardWidget({
    super.key,
    required this.incident,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openScreen(
          Routes.erTeamApproverTaskDetailsScreen,
          args: {
            'taskId': incident.id,
            'incidentId': incident.incidentCode,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(color: _getBorderColor(), width: 1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row with Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomCheckboxWidget(
                            state: _getCheckboxState(),
                            onChanged: (newState) {
                              if (onSelectionChanged != null) {
                                onSelectionChanged!(
                                  newState == CheckboxState.checked,
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              incident.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: ColorHelper.black4,
                                    height: 1.7,
                                    letterSpacing: -0.28,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        incident.incidentCode,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorHelper.black4,
                          fontWeight: FontWeight.w400,
                          height: 1,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Submitted By and Date Row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        TextHelper.submittedBy,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColorHelper.black4,
                              fontWeight: FontWeight.w400,
                            ),
                      ),

                      const SizedBox(width: 4),

                      Flexible(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: ColorHelper.textPrimary,
                                width: 0.8, // ✅ consistent underline
                              ),
                            ),
                          ),
                          child: Text(
                            incident.submittedBy,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: ColorHelper.textPrimary,
                                  fontWeight: FontWeight.w400,
                                  height:1.0,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Text(
                  _formatDate(incident.submittedDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: ColorHelper.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Timer and Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TimerWidget(
                  time: incident.timeElapsed,
                  status: incident.status,
                ),
                StatusBadgeWidget(status: incident.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (incident.isSelected &&
        incident.status == ErIncidentStatus.notVerified) {
      return const Color(0xFFE2FFE0).withValues(alpha: 0.4);
    }
    return const Color(0xFFFFFFFF).withValues(alpha: 0.4);
  }

  Color _getBorderColor() {
    if (incident.isSelected &&
        incident.status == ErIncidentStatus.notVerified) {
      return ColorHelper.primaryColor;
    }
    return Colors.white;
  }

  CheckboxState _getCheckboxState() {
    if (incident.isSelected) {
      return CheckboxState.checked;
    } else if (incident.status == ErIncidentStatus.rejected ||
        incident.status == ErIncidentStatus.verified) {
      return CheckboxState.partial;
    }
    return CheckboxState.unchecked;
  }

  String _formatDate(String rawDate) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(rawDate);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      debugPrint('DATE FORMAT FAILED -> $rawDate');
      return rawDate;
    }
  }
}
