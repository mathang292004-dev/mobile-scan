import 'dart:math' as math;

import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:flutter/material.dart';

/// Data model for a single category group in the bar chart.
class BarChartCategoryData {
  final String label;
  final List<double> values;

  const BarChartCategoryData({required this.label, required this.values});
}

/// Data model for a legend/series entry.
class BarChartSeriesData {
  final String label;
  final Color color;

  const BarChartSeriesData({required this.label, required this.color});
}

/// A reusable grouped bar chart widget matching the Figma Case Overview design.
///
/// Usage:
/// ```dart
/// CaseOverviewChartWidget(
///   title: 'Case Overview',
///   series: [
///     BarChartSeriesData(label: 'Pending', color: Color(0xFFC8EEBF)),
///     BarChartSeriesData(label: 'In Progress', color: Color(0xFF3DA229)),
///     BarChartSeriesData(label: 'Closed', color: Color(0xFF9EDC8F)),
///   ],
///   categories: [
///     BarChartCategoryData(label: 'Incident', values: [45, 120, 75]),
///     BarChartCategoryData(label: 'Near Miss', values: [65, 90, 110]),
///   ],
/// );
/// ```
class CaseOverviewChartWidget extends StatefulWidget {
  final String title;
  final List<BarChartSeriesData> series;
  final List<BarChartCategoryData> categories;
  final double chartHeight;
  final VoidCallback? onDropdownTap;

  const CaseOverviewChartWidget({
    super.key,
    required this.title,
    required this.series,
    required this.categories,
    this.chartHeight = 260,
    this.onDropdownTap,
  });

  @override
  State<CaseOverviewChartWidget> createState() =>
      _CaseOverviewChartWidgetState();
}

