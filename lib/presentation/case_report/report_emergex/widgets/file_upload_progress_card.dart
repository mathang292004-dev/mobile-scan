import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

class ProgressSectionWidget extends StatelessWidget {
  final double progress; // Value from 0.0 to 100.0
  final VoidCallback? onCancel;
  final String? fileName; // Optional file name to display

  const ProgressSectionWidget({
    super.key,
    required this.progress,
    this.onCancel,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    // Estimate remaining time - you can make this logic more sophisticated
    // Progress is now 0-100, so convert to 0-1 for calculations
    final progressNormalized = (progress / 100.0).clamp(0.0, 1.0);
    final estimatedTotalTime = 10; // seconds
    final remainingTime = (estimatedTotalTime * (1 - progressNormalized)).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorHelper.surfaceColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with status and controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status and percentage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TextHelper.uploading,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ColorHelper.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (fileName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        fileName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorHelper.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${progress.toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ColorHelper.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (remainingTime > 0)
                          Text(
                            ' • $remainingTime ${TextHelper.secondsRemaining}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: ColorHelper.textSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Cancel button
              if (onCancel != null)
                GestureDetector(
                  onTap: () => onCancel!(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorHelper.errorColor,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: ColorHelper.errorColor,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress bar
          Container(
            height: 8,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: ColorHelper.surfaceColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressNormalized.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: ColorHelper.successColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
