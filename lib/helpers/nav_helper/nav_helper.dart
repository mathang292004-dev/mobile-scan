import 'dart:collection';

//import 'package:emergex/apex_Screen.dart';
import 'package:emergex/presentation/emergex_onboarding/screen/client_screen/client_view_screen.dart';
import 'package:emergex/presentation/emergex_onboarding/screen/client_screen/project_screen.dart';
import 'package:emergex/presentation/emergex_onboarding/screen/project_screen/file_upload_screen/file_uploaded_screen.dart';
import 'package:emergex/presentation/emergex_onboarding/screen/project_screen/organization_project/role_details_screen.dart';
import 'package:emergex/presentation/emergex_onboarding/screen/project_screen/organization_project/organized_edit_member.dart';
import 'package:emergex/presentation/emergex_onboarding/screen/project_screen/organization_project/organization_structure_screen.dart';

//import 'package:emergex/er_team_screen.dart';
import 'package:emergex/helpers/preference_helper.dart';
import 'package:emergex/main.dart';
import 'package:emergex/presentation/case_report/approver/screens/incident_approval_screen.dart';
import 'package:emergex/presentation/case_report/member/screens/incident_report_detail.dart';
import 'package:emergex/presentation/case_report/approver/screens/preliminary_report_screen.dart';

import 'package:emergex/presentation/case_report/member/screens/home_screen.dart';
import 'package:emergex/presentation/emergex_onboarding/screen/project_screen/project_list_screen.dart';
import 'package:emergex/presentation/case_report/approver/screens/case_approver_dashboard_screen.dart';
import 'package:emergex/presentation/ert/er_team_approver/screen/er_team_approver_screen.dart';
import 'package:emergex/presentation/ert/er_team_approver/screen/ert_approver_dashboard_screen.dart';
import 'package:emergex/presentation/ert/er_team_approver/screen/er_team_approver_task_details_screen.dart';
import 'package:emergex/presentation/common/screens/notifications_screen.dart';
import 'package:emergex/presentation/chat/screens/chat_screen.dart';
import 'package:emergex/presentation/chat/screens/audio_call_screen.dart';
import 'package:emergex/presentation/chat/screens/video_call_screen.dart';
import 'package:emergex/presentation/chat/models/chat_member_model.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/screen/er_team_dashboard_screen.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/screen/er_team_over_view_screen.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/screen/my_task_dashboard_screen.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/screen/my_tasks_screen.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/screen/team_leader_task_overview/over_view_section.dart';
import 'package:emergex/presentation/hse/screen/hse_dashboard_screen.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/screens/task_details_screen.dart';
import 'package:emergex/presentation/onboarding/screen/forgot_password_screen.dart';
import 'package:emergex/presentation/onboarding/screen/otp_verification_screen.dart';
import 'package:emergex/presentation/onboarding/screen/reset_password_screen.dart';
import 'package:emergex/presentation/organization_structure/screen/organization_structure_screen.dart';
import 'package:emergex/presentation/onboarding/screen/login_screen.dart';
import 'package:emergex/presentation/onboarding/screen/no_access_screen.dart';
import 'package:emergex/presentation/onboarding/screen/reset_password_auth_screen.dart';
import 'package:emergex/presentation/user_onboarding/screens/user_management_screen.dart';
import 'package:emergex/presentation/case_report/report_emergex/screens/report_incident.dart';

// Investigation
import 'package:emergex/presentation/investigation/tl_task/screen/investigation_tl_task_screen.dart';
import 'package:emergex/presentation/investigation/tl_task/screen/investigation_tl_task_list_screen.dart';
import 'package:emergex/presentation/investigation/tl_task/screen/investigation_tl_task_detail_screen.dart';
import 'package:emergex/presentation/investigation/tl_team_setup/screen/investigation_team_setup_screen.dart';
import 'package:emergex/presentation/investigation/primary_investigator/screen/primary_investigator_dashboard_screen.dart';
import 'package:emergex/presentation/investigation/primary_investigator/screen/primary_investigator_detail_screen.dart';
import 'package:emergex/presentation/investigation/investigation_member/screen/investigation_member_dashboard_screen.dart';
import 'package:emergex/presentation/investigation/investigation_member/screen/investigation_member_task_screen.dart';
import 'package:emergex/presentation/investigation/investigation_approver/screen/investigation_approver_dashboard_screen.dart';
import 'package:emergex/presentation/investigation/investigation_approver/screen/investigation_approver_detail_screen.dart';
import 'package:emergex/presentation/investigation/investigation_team_member/screen/rca_workflow_board_screen.dart';
import 'package:emergex/presentation/investigation/investigation_team_member/screen/investigation_team_member_dashboard_screen.dart';
import 'package:emergex/presentation/investigation/investigation_team_member/screen/investigation_team_member_tasks_screen.dart';
import 'package:emergex/presentation/investigation/investigation_team_member/screen/investigation_team_member_task_details_screen.dart';
import 'package:emergex/helpers/widgets/common/settings_screen.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/presentation/onboarding/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/nav_helper/nav_observer.dart';

