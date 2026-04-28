import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ProcessingContainerWidget extends StatelessWidget {
  final String? statusTitle;
  final String? statusMessage;
  final Color? color;

  const ProcessingContainerWidget({
    super.key,
    this.statusTitle,
    this.statusMessage,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? ColorHelper.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statusTitle?.isNotEmpty ?? false
                ? Text(statusTitle!)
                : Lottie.asset(
                    Assets.reportIncidentLoading,
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
            const SizedBox(height: 12),
            Text(
              statusMessage ?? TextHelper.processingYourRecording,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColorHelper.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
