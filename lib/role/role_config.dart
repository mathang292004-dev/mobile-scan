import 'package:emergex/presentation/case_report/approver/cubit/case_approver_dashboard_cubit.dart';
import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/role/role_manager.dart';
import 'package:flutter/material.dart';
import 'package:emergex/di/app_di.dart';
import '../data/model/dashboard/metric_item.dart';
import '../helpers/nav_helper/nav_helper.dart';
import '../helpers/routes.dart';
import '../helpers/permission_helper.dart';

/// Configuration class that provides role-specific UI configurations
class RoleConfig {
  static final RoleConfig _instance = RoleConfig._internal();
  factory RoleConfig() => _instance;
  RoleConfig._internal();

  /// Get metric items based on current user permission
  List<MetricItem> getMetricItems(DashboardState state) {
    final isLoaded = state is DashboardLoaded;

    // Check if user has full access permission for Approval of Incident
    final bool hasFullAccess = PermissionHelper.hasFullAccessPermission(
      moduleName: "Incident Reporting & Monitoring",
      featureName: "Approval of EmergeX Case",
    );

    if (hasFullAccess) {
     return _getUserMetricItems(isLoaded, state);
    } else {
      // For users without full access, use manager/user metric items
      final roleManager = RoleManager();
      switch (roleManager.currentRole) {
        case UserRole.manager:
          return _getManagerMetricItems(isLoaded, state);
        case UserRole.user:
        case UserRole.admin:
          return _getUserMetricItems(isLoaded, state);
      }
    }
  }

  /// Get dashboard title based on role
  String getDashboardTitle() {
    final roleManager = RoleManager();
    switch (roleManager.currentRole) {
      case UserRole.admin:
        return 'Admin Dashboard';
      case UserRole.manager:
        return 'Manager Dashboard';
      case UserRole.user:
        return 'Dashboard';
    }
  }

  /// Get welcome message based on role
  String getWelcomeMessage(String? userName) {
    final roleManager = RoleManager();
    final name = userName ?? 'User';

    switch (roleManager.currentRole) {
      case UserRole.admin:
        return 'Welcome back, Admin $name';
      case UserRole.manager:
        return 'Welcome back, Manager $name';
      case UserRole.user:
        return 'Welcome back, $name';
    }
  }

  /// Check if user can report incidents
  bool canReportIncidents() {
    final roleManager = RoleManager();
    return roleManager.hasAnyRole([
      UserRole.user,
      UserRole.manager,
      UserRole.admin,
    ]);
  }

  /// Check if user can view all incidents
  bool canViewAllIncidents() {
    final roleManager = RoleManager();
    return roleManager.hasAnyRole([UserRole.admin, UserRole.manager]);
  }

  /// Check if user can approve incidents
  bool canApproveIncidents() {
    final roleManager = RoleManager();
    return roleManager.hasAnyRole([UserRole.admin, UserRole.manager]);
  }

  /// User role metric items
  List<MetricItem> _getUserMetricItems(bool isLoaded, DashboardState state) {
    return [
      MetricItem(
        title: TextHelper.totalIncidents,
        iconAsset: Assets.dashboardIconTotalIncidents,
        getValue: (state) => isLoaded ? '${state.totalIncidents}' : '--',
        color: ColorHelper.primaryColor,
        incidentStatusForTap: null,
      ),
      MetricItem(
        title: TextHelper.inProgress,
        iconAsset: Assets.dashboardapproveIconPending,
        getValue: (state) => isLoaded ? '${state.responseCount}' : '--',
        color: ColorHelper.successColor,
        incidentStatusForTap: 'inProgress',
      ),
      MetricItem(
        title: TextHelper.approvalPending,
        iconAsset: Assets.dashboardIconPending,
        getValue: (state) => isLoaded ? '${state.emergencyResponseTime}' : '--',
        color: ColorHelper.successColor,
        incidentStatusForTap: 'Pending Review',
      ),
      MetricItem(
        title: TextHelper.closed,
        iconAsset: Assets.dashboardIconResolved,
        getValue: (state) => isLoaded ? '${state.recoveryCount}' : '--',
        color: ColorHelper.successColor,
        incidentStatusForTap: 'closed',
      ),
    ];
  }

   
  /// Manager role metric items
  List<MetricItem> _getManagerMetricItems(bool isLoaded, DashboardState state) {
    return [
      MetricItem(
        title: TextHelper.totalIncidents,
        iconAsset: Assets.caseTypeIcon,
        getValue: (state) => isLoaded ? '${state.totalIncidents}' : '--',
        color: ColorHelper.primaryColor,
        incidentStatusForTap: null,
      ),
      MetricItem(
        title: TextHelper.inProgress,
        iconAsset: Assets.dashboardIconApproved,
        getValue: (state) => isLoaded ? '${state.responseCount}' : '--',
        color: ColorHelper.successColor,
        incidentStatusForTap: 'inProgress',
      ),
      MetricItem(
        title: TextHelper.approvalPending,
        iconAsset: Assets.dashboardIconPending,
        getValue: (state) => isLoaded ? '${state.emergencyResponseTime}' : '--',
        color: ColorHelper.successColor,
        incidentStatusForTap: 'Pending Review',
      ),
      MetricItem(
        title: TextHelper.closed,
        iconAsset: Assets.dashboardIconResolved,
        getValue: (state) => isLoaded ? '${state.recoveryCount}' : '--',
        color: ColorHelper.successColor,
        incidentStatusForTap: 'closed',
      ),
    ];
  }

  /// Handles tap on an incident/case card.
  ///
  /// [isApprover] tells the navigator which dashboard the tap came from:
  ///  - `true`  → Case Approver Dashboard (always sends to incident approval).
  ///  - `false` → Member Dashboard (route depends on case type / role).
  ///
  /// Each dashboard owns its own cubit, so the selected-metric index is read
  /// from the matching cubit's state — no more `PermissionHelper` branching.
  void handleIncidentCardNavigationAction(
    dynamic incident,
    BuildContext context, {
    bool isApprover = false,
  }) {
    // Drafts always go to the report screen, regardless of role.
    if (incident.status.toLowerCase() == 'draft') {
      openScreen(Routes.reportIncident, args: {'incidentId': incident.id});
      return;
    }

    if (isApprover) {
      // Approver flow: read the metric index from the approver cubit so the
      // approval screen opens on the correct tab.
      String initialDropdownValue = TextHelper.incident;
      final approverState = AppDI.caseApproverDashboardCubit.state;
      if (approverState is CaseApproverDashboardLoaded) {
        switch (approverState.selectedMetricIndex) {
          case 1:
            initialDropdownValue = TextHelper.intervention;
            break;
          case 2:
            initialDropdownValue = TextHelper.observation;
            break;
        }
      }
      openScreen(
        Routes.incidentApproval,
        args: {
          'incidentId': incident.id,
          'initialDropdownValue': initialDropdownValue,
          'isApprover': true,
        },
      );
      return;
    }

    // Member flow: route by case type, with a role-aware fallback.
    final roleManager = RoleManager();
    if (roleManager.currentRole == UserRole.manager) {
      openScreen(
        Routes.incidentReportDetails,
        args: {'incidentId': incident.id},
      );
      return;
    }

    if (incident.type == TextHelper.observation ||
        incident.type == TextHelper.intervention) {
      openScreen(
        Routes.incidentApproval,
        args: {
          'incidentId': incident.id,
          'initialDropdownValue': incident.type,
          'isEditRequired': false,
        },
      );
      return;
    }

    openScreen(
      Routes.incidentReportDetails,
      args: {'incidentId': incident.id},
    );
  }
}
