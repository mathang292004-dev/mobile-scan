import 'package:emergex/data/model/user_role_permission/user_permissions_response.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/routes.dart';

/// Helper class for checking user permissions
///
/// Structure: Module -> Feature -> Permission Type
/// Example: "Client" -> "Projects" -> "delete"
///
/// Dashboard Navigation Logic:
/// The dashboard routing is permission-based, not role-based.
/// The first module with fullAccess = true determines the dashboard to navigate to.
/// This matches the web application behavior exactly.
class PermissionHelper {
  /// Map of module names to their corresponding dashboard routes
  /// Note: 'ERT Team Leader' is handled separately in getFirstAccessibleDashboardRoute
  /// based on feature-level permissions (Task Management → My Tasks, Member Management → ER Team Tasks)
  static const Map<String, String> _moduleToDashboardRoute = {
    'ERT Team Member': Routes.erTeamMemberScreen,
    'ER Team Approval': Routes.erTeamApproverScreen,
    'Incident Reporting & Monitoring': Routes.homeScreen,
  };

  /// List of dashboard module names in fallback priority order
  /// Used when no module has fullAccess = true
  static const List<String> _dashboardModulesFallbackOrder = [
    'Incident Reporting & Monitoring',
    'ERT Team Leader',
    'ERT Team Member',
    'ER Team Approval',
  ];

  /// Check if user has a specific permission
  ///
  /// [moduleName] - The name of the module (e.g., "Client", "Incident Reporting & Monitoring")
  /// [featureName] - Optional. The name of the feature (e.g., "Projects", "Role Management").
  ///                 If null, checks if ANY feature in the module has the permission
  /// [permissionType] - The type of permission to check: 'create', 'view', 'edit', 'delete', or 'fullAccess'
  ///
  /// Example:
  /// ```dart
  /// // Check delete permission for "Projects" feature in "Client" module
  /// PermissionHelper.hasPermission(
  ///   moduleName: "Client",
  ///   featureName: "Projects",
  ///   permissionType: "delete",
  /// )
  /// ```
  ///
  /// Returns true if user has the permission, false otherwise
  static bool hasPermission({
    required String moduleName,
    String? featureName,
    required String permissionType,
  }) {
    final userPermissions = AppDI.emergexAppCubit.state.userPermissions;
    if (userPermissions == null) return false;

    return userPermissions.permissions.any(
      (rolePermission) => rolePermission.permissions.any((modulePermission) {
        if (modulePermission.module != moduleName) return false;

        return modulePermission.features.any((feature) {
          // If featureName is specified, check only that feature
          if (featureName != null && feature.name != featureName) {
            return false;
          }

          // Check the specific permission type
          switch (permissionType) {
            case 'create':
              return feature.permissions.create == true ||
                  feature.permissions.fullAccess == true;
            case 'view':
              return feature.permissions.view == true ||
                  feature.permissions.fullAccess == true;
            case 'edit':
              return feature.permissions.edit == true ||
                  feature.permissions.fullAccess == true;
            case 'delete':
              return feature.permissions.delete == true ||
                  feature.permissions.fullAccess == true;
            case 'fullAccess':
              return feature.permissions.fullAccess == true;
            default:
              return false;
          }
        });
      }),
    );
  }

  /// Convenience method to check any permission type
  ///
  /// [moduleName] - The module name (e.g., "Client")
  /// [featureName] - Optional. The feature name (e.g., "Projects")
  /// [permissionType] - The permission type: 'create', 'view', 'edit', 'delete', or 'fullAccess'
  ///
  /// Example:
  /// ```dart
  /// PermissionHelper.hasCheckPermission(
  ///   moduleName: "Client",
  ///   featureName: "Projects",
  ///   permissionType: "delete",
  /// )
  /// ```
  static bool hasCheckPermission({
    required String moduleName,
    String? featureName,
    required String permissionType,
  }) {
    return hasPermission(
      moduleName: moduleName,
      featureName: featureName,
      permissionType: permissionType,
    );
  }

