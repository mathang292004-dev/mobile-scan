import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/widgets/dashboard/app_metric_card.dart';

class InvestigationTeamMemberMetricsWidget extends StatelessWidget {
  const InvestigationTeamMemberMetricsWidget({
    super.key,
    this.totalActiveCount = '--',
    this.inProgressCount = '--',
    this.resolvedCount = '--',
    this.selectedMetricIndex = 0,
    this.onTotalActiveTap,
    this.onInProgressTap,
    this.onResolvedTap,
  });

  final String totalActiveCount;
  final String inProgressCount;
  final String resolvedCount;
  final int selectedMetricIndex;
  final VoidCallback? onTotalActiveTap;
  final VoidCallback? onInProgressTap;
  final VoidCallback? onResolvedTap;

  @override
  Widget build(BuildContext context) {
    return AppMetricCard(
      titles: const [
        'Total Active Investigations',
        'In Progress',
        'Resolved Investigations'
      ],
      counts: [
        totalActiveCount,
        inProgressCount,
        resolvedCount,
      ],
      icons: [
        Image.asset(Assets.dashboardIconTotalIncidents),
        Image.asset(Assets.dashboardIconApproved),
        Image.asset(Assets.dashboardIconTLResolved),
      ],
      selectedIndex: selectedMetricIndex,
      onTaps: [
        onTotalActiveTap,
        onInProgressTap,
        onResolvedTap,
      ],
    );
  }
}
