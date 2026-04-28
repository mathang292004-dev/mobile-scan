import 'package:emergex/helpers/widgets/feedback/session_expired_screen.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/client_view_cubit/client_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/project_view_cubit/project_cubit.dart';
import 'package:emergex/presentation/onboarding/cubit/login_cubit.dart';
import 'package:emergex/role/role_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:emergex/base/cubit/emergex_app_cubit.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/app_theme.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';
import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/notification_cubit.dart';
import 'package:emergex/presentation/chat/cubit/chat_cubit/chat_room_cubit.dart';
import 'package:emergex/di/app_di.dart';
import 'helpers/dialog_helper.dart';
import 'helpers/text_helper.dart';
import 'helpers/widgets/utils/unfocus_on_scroll_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    debugPrint('========================================');
    debugPrint('STARTING APP INITIALIZATION');
    debugPrint('========================================');

    // Initialize Firebase
    debugPrint('Step 1: Initializing Firebase...');
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');

    // Initialize Dependency Injection
    debugPrint('Step 2: Initializing Dependency Injection...');
    await AppDI.init();
    debugPrint('Dependency Injection initialized successfully');

    // Initialize Push Notification Service
    debugPrint('Step 3: Getting PushNotificationService instance...');
    final pushService = AppDI.pushNotificationService;
    debugPrint(
      'PushNotificationService instance retrieved: $pushService'  ,
    );

    debugPrint('Step 4: Calling initialize() on PushNotificationService...');
    await pushService.initialize();
    debugPrint('Push notification service initialized successfully');
    debugPrint('========================================');

    // Initialize role manager
    final roleManager = RoleManager();
    await roleManager.initializeRole();

    runApp(
      // DevicePreview(enabled: true, builder: (context) => const MyApp()),
      const MyApp(),
    );
  } catch (e) {
    debugPrint('Error during initialization: $e');
    // Initialize DI even on error
    await AppDI.init();
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<RoleManager>(create: (_) => RoleManager()),
        ChangeNotifierProvider<LoaderService>.value(value: loaderService),
        ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),

        BlocProvider<EmergexAppCubit>.value(value: getIt<EmergexAppCubit>()),
        // Use singleton instance from DI
        BlocProvider<IncidentFileHandleCubit>.value(
          value: getIt<IncidentFileHandleCubit>(),
        ),
        // Use singleton instances from DI
        BlocProvider<DashboardCubit>.value(value: getIt<DashboardCubit>()),
        BlocProvider<LoginCubit>.value(value: getIt<LoginCubit>()),
        BlocProvider<IncidentDetailsCubit>.value(
          value: getIt<IncidentDetailsCubit>(),
        ),
        BlocProvider<ClientCubit>.value(value: getIt<ClientCubit>()),
        BlocProvider<ProjectCubit>.value(value: getIt<ProjectCubit>()),
        BlocProvider<NotificationCubit>.value(
          value: getIt<NotificationCubit>(),
        ),
        BlocProvider<ChatRoomCubit>.value(value: getIt<ChatRoomCubit>()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'EmergeX',
        routerConfig: AppRouter.router,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.0)),
            child: UnfocusOnScrollWrapper(
              child: Consumer<LoaderService>(
                builder: (context, loaderService, child) {
                  bool sessionExpired = context
                      .watch<SessionProvider>()
                      .isSessionExpired;
                  return Stack(
                    children: [
                      child!,
                      if (loaderService.isShowing)
                        const Positioned.fill(child: LogoLoader(canPop: true)),
                      if (sessionExpired)
                        Positioned.fill(
                          child: SessionExpiredScreen(canPop: false),
                        ),
                    ],
                  );
                },
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          showErrorDialog(
            context,
            () => SystemNavigator.pop(),
            () => back(),
            TextHelper.areYouSure,
            TextHelper.areWantToLeaveThisApp,
            TextHelper.yesCancel,
            TextHelper.goBack,
          );
        }
      },
      child: SafeArea(
        bottom: true,
        top: false,
        left: false,
        right: false,
        child: child,
      ),
    );
  }
}
