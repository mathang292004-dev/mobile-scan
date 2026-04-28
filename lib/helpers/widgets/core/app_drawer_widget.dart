import 'package:emergex/base/cubit/emergex_app_cubit.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/preference_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/auth_guard.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppDrawerWidget extends StatefulWidget {
  const AppDrawerWidget({super.key});

  @override
  State<AppDrawerWidget> createState() => _AppDrawerWidgetState();
}

class _AppDrawerWidgetState extends State<AppDrawerWidget> {
  bool _isIncidentExpanded = false;
  bool _isERTExpanded = false;
  bool _isInvestigationExpanded = false;
  @override
  void initState() {
    super.initState();
    // Focus clearing is now handled in AppBarWidget._showFullScreenOverlay
    // before the drawer opens, eliminating the keyboard flicker issue
  }

  void _navigateIfNeeded(
    String targetRoute, {
    bool clearOldStacks = false,
  }) async {
    if (targetRoute == Routes.dashboard) {
      back(); // close drawer

      // Check if user has dashboard permission
      final hasDashboardAccess = PermissionHelper.hasViewPermission(
        moduleName: "Incident Reporting & Monitoring",
        featureName: "EmergeX Case",
      );

      if (hasDashboardAccess) {
        context.go(Routes.homeScreen);
      } else {
        // Navigate to first accessible screen instead
        final screenRoute = PermissionHelper.getFirstAccessibleScreenRoute();
        if (screenRoute != null) {
          context.go(screenRoute);
        } else {
          context.go(Routes.getRouterPath(Routes.noAccessScreen));
        }
      }
      return;
    }

    final routerState = GoRouterState.of(context);
    final currentLocation = routerState.matchedLocation;

    if (currentLocation.contains(targetRoute)) {
      back();
      return;
    }

    back();
    await _loadDashboardData(targetRoute);
    openScreen(targetRoute, clearOldStacks: clearOldStacks);
  }

  /// Load dashboard data before navigation
  Future<void> _loadDashboardData(String route) async {
    final selectedProjectId = AppDI.emergexAppCubit.state.selectedProjectId;

    switch (route) {
      case Routes.erteamleader:
        // Load ER Team Leader dashboard data
        await AppDI.erTeamLeaderDashboardCubit.loadDashboard(isRefresh: true);
        break;

      case Routes.inProgressScreen:
        // Load My Tasks data
        AppDI.myTaskCubit.reset();
        await AppDI.myTaskCubit.loadMyTasks();
        break;

      case Routes.erTeamMemberScreen:
        // Load ER Team Member dashboard data
        await AppDI.memberTaskDashboardCubit.loadDashboard(isRefresh: true);
        break;

      case Routes.erTeamApproverScreen:
      case Routes.caseApproverDashboard:
        // Case Approver Dashboard always calls /approver-dashboard.
        // The ERT approver cubit is still loaded because the incident-detail
        // / task screens depend on its state.
        await AppDI.caseApproverDashboardCubit.loadInitialData();
        await AppDI.erTeamApproverDashboardCubit.loadDashboard();
        break;

      case Routes.dashboard:
        // Member dashboard — always calls /member-dashboard.
        await AppDI.dashboardCubit.loadInitialData();
        break;

      case Routes.clientViewScreen:
        // Load Client list data
        await AppDI.clientCubit.getClients();
        break;

      case Routes.projectListScreen:
        // Load Project list data (requires clientId from ProjectCubit state)

        break;

      case Routes.organizationStructureScreen:
        // Load Organization Structure data
        if (selectedProjectId != null && selectedProjectId.isNotEmpty) {
          await AppDI.orgStructureCubit.getOrgStructure(selectedProjectId);
        }
        break;

      default:
        // No API call needed for other routes
        break;
    }
  }