// Flag to control navigation behavior during notification handling
bool isFromNotification = false;

class AppRouter {
  static GoRouter? _router;

  static GoRouter get router {
    _router ??= _createRouter();
    return _router!;
  }

  static PreferenceHelper get preferenceHelper {
    return PreferenceHelper();
  }

  static GoRouter _createRouter() {
    return GoRouter(
      initialLocation: Routes.initialRoute,
      navigatorKey: NavObserver.navKey,
      observers: [NavObserver.instance],
      debugLogDiagnostics: true,
      routerNeglect: true,
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(location: state.uri.toString(), child: child);
          },
          routes: [
            GoRoute(
              path: Routes.initialRoute,
              name: Routes.initialRoute,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: SplashScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.erTeamApproverScreen,
              name: Routes.erTeamApproverScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const ErtApproverDashboardScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.caseApproverDashboard,
              name: Routes.caseApproverDashboard,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const CaseApproverDashboardScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.erTeamApproverDetailScreen,
              name: Routes.erTeamApproverDetailScreen,
              pageBuilder: (context, state) {
                String? incidentId;

                // Handle LinkedHashMap (common when using pushNamed with extra)
                if (state.extra is LinkedHashMap) {
                  final args = state.extra as LinkedHashMap;
                  incidentId = args['incidentId']?.toString();
                } else if (state.extra is Map) {
                  // Handle regular Map
                  final extraMap = state.extra as Map;
                  final args = Map<String, dynamic>.from(
                    extraMap.map(
                      (key, value) => MapEntry(key.toString(), value),
                    ),
                  );
                  incidentId = args['incidentId']?.toString();
                }

                final showDialog =
                    state.uri.queryParameters['showDialog'] == 'true';

                return pageBuilder(
                  context: context,
                  state: state,
                  child: ErTeamApproverScreen(
                    incidentId: incidentId!,
                    showVerificationDialog: showDialog,
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.organizationStructureScreen,
              name: Routes.organizationStructureScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: OrganizationStructureScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.clientViewScreen,
              name: Routes.clientViewScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: ClientScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.chatScreen,
              name: Routes.chatScreen,
              pageBuilder: (context, state) {
                final incidentId =
                    state.uri.queryParameters['incidentId'] ?? '';
                return pageBuilder(
                  context: context,
                  state: state,
                  child: ChatScreen(incidentId: incidentId),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.audioCallScreen,
              name: Routes.audioCallScreen,
              pageBuilder: (context, state) {
                Map<String, dynamic> args = {};
                if (state.extra != null) {
                  if (state.extra is Map) {
                    final extraMap = state.extra as Map;
                    args = Map<String, dynamic>.from(
                      extraMap.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    );
                  }
                }
                final incidentId = args['incidentId']?.toString() ?? '';
                final chatGroupId =
                    args['chatGroupId']?.toString() ?? ''; // Get chat group ID
                final onlineCount = args['onlineCount'] as int? ?? 0;
                final totalMembers = args['totalMembers'] as int? ?? 0;
                final participants =
                    args['participants'] as List<ChatMember>? ?? [];
                final callId = args['callId']?.toString();
                final roomId = args['roomId']?.toString();

                return pageBuilder(
                  context: context,
                  state: state,
                  child: AudioCallScreen(
                    incidentId: incidentId,
                    chatGroupId: chatGroupId, // Pass chat group ID
                    onlineCount: onlineCount,
                    totalMembers: totalMembers,
                    participants: participants,
                    callId: callId,
                    roomId: roomId,
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.videoCallScreen,
              name: Routes.videoCallScreen,
              pageBuilder: (context, state) {
                Map<String, dynamic> args = {};
                if (state.extra != null) {
                  if (state.extra is Map) {
                    final extraMap = state.extra as Map;
                    args = Map<String, dynamic>.from(
                      extraMap.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    );
                  }
                }
                final incidentId = args['incidentId']?.toString() ?? '';
                final chatGroupId =
                    args['chatGroupId']?.toString() ?? ''; // Get chat group ID
                final onlineCount = args['onlineCount'] as int? ?? 0;
                final totalMembers = args['totalMembers'] as int? ?? 0;
                final participants =
                    args['participants'] as List<ChatMember>? ?? [];
                final callId = args['callId']?.toString();
                final roomId = args['roomId']?.toString();

                return pageBuilder(
                  context: context,
                  state: state,
                  child: VideoCallScreen(
                    incidentId: incidentId,
                    chatGroupId: chatGroupId, // Pass chat group ID
                    onlineCount: onlineCount,
                    totalMembers: totalMembers,
                    participants: participants,
                    callId: callId,
                    roomId: roomId,
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.notificationsScreen,
              name: Routes.notificationsScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: NotificationsScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.erTeamMemberScreen,
              name: Routes.erTeamMemberScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: MyTaskDashboardScreen(role: 'member'),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.hseDashboardScreen,
              name: Routes.hseDashboardScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: HseDashboardScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.employeeteamscreen,
              name: Routes.employeeteamscreen,
              pageBuilder: (context, state) {
                Map<String, dynamic> args = {};
                if (state.extra != null) {
                  if (state.extra is Map) {
                    // Convert LinkedHashMap<dynamic, dynamic> to Map<String, dynamic>
                    final extraMap = state.extra as Map;
                    args = Map<String, dynamic>.from(
                      extraMap.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    );
                  }
                }
                final roleId = args["roleId"]?.toString() ?? '';
                return pageBuilder(
                  context: context,
                  state: state,
                  child: EmployeeTeamScreen(roleId: roleId),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.viewprojectscreen,
              name: Routes.viewprojectscreen,
              pageBuilder: (context, state) {
                Map<String, dynamic> args = {};
                if (state.extra != null) {
                  if (state.extra is Map) {
                    // Convert LinkedHashMap<dynamic, dynamic> to Map<String, dynamic>
                    final extraMap = state.extra as Map;
                    args = Map<String, dynamic>.from(
                      extraMap.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    );
                  }
                }
                final clientId = args['clientId']?.toString() ?? '';
                final clientName = args['clientName']?.toString() ?? '';
                final imageUrl = args['imageUrl']?.toString();
                return pageBuilder(
                  context: context,
                  state: state,
                  child: ClientProjectScreen(
                    clientId: clientId,
                    clientName: clientName,
                    imageUrl: imageUrl,
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.projectListScreen,
              name: Routes.projectListScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: ProjectListScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.rolesScreen,
              name: Routes.rolesScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: RolesScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.erteamleader,
              name: Routes.erteamleader,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: ErTeamLeader(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.erTeamMemberTasksScreen,
              name: Routes.erTeamMemberTasksScreen,
              pageBuilder: (context, state) {
                Map<String, dynamic> args = {};
                if (state.extra != null) {
                  if (state.extra is Map) {
                    final extraMap = state.extra as Map;
                    args = Map<String, dynamic>.from(
                      extraMap.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    );
                  }
                }
                final incidentId = args['incidentId']?.toString();
                final caseType = args['caseType']?.toString();
                final reportedDate = args['reportedDate']?.toString();
                return pageBuilder(
                  context: context,
                  state: state,
                  child: InProgressPage(
                    incidentId: incidentId,
                    role: 'member',
                    caseType: caseType,
                    reportedDate: reportedDate,
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.erTeamMemberTaskDetailsScreen,
              name: Routes.erTeamMemberTaskDetailsScreen,
              pageBuilder: (context, state) {
                Map<String, dynamic> args = {};
                if (state.extra != null) {
                  if (state.extra is Map) {
                    final extraMap = state.extra as Map;
                    args = Map<String, dynamic>.from(
                      extraMap.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    );
                  }
                }
                final taskId = args['taskId']?.toString();
                final incidentId = args['incidentId']?.toString();
                return pageBuilder(
                  context: context,
                  state: state,
                  child: ErTeamLeaderTaskDetailsScreen(
                    task: args['task'],
                    taskId: taskId,
                    incidentId: incidentId,
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.organizationeditscreen,
              name: Routes.organizationeditscreen,
              pageBuilder: (context, state) {
                Map<String, dynamic> args = {};
                if (state.extra != null) {
                  if (state.extra is Map) {
                    // Convert LinkedHashMap<dynamic, dynamic> to Map<String, dynamic>
                    final extraMap = state.extra as Map;
                    args = Map<String, dynamic>.from(
                      extraMap.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    );
                  }
                }
                final roleId = args['roleId']?.toString() ?? '';
                return pageBuilder(
                  context: context,
                  state: state,
                  child: OrganizedEditMember(roleId: roleId),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.uploadDocumentsScreen,
              name: Routes.uploadDocumentsScreen,
              pageBuilder: (context, state) {
                Map<String, dynamic> args = {};
                if (state.extra != null) {
                  if (state.extra is Map) {
                    // Convert LinkedHashMap<dynamic, dynamic> to Map<String, dynamic>
                    final extraMap = state.extra as Map;
                    args = Map<String, dynamic>.from(
                      extraMap.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    );
                  }
                }
                final selectedCategory = args['selectedCategory']?.toString();
                return pageBuilder(
                  context: context,
                  state: state,
                  child: UploadDocumentsScreen(
                    selectedCategory: selectedCategory,
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.overviewScreen,
              name: Routes.overviewScreen,
              pageBuilder: (context, state) {
                // Extract incidentId and userId from state.extra if provided
                String? incidentId;
                String? userId;

                if (state.extra is Map) {
                  final args = state.extra as Map;
                  incidentId = args['incidentId']?.toString();
                  userId = args['userId']?.toString();
                }

                return pageBuilder(
                  context: context,
                  state: state,
                  child: OverviewScreen(incidentId: incidentId, userId: userId),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.erTeamOverviewScreen,
              name: Routes.erTeamOverviewScreen,
              pageBuilder: (context, state) {
                String? incidentId;

                // Handle LinkedHashMap (common when using pushNamed with extra)
                if (state.extra is LinkedHashMap) {
                  final args = state.extra as LinkedHashMap;
                  incidentId = args['incidentId']?.toString();
                } else if (state.extra is Map) {
                  // Handle regular Map
                  final extraMap = state.extra as Map;
                  final args = Map<String, dynamic>.from(
                    extraMap.map(
                      (key, value) => MapEntry(key.toString(), value),
                    ),
                  );
                  incidentId = args['incidentId']?.toString();
                }

                return pageBuilder(
                  context: context,
                  state: state,
                  child: ErTeamOverViewScreen(incidentId: incidentId),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.erTeamApproverTaskDetailsScreen,
              name: Routes.erTeamApproverTaskDetailsScreen,
              pageBuilder: (context, state) {
                Map<String, dynamic> args = {};
                if (state.extra != null) {
                  if (state.extra is Map) {
                    final extraMap = state.extra as Map;
                    args = Map<String, dynamic>.from(
                      extraMap.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    );
                  }
                }
                return pageBuilder(
                  context: context,
                  state: state,
                  child: ErTeamApproverTaskDetailsScreen(
                    taskId: args['taskId']?.toString() ?? '',
                    incidentId: args['incidentId']?.toString() ?? '',
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.inProgressScreen,
              name: Routes.inProgressScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: MyTaskDashboardScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.taskDetails,
              name: Routes.taskDetails,
              pageBuilder: (context, state) {
                String? incidentId;
                if (state.extra is LinkedHashMap) {
                  final args = state.extra as LinkedHashMap;
                  incidentId = args['incidentId']?.toString();
                } else if (state.extra is Map) {
                  final extraMap = state.extra as Map;
                  incidentId = Map<String, dynamic>.from(
                    extraMap.map(
                      (key, value) => MapEntry(key.toString(), value),
                    ),
                  )['incidentId']?.toString();
                }
                String? caseType;
                String? reportedDate;
                if (state.extra is LinkedHashMap) {
                  final args = state.extra as LinkedHashMap;
                  caseType = args['caseType']?.toString();
                  reportedDate = args['reportedDate']?.toString();
                } else if (state.extra is Map) {
                  final extraMap = Map<String, dynamic>.from(
                    (state.extra as Map).map(
                      (key, value) => MapEntry(key.toString(), value),
                    ),
                  );
                  caseType = extraMap['caseType']?.toString();
                  reportedDate = extraMap['reportedDate']?.toString();
                }
                return pageBuilder(
                  context: context,
                  state: state,
                  child: InProgressPage(
                    incidentId: incidentId,
                    caseType: caseType,
                    reportedDate: reportedDate,
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.preliminaryReportScreen,
              name: Routes.preliminaryReportScreen,
              pageBuilder: (context, state) {
                String? incidentId;
                if (state.extra is LinkedHashMap) {
                  final args = state.extra as LinkedHashMap;
                  incidentId = args['incidentId']?.toString();
                } else if (state.extra is Map) {
                  final args = state.extra as Map;
                  incidentId = args['incidentId']?.toString();
                }
                return pageBuilder(
                  context: context,
                  state: state,
                  child: PreliminaryReportScreen(incidentId: incidentId ?? ''),
                  transitionType: PageTransition.fade,
                );
              },
            ),

            GoRoute(
              path: Routes.login,
              name: Routes.login,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: LoginScreen(),
                transitionType: PageTransition.fade,
              ),
            ),

            // ─────────────────────────────────────────────────────────────────
            // Investigation Routes
            // ─────────────────────────────────────────────────────────────────
            GoRoute(
              path: Routes.investigationTlTaskScreen,
              name: Routes.investigationTlTaskScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const InvestigationTlTaskScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.investigationTlTaskListScreen,
              name: Routes.investigationTlTaskListScreen,
              pageBuilder: (context, state) {
                String incidentId = 'INC118';
                String incidentType = 'Incident';
                if (state.extra is Map) {
                  final args = Map<String, dynamic>.from(
                    (state.extra as Map).map(
                      (k, v) => MapEntry(k.toString(), v),
                    ),
                  );
                  incidentId = args['incidentId']?.toString() ?? incidentId;
                  incidentType =
                      args['incidentType']?.toString() ?? incidentType;
                }
                return pageBuilder(
                  context: context,
                  state: state,
                  child: InvestigationTlTaskListScreen(
                    incidentId: incidentId,
                    incidentType: incidentType,
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.investigationTlTaskDetailScreen,
              name: Routes.investigationTlTaskDetailScreen,
              pageBuilder: (context, state) {
                String taskId = '';
                if (state.extra is Map) {
                  final args = Map<String, dynamic>.from(
                    (state.extra as Map).map(
                      (k, v) => MapEntry(k.toString(), v),
                    ),
                  );
                  taskId = args['taskId']?.toString() ?? taskId;
                }
                return pageBuilder(
                  context: context,
                  state: state,
                  child: InvestigationTlTaskDetailScreen(taskId: taskId),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.investigationTeamSetupScreen,
              name: Routes.investigationTeamSetupScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const InvestigationTeamSetupScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.primaryInvestigatorScreen,
              name: Routes.primaryInvestigatorScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const PrimaryInvestigatorDashboardScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.primaryInvestigatorDetailScreen,
              name: Routes.primaryInvestigatorDetailScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const PrimaryInvestigatorDetailScreen(incidentId: '',),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.investigationMemberScreen,
              name: Routes.investigationMemberScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const InvestigationMemberDashboardScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.investigationMemberTaskScreen,
              name: Routes.investigationMemberTaskScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const InvestigationMemberTaskScreen(incidentId: ''),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.investigationApproverScreen,
              name: Routes.investigationApproverScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const InvestigationApproverDashboardScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.investigationApproverDetailScreen,
              name: Routes.investigationApproverDetailScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const InvestigationApproverDetailScreen(incidentId: ''),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.rcaWorkflowBoardScreen,
              name: Routes.rcaWorkflowBoardScreen,
              pageBuilder: (context, state) {
                // Determine incidentId from state parameters
                String? incidentId;
                if (state.extra is Map) {
                  final args = state.extra as Map;
                  incidentId = args['incidentId']?.toString();
                } else if (state.extra is LinkedHashMap) {
                  final args = state.extra as LinkedHashMap;
                  incidentId = args['incidentId']?.toString();
                }
                
                return pageBuilder(
                  context: context,
                  state: state,
                  child: RcaWorkflowBoardScreen(incidentId: incidentId),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.investigationTeamMemberDashboardScreen,
              name: Routes.investigationTeamMemberDashboardScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const InvestigationTeamMemberDashboardScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.investigationTeamMemberTasksScreen,
              name: Routes.investigationTeamMemberTasksScreen,
              pageBuilder: (context, state) {
                String? incidentId;
                if (state.extra is Map) {
                  final args = state.extra as Map;
                  incidentId = args['incidentId']?.toString();
                } else if (state.extra is LinkedHashMap) {
                  final args = state.extra as LinkedHashMap;
                  incidentId = args['incidentId']?.toString();
                }
                
                return pageBuilder(
                  context: context,
                  state: state,
                  child: InvestigationTeamMemberTasksScreen(incidentId: incidentId ?? ''),
                  transitionType: PageTransition.fade,
                );
              },
            ),
            GoRoute(
              path: Routes.investigationTeamMemberTaskDetailsScreen,
              name: Routes.investigationTeamMemberTaskDetailsScreen,
              pageBuilder: (context, state) {
                String? incidentId;
                String? taskId;
                if (state.extra is Map) {
                  final args = state.extra as Map;
                  incidentId = args['incidentId']?.toString();
                  taskId = args['taskId']?.toString();
                } else if (state.extra is LinkedHashMap) {
                  final args = state.extra as LinkedHashMap;
                  incidentId = args['incidentId']?.toString();
                  taskId = args['taskId']?.toString();
                }
                
                return pageBuilder(
                  context: context,
                  state: state,
                  child: InvestigationTeamMemberTaskDetailsScreen(
                    incidentId: incidentId,
                    taskId: taskId,
                  ),
                  transitionType: PageTransition.fade,
                );
              },
            ),

            GoRoute(
              path: Routes.settingsScreen,
              name: Routes.settingsScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const CommonSettingsScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.noAccessScreen,
              name: Routes.noAccessScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const NoAccessScreen(),
                transitionType: PageTransition.fade,
              ),
            ),

            GoRoute(
              path: Routes.incidentReportDetails,
              name: Routes.incidentReportDetails,
              builder: (context, state) {
                String? incidentId;
                if (state.extra is LinkedHashMap) {
                  final args = state.extra as LinkedHashMap;
                  incidentId = args['incidentId'] as String?;
                }
                return IncidentReportDetailsScreen(incidentId: incidentId);
              },
            ),
            GoRoute(
              path: Routes.loader,
              name: Routes.loader,
              builder: (context, state) {
                return const LogoLoader(canPop: true);
              },
            ),
            GoRoute(
              path: Routes.forgotPassword,
              name: Routes.forgotPassword,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const ForgotPasswordScreen(),
              ),
            ),
            GoRoute(
              path: Routes.otpVerification,
              name: Routes.otpVerification,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const OtpVerificationScreen(),
              ),
            ),
            GoRoute(
              path: Routes.resetPassword,
              name: Routes.resetPassword,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const ResetPasswordScreen(),
              ),
            ),
            GoRoute(
              path: Routes.resetPasswordAuth,
              name: Routes.resetPasswordAuth,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const ResetPasswordAuthScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.userManagementScreen,
              name: Routes.userManagementScreen,
              pageBuilder: (context, state) => pageBuilder(
                context: context,
                state: state,
                child: const UserManagementScreen(),
                transitionType: PageTransition.fade,
              ),
            ),
            GoRoute(
              path: Routes.getRouterPath(Routes.homeScreen),
              name: Routes.homeScreen,
              pageBuilder: (context, state) {
                return pageBuilder(
                  context: context,
                  state: state,
                  child: const HomeScreen(),
                  transitionType: PageTransition.leftToRight,
                );
              },
              routes: [
                GoRoute(
                  path: Routes.reportIncident,
                  name: Routes.reportIncident,
                  builder: (context, state) {
                    String? incidentId;
                    if (state.extra is Map) {
                      final args = state.extra as Map;
                      incidentId = args['incidentId']?.toString();
                    }
                    return ReportIncident(incidentId: incidentId);
                  },
                ),
                GoRoute(
                  path: Routes.incidentApproval,
                  name: Routes.incidentApproval,
                  builder: (context, state) {
                    String? incidentId;
                    String? initialDropdownValue;
                    bool isEditRequired = true;
                    bool isApprover = false;
                    if (state.extra is LinkedHashMap) {
                      final args = state.extra as LinkedHashMap;
                      incidentId = args['incidentId'] as String?;
                      initialDropdownValue =
                          args['initialDropdownValue'] as String?;
                      isEditRequired = args['isEditRequired'] is bool
                          ? args['isEditRequired']
                          : true;
                      isApprover =
                          args['isApprover'] is bool ? args['isApprover'] : false;
                    }
                    return IncidentApprovalScreen(
                      incidentId: incidentId ?? '',
                      initialDropdownValue: initialDropdownValue,
                      isEditRequired: isEditRequired,
                      isApprover: isApprover,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static void resetRouter() {
    _router = null;
  }
}

/// Opens a screen based on the route name
/// If [clearOldStacks] is true, it uses pushReplacement; otherwise pushNamed
void openScreen(
  String routeName, {
  bool clearOldStacks = false,
  bool shouldReplace = false,
  Map? args,
}) {
  final ctx = NavObserver.getCtx();
  if (ctx == null) {
    return;
  }

  if (clearOldStacks) {
    ctx.goNamed(routeName, extra: args); // Replaces the stack
  } else if (shouldReplace) {
    ctx.pushReplacementNamed(routeName, extra: args); // Replaces current screen
  } else {
    ctx.pushNamed(routeName, extra: args); // Adds to the stack
  }
}

/// Navigate to loader screen
void showLoader(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const LogoLoader(canPop: false),
  );
}

void hideLoader(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

/// Back navigation helper
void back({dynamic result}) {
  final ctx = NavObserver.getCtx();
  if (ctx == null) return;

  final router = GoRouter.of(ctx);

  if (router.canPop()) {
    router.pop(result);
  }
}

/// Custom Page Builder with transition animations
class AppCustomTransitionPage<T> extends CustomTransitionPage<T> {
  AppCustomTransitionPage({
    required super.child,
    required String super.name,
    required PageTransition transitionType,
    super.arguments,
    super.restorationId,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return _buildTransition(
             animation,
             secondaryAnimation,
             child,
             transitionType,
           );
         },
       );
}

/// Available page transition types
enum PageTransition {
  fade,
  rightToLeft,
  leftToRight,
  upToDown,
  downToUp,
  scale,
  rotate,
  size,
  rightToLeftWithFade,
  leftToRightWithFade,
}

/// Build the transitions based on the specified type
Widget _buildTransition(
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
  PageTransition transitionType,
) {
  const Curve curve = Curves.easeInOut;
  final CurvedAnimation curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: curve,
  );

  switch (transitionType) {
    case PageTransition.fade:
      return FadeTransition(opacity: curvedAnimation, child: child);

    case PageTransition.rightToLeft:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );

    case PageTransition.leftToRight:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );

    case PageTransition.upToDown:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );

    case PageTransition.downToUp:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );

    case PageTransition.scale:
      return ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
        child: child,
      );

    case PageTransition.rotate:
      return RotationTransition(
        turns: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
        child: child,
      );

    case PageTransition.size:
      return SizeTransition(sizeFactor: curvedAnimation, child: child);

    case PageTransition.rightToLeftWithFade:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(opacity: curvedAnimation, child: child),
      );

    case PageTransition.leftToRightWithFade:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(opacity: curvedAnimation, child: child),
      );
  }
}

/// Custom Page Builder that adds page transitions
Page<dynamic> pageBuilder<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  PageTransition transitionType = PageTransition.fade,
}) {
  return AppCustomTransitionPage<T>(
    child: child,
    name: state.name ?? state.path ?? 'unknown',
    transitionType: transitionType,
    arguments: state.extra,
  );
}
