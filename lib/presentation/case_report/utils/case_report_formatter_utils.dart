import 'dart:math';

import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

/// Pure formatting / display utilities for the case_report module.
///
/// Every method is static and side-effect free.
class CaseReportFormatterUtils {
  CaseReportFormatterUtils._();

  // ---------------------------------------------------------------------------
  // Date formatting
  // ---------------------------------------------------------------------------

  /// Formats [date] as `DD/MM/YYYY`.
  static String formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  /// Converts a [DateTime] to the ISO-like string used by the dashboard API.
  ///
  /// Example output: `2025-03-05T00:00:00.000Z`
  static String toApiDateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00.000Z';

  /// Builds the `{from, to}` date-range map expected by `loadIncidents`.
  ///
  /// Returns `null` when either date is `null`.
  static Map<String, String>? buildDateRangeMap(
    DateTime? from,
    DateTime? to,
  ) {
    if (from == null || to == null) return null;
    return {
      'from': toApiDateString(from),
      'to': toApiDateString(to),
    };
  }

  // ---------------------------------------------------------------------------
  // File-size formatting
  // ---------------------------------------------------------------------------

  /// Human-readable file size (e.g. `1.23 MB`, `456 KB`).
  ///
  /// Uses a simple KB/MB threshold.
  static String formatFileSize(int? bytes) {
    const int kb = 1024;
    const int mb = 1024 * 1024;

    if (bytes == null || bytes <= 0) return '0 B';
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    } else if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(2)} KB';
    } else {
      return '$bytes B';
    }
  }

  /// Human-readable file size with auto-scaled suffix (B / KB / MB / GB / TB).
  static String formatFileSizeAuto(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // ---------------------------------------------------------------------------
  // Filename helpers
  // ---------------------------------------------------------------------------

  /// Decodes a URL-encoded [fileName].
  static String decodeFileName(String fileName) {
    if (fileName.isEmpty) return '';
    try {
      return Uri.decodeComponent(fileName);
    } catch (_) {
      return fileName;
    }
  }

  /// Returns a readable filename from [fileName] or [fileUrl] fallback.
  static String resolveFileName(String fileName, String? fileUrl) {
    if (fileName.isNotEmpty) return decodeFileName(fileName);
    if (fileUrl != null && fileUrl.isNotEmpty) {
      return decodeFileName(fileUrl.split('/').last);
    }
    return 'Unnamed File';
  }

  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  /// Maps a case [status] string to `(textColor, bgColor)`.
  static (Color, Color) getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return (ColorHelper.resolvedColor, ColorHelper.primaryLight4);
      case 'pending':
        return (ColorHelper.pendingColor, ColorHelper.pendingBackgroundColor);
      case 'inprogress':
        return (
          ColorHelper.timerInProgressColor,
          ColorHelper.inProgressBackgroundColor,
        );
      case 'active' || 'approved':
        return (ColorHelper.successColor, ColorHelper.primaryLight4);
      case 'draft':
        return (ColorHelper.draftColor, ColorHelper.draftBackgroundColor);
      case 'ert assigned':
        return (ColorHelper.assignedColor, ColorHelper.assignedBackgroundColor);
      default:
        return (ColorHelper.resolvedColor, ColorHelper.primaryLight4);
    }
  }

  // ---------------------------------------------------------------------------
  // Map / data helpers
  // ---------------------------------------------------------------------------

  /// Safely converts [obj] to `Map<String, dynamic>`.
  static Map<String, dynamic> toMap(dynamic obj) {
    if (obj == null) return {};
    if (obj is Map<String, dynamic>) return obj;
    if (obj is Map) return Map<String, dynamic>.from(obj);
    try {
      return obj.toJson() as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Returns `true` if [data] contains at least one non-null, non-empty,
  /// non-placeholder (`--`) value.
  static bool hasMeaningfulData(Map<String, dynamic> data) {
    return data.values.any(
      (value) =>
          value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().trim() != '--',
    );
  }
}
