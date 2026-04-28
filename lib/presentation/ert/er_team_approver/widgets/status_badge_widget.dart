import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/ert/er_team_approver/model/er_incident_model.dart';
import 'package:flutter/material.dart';

/// Status Badge Widget
/// Displays the status of an incident with appropriate colors
class StatusBadgeWidget extends StatelessWidget {
  final ErIncidentStatus status;

  const StatusBadgeWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.41),
            blurRadius: 13.5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: _getTextColor(),
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getTextColor() {
    switch (status) {
      case ErIncidentStatus.verified:
        return ColorHelper.verifiedTextColor;   // green text
      case ErIncidentStatus.notVerified:
        return ColorHelper.notVerifiedTextColor; // yellow/brown text
      case ErIncidentStatus.rejected:
        return ColorHelper.rejectedTextColor;   // red text
    }
  }

  Color _getBackgroundColor() {
    switch (status) {
      case ErIncidentStatus.verified:
        return ColorHelper.verifiedBackgroundColor; // Light green
      case ErIncidentStatus.notVerified:
        return ColorHelper.notVerifiedBackgroundColor; // Light yellow
      case ErIncidentStatus.rejected:
        return ColorHelper.rejectedBackgroundColor; // Light red
    }
  }
}
