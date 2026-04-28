import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

class EmergeXSectionWidget extends StatelessWidget {
  final String description;
  final int maxLinesCollapsed;

  const EmergeXSectionWidget({
    super.key,
    required this.description,
    this.maxLinesCollapsed = 4,
  });

  List<String> _getBulletPoints() {
    if (description.trim().isEmpty) {
      return ['No description available'];
    }

    final cleaned = description
        .replaceAll(RegExp(r'[\[\]\{\}]'), '')
        .replaceAll('\n', ' ')
        .trim();

    if (cleaned.isEmpty) {
      return ['No description available'];
    }

    if (cleaned.contains(',')) {
      return cleaned
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final sentences = cleaned
        .split(RegExp(r'[.!?]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return sentences.isNotEmpty ? sentences : [cleaned];
  }

  @override
  Widget build(BuildContext context) {
    final bulletPoints = _getBulletPoints();
    final showToggle = bulletPoints.length > 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: ColorHelper.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            TextHelper.emergexCaseOverView,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorHelper.black4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorHelper.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: showToggle
                ? _ExpandableDescription(
                    bulletPoints: bulletPoints,
                    maxLinesCollapsed: maxLinesCollapsed,
                  )
                : _StaticDescription(
                    bulletPoints: bulletPoints,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatelessWidget {
  final List<String> bulletPoints;
  final int maxLinesCollapsed;
  final ValueNotifier<bool> _isExpanded = ValueNotifier(false);

  _ExpandableDescription({
    required this.bulletPoints,
    required this.maxLinesCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isExpanded,
      builder: (context, isExpanded, _) {
        final visiblePoints = isExpanded ? bulletPoints : [bulletPoints.first];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TextHelper.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorHelper.black4,
                  ),
            ),
            const SizedBox(height: 8),
            ...visiblePoints.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: ColorHelper.black4,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: ColorHelper.black4,
                            ),
                        maxLines: !isExpanded && entry.key == 0
                            ? maxLinesCollapsed
                            : null,
                        overflow: !isExpanded && entry.key == 0
                            ? TextOverflow.ellipsis
                            : TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _isExpanded.value = !_isExpanded.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded ? 'Read Less' : 'Read More',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: ColorHelper.primaryColor,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: ColorHelper.primaryColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StaticDescription extends StatelessWidget {
  final List<String> bulletPoints;

  const _StaticDescription({required this.bulletPoints});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TextHelper.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorHelper.black4,
              ),
        ),
        const SizedBox(height: 8),
        ...bulletPoints.map((point) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: ColorHelper.black4,
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: ColorHelper.black4,
                        ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
