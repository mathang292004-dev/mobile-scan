import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';
class AppMetricCard extends StatelessWidget {
  final List<String> titles;
  final List<String> counts;
  final List<Widget> icons;
  final int selectedIndex;

  /// Optional tap callbacks — one per item. Length must match [titles].
  final List<VoidCallback?>? onTaps;

  const AppMetricCard({
    super.key,
    required this.titles,
    required this.counts,
    required this.icons,
    this.selectedIndex = 0,
    this.onTaps,
  }) : assert(
          titles.length == counts.length && counts.length == icons.length,
          'titles, counts and icons must all have the same length',
        );

  VoidCallback? _tap(int i) =>
      (onTaps != null && i < onTaps!.length) ? onTaps![i] : null;

  _GridCell _cell(int i) => _GridCell(
        title: titles[i],
        count: counts[i],
        icon: icons[i],
        isHighlighted: i == selectedIndex,
        onTap: _tap(i),
      );

  @override
  Widget build(BuildContext context) {
    final n = titles.length;

    if (n == 3) {
      // Row 1 — two cells side by side, Row 2 — one full-width cell
      return Column(
        children: [
          _cell(0),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _cell(1)),
              const SizedBox(width: 8),
              Expanded(child: _cell(2)),
            ],
          ),
        ],
      );
    }

    // GridView for all other counts
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        childAspectRatio: 2.0,
      ),
      itemCount: n,
      itemBuilder: (_, i) => _cell(i),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified grid cell — highlighted (green border + glow) or plain (white border)
// ─────────────────────────────────────────────────────────────────────────────

class _GridCell extends StatelessWidget {
  final String title;
  final String count;
  final Widget icon;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const _GridCell({
    required this.title,
    required this.count,
    required this.icon,
    required this.isHighlighted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? ColorHelper.selectedCardColor
              : ColorHelper.textLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted
                ? ColorHelper.selectedCardStrokeColor.withValues(alpha: 0.80)
                : ColorHelper.white,
            width: 1.0,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: ColorHelper.selectedCardStrokeColor
                        .withValues(alpha: 0.10),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    count,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: ColorHelper.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.69),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: icon),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
