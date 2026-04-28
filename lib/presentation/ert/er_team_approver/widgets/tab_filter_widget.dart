import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

/// Tab Filter Widget
/// Shows filter tabs for All, Verified, Not Verified, Rejected
class TabFilterWidget extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onTabChanged;

  const TabFilterWidget({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        border: Border.all(color: Colors.white, width: 0.5),
        borderRadius: BorderRadius.circular(44),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab(TextHelper.tabAll, context),
          const SizedBox(width: 4),
          _buildTab(TextHelper.tabVerified, context),
          const SizedBox(width: 4),
          _buildTab(TextHelper.tabNotVerified, context),
          const SizedBox(width: 4),
          _buildTab(TextHelper.tabRejected, context),
        ],
      ),
    );
  }

  Widget _buildTab(String label, BuildContext context) {
    final isSelected = selectedTab == label;

    return GestureDetector(
      onTap: () => onTabChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ColorHelper.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(84),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : ColorHelper.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
