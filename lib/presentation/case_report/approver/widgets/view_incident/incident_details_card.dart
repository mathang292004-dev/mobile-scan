import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';

import 'package:flutter/material.dart';

class IncidentDetailsCard extends StatefulWidget {
  final dynamic incidentOverview;
  final String imageAsset;
  final int rowSize;
  final bool isEditing;
  final Function(Map<String, dynamic> updatedData)? onSave;
  final VoidCallback? onChanged;

  const IncidentDetailsCard({
    super.key,
    this.incidentOverview,
    this.imageAsset = Assets.summaryIcon,
    this.rowSize = 2,
    this.isEditing = false,
    this.onSave,
    this.onChanged,
  });

  @override
  State<IncidentDetailsCard> createState() => IncidentDetailsCardState();
}

class IncidentDetailsCardState extends State<IncidentDetailsCard> {
  late Map<String, dynamic> _currentData;
  final Map<String, TextEditingController> _controllers = {};

  // Dropdown options for job, shore, and incidentLevel fields
  final Map<String, List<String>> _dropdownOptions = {
    'job': ['Onjob', 'Offjob'],
    'shore': ['Onshore', 'Offshore'],
    'incidentlevel': ['Low', 'Medium', 'High'],
  };

  @override
  void initState() {
    super.initState();
    _currentData = _toMap(widget.incidentOverview);
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant IncidentDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing) {
      return;
    }
    if (widget.incidentOverview != oldWidget.incidentOverview) {
      _currentData = _toMap(widget.incidentOverview);
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    _currentData.forEach((key, value) {
      if (key.toLowerCase() != 'summary') {
        final displayValue = value is Map && value.containsKey('value')
            ? value['value']
            : value;

        _controllers[key] = TextEditingController(
          text: displayValue?.toString() ?? '',
        );
      }
    });
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Map<String, dynamic> getUpdatedData() {
    final updatedData = <String, dynamic>{};
    _controllers.forEach((key, controller) {
      updatedData[key] = controller.text;
    });
    return updatedData;
  }

  Map<String, dynamic> _toMap(dynamic obj) {
    if (obj == null) return {};
    if (obj is Map<String, dynamic>) return Map.from(obj);
    try {
      return obj.toJson() as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (match) {
          return '${match.group(1)} ${match.group(2)}';
        })
        .replaceAll('_', ' ')
        .capitalize();
  }

  bool _isDropdownField(String key) {
    return _dropdownOptions.containsKey(key.toLowerCase()) ||
        key.toLowerCase() == 'incidentlevel';
  }

  @override
  Widget build(BuildContext context) {
    _currentData.removeWhere((key, value) => key.toLowerCase() == 'summary');
    final entries = _currentData.entries.toList();

    return entries.isNotEmpty
        ? Card(
            color: ColorHelper.white.withValues(alpha: 0.8),
            shadowColor: ColorHelper.transparent,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: List.generate(
                  (entries.length / widget.rowSize).ceil(),
                  (rowIndex) {
                    final startIndex = rowIndex * widget.rowSize;
                    final rowItems = <Widget>[];

                    for (int j = 0; j < widget.rowSize; j++) {
                      final index = startIndex + j;
                      if (index < entries.length) {
                        final entry = entries[index];
                        final value =
                            entry.value is Map &&
                                entry.value.containsKey('value')
                            ? entry.value['value']
                            : entry.value;

                        rowItems.add(
                          Expanded(
                            child: widget.isEditing
                                ? _buildEditField(
                                    key: entry.key.isNotEmpty
                                        ? entry.key
                                        : 'Unknown',
                                    controller: _controllers[entry.key]!,
                                  )
                                : _buildKeyValueRow(
                                    key: entry.key.isNotEmpty
                                        ? entry.key
                                        : 'Unknown',
                                    value:
                                        value ?? _controllers[entry.key]?.text,
                                    context: context,
                                  ),
                          ),
                        );
                        if (j < widget.rowSize - 1) {
                          rowItems.add(const SizedBox(width: 8));
                        }
                      } else {
                        rowItems.add(const Expanded(child: SizedBox()));
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: rowItems),
                    );
                  },
                ),
              ),
            ),
          )
        : const SizedBox();
  }

  Widget _buildKeyValueRow({
    required String key,
    required dynamic value,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatKey(key),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 12,
                  color: ColorHelper.textColorDefault,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.toString().isEmpty ? 'Not Specified' : value.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditField({
    required String key,
    required TextEditingController controller,
  }) {
    if (_isDropdownField(key)) {
      return _buildDropdownField(key: key, controller: controller);
    }

    // Regular text field
    return AppTextField(
      key: ValueKey('incident_field_$key'),
      controller: controller,
      label: _formatKey(key),
      fillColor: ColorHelper.white,
      onChanged: (value) {
        // Use a microtask to defer the state update until after the current frame
        Future.microtask(() {
          if (mounted) {
            widget.onChanged?.call();
          }
        });
      },
      maxLines: 3,
      minLines: 3,
    );
  }

  Widget _buildDropdownField({
    required String key,
    required TextEditingController controller,
  }) {
    final fieldKey = key.toLowerCase();
    final options =
        _dropdownOptions[fieldKey] ??
        (fieldKey == 'incidentlevel' ? _dropdownOptions['incidentlevel'] : []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatKey(key) == "Incidentlevel"
              ? "Incident classification"
              : _formatKey(key),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: ColorHelper.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            // Listen to controller changes so the dropdown rebuilds
            // when controller.text is updated programmatically.
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, textValue, _) {
                final currentValue =
                    textValue.text.isNotEmpty &&
                        (options?.contains(textValue.text) ?? false)
                    ? textValue.text
                    : (options?.isNotEmpty ?? false)
                    ? options!.first
                    : '';

                return DropdownButton<String>(
                  value: currentValue,
                  isExpanded: true,
                  items: (options ?? []).map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.text = newValue;
                      widget.onChanged?.call();
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }
}
