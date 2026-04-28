import 'dart:math';
import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

/// Report upload loader widget with percentage-based circular progress
/// Matches Figma design with green theme and wave animations
class ReportUploadLoader extends StatelessWidget {
  final double percentage;

  const ReportUploadLoader({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4), // Modal overlay
      child: Center(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Wave Circles
                  _WaveCircle(size: 232, opacity: 0.10),
                  _WaveCircle(size: 208, opacity: 0.15),
                  _WaveCircle(size: 182, opacity: 0.20),
                  _WaveCircle(size: 152, opacity: 0.25),

                  // Circular Progress
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Transform.rotate(
                      angle: -pi / 2,
                      child: CustomPaint(
                        painter: _CirclePainter(
                          radius: 60.0,
                          backgroundColor: const Color(0xFFE8F5E8),
                          foregroundColor: const Color(0xFF3DA229),
                          strokeWidth: 12,
                          percentage: percentage,
                        ),
                      ),
                    ),
                  ),

                  // Percentage Text
                  Text(
                    "${percentage.toInt()}%",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: ColorHelper.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Generating Your Smart AI Report...",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorHelper.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Hang tight — it'll be ready shortly!",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorHelper.textColorDefault,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wave circle widget for background animation effect
class _WaveCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _WaveCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF3DA229).withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }
}

/// Custom painter for circular progress indicator
class _CirclePainter extends CustomPainter {
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final double strokeWidth;
  final double percentage;

  _CirclePainter({
    required this.radius,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.strokeWidth,
    required this.percentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth - 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final progressAngle = 2 * pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      progressAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
