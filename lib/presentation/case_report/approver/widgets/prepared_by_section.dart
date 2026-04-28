import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:flutter/material.dart';

String _formatDate(String? dateString) {
  if (dateString == null) return "Not specified";

  try {
    final date = DateTime.parse(dateString);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  } catch (e) {
    return dateString;
  }
}

class PreparedBySection extends StatelessWidget {
  final IncidentDetails? incident;
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);

  PreparedBySection({super.key, this.incident});

  List<Map<String, String>> get _preparedByFields {
    final preparedBy = incident?.preparedBy;
    return [
      {
        'label': "Name",
        'value': preparedBy?['name']?.toString() ?? "Not specified",
      },
      {
        'label': "Date",
        'value': _formatDate(preparedBy?['date']?.toString()),
      },
      {
        'label': "Contact No.",
        'value': _resolvePhone(preparedBy?['phone']),
      },
      {
        'label': "Signature",
        'value': preparedBy?['role']?.toString() ?? "Not specified",
      },
    ];
  }

  /// `phone` may be:
  ///  - a plain `String` (new API: `"+65 9173 7708"`)
  ///  - a `Map` with a `mobile_ph` list (legacy API)
  ///  - `null`
  String _resolvePhone(dynamic phone) {
    if (phone is String) {
      return phone.isEmpty ? 'Not specified' : phone;
    }
    if (phone is Map) {
      final mobileList = phone['mobile_ph'];
      if (mobileList is List && mobileList.isNotEmpty) {
        return mobileList.first?.toString() ?? 'Not specified';
      }
    }
    return 'Not specified';
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
                  "Prepared By",
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
      children: _preparedByFields.map((field) {
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ColorHelper.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
