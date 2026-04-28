import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:emergex/presentation/case_report/utils/case_report_formatter_utils.dart';
import 'package:flutter/material.dart';

import '../approver/cubit/case_approver_dashboard_cubit.dart';

/// Dashboard-specific business logic extracted from screen widgets.
///
/// Encapsulates metric-tap, search, pagination, and reload operations
/// that were previously inline in [DashboardScreen].
class CaseReportDashboardUtils {
  CaseReportDashboardUtils._();

  // ---------------------------------------------------------------------------
  // Member dashboard helpers
  // ---------------------------------------------------------------------------

  /// Handles metric-card tap in the member dashboard.
  static void handleMemberMetricTap(
    DashboardLoaded state,
    dynamic item,
    int index,
  ) {
    final currentState = AppDI.dashboardCubit.state;
    Map<String, String>? daterange;
    if (currentState is DashboardLoaded) {
      daterange = CaseReportFormatterUtils.buildDateRangeMap(
        currentState.fromDate,
        currentState.toDate,
      );
    }
    AppDI.dashboardCubit.loadIncidents(
      page: 1,
      limit: 10,
      incidentStatus: item.incidentStatusForTap,
      search: state.searchQuery?.isNotEmpty == true ? state.searchQuery : null,
      daterange: daterange,
      selectedMetricIndex: index,
    );
  }

  /// Handles search in the member dashboard.
  static void performMemberSearch(DashboardCubit cubit, String value) {
    final currentState = cubit.state;
    if (currentState is DashboardLoaded) {
      final daterange = CaseReportFormatterUtils.buildDateRangeMap(
        currentState.fromDate,
        currentState.toDate,
      );
      cubit.loadIncidents(
        page: 1,
        limit: 10,
        search: value.isNotEmpty ? value : null,
        incidentStatus: currentState.incidentStatus,
        daterange: daterange,
        selectedMetricIndex: currentState.selectedMetricIndex,
      );
    }
  }

  /// Handles page change in the member dashboard.
  static void performMemberPageChange(DashboardLoaded state, int page) {
    final daterange = CaseReportFormatterUtils.buildDateRangeMap(
      state.fromDate,
      state.toDate,
    );
    AppDI.dashboardCubit.loadIncidents(
      page: page,
      limit: 10,
      incidentStatus: state.incidentStatus,
      search: state.searchQuery?.isNotEmpty == true ? state.searchQuery : null,
      daterange: daterange,
      selectedMetricIndex: state.selectedMetricIndex,
    );
  }

  /// Reloads member dashboard incidents and clears the search bar.
  static Future<void> reloadMemberIncidents(
    GlobalKey<SearchBarWidgetState> searchBarKey,
  ) async {
    searchBarKey.currentState?.clearSearchBar();
    final currentState = AppDI.dashboardCubit.state;
    if (currentState is DashboardLoaded) {
      final daterange = CaseReportFormatterUtils.buildDateRangeMap(
        currentState.fromDate,
        currentState.toDate,
      );
      AppDI.dashboardCubit.loadIncidents(
        page: 1,
        limit: 10,
        incidentStatus: currentState.incidentStatus,
        daterange: daterange,
        selectedMetricIndex: currentState.selectedMetricIndex,
      );
    } else {
      AppDI.dashboardCubit.loadIncidents(
        page: 1,
        limit: 10,
        selectedMetricIndex: 0,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Approver dashboard helpers
  // ---------------------------------------------------------------------------

  /// Handles metric-card tap in the approver dashboard.
  static void handleApproverMetricTap(int index, String? statusFilter) {
    final cubit = AppDI.caseApproverDashboardCubit;
    final currentState = cubit.state;

    Map<String, String>? daterange;

    if (currentState is CaseApproverDashboardLoaded) {
      if (currentState.fromDate != null && currentState.toDate != null) {
        daterange = {
          'from': cubit.formatDateForAPI(currentState.fromDate!),
          'to': cubit.formatEndOfDayForAPI(currentState.toDate!),
        };
      }
    }

    AppDI.caseApproverDashboardCubit.loadIncidents(
      page: 1,
      limit: 10,
      incidentStatus: statusFilter,
      daterange: daterange,
      selectedMetricIndex: index,
    );
  }

  /// Reloads approver dashboard and clears search bar.
  static Future<void> reloadApproverDashboard(
    GlobalKey<SearchBarWidgetState> searchBarKey,
  ) async {
    searchBarKey.currentState?.clearSearchBar();
    await AppDI.caseApproverDashboardCubit.loadInitialData();
  }
}
