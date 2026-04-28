import 'package:dio/dio.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/client_view_cubit/client_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/fetch_members_cubit/fetch_members_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/project_view_cubit/project_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_details_cubit/role_details_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_form_cubit/role_form_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/use_cases/client_use_case/client_use_case.dart';
import 'package:emergex/presentation/emergex_onboarding/use_cases/project_view_use_case/project_use_case.dart';
import 'package:emergex/presentation/emergex_onboarding/use_cases/upload_doc_use_case/upload_doc_use_case.dart';
import 'package:emergex/presentation/ert/er_team_approver/cubit/er_team_approver_dashboard_cubit.dart';
import 'package:emergex/presentation/ert/er_team_approver/use_cases/er_team_approver_dashboard_use_case.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/cubit/er_team_leader_dashboard_cubit.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/use_cases/er_team_leader_dashboard_use_case.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/cubit/my_task_cubit.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/cubit/my_task_dashboard_cubit.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/use_cases/my_task_use_case.dart';
import 'package:emergex/data/remote_data_source/hse_dashboard_remote_data_source.dart';
import 'package:emergex/domain/repo/hse_dashboard_repo.dart';
import 'package:emergex/domain/repo/impl/hse_dashboard_repo_impl.dart';
import 'package:emergex/presentation/hse/use_cases/hse_dashboard_use_case.dart';
import 'package:emergex/presentation/hse/cubit/hse_dashboard_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:emergex/data/remote_data_source/client_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/dashboard_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/incident_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/login_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/password_reset_remote_data_source.dart';
import 'package:emergex/presentation/onboarding/cubit/password_reset_cubit.dart';
import 'package:emergex/data/remote_data_source/project_view_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/upload_doc_remote_data_source.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/repo/dashboard_repo.dart';
import 'package:emergex/domain/repo/client_repo.dart';
import 'package:emergex/domain/repo/project_view_repo.dart';
import 'package:emergex/domain/repo/impl/client_repo_impl.dart';
import 'package:emergex/domain/repo/impl/dashboard_repo_impl.dart';
import 'package:emergex/domain/repo/impl/incident_repo_impl.dart';
import 'package:emergex/domain/repo/impl/login_repo_impl.dart';
import 'package:emergex/domain/repo/impl/project_view_repo_impl.dart';
import 'package:emergex/domain/repo/impl/upload_doc_repo_impl.dart';
import 'package:emergex/domain/repo/incident_repo.dart';
import 'package:emergex/domain/repo/login_repo.dart';
import 'package:emergex/domain/repo/upload_doc_repo.dart';
import 'package:emergex/helpers/preference_helper.dart';
import 'package:emergex/services/push_notification_service.dart';
import 'package:emergex/presentation/investigation/tl_task/cubit/investigation_tl_task_cubit.dart';
import 'package:emergex/presentation/investigation/tl_team_setup/cubit/investigation_team_setup_cubit.dart';
import 'package:emergex/presentation/investigation/primary_investigator/cubit/primary_investigator_cubit.dart';
import 'package:emergex/presentation/investigation/investigation_member/cubit/investigation_member_cubit.dart';
import 'package:emergex/presentation/investigation/investigation_approver/cubit/investigation_approver_cubit.dart';
import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:emergex/presentation/case_report/approver/cubit/approval_view_manager_cubit.dart';
import 'package:emergex/presentation/case_report/approver/cubit/case_approver_dashboard_cubit.dart';
import 'package:emergex/presentation/case_report/approver/cubit/preliminary_report_cubit.dart';
import 'package:emergex/presentation/case_report/approver/use_cases/case_approver_dashboard_use_case.dart';
import 'package:emergex/data/remote_data_source/case_approver_dashboard_remote_data_source.dart';
import 'package:emergex/domain/repo/case_approver_dashboard_repo.dart';
import 'package:emergex/domain/repo/impl/case_approver_dashboard_repo_impl.dart';
import 'package:emergex/presentation/common/cubit/audit_log_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';
import 'package:emergex/presentation/case_report/member/use_cases/dashboard_use_case.dart';
import 'package:emergex/presentation/common/use_cases/get_incident_by_id_use_case.dart';
import 'package:emergex/presentation/case_report/report_emergex/use_cases/upload_incident_use_case.dart';
import 'package:emergex/data/remote_data_source/ert_dashboard_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/my_task_dashboard_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/er_team_approver_dashboard_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/my_task_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/org_structure_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/chat_room_remote_data_source.dart';
import 'package:emergex/domain/repo/er_team_leader_dashboard_repo.dart';
import 'package:emergex/domain/repo/er_team_approver_dashboard_repo.dart';
import 'package:emergex/domain/repo/my_task_repo.dart';
import 'package:emergex/domain/repo/org_structure_repo.dart';
import 'package:emergex/domain/repo/chat_room_repo.dart';
import 'package:emergex/domain/repo/impl/er_team_leader_dashboard_repo_impl.dart';
import 'package:emergex/domain/repo/impl/er_team_approver_dashboard_repo_impl.dart';
import 'package:emergex/domain/repo/impl/my_task_repo_impl.dart';
import 'package:emergex/domain/repo/impl/org_structure_repo_impl.dart';
import 'package:emergex/domain/repo/impl/chat_room_repo_impl.dart';
import 'package:emergex/presentation/chat/cubit/chat_cubit/chat_room_cubit.dart';
import 'package:emergex/presentation/chat/use_cases/chat_room_use_case.dart';
import 'package:emergex/presentation/user_onboarding/cubit/user_management_cubit.dart';
import 'package:emergex/data/remote_data_source/user_management_remote_data_source.dart';
import 'package:emergex/domain/repo/user_management_repo.dart';
import 'package:emergex/domain/repo/impl/user_management_repo_impl.dart';
import 'package:emergex/presentation/user_onboarding/use_cases/add_user_use_case.dart';
import 'package:emergex/presentation/user_onboarding/use_cases/get_users_use_case.dart';
import 'package:emergex/presentation/user_onboarding/cubit/add_single_user_cubit.dart';
import 'package:emergex/presentation/user_onboarding/cubit/add_multi_user_cubit.dart';
import 'package:emergex/presentation/organization_structure/cubit/org_structure_cubit.dart';
import 'package:emergex/presentation/organization_structure/use_cases/org_structure_use_case.dart';
import 'package:emergex/presentation/onboarding/cubit/login_cubit.dart';
import 'package:emergex/presentation/onboarding/cubit/reset_password_auth_cubit.dart';
import 'package:emergex/presentation/onboarding/use_cases/login_use_cases.dart';
import 'package:emergex/presentation/onboarding/use_cases/reset_password_auth_use_case.dart';
import 'package:emergex/services/connectivity_service.dart';
import 'package:emergex/services/socket_service.dart';
import 'package:emergex/services/mediasoup_service.dart';
import 'package:emergex/base/cubit/emergex_app_cubit.dart';
import 'package:emergex/data/remote_data_source/notification_remote_data_source.dart';
import 'package:emergex/domain/repo/notification_repo.dart';
import 'package:emergex/domain/repo/impl/notification_repo_impl.dart';
import 'package:emergex/presentation/common/cubit/notification_cubit.dart';
import 'package:emergex/presentation/common/use_cases/notification_use_case.dart';

