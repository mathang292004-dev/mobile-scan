import 'package:flutter/material.dart';

/// UI Model for Task Card Widget
/// Separated from screen file to follow clean architecture
class UiTaskModel {
  final String title;
  final String code;
  final String date;
  final String description;
  final TextStyle? timerStyle;
  final String timer;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final Color timerColor;
  final String? startedAt;
  final DateTime? startedAtDateTime;
  final DateTime? pausedAtDateTime;
  final DateTime? completedAtDateTime;
  final int? totalPausedTime;

  const UiTaskModel({
    required this.title,
    required this.code,
    required this.date,
    required this.description,
    this.timerStyle,
    required this.timer,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.timerColor,
    this.startedAt,
    this.startedAtDateTime,
    this.pausedAtDateTime,
    this.completedAtDateTime,
    this.totalPausedTime,
  });
}
