import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double progress;
  final Color progressColor;
  final bool showProgress;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    this.progress = 0.0,
    this.progressColor = ColorHelper.primaryColor,
    this.showProgress = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dashed border
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(24), // Match border radius
        ),
      );

    canvas.drawPath(_createDashedPath(path, dashWidth, dashSpace), paint);

    // Draw progress bar fill if enabled
    if (showProgress && progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 1; // Make it slightly thicker to overlap

      final progressPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(24),
          ),
        );

      // Extract a portion of the path based on progress
      final pathMetrics = progressPath.computeMetrics();
      for (final metric in pathMetrics) {
        final extract = metric.extractPath(
          0.0,
          metric.length * progress.clamp(0.0, 1.0),
        );
        canvas.drawPath(extract, progressPaint);
      }
    }
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final dashedPath = Path();
    final pathMetrics = source.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool shouldDraw = true;

      while (distance < pathMetric.length) {
        final double length = shouldDraw ? dashWidth : dashSpace;
        final double end = (distance + length).clamp(0.0, pathMetric.length);

        if (shouldDraw) {
          dashedPath.addPath(
            pathMetric.extractPath(distance, end),
            Offset.zero,
          );
        }

        distance = end;
        shouldDraw = !shouldDraw;
      }
    }

    return dashedPath;
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showProgress != showProgress ||
        oldDelegate.color != color ||
        oldDelegate.progressColor != progressColor;
  }
}