final GetIt getIt = GetIt.instance;

class AppDI {
  static bool _isInitialized = false;

  static Future<void> init() async {
    // Prevent duplicate initialization during hot reload
    if (_isInitialized && getIt.isRegistered<PreferenceHelper>()) {
      return;
    }

    // Reset GetIt if already initialized (for hot reload)
    if (_isInitialized) {
      await getIt.reset();
      _isInitialized = false;
    }

    // Core Services
    await _initCoreServices();

    // Remote Data Sources
    _initRemoteDataSources();

    // Repositories
    _initRepositories();

    // Use Cases
    _initUseCases();

    // Cubits/Blocs
    _initCubits();

    _isInitialized = true;
  }

  static Future<void> _initCoreServices() async {
    // Initialize PreferenceHelper
    final preferenceHelper = PreferenceHelper();
    await preferenceHelper.initialize();
    getIt.registerLazySingleton<PreferenceHelper>(() => preferenceHelper);

    // Initialize ConnectivityService
    final connectivityService = ConnectivityService();
    await connectivityService.initialize();
    getIt.registerLazySingleton<ConnectivityService>(() => connectivityService);

    // Initialize SocketService
    final socketService = SocketService();
    getIt.registerLazySingleton<SocketService>(() => socketService);

    // Initialize PushNotificationService
    final pushNotificationService = PushNotificationService();
    getIt.registerLazySingleton<PushNotificationService>(
      () => pushNotificationService,
    );

    // Initialize MediasoupService (requires SocketService and user info)
    // Note: This will be initialized after login with actual user info
    // For now, we register a factory that can be called when needed
    getIt.registerFactoryParam<MediasoupService, String, String>(
      (userId, userName) => MediasoupService(
        socketService: socketService,
        userId: userId,
        userName: userName,
      ),
    );

    // Dio
    getIt.registerLazySingleton<Dio>(() => Dio());

    // Api Client
    getIt.registerLazySingleton<ApiClient>(
      () => ApiClientImpl(getIt(), getIt()),
    );
  }

