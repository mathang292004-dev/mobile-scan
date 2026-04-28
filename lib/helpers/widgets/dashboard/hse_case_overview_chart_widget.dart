import 'dart:math' as math;

import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:flutter/material.dart';

/// Data model for a single bar group in the HSE Case Overview chart.
class HseBarData {
  final String label;
  final double safe;
  final double atRisk;

  const HseBarData(this.label, this.safe, this.atRisk);
}

/// HSE Case Overview chart with side-by-side Safe/At Risk bars.
///
/// Features:
/// - Side-by-side capsule bars (green Safe, red At Risk)
/// - Horizontally scrollable for many categories
/// - Y-axis labels on the left
/// - Legend on the top-right
///
/// Usage:
/// ```dart
/// HseCaseOverviewChartWidget(
///   title: 'Case Overview',
///   data: [
///     HseBarData('Incident', 115, 89),
///     HseBarData('Line of..', 149, 56),
///   ],
/// );
/// ```
class HseCaseOverviewChartWidget extends StatelessWidget {
  final String title;
  final List<HseBarData> data;
  final double chartHeight;
  final double barWidth;
  final double groupWidth;

  const HseCaseOverviewChartWidget({
    super.key,
    this.title = TextHelper.caseOverview,
    required this.data,
    this.chartHeight = 220,
    this.barWidth = 12,
    this.groupWidth = 38,
  });

  double get _maxValue {
    double max = 0;
    for (final d in data) {
      if (d.safe > max) max = d.safe;
      if (d.atRisk > max) max = d.atRisk;
    }
    return max == 0 ? 100 : max;
  }

  List<String> get _yLabels {
    final max = _maxValue;
    final niceMax = (max / 15).ceil() * 15;
    final step = (niceMax / 5).ceil();
    final labels = <String>[];
    for (int i = 0; i <= 5; i++) {
      labels.add((step * i).toString());
    }
    return labels.reversed.toList();
  }

  double get _yAxisMax {
    final max = _maxValue;
    return ((max / 15).ceil() * 15).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      alpha: 0.4,
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildChart(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: ColorHelper.black5,
                letterSpacing: -0.2,
              ),
        ),
        Row(
          children: [
            _legendItem(context, ColorHelper.primaryColor, TextHelper.safe),
            const SizedBox(width: 16),
            _legendItem(context, ColorHelper.errorColor, TextHelper.atRisk),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: ColorHelper.textSecondary,
                fontWeight: FontWeight.w400,
              ),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final yLabels = _yLabels;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Y-axis labels
        SizedBox(
          height: chartHeight + 24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: yLabels
                .map((v) => Text(
                      v,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            color: ColorHelper.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: 6),
        // Scrollable bars
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: data.length * groupWidth,
              child: Column(
                children: [
                  SizedBox(
                    height: chartHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: data.map((d) => _buildBarGroup(d)).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // X-axis labels
                  Row(
                    children: data
                        .map((d) => SizedBox(
                              width: groupWidth,
                              child: Text(
                                d.label,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 8,
                                      color: ColorHelper.textSecondary,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarGroup(HseBarData d) {
    final yMax = _yAxisMax;
    // Scale so combined safe + atRisk + gap fits within chartHeight
    final scale = yMax > 0 ? chartHeight / yMax : 0.0;
    final safeH = d.safe * scale * 0.48;
    final riskH = d.atRisk * scale * 0.48;

    return SizedBox(
      width: groupWidth,
      height: chartHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // At Risk bar (red) — on top
          Container(
            width: barWidth,
            height: math.max(riskH, 4),
            decoration: BoxDecoration(
              color: ColorHelper.errorColor,
              borderRadius: BorderRadius.circular(barWidth / 2),
            ),
          ),
          const SizedBox(height: 3),
          // Safe bar (green) — on bottom
          Container(
            width: barWidth,
            height: math.max(safeH, 4),
            decoration: BoxDecoration(
              color: ColorHelper.primaryColor,
              borderRadius: BorderRadius.circular(barWidth / 2),
            ),
          ),
        ],
      ),
    );
  }
}
