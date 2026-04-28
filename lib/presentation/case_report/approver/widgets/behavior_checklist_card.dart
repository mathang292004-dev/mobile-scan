import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/toggle_button.dart';
import 'package:emergex/utils/text_format.dart';
import 'package:flutter/material.dart';

class BehaviorChecklistCard extends StatefulWidget {
  final String title;
  final Map<String, BehaviourItem?> behaviors;
  final Map<String, BehaviourItem?> originalBehaviors;
  final bool isEditing;
  final VoidCallback? onChanged;

  /// Decide whether to show Safe and/or AtRisk columns
  final bool showSafe;
  final bool showAtRisk;

  const BehaviorChecklistCard({
    super.key,
    required this.title,
    required this.behaviors,
    required this.originalBehaviors,
    this.isEditing = false,
    this.onChanged,
    this.showSafe = true,
    this.showAtRisk = true,
  });

  @override
  State<BehaviorChecklistCard> createState() => BehaviorChecklistCardState();
}

class BehaviorChecklistCardState extends State<BehaviorChecklistCard> {
  final ValueNotifier<bool> _isExpandedNotifier = ValueNotifier<bool>(false);
  late final ValueNotifier<Map<String, BehaviourItem?>> _behaviorsNotifier;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the behaviors to manage state
    _behaviorsNotifier =
        ValueNotifier<Map<String, BehaviourItem?>>(Map.from(widget.behaviors));
  }

  @override
  void dispose() {
    _isExpandedNotifier.dispose();
    _behaviorsNotifier.dispose();
    super.dispose();
  }

  Map<String, BehaviourItem?> _deepCopyBehaviors(
    Map<String, BehaviourItem?> behaviors,
  ) {
    Map<String, BehaviourItem?> copy = {};
    for (var entry in behaviors.entries) {
      if (entry.value != null) {
        copy[entry.key] = BehaviourItem(
          safe: entry.value!.safe,
          atRisk: entry.value!.atRisk,
        );
      } else {
        copy[entry.key] = BehaviourItem();
      }
    }
    return copy;
  }

  void _handleToggle(String key, bool isSafeToggle, bool newValue) {
    if (!widget.isEditing) return;
    final currentMap = Map<String, BehaviourItem?>.from(_behaviorsNotifier.value);
    final item = currentMap[key];
    if (item != null) {
      if (isSafeToggle) {
        item.safe = newValue;
        // If Safe is set to true, automatically set At Risk to false
        if (newValue == true) {
          item.atRisk = false;
        }
      } else {
        item.atRisk = newValue;
        // If At Risk is set to true, automatically set Safe to false
        if (newValue == true) {
          item.safe = false;
        }
      }
    }
    // Reassign to trigger ValueNotifier listeners
    _behaviorsNotifier.value = currentMap;
    widget.onChanged?.call();
  }

  Map<String, dynamic>? getUpdatedBehaviors() {
    Map<String, dynamic> result = {};
    for (var entry in _behaviorsNotifier.value.entries) {
      if (entry.value != null) {
        result[entry.key] = {
          'safe': entry.value!.safe ?? false,
          'atRisk': entry.value!.atRisk ?? false,
        };
      }
    }
    return result;
  }

  void resetToOriginalData() {
    _behaviorsNotifier.value = _deepCopyBehaviors(widget.originalBehaviors);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        ValueListenableBuilder<bool>(
          valueListenable: _isExpandedNotifier,
          builder: (context, isExpanded, _) {
            return InkWell(
              onTap: () =>
                  _isExpandedNotifier.value = !_isExpandedNotifier.value,
              child: Container(
                margin: const EdgeInsets.all(8.0),
                padding: const EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: 8.0,
                ),
                decoration: BoxDecoration(
                  color: ColorHelper.white,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        TextFormat.getTextFormt(widget.title),
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorHelper.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: ColorHelper.appBarblur,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Collapsible Body
        ValueListenableBuilder<bool>(
          valueListenable: _isExpandedNotifier,
          builder: (context, isExpanded, _) {
            if (!isExpanded) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16, 16.0, 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sub-header
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Critical Safety Behaviours',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (widget.showSafe)
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text(
                                'Safe',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        if (widget.showAtRisk)
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text(
                                'At Risk',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // List of behaviors
                  ValueListenableBuilder<Map<String, BehaviourItem?>>(
                    valueListenable: _behaviorsNotifier,
                    builder: (context, currentBehaviors, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: currentBehaviors.entries.map((entry) {
                          final item = entry.value ?? BehaviourItem();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 24.0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14.0),
                                color: ColorHelper.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      TextFormat.getTextFormt(entry.key),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                  if (widget.showSafe)
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: ToggleButton(
                                          checked: item.safe ?? false,
                                          handleToggle: widget.isEditing
                                              ? (newValue) => _handleToggle(
                                                    entry.key,
                                                    true,
                                                    newValue,
                                                  )
                                              : (_) {},
                                          innerCircleColor:
                                              ColorHelper.successColor,
                                          isEnabled: widget.isEditing,
                                        ),
                                      ),
                                    ),
                                  if (widget.showAtRisk)
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: ToggleButton(
                                          checked: item.atRisk ?? false,
                                          handleToggle: widget.isEditing
                                              ? (newValue) => _handleToggle(
                                                    entry.key,
                                                    false,
                                                    newValue,
                                                  )
                                              : (_) {},
                                          innerCircleColor:
                                              ColorHelper.successColor,
                                          isEnabled: widget.isEditing,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
