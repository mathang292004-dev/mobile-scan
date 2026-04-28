import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

class AISummary extends StatelessWidget {
  final String title;
  final String summary;
  final VoidCallback onPressed;
  final Color? color;
  const AISummary({
    super.key,
    required this.title,
    required this.summary,
    required this.onPressed,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: color ?? ColorHelper.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(
            summary,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ColorHelper.textSecondary),
          ),
        ],
      ),
    );
  }
}
