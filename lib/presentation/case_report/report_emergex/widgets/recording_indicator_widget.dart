import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RecordingIndicatorWidget extends StatelessWidget {
  const RecordingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 15),
      child: Row(
        children: [
          Text(
            TextHelper.aiAnalyzing,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ColorHelper.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Lottie.asset(
            Assets.reportIncidentLoading,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