  /// Check if user has delete permission
  ///
  /// [moduleName] - The module name (e.g., "Client")
  /// [featureName] - Optional. The feature name (e.g., "Projects")
  ///
  /// Example:
  /// ```dart
  /// PermissionHelper.hasDeletePermission(
  ///   moduleName: "Client",
  ///   featureName: "Projects",
  /// )
  /// ```
  static bool hasDeletePermission({
    required String moduleName,
    String? featureName,
  }) {
    return hasPermission(
      moduleName: moduleName,
      featureName: featureName,
      permissionType: 'delete',
    );
  }

  /// Check if user has create permission
  ///
  /// [moduleName] - The module name (e.g., "Client")
  /// [featureName] - Optional. The feature name (e.g., "Projects")
  ///
  /// Example:
  /// ```dart
  /// PermissionHelper.hasCreatePermission(
  ///   moduleName: "Client",
  ///   featureName: "Projects",
  /// )
  /// ```
  static bool hasCreatePermission({
    required String moduleName,
    String? featureName,
  }) {
    return hasPermission(
      moduleName: moduleName,
      featureName: featureName,
      permissionType: 'create',
    );
  }

  /// Check if user has view permission
  ///
  /// [moduleName] - The module name (e.g., "Client")
  /// [featureName] - Optional. The feature name (e.g., "Projects")
  ///
  /// Example:
  /// ```dart
  /// PermissionHelper.hasViewPermission(
  ///   moduleName: "Client",
  ///   featureName: "Projects",
  /// )
  /// ```
  static bool hasViewPermission({
    required String moduleName,
    String? featureName,
  }) {
    return hasPermission(
      moduleName: moduleName,
      featureName: featureName,
      permissionType: 'view',
    );
  }

  /// Check if user has edit permission
  ///
  /// [moduleName] - The module name (e.g., "Client")
  /// [featureName] - Optional. The feature name (e.g., "Projects")
  ///
  /// Example:
  /// ```dart
  /// PermissionHelper.hasEditPermission(
  ///   moduleName: "Client",
  ///   featureName: "Projects",
  /// )
  /// ```
  static bool hasEditPermission({
    required String moduleName,
    String? featureName,
  }) {
    return hasPermission(
      moduleName: moduleName,
      featureName: featureName,
      permissionType: 'edit',
    );
  }

  /// Check if user has fullAccess permission
  ///
  /// [moduleName] - The module name (e.g., "Client")
  /// [featureName] - Optional. The feature name (e.g., "Projects")
  ///
  /// Example:
  /// ```dart
  /// PermissionHelper.hasFullAccessPermission(
  ///   moduleName: "Client",
  ///   featureName: "Projects",
  /// )
  /// ```
  static bool hasFullAccessPermission({
    required String moduleName,
    String? featureName,
  }) {
    return hasPermission(
      moduleName: moduleName,
      featureName: featureName,
      permissionType: 'fullAccess',
    );
  }

  /// Check if user has access to any screen
  /// Returns true if user has at least one accessible screen
  static bool hasAnyScreenAccess() {
    // Check ER Team Lead Dashboard
    if (hasViewPermission(moduleName: "ERT Team Leader")) {
      return true;
    }

    // Check ER Team Member Dashboard
    if (hasViewPermission(moduleName: "ERT Team Member")) {
      return true;
    }

    // Check ER Team Approver
    if (hasViewPermission(moduleName: "ER Team Approval")) {
      return true;
    }

    // Check Incident Dashboard
    if (hasViewPermission(moduleName: "Incident Reporting & Monitoring")) {
      return true;
    }

    // Check Report Incident
    if (hasCreatePermission(
      moduleName: "Incident Reporting & Monitoring",
      featureName: "EmergeX Case",
    )) {
      return true;
    }

    // Check EmergeX Client
    if (hasViewPermission(moduleName: "EmergeX Client Onboarding")) {
      return true;
    }

    // Check Our Project
    if (hasViewPermission(
      moduleName: "Client Admin",
      featureName: "Projects",
    )) {
      return true;
    }

    // Check Organization Chart
    if (hasViewPermission(
      moduleName: "Org Structure",
      featureName: "View Org Structure",
    )) {
      return true;
    }

    return false;
  }

