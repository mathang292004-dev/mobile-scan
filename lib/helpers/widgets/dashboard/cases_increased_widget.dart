import 'dart:math' as math;

import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:flutter/material.dart';

/// Widget showing the percentage increase in cases this month with a mini donut.
class CasesIncreasedWidget extends StatelessWidget {
  final double percentage;

  const CasesIncreasedWidget({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      alpha: 0.4,
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${percentage.toInt()}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: ColorHelper.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 26,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  TextHelper.casesIncreasedThisMonth,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.chartLabelColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 47,
            height: 47,
            child: CustomPaint(
              painter: _MiniDonutPainter(percentage: percentage),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDonutPainter extends CustomPainter {
  final double percentage;

  _MiniDonutPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 6.0;

    final trackPaint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = ColorHelper.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage / 100) * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniDonutPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
