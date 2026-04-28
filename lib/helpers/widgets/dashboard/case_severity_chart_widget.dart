import 'package:emergex/helpers/text_helper.dart';
import 'dart:math' as math;

import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:flutter/material.dart';

/// Data model for a single severity entry.
class SeverityData {
  final String label;
  final int caseCount;
  final double percentage;
  final Color color;

  const SeverityData({
    required this.label,
    required this.caseCount,
    required this.percentage,
    required this.color,
  });
}

/// A reusable Case Severity Analysis widget matching the Figma design.
///
/// Displays concentric donut rings and severity breakdown rows with progress bars.
///
/// Usage:
/// ```dart
/// CaseSeverityChartWidget(
///   title: 'Case Severity Analysis',
///   severities: [
///     SeverityData(label: 'Low', caseCount: 25, percentage: 45, color: Color(0xFFA2E295)),
///     SeverityData(label: 'Medium', caseCount: 50, percentage: 80, color: Color(0xFF70D65C)),
///     SeverityData(label: 'High', caseCount: 60, percentage: 60, color: Color(0xFF3DA229)),
///   ],
/// );
/// ```
class CaseSeverityChartWidget extends StatelessWidget {
  final String title;
  final List<SeverityData> severities;
  final double ringSize;

  const CaseSeverityChartWidget({
    super.key,
    required this.title,
    required this.severities,
    this.ringSize = 184,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      color: Colors.white.withValues(alpha: 0.4),
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(context),
          const SizedBox(height: 12),
          _buildDonutChart(),
          const SizedBox(height: 20),
          _buildSeverityRows(context),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: const Color(0xFF2B2B2B),
            letterSpacing: -0.25,
          ),
    );
  }

  Widget _buildDonutChart() {
    return Center(
      child: SizedBox(
        width: ringSize,
        height: ringSize,
        child: CustomPaint(
          painter: _ConcentricRingPainter(severities: severities),
        ),
      ),
    );
  }

  Widget _buildSeverityRows(BuildContext context) {
    // Define the specific display order requested: Low, Medium, High
    final displayWeight = {
      TextHelper.low: 0,
      TextHelper.medium: 1,
      TextHelper.high: 2,
    };

    // Create a copy and sort for display in horizontal bars
    final sortedSeverities = List<SeverityData>.from(severities)
      ..sort((a, b) {
        final weightA = displayWeight[a.label] ?? 99;
        final weightB = displayWeight[b.label] ?? 99;
        return weightA.compareTo(weightB);
      });

    return Column(
      children: sortedSeverities
          .asMap()
          .entries
          .map((entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key < sortedSeverities.length - 1 ? 10 : 0,
                ),
                child: _SeverityRow(data: entry.value),
              ))
          .toList(),
    );
  }
}

class _SeverityRow extends StatelessWidget {
  final SeverityData data;

  const _SeverityRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${data.percentage.toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: const Color(0xFF2B2B2B),
                    letterSpacing: -0.25,
                  ),
            ),
            Text(
              '${data.label} - ${data.caseCount} cases',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: const Color(0xFF808080),
                    letterSpacing: -0.16,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: data.percentage / 100,
            minHeight: 5,
            backgroundColor: const Color(0xFFE1EFDE),
            valueColor: AlwaysStoppedAnimation<Color>(data.color),
          ),
        ),
      ],
    );
  }
}

class _ConcentricRingPainter extends CustomPainter {
  final List<SeverityData> severities;

  _ConcentricRingPainter({required this.severities});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Ring configs: outermost to innermost
    // Each ring shrinks by ~15% inward
    final ringConfigs = <_RingConfig>[];
    final ringCount = severities.length;

    for (int i = 0; i < ringCount; i++) {
      final outerFactor = 1.0 - (i * 0.15);
      final innerFactor = outerFactor - 0.08;
      ringConfigs.add(_RingConfig(
        outerRadius: maxRadius * outerFactor,
        innerRadius: maxRadius * innerFactor,
        percentage: severities[i].percentage,
        color: severities[i].color,
      ));
    }

    for (final ring in ringConfigs) {
      // Track background
      final trackPaint = Paint()
        ..color = const Color(0xFFE1EFDE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.outerRadius - ring.innerRadius
        ..strokeCap = StrokeCap.round;

      final ringRadius = (ring.outerRadius + ring.innerRadius) / 2;

      canvas.drawCircle(center, ringRadius, trackPaint);

      // Filled arc
      final arcPaint = Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.outerRadius - ring.innerRadius
        ..strokeCap = StrokeCap.round;

      final sweepAngle = (ring.percentage / 100) * 2 * math.pi;
      const startAngle = -math.pi / 2; // Start from top

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingPainter oldDelegate) {
    return oldDelegate.severities != severities;
  }
}

class _RingConfig {
  final double outerRadius;
  final double innerRadius;
  final double percentage;
  final Color color;

  _RingConfig({
    required this.outerRadius,
    required this.innerRadius,
    required this.percentage,
    required this.color,
  });
}