  static void _initRemoteDataSources() {
    // Login
    getIt.registerLazySingleton<LoginRemoteDataSource>(
      () => LoginRemoteDataSourceImpl(getIt(), getIt()),
    );

    // Password Reset
    getIt.registerLazySingleton<PasswordResetRemoteDataSource>(
      () => PasswordResetRemoteDataSourceImpl(getIt()),
    );

    // Dashboard
    getIt.registerLazySingleton<DashboardRemoteDataSource>(
      () => DashboardRemoteDataSourceImpl(getIt()),
    );

    // Incident
    getIt.registerLazySingleton<IncidentRemoteDataSource>(
      () => IncidentRemoteDataSourceImpl(getIt()),
    );

    // Client
    getIt.registerLazySingleton<ClientRemoteDataSource>(
      () => ClientRemoteDataSourceImpl(getIt()),
    );

    // Project
    getIt.registerLazySingleton<ProjectRemoteDataSource>(
      () => ProjectRemoteDataSourceImpl(getIt()),
    );

    // Upload Document
    getIt
        .registerLazySingleton<OnboardingOrganizationStructureRemoteDataSource>(
          () => OnboardingOrganizationStructureRemoteDataSourceImpl(getIt()),
        );

    // ERT Dashboard (common for TL and Member)
    getIt.registerLazySingleton<ErtDashboardRemoteDataSource>(
      () => ErtDashboardRemoteDataSourceImpl(getIt()),
    );

    // HSE Dashboard
    getIt.registerLazySingleton<HseDashboardRemoteDataSource>(
      () => HseDashboardRemoteDataSourceImpl(getIt()),
    );

    // ER Team Approver Dashboard
    getIt.registerLazySingleton<ErTeamApproverDashboardRemoteDataSource>(
      () => ErTeamApproverDashboardRemoteDataSourceImpl(getIt()),
    );

    // Case Approver Dashboard (case_report flow — separate from ERT approver)
    getIt.registerLazySingleton<CaseApproverDashboardRemoteDataSource>(
      () => CaseApproverDashboardRemoteDataSourceImpl(getIt()),
    );

    // My Task
    getIt.registerLazySingleton<MyTaskRemoteDataSource>(
      () => MyTaskRemoteDataSourceImpl(getIt()),
    );

    // My Task Dashboard
    getIt.registerLazySingleton<MyTaskDashboardRemoteDataSource>(
      () => MyTaskDashboardRemoteDataSourceImpl(getIt()),
    );

    // Organization Structure
    getIt.registerLazySingleton<OrgStructureRemoteDataSource>(
      () => OrgStructureRemoteDataSourceImpl(getIt()),
    );

    // Notification
    getIt.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(getIt()),
    );

