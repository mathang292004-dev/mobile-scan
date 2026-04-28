import 'dart:math';
import 'package:flutter/material.dart';

class BehaviourInsightsWidget extends StatelessWidget {
  final double safePercentage;
  final double atRiskPercentage;

  const BehaviourInsightsWidget({
    super.key,
    required this.safePercentage,
    required this.atRiskPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Behaviour Insights',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Donut chart ──
              SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: _DonutPainter(
                    safePercent: safePercentage / 100,
                    riskPercent: atRiskPercentage / 100,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // ── Stats ──
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatRow(
                      percentage: safePercentage,
                      label: 'Safe',
                      fillColor: const Color(0xFF4CAF50),
                      trackColor: const Color(0xFFD6E8D2),
                    ),
                    const SizedBox(height: 20),
                    _StatRow(
                      percentage: atRiskPercentage,
                      label: 'At Risk',
                      fillColor: const Color(0xFFE74B48),
                      trackColor: const Color(0xFFD6E8D2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Donut painter ─────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double safePercent;  // 0.0 – 1.0
  final double riskPercent;  // 0.0 – 1.0

  const _DonutPainter({
    required this.safePercent,
    required this.riskPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── Outer ring (Safe) ──────────────────────────────
    const outerStroke = 14.0;
    final outerRadius = (size.width / 2) - outerStroke / 2;

    // Track
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = const Color(0xFFD6E8D2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerStroke,
    );

    // Arc — starts at -90° (top), sweeps clockwise by safePercent * 360°
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      -pi / 2,                    // start angle: top
      2 * pi * safePercent,       // sweep angle
      false,
      Paint()
        ..color = const Color(0xFF4CAF50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerStroke
        ..strokeCap = StrokeCap.round,
    );

    // ── Inner ring (At Risk) ───────────────────────────
    const innerStroke = 10.0;
    final innerRadius = outerRadius - outerStroke / 2 - 6 - innerStroke / 2;

    // Track
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = const Color(0xFFD6E8D2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerStroke,
    );

    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -pi / 2,
      2 * pi * riskPercent,
      false,
      Paint()
        ..color = const Color(0xFFE74B48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerStroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.safePercent != safePercent || old.riskPercent != riskPercent;
}

// ── Single stat row (percentage + label + progress bar) ───────────────────────
class _StatRow extends StatelessWidget {
  final double percentage;   // e.g. 60 (not 0.60)
  final String label;
  final Color fillColor;
  final Color trackColor;

  const _StatRow({
    required this.percentage,
    required this.label,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${percentage.toInt()}%',
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar using LayoutBuilder so it adapts to any screen width
        LayoutBuilder(
          builder: (context, constraints) {
            final fillWidth = constraints.maxWidth * (percentage / 100);
            return Stack(
              children: [
                Container(
                  width: constraints.maxWidth,
                  height: 4,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: fillWidth,
                  height: 4,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