class _CaseOverviewChartWidgetState extends State<CaseOverviewChartWidget> {
  int? _selectedCatIdx;
  int? _selectedSeriesIdx;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      alpha: 0.4,
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 14),
          _buildLegend(context),
          const SizedBox(height: 16),
          _buildChart(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      widget.title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: ColorHelper.black5,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 22,
      runSpacing: 8,
      children: widget.series.map((s) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: s.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              s.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF2B2B2B),
                letterSpacing: -0.16,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildChart(BuildContext context) {
    final maxValue = _computeMaxValue();
    final yAxisMax = _ceilToNice(maxValue);
    final ySteps = _generateYLabels(yAxisMax);

    return SizedBox(
      height: widget.chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Y-axis labels
          SizedBox(
            width: 28,
            height: widget.chartHeight - 24,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ySteps.reversed
                  .map(
                    (v) => Text(
                      v.toInt().toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xB0808080),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 8),
          // Scrollable Chart area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double minWidthPerCategory = 100.0;
                final double totalNeededWidth =
                    widget.categories.length * minWidthPerCategory;
                final double chartWidth = math.max(
                  constraints.maxWidth,
                  totalNeededWidth,
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: chartWidth,
                    child: Column(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) =>
                                _handleTap(details.localPosition, chartWidth),
                            child: _BarChartPainterWidget(
                              series: widget.series,
                              categories: widget.categories,
                              yAxisMax: yAxisMax,
                              ySteps: ySteps,
                              selectedCatIdx: _selectedCatIdx,
                              selectedSeriesIdx: _selectedSeriesIdx,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // X-axis labels
                        Row(
                          children: widget.categories.map((c) {
                            return Expanded(
                              child: Text(
                                c.label,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF808080),
                                    ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(Offset localPosition, double chartWidth) {
    if (widget.categories.isEmpty || widget.series.isEmpty) return;

    final catCount = widget.categories.length;
    final barCount = widget.series.length;
    final groupWidth = chartWidth / catCount;

    // Determine category
    final catIdx = (localPosition.dx / groupWidth).floor();
  

    // Determine bar within category
    final barGap = 6.0;
    final maxBarWidth = 28.0;
    final totalBarGaps = (barCount - 1) * barGap;
    final availableBarWidth = math.min(
      maxBarWidth,
      (groupWidth * 0.6 - totalBarGaps) / barCount,
    );
    final totalGroupBarWidth = availableBarWidth * barCount + totalBarGaps;
    final groupCenterX = groupWidth * catIdx + groupWidth / 2;
    final groupStartX = groupCenterX - totalGroupBarWidth / 2;

    int? tappedSeriesIdx;
    for (int i = 0; i < barCount; i++) {
      final barXStart = groupStartX + i * (availableBarWidth + barGap);
      final barXEnd = barXStart + availableBarWidth;

      // Add a small hit-testing buffer around the bar horizontally
      if (localPosition.dx >= barXStart - 2 &&
          localPosition.dx <= barXEnd + 2) {
        tappedSeriesIdx = i;
        break;
      }
    }

    if (mounted) {
      setState(() {
        if (_selectedCatIdx == catIdx &&
            _selectedSeriesIdx == tappedSeriesIdx) {
          _selectedCatIdx = null;
          _selectedSeriesIdx = null;
        } else {
          _selectedCatIdx = catIdx;
          _selectedSeriesIdx = tappedSeriesIdx;
        }
      });
    }
  }

  double _computeMaxValue() {
    double max = 0;
    for (final cat in widget.categories) {
      for (final v in cat.values) {
        if (v > max) max = v;
      }
    }
    return max == 0 ? 100 : max;
  }

  double _ceilToNice(double value) {
    if (value <= 0) return 9;
    final step = value / 9;
    final magnitude = math
        .pow(10, (math.log(step) / math.ln10).floor())
        .toDouble();
    final niceStep = (step / magnitude).ceil() * magnitude;
    return niceStep * 9;
  }

  List<double> _generateYLabels(double yMax) {
    final step = yMax / 9;
    return List.generate(10, (i) => i * step);
  }
}

class _BarChartPainterWidget extends StatelessWidget {
  final List<BarChartSeriesData> series;
  final List<BarChartCategoryData> categories;
  final double yAxisMax;
  final List<double> ySteps;
  final int? selectedCatIdx;
  final int? selectedSeriesIdx;

  const _BarChartPainterWidget({
    required this.series,
    required this.categories,
    required this.yAxisMax,
    required this.ySteps,
    this.selectedCatIdx,
    this.selectedSeriesIdx,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(
        series: series,
        categories: categories,
        yAxisMax: yAxisMax,
        ySteps: ySteps,
        selectedCatIdx: selectedCatIdx,
        selectedSeriesIdx: selectedSeriesIdx,
      ),
      size: Size.infinite,
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<BarChartSeriesData> series;
  final List<BarChartCategoryData> categories;
  final double yAxisMax;
  final List<double> ySteps;
  final int? selectedCatIdx;
  final int? selectedSeriesIdx;

  _BarChartPainter({
    required this.series,
    required this.categories,
    required this.yAxisMax,
    required this.ySteps,
    this.selectedCatIdx,
    this.selectedSeriesIdx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height;
    final chartWidth = size.width;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = const Color(0x1A808080)
      ..strokeWidth = 0.8;

    for (final step in ySteps) {
      final y = chartHeight - (step / yAxisMax) * chartHeight;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // Draw axis lines
    final axisPaint = Paint()
      ..color = const Color(0x40808080)
      ..strokeWidth = 0.8;

    // Y-axis
    canvas.drawLine(Offset.zero, Offset(0, chartHeight), axisPaint);
    // X-axis
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(chartWidth, chartHeight),
      axisPaint,
    );

    if (categories.isEmpty || series.isEmpty) return;

    final catCount = categories.length;
    final barCount = series.length;
    final groupWidth = chartWidth / catCount;
    final barGap = 6.0;
    final totalBarGaps = (barCount - 1) * barGap;
    final maxBarWidth = 28.0;
    final availableBarWidth = math.min(
      maxBarWidth,
      (groupWidth * 0.6 - totalBarGaps) / barCount,
    );
    final totalGroupBarWidth = availableBarWidth * barCount + totalBarGaps;

    Offset? tooltipPos;
    String? tooltipText;
    Color? tooltipColor;

    for (int catIdx = 0; catIdx < catCount; catIdx++) {
      final groupCenterX = groupWidth * catIdx + groupWidth / 2;
      final groupStartX = groupCenterX - totalGroupBarWidth / 2;
      final catData = categories[catIdx];

      for (int sIdx = 0; sIdx < barCount; sIdx++) {
        if (sIdx >= catData.values.length) continue;

        final value = catData.values[sIdx];
        final barHeight = (value / yAxisMax) * chartHeight;
        final barX = groupStartX + sIdx * (availableBarWidth + barGap);
        final barY = chartHeight - barHeight;
        final barRadius = availableBarWidth / 2;

        final barRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(barX, barY, availableBarWidth, barHeight),
          topLeft: Radius.circular(barRadius),
          topRight: Radius.circular(barRadius),
          bottomLeft: Radius.circular(barRadius),
          bottomRight: Radius.circular(barRadius),
        );

        final paint = Paint()..color = series[sIdx].color;
        canvas.drawRRect(barRect, paint);

        // Store info for tooltip if this bar is selected
        if (catIdx == selectedCatIdx && sIdx == selectedSeriesIdx) {
          tooltipPos = Offset(barX + availableBarWidth / 2, barY);
          tooltipText = '${series[sIdx].label} - ${value.toInt()} cases';
          tooltipColor = series[sIdx].color;
        }
      }
    }

    // Draw Tooltip if needed
    if (tooltipPos != null && tooltipText != null && tooltipColor != null) {
      _drawTooltip(canvas, tooltipPos, tooltipText, tooltipColor);
    }
  }

  void _drawTooltip(Canvas canvas, Offset pos, String text, Color baseColor) {
    const bgColor = Color(0xFFD4F0CF);
    const textColor = Color(0xFF3DA229);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final paddingH = 10.0;
    final paddingV = 6.0;
    final tooltipWidth = textPainter.width + paddingH * 2;
    final tooltipHeight = textPainter.height + paddingV * 2;
    const arrowHeight = 6.0;
    const arrowWidth = 10.0;
    const verticalOffset = 12.0;

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - tooltipHeight / 2 - verticalOffset),
        width: tooltipWidth,
        height: tooltipHeight,
      ),
      const Radius.circular(6),
    );

    // Draw shadow
    final shadowPath = Path()..addRRect(tooltipRect);
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.15), 4, false);

    // Prepare fill paint
    final fillPaint = Paint()..color = bgColor;
    final fillPaintArrow = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw background bubble
    canvas.drawRRect(tooltipRect, fillPaint);
    canvas.drawRRect(tooltipRect, borderPaint);

    // Draw triangle pointer at bottom
    final arrowPath = Path()
      ..moveTo(pos.dx - arrowWidth / 2, pos.dy - verticalOffset)
      ..lineTo(pos.dx + arrowWidth / 2, pos.dy - verticalOffset)
      ..lineTo(pos.dx, pos.dy - verticalOffset + arrowHeight)
      ..close();
    
    // Rotate 180 as it's at the bottom pointing down
    // Actually the logic above is for pointing down if verticalOffset is subtracted.
    // Wait, pos.dy is the top of the bar. Tooltip is above it.
    // So the arrow should be at the bottom of the tooltip pointing DOWN to the bar.
    final arrowDownPath = Path()
      ..moveTo(pos.dx - arrowWidth / 2, pos.dy - verticalOffset)
      ..lineTo(pos.dx + arrowWidth / 2, pos.dy - verticalOffset)
      ..lineTo(pos.dx, pos.dy - verticalOffset + arrowHeight)
      ..close();
    
    // Let's fix the arrow path to be attached to the tooltip
    final attachedArrowPath = Path()
      ..moveTo(pos.dx - arrowWidth / 2, pos.dy - verticalOffset + 0.5) // Slight overlap to avoid lines
      ..lineTo(pos.dx + arrowWidth / 2, pos.dy - verticalOffset + 0.5)
      ..lineTo(pos.dx, pos.dy - verticalOffset + arrowHeight)
      ..close();

    // Draw the dot on the bar (indicator)
    final dotPosition = Offset(pos.dx, pos.dy + 3);
    canvas.saveLayer(Rect.fromLTWH(0, 0, 2000, 2000), Paint());
    canvas.drawCircle(dotPosition, 10, Paint()..color = Colors.white.withOpacity(0.3));
    canvas.restore();
    canvas.drawCircle(dotPosition, 3, Paint()..color = baseColor);
    canvas.drawCircle(
      dotPosition,
      5,
      Paint()
        ..color = baseColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    canvas.drawPath(attachedArrowPath, fillPaintArrow);
    // Draw white border for the arrow too (optional, but looks better)
    final arrowBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(attachedArrowPath, arrowBorderPaint);

    // Draw text
    textPainter.paint(
      canvas,
      Offset(
        pos.dx - textPainter.width / 2,
        pos.dy - tooltipHeight - verticalOffset + paddingV,
      ),
    );

  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.series != series ||
        oldDelegate.yAxisMax != yAxisMax ||
        oldDelegate.selectedCatIdx != selectedCatIdx ||
        oldDelegate.selectedSeriesIdx != selectedSeriesIdx;
  }
}