    // Chat Room
    getIt.registerLazySingleton<ChatRoomRemoteDataSource>(
      () => ChatRoomRemoteDataSourceImpl(getIt()),
    );
  }

  static void _initRepositories() {
    // Login Repository
    getIt.registerLazySingleton<LoginRepository>(
      () => LoginRepositoryImpl(getIt()),
    );

    // Dashboard Repository
    getIt.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(getIt()),
    );

    // Incident Repository
    getIt.registerLazySingleton<IncidentRepository>(
      () => IncidentRepositoryImpl(getIt()),
    );

    // Client Repository
    getIt.registerLazySingleton<ClientRepository>(
      () => ClientRepositoryImpl(getIt()),
    );

    // Project Repository
    getIt.registerLazySingleton<ProjectRepository>(
      () => ProjectRepositoryImpl(getIt()),
    );

    // Upload Document Repository
    getIt.registerLazySingleton<OnboardingOrganizationStructureRepository>(
      () => OnboardingOrganizationStructureRepositoryImpl(getIt()),
    );

    // ER Team Leader Dashboard Repository
    getIt.registerLazySingleton<ErTeamLeaderDashboardRepository>(
      () => ErTeamLeaderDashboardRepositoryImpl(
        getIt<ErtDashboardRemoteDataSource>(),
      ),
    );

    // HSE Dashboard Repository
    getIt.registerLazySingleton<HseDashboardRepository>(
      () => HseDashboardRepositoryImpl(getIt()),
    );

    // ER Team Approver Dashboard Repository
    getIt.registerLazySingleton<ErTeamApproverDashboardRepository>(
      () => ErTeamApproverDashboardRepositoryImpl(getIt()),
    );

    // Case Approver Dashboard Repository
    getIt.registerLazySingleton<CaseApproverDashboardRepository>(
      () => CaseApproverDashboardRepositoryImpl(getIt()),
    );

    // My Task Repository
    getIt.registerLazySingleton<MyTaskRepository>(
      () => MyTaskRepositoryImpl(getIt()),
    );

    // Organization Structure Repository
    getIt.registerLazySingleton<OrgStructureRepository>(
      () => OrgStructureRepositoryImpl(getIt()),
    );

    // Notification Repository
    getIt.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(getIt()),
    );

    // Chat Room Repository
    getIt.registerLazySingleton<ChatRoomRepository>(
      () => ChatRoomRepositoryImpl(getIt()),
    );
  }

  static void _initUseCases() {
    // Login Use Cases
    getIt.registerLazySingleton<LoginUseCase>(() => LoginUseCase(getIt()));

    // Dashboard Use Cases
    getIt.registerLazySingleton<DashboardUseCase>(
      () => DashboardUseCase(getIt()),
    );
    getIt.registerLazySingleton<GetIncidentByIdUseCase>(
      () => GetIncidentByIdUseCase(getIt()),
    );

    // Incident Use Cases
    getIt.registerLazySingleton<UploadIncidentUseCase>(
      () => UploadIncidentUseCase(getIt()),
    );

    // Client Use Cases
    getIt.registerLazySingleton<ClientUseCase>(() => ClientUseCase(getIt()));

    // Project Use Cases
    getIt.registerLazySingleton<ProjectUseCase>(() => ProjectUseCase(getIt()));

    // ER Team Leader Dashboard Use Cases
    getIt.registerLazySingleton<ErTeamLeaderDashboardUseCase>(
      () => ErTeamLeaderDashboardUseCase(getIt()),
    );

    // HSE Dashboard Use Case
    getIt.registerLazySingleton<HseDashboardUseCase>(
      () => HseDashboardUseCase(getIt()),
    );

    // ER Team Approver Dashboard Use Cases
    getIt.registerLazySingleton<ErTeamApproverDashboardUseCase>(
      () => ErTeamApproverDashboardUseCase(getIt()),
    );

    // Case Approver Dashboard Use Case
    getIt.registerLazySingleton<CaseApproverDashboardUseCase>(
      () => CaseApproverDashboardUseCase(getIt()),
    );

    // My Task Use Cases
    getIt.registerLazySingleton<MyTaskUseCase>(() => MyTaskUseCase(getIt()));

    // My Task Dashboard Use Case
    getIt.registerLazySingleton<MyTaskDashboardUseCase>(
      () => MyTaskDashboardUseCase(getIt()),
    );

    // Upload Document Use Cases
    getIt.registerLazySingleton<OnboardingOrganizationStructureUseCase>(
      () => OnboardingOrganizationStructureUseCase(getIt()),
    );

    // Organization Structure Use Cases
    getIt.registerLazySingleton<OrgStructureUseCase>(
      () => OrgStructureUseCase(getIt()),
    );

    // Notification Use Cases
    getIt.registerLazySingleton<NotificationUseCase>(
      () => NotificationUseCase(getIt()),
    );

    // Chat Room Use Cases
    getIt.registerLazySingleton<ChatRoomUseCase>(
      () => ChatRoomUseCase(getIt()),
    );
    getIt.registerLazySingleton<ResetPasswordAuthUseCase>(
      () => ResetPasswordAuthUseCase(getIt()),
    );
  }

  static void _initCubits() {
    // Emergex App Cubit (Singleton for global access)
    getIt.registerLazySingleton<EmergexAppCubit>(
      () => EmergexAppCubit(getIt(), getIt()),
    );

    // Login Cubit (Singleton for global access)
    getIt.registerLazySingleton<LoginCubit>(() => LoginCubit(getIt()));

    // Password Reset Cubit (Singleton for global access)
    getIt.registerLazySingleton<PasswordResetCubit>(
      () => PasswordResetCubit(getIt()),
    );

    // Dashboard Cubit (Singleton for global access)
    getIt.registerLazySingleton<DashboardCubit>(() => DashboardCubit(getIt()));

    // Incident Details Cubit (Singleton for global access)
    getIt.registerLazySingleton<IncidentDetailsCubit>(
      () => IncidentDetailsCubit(getIt()),
    );

    // Preliminary Report Cubit (Factory - fresh state per screen open)
    getIt.registerFactory<PreliminaryReportCubit>(
      () => PreliminaryReportCubit(getIt()),
    );

    // Audit Log Cubit (Factory - fresh state per dashboard open)
    getIt.registerFactory<AuditLogCubit>(() => AuditLogCubit(getIt()));

    // Approval View Manager Cubit (Factory - one per screen)
    getIt.registerFactory<ApprovalViewManagerCubit>(
      () => ApprovalViewManagerCubit(),
    );

    // Incident File Handle Cubit (Singleton for global access)
    getIt.registerLazySingleton<IncidentFileHandleCubit>(
      () => IncidentFileHandleCubit(getIt()),
    );

    // Client Cubit (Singleton for global access)
    getIt.registerLazySingleton<ClientCubit>(() => ClientCubit(getIt()));

    // Project Cubit (Singleton for global access)
    getIt.registerLazySingleton<ProjectCubit>(() => ProjectCubit(getIt()));

    // Upload Document Cubit (Singleton for global access)
    getIt.registerLazySingleton<OnboardingOrganizationStructureCubit>(
      () => OnboardingOrganizationStructureCubit(getIt()),
    );

    // Role Details Cubit (Singleton for global access)
    getIt.registerLazySingleton<RoleDetailsCubit>(
      () => RoleDetailsCubit(getIt()),
    );

    // Role Form Cubit (Singleton for global access)
    getIt.registerLazySingleton<RoleFormCubit>(() => RoleFormCubit(getIt()));

    // Fetch Members Cubit (Singleton for global access)
    getIt.registerLazySingleton<FetchMembersCubit>(
      () => FetchMembersCubit(getIt()),
    );

    // ER Team Leader Dashboard Cubit (Singleton for global access)
    getIt.registerLazySingleton<ErTeamLeaderDashboardCubit>(
      () => ErTeamLeaderDashboardCubit(getIt()),
    );

    // HSE Dashboard Cubit (Singleton for global access)
    getIt.registerLazySingleton<HseDashboardCubit>(
      () => HseDashboardCubit(),
    );

    // ER Team Approver Dashboard Cubit (Singleton for global access)
    getIt.registerLazySingleton<ErTeamApproverDashboardCubit>(
      () => ErTeamApproverDashboardCubit(getIt()),
    );

    // Case Approver Dashboard Cubit
    getIt.registerLazySingleton<CaseApproverDashboardCubit>(
      () => CaseApproverDashboardCubit(getIt()),
    );

    // My Task Cubit (TL)
    getIt.registerLazySingleton<MyTaskCubit>(() => MyTaskCubit(getIt()));

    // My Task Cubit (Member)
    getIt.registerLazySingleton<MyTaskCubit>(
      () => MyTaskCubit(getIt(), role: 'member'),
      instanceName: 'member',
    );

    // My Task Dashboard Cubit (TL)
    getIt.registerLazySingleton<MyTaskDashboardCubit>(
      () => MyTaskDashboardCubit(getIt()),
    );

    // My Task Dashboard Cubit (Member)
    getIt.registerLazySingleton<MyTaskDashboardCubit>(
      () => MyTaskDashboardCubit(
        MyTaskDashboardUseCase(MyTaskDashboardRemoteDataSourceImpl(getIt())),
        role: 'member',
      ),
      instanceName: 'member',
    );

    // Organization Structure Cubit (Singleton for global access)
    getIt.registerLazySingleton<OrgStructureCubit>(
      () => OrgStructureCubit(getIt()),
    );

    // Notification Cubit (Singleton for global access)
    getIt.registerLazySingleton<NotificationCubit>(
      () => NotificationCubit(getIt()),
    );

    // Chat Room Cubit (Singleton for global access)
    getIt.registerLazySingleton<ChatRoomCubit>(() => ChatRoomCubit(getIt()));

    // User Management Cubit (Singleton for global access)
    // User Management Data Layer
    getIt.registerLazySingleton<UserManagementRemoteDataSource>(
      () => UserManagementRemoteDataSourceImpl(getIt()),
    );
    getIt.registerLazySingleton<UserManagementRepo>(
      () => UserManagementRepoImpl(getIt()),
    );
    getIt.registerLazySingleton<AddUserUseCase>(
      () => AddUserUseCase(getIt()),
    );
    getIt.registerLazySingleton<GetUsersUseCase>(
      () => GetUsersUseCase(getIt()),
    );

    getIt.registerLazySingleton<UserManagementCubit>(
      () => UserManagementCubit(getIt<GetUsersUseCase>(), getIt<UserManagementRepo>()),
    );

    // Add Single User Cubit (Singleton for global access)
    getIt.registerLazySingleton<AddSingleUserCubit>(
      () => AddSingleUserCubit(getIt()),
    );

    // Add Multi User Cubit (Singleton for global access)
    getIt.registerLazySingleton<AddMultiUserCubit>(
      () => AddMultiUserCubit(getIt<UserManagementRepo>()),
    );

    // Investigation Cubits (UI-only with dummy data)
    getIt.registerLazySingleton<InvestigationTlTaskCubit>(
      () => InvestigationTlTaskCubit(),
    );
    getIt.registerLazySingleton<InvestigationTeamSetupCubit>(
      () => InvestigationTeamSetupCubit(),
    );
    getIt.registerLazySingleton<PrimaryInvestigatorCubit>(
      () => PrimaryInvestigatorCubit(),
    );
    getIt.registerLazySingleton<InvestigationMemberCubit>(
      () => InvestigationMemberCubit(),
    );
    getIt.registerLazySingleton<InvestigationApproverCubit>(
      () => InvestigationApproverCubit(),
    );
    getIt.registerLazySingleton<ResetPasswordAuthCubit>(
      () => ResetPasswordAuthCubit(getIt()),
    );
  }

  static Future<void> dispose() async {
    // Dispose services
    final connectivityService = getIt<ConnectivityService>();
    connectivityService.dispose();

    // Dispose socket service
    final socketService = getIt<SocketService>();
    socketService.dispose();

    // Dispose push notification service
    final pushService = getIt<PushNotificationService>();
    pushService.dispose();

    // Reset GetIt
    await getIt.reset();
  }

  // Helper methods for accessing services
  static EmergexAppCubit get emergexAppCubit => getIt<EmergexAppCubit>();
  static LoginCubit get loginCubit => getIt<LoginCubit>();
  static PasswordResetCubit get passwordResetCubit => getIt<PasswordResetCubit>();
  static DashboardCubit get dashboardCubit => getIt<DashboardCubit>();
  static IncidentDetailsCubit get incidentDetailsCubit =>
      getIt<IncidentDetailsCubit>();
  static AuditLogCubit get auditLogCubit => getIt<AuditLogCubit>();
  static ApprovalViewManagerCubit get approvalViewManagerCubit =>
      getIt<ApprovalViewManagerCubit>();
  static IncidentFileHandleCubit get incidentFileHandleCubit =>
      getIt<IncidentFileHandleCubit>();
  static ClientCubit get clientCubit => getIt<ClientCubit>();
  static ProjectCubit get projectCubit => getIt<ProjectCubit>();
  static OnboardingOrganizationStructureCubit
  get onboardingOrganizationStructureCubit =>
      getIt<OnboardingOrganizationStructureCubit>();
  static RoleDetailsCubit get roleDetailsCubit => getIt<RoleDetailsCubit>();
  static RoleFormCubit get roleFormCubit => getIt<RoleFormCubit>();
  static FetchMembersCubit get fetchMembersCubit => getIt<FetchMembersCubit>();
  static ErTeamLeaderDashboardCubit get erTeamLeaderDashboardCubit =>
      getIt<ErTeamLeaderDashboardCubit>();
  static HseDashboardCubit get hseDashboardCubit => getIt<HseDashboardCubit>();
  static ErTeamApproverDashboardCubit get erTeamApproverDashboardCubit =>
      getIt<ErTeamApproverDashboardCubit>();
  static CaseApproverDashboardCubit get caseApproverDashboardCubit =>
      getIt<CaseApproverDashboardCubit>();
  static ErTeamApproverDashboardUseCase get erTeamApproverDashboardUseCase =>
      getIt<ErTeamApproverDashboardUseCase>();
  static MyTaskCubit get myTaskCubit => getIt<MyTaskCubit>();
  static MyTaskCubit get memberTaskCubit =>
      getIt<MyTaskCubit>(instanceName: 'member');
  static MyTaskUseCase get myTaskUseCase => getIt<MyTaskUseCase>();
  static MyTaskDashboardCubit get myTaskDashboardCubit =>
      getIt<MyTaskDashboardCubit>();
  static MyTaskDashboardCubit get memberTaskDashboardCubit =>
      getIt<MyTaskDashboardCubit>(instanceName: 'member');
  static OrgStructureCubit get orgStructureCubit => getIt<OrgStructureCubit>();
  static OrgStructureUseCase get orgStructureUseCase =>
      getIt<OrgStructureUseCase>();
  static NotificationCubit get notificationCubit => getIt<NotificationCubit>();
  static NotificationRepository get notificationRepo =>
      getIt<NotificationRepository>();
  static NotificationUseCase get notificationUseCase =>
      getIt<NotificationUseCase>();
  static ConnectivityService get connectivityService =>
      getIt<ConnectivityService>();
  static SocketService get socketService => getIt<SocketService>();
  static PushNotificationService get pushNotificationService =>
      getIt<PushNotificationService>();
  static PreferenceHelper get preferenceHelper => getIt<PreferenceHelper>();
  static ApiClient get apiClient => getIt<ApiClient>();
  static ChatRoomCubit get chatRoomCubit => getIt<ChatRoomCubit>();
  static ChatRoomUseCase get chatRoomUseCase => getIt<ChatRoomUseCase>();
  static ChatRoomRepository get chatRoomRepository =>
      getIt<ChatRoomRepository>();
  static UserManagementCubit get userManagementCubit =>
      getIt<UserManagementCubit>();
  static AddSingleUserCubit get addSingleUserCubit =>
      getIt<AddSingleUserCubit>();
  static AddMultiUserCubit get addMultiUserCubit =>
      getIt<AddMultiUserCubit>();
  static InvestigationTlTaskCubit get investigationTlTaskCubit =>
      getIt<InvestigationTlTaskCubit>();
  static InvestigationTeamSetupCubit get investigationTeamSetupCubit =>
      getIt<InvestigationTeamSetupCubit>();
  static PrimaryInvestigatorCubit get primaryInvestigatorCubit =>
      getIt<PrimaryInvestigatorCubit>();
  static InvestigationMemberCubit get investigationMemberCubit =>
      getIt<InvestigationMemberCubit>();
  static InvestigationApproverCubit get investigationApproverCubit =>
      getIt<InvestigationApproverCubit>();
  static ResetPasswordAuthCubit get resetPasswordAuthCubit =>
      getIt<ResetPasswordAuthCubit>();
  static PreliminaryReportCubit get preliminaryReportCubit =>
      getIt<PreliminaryReportCubit>();
}
