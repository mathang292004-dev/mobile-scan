import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

enum TabSize { expanded, fixed }

class CustomTabBar extends StatefulWidget {
  final List<String> tabs;
  final List<Widget> tabContents;
  final ValueChanged<int>? onChanged;
  final TabSize tabSize;
  final double? fixedTabWidth;
  final Widget Function(BuildContext, int, bool)? tabBuilder;
  final Widget? customTabBar;
  final int initialIndex;

  const CustomTabBar({
    super.key,
    required this.tabs,
    required this.tabContents,
    this.onChanged,
    this.tabSize = TabSize.expanded,
    this.fixedTabWidth,
    this.tabBuilder,
    this.customTabBar,
    this.initialIndex = 0,
  });

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.customTabBar ?? _buildDefaultTabBar(),
        const SizedBox(height: 16),
        _buildTabContent(),
      ],
    );
  }

  Widget _buildDefaultTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ColorHelper.surfaceColor.withValues(alpha: 0.7),
        border: Border.all(color: ColorHelper.surfaceColor),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: List.generate(widget.tabs.length, (index) {
          final isSelected = index == _selectedIndex;
          final tabWidget = widget.tabBuilder != null
              ? widget.tabBuilder!(context, index, isSelected)
              : _buildDefaultTabItem(index, isSelected);
          return widget.tabSize == TabSize.expanded
              ? Expanded(child: tabWidget)
              : SizedBox(
                  width: widget.fixedTabWidth ?? 120, child: tabWidget);
        }),
      ),
    );
  }

  Widget _buildDefaultTabItem(int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        widget.onChanged?.call(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : ColorHelper.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            widget.tabs[index],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isSelected ? Colors.white : ColorHelper.textTertiary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (widget.tabContents.isEmpty) return const SizedBox.shrink();
    return Stack(
      children: widget.tabContents.asMap().entries.map((entry) {
        return Offstage(
          offstage: _selectedIndex != entry.key,
          child: entry.value,
        );
      }).toList(),
    );
  }
}
