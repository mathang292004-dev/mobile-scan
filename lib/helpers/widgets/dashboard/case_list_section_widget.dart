import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/dashboard/case_dashboard_card_widget.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:flutter/material.dart';

/// Data model for a single case item in the list.
class CaseListItem {
  final String caseId;
  final String status;
  final String? severityLevel;
  final String? caseType;
  final String? date;

  const CaseListItem({
    required this.caseId,
    required this.status,
    this.severityLevel,
    this.caseType,
    this.date,
  });
}

/// A reusable case list section widget matching the Figma design.
///
/// Contains:
/// - Title row with optional action icon
/// - Search bar + filter button
/// - List of [CaseDashboardCardWidget] cards
/// - Pagination widget slot
///
/// Usage:
/// ```dart
/// CaseListSectionWidget(
///   title: TextHelper.emergexCase,
///   searchBarKey: _searchBarKey,
///   items: incidents.map((i) => CaseListItem(...)).toList(),
///   onSearchChanged: (value) => cubit.search(value),
///   onFilterTap: () => showFilterDialog(),
///   onItemTap: (index) => navigateToDetail(incidents[index]),
///   onAuditTap: (index) => openAuditLog(incidents[index]),
///   paginationWidget: PaginationControls(),
/// );
/// ```
class CaseListSectionWidget extends StatefulWidget {
  final String title;
  final GlobalKey<SearchBarWidgetState>? searchBarKey;
  final List<CaseListItem> items;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterTap;
  final ValueChanged<int>? onItemTap;
  final ValueChanged<int>? onAuditTap;
  final VoidCallback? onActionTap;
  final Widget? paginationWidget;
  final String? emptyMessage;
  final bool isExpanded;

  const CaseListSectionWidget({
    super.key,
    required this.title,
    required this.items,
    this.searchBarKey,
    this.onSearchChanged,
    this.onFilterTap,
    this.onItemTap,
    this.onAuditTap,
    this.onActionTap,
    this.paginationWidget,
    this.emptyMessage,
    this.isExpanded = false,
  });

  @override
  State<CaseListSectionWidget> createState() => _CaseListSectionWidgetState();
}

class _CaseListSectionWidgetState extends State<CaseListSectionWidget> {
  final ScrollController _scrollController = ScrollController();
  double _scrollFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) {
      if (_scrollFraction != 0.0) setState(() => _scrollFraction = 0.0);
      return;
    }
    final fraction = (_scrollController.offset / pos.maxScrollExtent).clamp(0.0, 1.0);
    if (fraction != _scrollFraction) setState(() => _scrollFraction = fraction);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      alpha: 0.4,
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(context),
          const SizedBox(height: 10),
          _buildSearchRow(context),
          const SizedBox(height: 12),
          if (widget.items.isEmpty)
            _buildEmptyState(context)
          else
            _buildList(),
          if (widget.paginationWidget != null) ...[
            const SizedBox(height: 16),
            Center(child: widget.paginationWidget!),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: ColorHelper.black5,
                letterSpacing: -0.2,
              ),
        ),
        GestureDetector(
          onTap: widget.onActionTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorHelper.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(109),
              border: Border.all(
                color: ColorHelper.white,
                width: 1,
              ),
            ),
            child: Image.asset(
              widget.isExpanded
                  ? Assets.compressDashboard
                  : Assets.expandDashboard,
              width: 12,
              height: 12,
              color: ColorHelper.black5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SearchBarWidget(
            key: widget.searchBarKey,
            prefixIcon: Icons.search,
            incidentSection: true,
              hintText: "Search",
            onChanged: widget.onSearchChanged,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: widget.onFilterTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: ColorHelper.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                Assets.funnelIcon,
                color: ColorHelper.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (widget.isExpanded) {
      return ListView.separated(
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        itemBuilder: (context, index) => _buildCard(index),
      );
    }

    // Graph view: constrained height showing ~2 cards with custom scrollbar
    const double listHeight = 200.0;
    const double scrollbarWidth = 8.0;
    const double indicatorHeight = 32.0;
    const double trackHeight = listHeight;

    final indicatorTop = _scrollFraction * (trackHeight - indicatorHeight);

    return SizedBox(
      height: listHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              physics: const BouncingScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (context, index) => _buildCard(index),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: scrollbarWidth,
            height: trackHeight,
            decoration: BoxDecoration(
              color: ColorHelper.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: ColorHelper.white, width: 0.5),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: indicatorTop,
                  left: 1,
                  right: 1,
                  child: Container(
                    height: indicatorHeight,
                    decoration: BoxDecoration(
                      color: ColorHelper.primaryColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final item = widget.items[index];
    return CaseDashboardCardWidget(
      caseId: item.caseId,
      status: item.status,
      severityLevel: item.severityLevel,
      caseType: item.caseType,
      date: item.date,
      onTap: widget.onItemTap != null ? () => widget.onItemTap!(index) : null,
      onAuditTap: widget.onAuditTap != null ? () => widget.onAuditTap!(index) : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: ColorHelper.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage ?? TextHelper.noDataAvailable,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