  /// Reload current screen data when project is changed
  Future<void> _reloadCurrentScreenData(String currentRoute) async {
    final selectedProjectId = AppDI.emergexAppCubit.state.selectedProjectId;

    if (currentRoute.contains(Routes.inProgressScreen)) {
      AppDI.myTaskCubit.reset();
      await AppDI.myTaskCubit.loadMyTasks();
    } else if (currentRoute.contains(Routes.erteamleader)) {
      await AppDI.erTeamLeaderDashboardCubit.loadDashboard(isRefresh: true);
    } else if (currentRoute.contains(Routes.erTeamMemberScreen)) {
      await AppDI.memberTaskDashboardCubit.loadDashboard(isRefresh: true);
    } else if (currentRoute.contains(Routes.erTeamApproverScreen) ||
        currentRoute.contains(Routes.caseApproverDashboard)) {
      // Case Approver Dashboard reload. Keeps the ERT approver cubit primed
      // for the incident-detail / task screens that still depend on it.
      await AppDI.caseApproverDashboardCubit.loadInitialData();
      await AppDI.erTeamApproverDashboardCubit.loadDashboard();
    } else if (currentRoute.contains(Routes.dashboard) ||
        currentRoute.contains(Routes.homeScreen)) {
      // Dashboard is accessed via homeScreen?tab=0, so check both routes
      await AppDI.dashboardCubit.loadInitialData();
    } else if (currentRoute.contains(Routes.clientViewScreen)) {
      await AppDI.clientCubit.getClients();
    } else if (currentRoute.contains(Routes.projectListScreen)) {
    }
    // ADD THIS BLOCK
    else if (currentRoute.contains(Routes.viewprojectscreen)) {
      await AppDI.projectCubit.refreshProjects();
    } else if (currentRoute.contains(Routes.organizationStructureScreen)) {
      if (selectedProjectId != null && selectedProjectId.isNotEmpty) {
        await AppDI.orgStructureCubit.getOrgStructure(selectedProjectId);
      }
    }
    // Handle RolesScreen - fetch roles for the new project
    else if (currentRoute.contains(Routes.rolesScreen)) {
      if (selectedProjectId != null && selectedProjectId.isNotEmpty) {
        await AppDI.onboardingOrganizationStructureCubit.fetchRoles(
          selectedProjectId,
        );
      }
    }
  }

  /// Check if user has permission for a specific route
  /// Returns true if user can access the route, false otherwise
  bool _hasPermissionForRoute(String currentRoute) {
    // Incident Dashboard
    if (currentRoute.contains(Routes.dashboard) ||
        currentRoute.contains(Routes.homeScreen)) {
      return PermissionHelper.hasViewPermission(
        moduleName: "Incident Reporting & Monitoring",
        featureName: "EmergeX Case",
      );
    }

    // ERT Team Leader — My Tasks
    if (currentRoute.contains(Routes.inProgressScreen)) {
      return PermissionHelper.hasViewPermission(
        moduleName: "ERT Team Leader",
        featureName: "Task Management",
      );
    }

    // ERT Team Leader — ER Team Tasks
    if (currentRoute.contains(Routes.erteamleader) ||
        currentRoute.contains(Routes.overviewScreen) ||
        currentRoute.contains(Routes.erTeamOverviewScreen)) {
      return PermissionHelper.hasViewPermission(
        moduleName: "ERT Team Leader",
        featureName: "Member Management",
      );
    }

    // ERT Team Member
    if (currentRoute.contains(Routes.erTeamMemberScreen) ||
        currentRoute.contains(Routes.erTeamMemberTasksScreen) ||
        currentRoute.contains(Routes.erTeamMemberTaskDetailsScreen)) {
      return PermissionHelper.hasViewPermission(
        moduleName: "ERT Team Member",
        featureName: "Update Status of Task",
      );
    }

    // ERT Approver
    if (currentRoute.contains(Routes.erTeamApproverScreen) ||
        currentRoute.contains(Routes.erTeamApproverDetailScreen) ||
        currentRoute.contains(Routes.erTeamApproverTaskDetailsScreen)) {
      return PermissionHelper.hasViewPermission(
        moduleName: "ER Team Approval",
        featureName: "Status of Report & Report Download",
      );
    }

    // Client
    if (currentRoute.contains(Routes.clientViewScreen) ||
        currentRoute.contains(Routes.viewprojectscreen)) {
      return PermissionHelper.hasViewPermission(
        moduleName: "EmergeX Client Onboarding",
        featureName: "Onboard EmergeX Customers",
      );
    }

    // Project List
    if (currentRoute.contains(Routes.projectListScreen)) {
      return PermissionHelper.hasViewPermission(
        moduleName: "Client Admin",
        featureName: "Projects",
      );
    }

    // Organization Structure
    if (currentRoute.contains(Routes.organizationStructureScreen)) {
      return PermissionHelper.hasViewPermission(
        moduleName: "Org Structure",
        featureName: "View Org Structure",
      );
    }

    // Report Incident
    if (currentRoute.contains(Routes.reportIncident)) {
      return PermissionHelper.hasCreatePermission(
        moduleName: "Incident Reporting & Monitoring",
        featureName: "EmergeX Case",
      );
    }

    // Default: allow access for unknown routes
    return true;
  }