  /// Get the first accessible dashboard route based on permissions
  ///
  /// Navigation Logic (matches web application):
  /// 1. Iterate through permission modules in the order they appear in API response
  /// 2. Find the first module where any feature has rules.fullAccess == true
  /// 3. Navigate to the corresponding dashboard for that module
  /// 4. If no fullAccess module exists, fall back to first accessible dashboard
  ///
  /// Returns the route string or null if no dashboard is accessible
  static String? getFirstAccessibleDashboardRoute() {
    final userPermissions = AppDI.emergexAppCubit.state.userPermissions;
    if (userPermissions == null) return null;

    // Step 1: Find the first module with fullAccess = true (in API response order)
    for (final rolePermission in userPermissions.permissions) {
      for (final modulePermission in rolePermission.permissions) {
        // Handle ERT Team Leader with feature-level routing
        if (modulePermission.module == 'ERT Team Leader') {
          final hasFullAccess = modulePermission.features.any(
            (feature) => feature.permissions.fullAccess == true,
          );
          if (hasFullAccess) {
            // Task Management → My Tasks, Member Management → ER Team Tasks
            final hasTaskMgmt = modulePermission.features.any(
              (f) => f.name == 'Task Management' &&
                  (f.permissions.view == true || f.permissions.fullAccess == true),
            );
            return hasTaskMgmt ? Routes.inProgressScreen : Routes.erteamleader;
          }
          continue;
        }

        // Check if this module is a dashboard module
        final dashboardRoute = _moduleToDashboardRoute[modulePermission.module];
        if (dashboardRoute == null) continue;

        // Check if any feature in this module has fullAccess = true
        final hasFullAccess = modulePermission.features.any(
          (feature) => feature.permissions.fullAccess == true,
        );

        if (hasFullAccess) {
          // Found the first module with fullAccess - return its dashboard route
          return dashboardRoute;
        }
      }
    }

    // Step 2: Fallback - if no fullAccess module found, return first accessible dashboard
    for (final moduleName in _dashboardModulesFallbackOrder) {
      if (moduleName == 'ERT Team Leader') {
        // Feature-level check for ERT Team Leader
        if (hasViewPermission(moduleName: moduleName, featureName: 'Task Management')) {
          return Routes.inProgressScreen;
        }
        if (hasViewPermission(moduleName: moduleName, featureName: 'Member Management')) {
          return Routes.erteamleader;
        }
        continue;
      }
      if (hasFullAccessPermission(moduleName: moduleName)) {
        return _moduleToDashboardRoute[moduleName];
      }
    }

    return null;
  }

  /// Get the first accessible screen route (dashboard or other screen)
  /// Returns the route string or null if no screen is accessible
  static String? getFirstAccessibleScreenRoute() {
    // First check dashboards (priority)
    final dashboardRoute = getFirstAccessibleDashboardRoute();
    if (dashboardRoute != null) {
      return dashboardRoute;
    }

    // Then check other screens
    // Report Incident
    if (hasCreatePermission(
      moduleName: "Incident Reporting & Monitoring",
      featureName: "EmergeX Case",
    )) {
      return Routes.reportIncident;
    }

    // EmergeX Client
    if (hasViewPermission(moduleName: "EmergeX Client Onboarding")) {
      return Routes.clientViewScreen;
    }

    // Our Project
    if (hasViewPermission(
      moduleName: "Client Admin",
      featureName: "Projects",
    )) {
      return Routes.projectListScreen;
    }

    // Organization Chart
    if (hasViewPermission(
      moduleName: "Org Structure",
      featureName: "View Org Structure",
    )) {
      return Routes.organizationStructureScreen;
    }

    return null;
  }

  /// Get all feature permissions for the current user
  static List<UserFeaturePermission> getAllFeaturePermissions() {
    final userPermissions = AppDI.emergexAppCubit.state.userPermissions;
    if (userPermissions == null) return [];

    return userPermissions.permissions
        .expand((role) => role.permissions)
        .expand((module) => module.features)
        .toList();
  }
}
