import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/ert/er_team_approver/model/er_incident_model.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';

/// Timer Widget
/// Displays elapsed time with appropriate icon color based on status
class TimerWidget extends StatelessWidget {
  final String time;
  final ErIncidentStatus status;
  final bool isMainTimer;

  const TimerWidget({
    super.key,
    required this.time,
    required this.status,
    this.isMainTimer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21,
      padding: isMainTimer
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
          : EdgeInsets.zero,
      decoration: isMainTimer
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFF005B8B)),
              borderRadius: BorderRadius.circular(24),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Assets.tasktime, width: 8, height: 8, color: isMainTimer ? const Color(0xFF005B8B) : _getIconColor(),),

          const SizedBox(width: 5),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isMainTimer ? const Color(0xFF005B8B) : _getIconColor(),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconColor() {
    if (isMainTimer) {
      return const Color(0xFF005B8B);
    }

    switch (status) {
      case ErIncidentStatus.verified:
        return ColorHelper.primaryColor; // Green
      case ErIncidentStatus.notVerified:
        return ColorHelper.notVerifiedTimerColor; // Dark gray/black
      case ErIncidentStatus.rejected:
        return ColorHelper.rejectedTimerColor; // Red
    }
  }
}