  String? _getHighestPriorityRoute() {
    // 1. Incident Dashboard
    if (PermissionHelper.hasViewPermission(
      moduleName: "Incident Reporting & Monitoring",
      featureName: "EmergeX Case",
    )) {
      return Routes.homeScreen;
    }

    // 2a. ERT Team Leader — My Tasks
    if (PermissionHelper.hasViewPermission(
      moduleName: "ERT Team Leader",
      featureName: "Task Management",
    )) {
      return Routes.inProgressScreen;
    }

    // 2b. ERT Team Leader — ER Team Tasks
    if (PermissionHelper.hasViewPermission(
      moduleName: "ERT Team Leader",
      featureName: "Member Management",
    )) {
      return Routes.erteamleader;
    }

    // 3. ERT Team Member
    if (PermissionHelper.hasViewPermission(
      moduleName: "ERT Team Member",
      featureName: "Update Status of Task",
    )) {
      return Routes.erTeamMemberScreen;
    }

    // 4. ERT Approver
    if (PermissionHelper.hasViewPermission(
      moduleName: "ER Team Approval",
      featureName: "Status of Report & Report Download",
    )) {
      return Routes.erTeamApproverScreen;
    }

    // 5. Client
    if (PermissionHelper.hasViewPermission(
      moduleName: "EmergeX Client Onboarding",
      featureName: "Onboard EmergeX Customers",
    )) {
      return Routes.clientViewScreen;
    }

    // 6. Our Project
    if (PermissionHelper.hasViewPermission(
      moduleName: "Client Admin",
      featureName: "Projects",
    )) {
      return Routes.projectListScreen;
    }

    // 7. No permission anywhere - return null to trigger logout
    return null;
  }

  /// Handle project change with silent navigation
  /// Checks permission for current route and navigates to priority route if needed
  Future<void> _handleProjectChange(
    BuildContext context,
    String newProjectId,
  ) async {
    // Update the selected project and fetch new permissions
    final success = await AppDI.emergexAppCubit.updateSelectedProject(
      newProjectId,
    );

    if (!success || !context.mounted) return;

    // Get the current route
    final routerState = GoRouterState.of(context);
    final currentRoute = routerState.matchedLocation;

    // Check if user has permission for current route
    final hasPermission = _hasPermissionForRoute(currentRoute);

    if (!hasPermission) {
      // User lost permission for current route - navigate to priority route
      final priorityRoute = _getHighestPriorityRoute();

      if (priorityRoute == null) {
        // No permission anywhere - logout
        back(); // Close drawer
        await PreferenceHelper().clearAll();
        if (context.mounted) {
          context.go(Routes.login);
        }
        return;
      }

      // Load data for the new route before navigating
      await _loadDashboardData(_getRouteNameFromPath(priorityRoute));

      // Navigate silently without closing drawer first
      // Using go() for replace-style navigation without animations
      if (context.mounted) {
        context.go(priorityRoute);
      }
    } else {
      // User still has permission - reload current screen data silently
      await _reloadCurrentScreenData(currentRoute);
    }
  }

