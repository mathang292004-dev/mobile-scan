import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/ert/er_team_approver/cubit/er_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';

/// Utility class for ER Approver filter operations
class ErApproverFilterUtils {
  /// Get current search text from search bar or cubit state
  static String? getCurrentSearchTextFromSearchBar(BuildContext context) {
    try {
      final searchBarState = context.findAncestorStateOfType<SearchBarWidgetState>();
      final searchText = searchBarState?.getSearchBarText();
      if (searchText?.isNotEmpty ?? false) {
        return searchText;
      }
    } catch (e) {
      // Ignore
    }

    final currentSearch = AppDI.erTeamApproverDashboardCubit.state.filters?.search;
    return (currentSearch?.trim().isNotEmpty ?? false) ? currentSearch : null;
  }

  /// Apply filters to ER Team Approver dashboard
  static void applyFilters(BuildContext context, ErApproverFilterState filterState) {
    final approverCubit = AppDI.erTeamApproverDashboardCubit;
    final currentSearchText = getCurrentSearchTextFromSearchBar(context);

    String? searchValue = currentSearchText?.trim();
    if (searchValue?.isEmpty ?? true) {
      searchValue = null;
    }

    // Build date range map for API
    Map<String, String>? daterange;
    if (filterState.fromDate != null || filterState.toDate != null) {
      daterange = {
        'from': formatDate(filterState.fromDate),
        'to': formatDate(filterState.toDate),
      };
    }

    approverCubit.applyFilters(
      reportedBy: filterState.reportedBy?.trim().isNotEmpty == true
          ? filterState.reportedBy!.trim()
          : null,
      department: filterState.department,
      search: searchValue,
      daterange: daterange,
    );

    back();
  }

  /// Get initial filter state from applied filters
  static ErApproverFilterState getInitialFilterState() {
    final appliedFilters = AppDI.erTeamApproverDashboardCubit.state.filters;

    if (appliedFilters == null) {
      return ErApproverFilterState.initial();
    }

    DateTime? fromDate;
    DateTime? toDate;

    if (appliedFilters.daterange != null) {
      final fromStr = appliedFilters.daterange!['from'];
      final toStr = appliedFilters.daterange!['to'];

      if (fromStr != null && fromStr.isNotEmpty) {
        fromDate = parseDateFromString(fromStr);
      }
      if (toStr != null && toStr.isNotEmpty) {
        toDate = parseDateFromString(toStr);
      }
    }

    return ErApproverFilterState(
      fromDate: fromDate,
      toDate: toDate,
      reportedBy: appliedFilters.reportedBy,
      department: appliedFilters.department,
    );
  }

  /// Format date to YYYY-MM-DD string
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Parse date from string (supports multiple formats)
  static DateTime? parseDateFromString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Try parsing YYYY-MM-DD format
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }

      // Try parsing DD/MM/YYYY format
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      // Return null if parsing fails
    }

    return null;
  }

  /// Show date picker dialog
  static Future<void> showApproverDatePicker({
    required BuildContext context,
    required Function(DateTime) onDateSelected,
    DateTime? initialDate,
    bool isFromDate = true,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final now = DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);

    // Determine initial date
    DateTime displayDate = initialDate ?? now;

    // Restrict date ranges
    if (isFromDate && toDate != null) {
      lastDate = toDate;
      if (displayDate.isAfter(toDate)) {
        displayDate = toDate;
      }
    } else if (!isFromDate && fromDate != null) {
      firstDate = fromDate;
      if (displayDate.isBefore(fromDate)) {
        displayDate = fromDate;
      }
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: displayDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorHelper.primaryColor,
              onPrimary: ColorHelper.white,
              surface: ColorHelper.white,
              onSurface: ColorHelper.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      onDateSelected(selectedDate);
    }
  }
}
