import 'package:flutter/material.dart';
import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';

/// Model class to represent a metric item
class MetricItem {
  final String title;
  final String iconAsset;
  final String Function(DashboardLoaded state) getValue;
  final Color color;
  final String? incidentStatusForTap;

  const MetricItem({
    required this.title,
    required this.iconAsset,
    required this.getValue,
    required this.color,
    this.incidentStatusForTap,
  });
}