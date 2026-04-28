import 'package:emergex/presentation/investigation/utils/date_time_formatter.dart';
import 'package:emergex/presentation/investigation/utils/status_color_helper.dart';
import 'package:flutter/material.dart';

/// Helper class for task-related operations
/// Extracted from UI files to follow clean architecture
class InvestigationTaskHelper {
  /// Get status color for task
  static Color getStatusColor(String? status) {
    return InvestigationStatusColorHelper.getStatusColor(status ?? '');
  }

  /// Format task date
  static String formatTaskDate(DateTime? date) {
    return InvestigationDateTimeFormatter.formatDate(date);
  }

  /// Get month name from month number
  static String getMonthName(int month) {
    return InvestigationDateTimeFormatter.getMonthName(month);
  }

  /// Format time taken (timeTaken is in seconds from the API)
  static String formatTimeTaken(String? timeTaken) {
    return InvestigationDateTimeFormatter.formatTimeTakenAsDuration(timeTaken);
  }

  /// Format duration in seconds
  static String formatDuration(int seconds) {
    return InvestigationDateTimeFormatter.formatDuration(seconds);
  }

  /// Get file icon based on file extension
  static String getFileIcon(String fileName) {
    final lowerFileName = fileName.toLowerCase();
    if (lowerFileName.endsWith('.jpg') ||
        lowerFileName.endsWith('.jpeg') ||
        lowerFileName.endsWith('.png')) {
      return 'image';
    }
    return 'document';
  }

  /// Get status background color for task card
  static Color getStatusBackgroundColor(String? status) {
    return InvestigationStatusColorHelper.getStatusBackgroundColor(
      status ?? '',
    );
  }

  /// Get status text color for task card
  static Color getStatusTextColor(String? status) {
    return InvestigationStatusColorHelper.getStatusColor(status ?? '');
  }

  static Color getStatusTimerColor(String? status) {
    return InvestigationStatusColorHelper.getTimerColor(status ?? '');
  }
}
