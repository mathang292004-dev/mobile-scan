import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:flutter/material.dart';

class ProjectManagerSection extends StatelessWidget {
  final IncidentDetails? incident;
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);

  ProjectManagerSection({super.key, this.incident});

  List<Map<String, String>> get _projectManagerFields {
    final approver = incident?.caseApprover;

    final roles = approver?['roles'];
    final roleText = roles is List && roles.isNotEmpty
        ? roles.map((r) => r.toString()).join(', ')
        : 'Not specified';

    return [
      {
        'label': TextHelper.nameLabel,
        'value': approver?['name']?.toString() ?? 'Not specified',
      },
      {
        'label': TextHelper.emailLabel,
        'value': approver?['email']?.toString() ?? 'Not specified',
      },
      {
        'label': TextHelper.contactLabel,
        'value': approver?['contactNo']?.toString() ?? 'Not specified',
      },
      {
        'label': TextHelper.role,
        'value': roleText,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      radius: 28,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _isExpanded.value = !_isExpanded.value,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TextHelper.projectManager,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorHelper.textSecondary,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _isExpanded,
                  builder: (context, isExpanded, child) {
                    return AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ColorHelper.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isExpanded,
            builder: (context, isExpanded, child) {
              return AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _buildContent(context),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
                sizeCurve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: _projectManagerFields.map((field) {
        return _buildFieldItem(
          context: context,
          label: field['label']!,
          value: field['value']!,
        );
      }).toList(),
    );
  }

  Widget _buildFieldItem({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.green.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ColorHelper.textSecondary),
          ),
        ],
      ),
    );
  }
}
