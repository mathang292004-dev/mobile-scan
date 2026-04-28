import 'package:flutter/material.dart';

import '../../../../generated/color_helper.dart';

class RecordingTimerWidget extends StatelessWidget {
  final int durationSeconds;

  const RecordingTimerWidget({
    super.key,
    required this.durationSeconds,
  });

  String _formatTime(int seconds) {
    final hrs = (seconds ~/ 3600).toString().padLeft(2, '0');
    final mins = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$hrs:$mins:$secs";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(durationSeconds),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: ColorHelper.textSecondary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