  /// Helper to get route name from full path
  String _getRouteNameFromPath(String path) {
    if (path.contains(Routes.dashboard)) return Routes.dashboard;
    if (path.contains(Routes.inProgressScreen)) return Routes.inProgressScreen;
    if (path.contains(Routes.erteamleader)) return Routes.erteamleader;
    if (path.contains(Routes.erTeamMemberScreen))
      return Routes.erTeamMemberScreen;
    if (path.contains(Routes.erTeamApproverScreen))
      return Routes.erTeamApproverScreen;
    if (path.contains(Routes.clientViewScreen)) return Routes.clientViewScreen;
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmergexAppCubit, EmergexAppState>(
      builder: (context, state) {
        final userName = state.userPermissions?.name ?? 'Jerome Bell';
        final userEmail = state.userPermissions?.email ?? '';

        return Drawer(
          backgroundColor: const Color(0xFFEAF2E8),
          width: MediaQuery.of(context).size.width * 0.85,
          child: SafeArea(
            child: Column(
              children: [
                // Header with close button and user profile
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile
                      Expanded(
                        child: _buildUserProfile(context, userName, userEmail),
                      ),
                      // Close Button
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF374151),
                          size: 24,
                        ),
                        onPressed: () => back(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Project Dropdown
                if (state.userPermissions != null)
                  _buildProjectDropdown(context, state),

                  if (PermissionHelper.hasCreatePermission(
                moduleName: "Incident Reporting & Monitoring",
                featureName: "EmergeX Case",
              ))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: EmergexButton(
                    borderRadius: 30,
                    textSize: 16,
                    onPressed: () {
                      openScreen(Routes.reportIncident);
                    },
                    leadingIcon: Icon(Icons.add, color: ColorHelper.white),
                    text: TextHelper.createEmergeXCase,
                  ),
                ),

                const Divider(
                  color: Color.fromARGB(255, 255, 255, 255),
                  height: 1,
                  thickness: 1,
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    children: _buildMenuItems(context, state),
                  ),
                ),

                const Divider(
                  color: Color.fromARGB(255, 255, 254, 254),
                  height: 1,
                  thickness: 1,
                ),
                _buildSettingsButton(context),
                _buildLogoutButton(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          back(); // Close drawer
          openScreen(Routes.settingsScreen);
        },
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFF2D5F3C).withValues(alpha: 0.1),
        highlightColor: const Color(0xFF2D5F3C).withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Image.asset(
                Assets.appbarIconSetting,
                width: 20,
                height: 20,
                color: ColorHelper.black4,
              ),
              const SizedBox(width: 14),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ColorHelper.black4,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, String name, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 72, // 👈 increased size
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8EDE5),
            border: Border.all(color: const Color(0xFFD4E5D0), width: 1.5),
          ),
          child: ClipOval(
            child: Image.asset(Assets.profile, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),

        // User name
        Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF272727),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProjectDropdown(BuildContext context, EmergexAppState state) {
    final projects = state.userPermissions?.projects ?? [];
    final selectedProjectId = state.selectedProjectId;
    final isLoading = state.permissionLoadingState == ProcessState.loading;

    final selectedProject = projects.isEmpty
        ? null
        : projects.firstWhere(
            (p) => p.projectId == selectedProjectId,
            orElse: () => projects.first,
          );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E8DC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'Select Project',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),

          // Dropdown Container
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: projects.isEmpty
                  ? DropdownButton<String>(
                      value: 'none',
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 24,
                        color: Color(0xFF6B7280),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(
                          value: 'none',
                          child: Text(
                            'No project available',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      onChanged: null,
                    )
                  : DropdownButton<String>(
                      value: selectedProject?.projectId,
                      isExpanded: true,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2D5F3C),
                              ),
                            )
                          : const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 24,
                              color: Color(0xFF6B7280),
                            ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF374151),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      items: projects.map((project) {
                        return DropdownMenuItem<String>(
                          value: project.projectId,
                          child: Text(
                            project.projectName.isNotEmpty
                                ? project.projectName
                                : 'Project ${project.projectId}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (String? newValue) async {
                              if (newValue == null) return;
                              if (newValue == selectedProjectId) return;

                              // Handle project change with permission check and silent navigation
                              await _handleProjectChange(context, newValue);
                            },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleLogout(context),
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFF2D5F3C).withValues(alpha: 0.1),
        highlightColor: const Color(0xFF2D5F3C).withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Image.asset(
                Assets.appbarIconLogout,
                width: 20,
                height: 20,
                color: ColorHelper.black4,
              ),
              const SizedBox(width: 14),
              Text(
                'Logout',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ColorHelper.black4,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    back(); // Close drawer first
    showErrorDialog(
      context,
      () async {
        back(); // Close dialog

        // Set strict logout state in AuthGuard
        AuthGuard.setLogoutState(true);

        // Cancel any pending API calls from cubits before clearing data
        try { AppDI.userManagementCubit.reset(); } catch (_) {}

        // Clear user-specific in-memory state
        try { AppDI.emergexAppCubit.clearSession(); } catch (_) {}
        try { AppDI.projectCubit.clearCache(); } catch (_) {}

        // Dashboard cubits
        try { AppDI.dashboardCubit.clearCache(); } catch (_) {}
        try { AppDI.caseApproverDashboardCubit.clearCache(); } catch (_) {}
        try { AppDI.erTeamApproverDashboardCubit.clearCache(); } catch (_) {}
        try { AppDI.erTeamLeaderDashboardCubit.clearCache(); } catch (_) {}
        try { AppDI.hseDashboardCubit.clearCache(); } catch (_) {}

        // Task cubits
        try { AppDI.myTaskDashboardCubit.clearCache(); } catch (_) {}
        try { AppDI.memberTaskDashboardCubit.clearCache(); } catch (_) {}
        try { AppDI.myTaskCubit.reset(); } catch (_) {}
        try { AppDI.memberTaskCubit.reset(); } catch (_) {}

        // Investigation cubits
        try { AppDI.investigationTlTaskCubit.clearCache(); } catch (_) {}
        try { AppDI.primaryInvestigatorCubit.clearCache(); } catch (_) {}
        try { AppDI.investigationMemberCubit.clearCache(); } catch (_) {}
        try { AppDI.investigationApproverCubit.clearCache(); } catch (_) {}

        // Shared data cubits
        try { AppDI.incidentDetailsCubit.clearCache(); } catch (_) {}
        try { AppDI.notificationCubit.clearCache(); } catch (_) {}
        try { AppDI.orgStructureCubit.reset(); } catch (_) {}
        try { AppDI.chatRoomCubit.clearCache(); } catch (_) {}
        try { AppDI.clientCubit.clearCache(); } catch (_) {}

        // Unregister FCM token before logout
        try {
          await AppDI.pushNotificationService.unregisterToken();
        } catch (e) {
          debugPrint('Error unregistering FCM token on logout: $e');
        }

        // Clear all stored data
        await PreferenceHelper().clearAll();
        // Navigate to login screen
        openScreen(Routes.login, clearOldStacks: true);
      },
      () {
        back(); // Close dialog
      },
      TextHelper.areyousure,
      TextHelper.areYouSureYouWantToLogout,
      TextHelper.yesLogOut,
      TextHelper.goBack,
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String iconAsset,
    required String title,
    required VoidCallback onTap,
    bool hasPermission = true,
  }) {
    if (!hasPermission) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFF2D5F3C).withValues(alpha: 0.1),
        highlightColor: const Color(0xFF2D5F3C).withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Image.asset(
                iconAsset,
                width: 20,
                height: 20,
                color: ColorHelper.black4,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColorHelper.black4,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build Incident menu with separate actions:
  /// - Clicking text/icon navigates to Dashboard
  /// - Clicking arrow expands/collapses dropdown
  Widget _buildIncidentMenuWithNavigation(
    BuildContext context, {
    required String iconAsset,
    required String title,
    required bool isExpanded,
    required VoidCallback onTextTap,
    required VoidCallback onArrowTap,
    required List<Widget> children,
  }) {
    const primaryGreen = Color(0xFF2D5F3C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isExpanded ? const Color(0xFFD4E8D1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Text/Icon area
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTextTap,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    splashColor: primaryGreen.withValues(alpha: 0.1),
                    highlightColor: primaryGreen.withValues(alpha: 0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isExpanded ? Colors.white : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            Assets.incidentbar,
                            width: 22,
                            height: 22,
                            color: isExpanded
                                ? const Color.fromARGB(255, 10, 172, 59)
                                : const Color(0xFF6B7280),
                            colorBlendMode: BlendMode.srcIn,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isExpanded
                                        ? const Color.fromARGB(255, 10, 172, 59)
                                        : const Color(0xFF374151),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Arrow area
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onArrowTap,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  splashColor: primaryGreen.withValues(alpha: 0.1),
                  highlightColor: primaryGreen.withValues(alpha: 0.05),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isExpanded ? Colors.white : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isExpanded
                          ? primaryGreen
                          : const Color(0xFF6B7280),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 🔹 INCIDENT CONTINUOUS VERTICAL LINE
        if (isExpanded && children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔹 INCIDENT CONTINUOUS LINE (AUTO)
                  Container(
                    width: 2,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4E5D0),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  // 🔹 INCIDENT CHILDREN (ERT block)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children, // <-- includes ERT expanded content
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandableSubmenu(
    BuildContext context, {
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    const primaryGreen = Color(0xFF2D5F3C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            splashColor: primaryGreen.withValues(alpha: 0.1),
            highlightColor: primaryGreen.withValues(alpha: 0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isExpanded ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isExpanded
                            ? const Color.fromARGB(255, 10, 172, 59)
                            : const Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? primaryGreen : const Color(0xFF6B7280),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 🔹 CONTINUOUS ERT VERTICAL LINE
        if (isExpanded && children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 2,
                  height: children.length * 36.0,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4E5D0),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubMenuItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
    bool hasPermission = true,
  }) {
    if (!hasPermission) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4B5563),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  /// Build menu items with permission checks
  List<Widget> _buildMenuItems(BuildContext context, EmergexAppState state) {
    final menuItems = <Widget>[];

    menuItems.add(const SizedBox(height: 8));

    // Check if user has any Incident/ERT permissions
    final hasIncidentPermission =
        PermissionHelper.hasViewPermission(
          moduleName: "Incident Reporting & Monitoring",
          featureName: "EmergeX Case",
        ) ||
        PermissionHelper.hasViewPermission(
          moduleName: "ERT Team Leader",
          featureName: "Task Management",
        ) ||
        PermissionHelper.hasViewPermission(
          moduleName: "ERT Team Leader",
          featureName: "Member Management",
        ) ||
        PermissionHelper.hasViewPermission(
          moduleName: "ERT Team Member",
          featureName: "Update Status of Task",
        ) ||
        PermissionHelper.hasViewPermission(
          moduleName: "ER Team Approval",
          featureName: "Status of Report & Report Download",
        );

    // ── Reported EmergeX Case (flat) ──────────────────────────────────────
    final hasDashboardPermission = PermissionHelper.hasViewPermission(
      moduleName: "Incident Reporting & Monitoring",
      featureName: "EmergeX Case",
    );
    if (hasDashboardPermission) {
      menuItems.add(
        _buildMenuItem(
          context,
          iconAsset: Assets.reportedEmergeCase,
          title: 'Reported EmergeX Case',
          onTap: () =>
              _navigateIfNeeded(Routes.dashboard, clearOldStacks: true),
        ),
      );
      menuItems.add(const SizedBox(height: 8));
    }

    // ── ERT (separate expandable) ──────────────────────────────────────────
    if (hasIncidentPermission) {
      // TODO: restore permission checks for ERT when ready
      // final hasERTLeadTaskPermission = PermissionHelper.hasViewPermission(
      //   moduleName: "ERT Team Leader",
      //   featureName: "Task Management",
      // );
      // final hasERTLeadMemberPermission = PermissionHelper.hasViewPermission(
      //   moduleName: "ERT Team Leader",
      //   featureName: "Member Management",
      // );
      // final hasERTMemberPermission = PermissionHelper.hasViewPermission(
      //   moduleName: "ERT Team Member",
      //   featureName: "Update Status of Task",
      // );
      // final hasERTApproverPermission = PermissionHelper.hasViewPermission(
      //   moduleName: "ER Team Approval",
      //   featureName: "Status of Report & Report Download",
      // );

      final ertSubmenuItems = <Widget>[
        _buildSubMenuItem(
          context,
          title: 'My Tasks',
          hasPermission: true, // hasERTLeadTaskPermission
          onTap: () =>
              _navigateIfNeeded(Routes.inProgressScreen, clearOldStacks: true),
        ),
        _buildSubMenuItem(
          context,
          title: 'ER Team Tasks',
          hasPermission: true, // hasERTLeadMemberPermission
          onTap: () =>
              _navigateIfNeeded(Routes.erteamleader, clearOldStacks: true),
        ),
        _buildSubMenuItem(
          context,
          title: 'ERT Team Member',
          hasPermission: true, // hasERTMemberPermission
          onTap: () => _navigateIfNeeded(
            Routes.erTeamMemberScreen,
            clearOldStacks: true,
          ),
        ),
        _buildSubMenuItem(
          context,
          title: 'ERT Approver',
          hasPermission: true, // hasERTApproverPermission
          onTap: () => _navigateIfNeeded(
            Routes.erTeamApproverScreen,
            clearOldStacks: true,
          ),
        ),
      ];

      menuItems.add(
        _buildExpandableSubmenu(
          context,
          title: 'ERT',
          isExpanded: _isERTExpanded,
          onTap: () => setState(() => _isERTExpanded = !_isERTExpanded),
          children: ertSubmenuItems,
        ),
      );
      menuItems.add(const SizedBox(height: 8));
    }

    // Case Approver Dashboard — only visible when the user has the
    // "Approval of EmergeX Case" full-access permission.
    final hasCaseApproverPermission = PermissionHelper.hasFullAccessPermission(
      moduleName: "Incident Reporting & Monitoring",
      featureName: "Approval of EmergeX Case",
    );
    if (hasCaseApproverPermission) {
      menuItems.add(
        _buildMenuItem(
          context,
          iconAsset: Assets.appbarIconApproval,
          title: 'Approvals',
          onTap: () {
            _navigateIfNeeded(
              Routes.caseApproverDashboard,
              clearOldStacks: true,
            );
          },
        ),
      );
      menuItems.add(const SizedBox(height: 8));
    }

    // // HSE (Closure Dashboard)
    // menuItems.add(
    //   _buildMenuItem(
    //     context,
    //     iconAsset: Assets.menuIconHome,
    //     title: TextHelper.hse,
    //     onTap: () {
    //       _navigateIfNeeded(Routes.hseDashboardScreen, clearOldStacks: true);
    //     },
    //   ),
    // );
    // menuItems.add(const SizedBox(height: 8));

    // // CATR Member Task
    // menuItems.add(
    //   _buildMenuItem(
    //     context,
    //     iconAsset: Assets.menuIconReport,
    //     title: TextHelper.catrMemberTask,
    //     onTap: () {
    //       _navigateIfNeeded(Routes.hseDashboardScreen, clearOldStacks: true);
    //     },
    //   ),
    // );
    // menuItems.add(const SizedBox(height: 8));

    // // ──────────────────────────────────────────────
    // // Investigation
    // // ──────────────────────────────────────────────
    // final investigationSubItems = <Widget>[];

    // // TL Tasks
    // investigationSubItems.add(
    //   _buildSubMenuItem(
    //     context,
    //     title: 'TL Tasks',
    //     onTap: () {
    //       _navigateIfNeeded(
    //         Routes.investigationTlTaskScreen,
    //         clearOldStacks: true,     
    //       );
    //     },
    //   ),
    // );

    // Team Setup
    // investigationSubItems.add(
    //   _buildSubMenuItem(
    //     context,
    //     title: 'Team Setup',
    //     onTap: () {
    //       _navigateIfNeeded(
    //         Routes.investigationTeamSetupScreen,
    //         clearOldStacks: true,
    //       );
    //     },
    //   ),
    // );

    // // Primary Investigator
    // investigationSubItems.add(
    //   _buildSubMenuItem(
    //     context,
    //     title: 'Primary Investigator',
    //     onTap: () {
    //       _navigateIfNeeded(
    //         Routes.primaryInvestigatorScreen,
    //         clearOldStacks: true,
    //       );
    //     },
    //   ),
    // );

    // // Team Member
    // investigationSubItems.add(
    //   _buildSubMenuItem(
    //     context,
    //     title: 'Team Member',
    //     onTap: () {
    //       _navigateIfNeeded(
    //         Routes.investigationMemberScreen,
    //         clearOldStacks: true,
    //       );
    //     },
    //   ),
    // );

    // // Approver
    // investigationSubItems.add(
    //   _buildSubMenuItem(
    //     context,
    //     title: 'Approver',
    //     onTap: () {
    //       _navigateIfNeeded(
    //         Routes.investigationApproverScreen,
    //         clearOldStacks: true,
    //       );
    //     },
    //   ),
    // );

    // menuItems.add(
    //   _buildIncidentMenuWithNavigation(
    //     context,
    //     iconAsset: Assets.menuIconReport,
    //     title: 'Investigation',
    //     isExpanded: _isInvestigationExpanded,
    //     // Title tap — no top-level route for Investigation, just toggle
    //     onTextTap: () {
    //       setState(() {
    //         _isInvestigationExpanded = !_isInvestigationExpanded;
    //       });
    //     },
    //     onArrowTap: () {
    //       setState(() {
    //         _isInvestigationExpanded = !_isInvestigationExpanded;
    //       });
    //     },
    //     children: investigationSubItems,
    //   ),
    // );
    // menuItems.add(const SizedBox(height: 8));

    // EmergeX Client
    final hasClientPermission = PermissionHelper.hasViewPermission(
      moduleName: "EmergeX Client Onboarding",
      featureName: "Onboard EmergeX Customers",
    );
    if (hasClientPermission) {
      menuItems.add(
        _buildMenuItem(
          context,
          iconAsset: Assets.appbarClient,
          title: 'EmergeX Client',
          hasPermission: hasClientPermission,
          onTap: () {
            _navigateIfNeeded(Routes.clientViewScreen, clearOldStacks: true);
          },
        ),
      );
      menuItems.add(const SizedBox(height: 8));
    }

    // // User Management
    // final hasUserManagementPermission = PermissionHelper.hasViewPermission(
    //   moduleName: "User Onboarding",
    //   featureName: "User Management",
    // );
    // if (hasUserManagementPermission) {
    //   menuItems.add(
    //     _buildMenuItem(
    //       context,
    //       iconAsset: Assets.userManagementIcon,
    //       title: 'User Management',
    //       hasPermission: hasUserManagementPermission,
    //       onTap: () {
    //         _navigateIfNeeded(
    //           Routes.userManagementScreen,
    //           clearOldStacks: true,
    //         );
    //       },
    //     ),
    //   );
    //   menuItems.add(const SizedBox(height: 8));
    // }

    // Our Project
    final hasProjectPermission = PermissionHelper.hasViewPermission(
      moduleName: "Client Admin",
      featureName: "Projects",
    );
    if (hasProjectPermission) {
      menuItems.add(
        _buildMenuItem(
          context,
          iconAsset: Assets.appbarProject,
          title: 'Our Project',
          hasPermission: hasProjectPermission,
          onTap: () {
            _navigateIfNeeded(Routes.projectListScreen, clearOldStacks: false);
          },
        ),
      );
      menuItems.add(const SizedBox(height: 8));
    }

    // final hasOrgStructurePermission = PermissionHelper.hasViewPermission(
    //   moduleName: "Org Structure",
    //   featureName: "View Org Structure",
    // );
    // if (hasOrgStructurePermission) {
    //   menuItems.add(
    //     _buildMenuItem(
    //       context,
    //       iconAsset: Assets.appbarOrgStu,
    //       title: 'Org Structure',
    //       hasPermission: hasOrgStructurePermission,
    //       onTap: () {
    //         _navigateIfNeeded(
    //           Routes.organizationStructureScreen,
    //           clearOldStacks: true,
    //         );
    //       },
    //     ),
    //   );
    // }

    return menuItems;
  }
}
