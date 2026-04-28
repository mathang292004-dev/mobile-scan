import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

/// Case Overview Widget
/// Displays the collapsible case overview section
class CaseOverviewWidget extends StatefulWidget {
  final String title;
  final String description;

  const CaseOverviewWidget({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<CaseOverviewWidget> createState() => _CaseOverviewWidgetState();
}

class _CaseOverviewWidgetState extends State<CaseOverviewWidget> {
  bool isExpanded = false;
  bool isReadMoreExpanded = false;

  @override
  Widget build(BuildContext context) {
    final descriptionPoints = widget.description
        .split('\n')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.4),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ColorHelper.black4,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.28,
                  height: 1.7,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                    }
                  );
                },
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: const Color(0xFF525252),
                ),
              ),
            ],
          ),

          /// CONTENT
          if (isExpanded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: isReadMoreExpanded ? null : 0.55, // 👈 controls cut
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TextHelper.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: ColorHelper.black4,
                                height: 2,
                              ),
                            ),

                            ...descriptionPoints.map(
                              (point) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(' • ', style: TextStyle(height: 1.8, fontSize: 10)),
                                    Expanded(
                                      child: Text(
                                        point,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: ColorHelper.black4,
                                          height: 1.8,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isReadMoreExpanded = !isReadMoreExpanded; // 👈 toggle
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isReadMoreExpanded
                                ? TextHelper.readLess
                                : TextHelper.readMore,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: ColorHelper.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isReadMoreExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 12,
                            color: ColorHelper.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
