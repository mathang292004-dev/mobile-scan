import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/toggle_button.dart';

class ToggleSectionWidget extends StatefulWidget {
  final String title;
  final List<bool> toggles;
  final Function(int index, bool value)? onToggleChanged;
  final bool isReadOnly;
  final bool isFullAccessOnly;

  const ToggleSectionWidget({
    super.key,
    required this.title,
    required this.toggles,
    this.onToggleChanged,
    this.isReadOnly = false,
    this.isFullAccessOnly = false,
  });

  @override
  State<ToggleSectionWidget> createState() => _ToggleSectionWidgetState();
}

class _ToggleSectionWidgetState extends State<ToggleSectionWidget> {
  final List<String> subtitles = ["Create", "View", "Edit", "Delete", "Allow"];
  late List<bool> _toggles;

  @override
  void initState() {
    super.initState();
    _toggles = List<bool>.from(widget.toggles);
  }

  @override
  void didUpdateWidget(ToggleSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.toggles != oldWidget.toggles) {
      _toggles = List<bool>.from(widget.toggles);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: ColorHelper.black4,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              // For full access only features, only index 4 (Allow/Full Access) is enabled
              // Indices 0-3 (Create, View, Edit, Delete) are restricted
              final isRestricted = widget.isFullAccessOnly && index != 4;

              return Column(
                children: [
                  if (isRestricted)
                    // Show red X for restricted permissions
                    Text(
                      '✕',
                      style: TextStyle(
                        color: ColorHelper.errorColor.withValues(alpha: 0.7),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    ToggleButton(
                      handleToggle: widget.isReadOnly
                          ? (_) {}
                          : (value) {
                              setState(() {
                                _toggles[index] = value;
                              });
                              widget.onToggleChanged?.call(index, value);
                            },
                      checked: _toggles[index],
                      innerCircleColor: ColorHelper.primaryColor,
                      size: 40,
                      isEnabled: !widget.isReadOnly,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    subtitles[index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: ColorHelper.grey4,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
