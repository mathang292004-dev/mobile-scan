import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/presentation/onboarding/utils/onboarding_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashNavigateTo extends SplashState {
  final String route;
  final bool shouldLoadDashboard;

  SplashNavigateTo(this.route, {this.shouldLoadDashboard = false});
}

class SplashNavigateViaNotification extends SplashState {}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 4));

    final token = await AppDI.preferenceHelper.getUserToken();

    if (token.isEmpty) {
      emit(SplashNavigateTo(Routes.getRouterPath(Routes.login)));
      return;
    }

    await AppDI.emergexAppCubit.fetchUserPermissions();

    if (!PermissionHelper.hasAnyScreenAccess()) {
      loaderService.hideLoader();
      emit(SplashNavigateTo(Routes.getRouterPath(Routes.noAccessScreen)));
      return;
    }

    // Wait for push notification service to fully initialize
    debugPrint('SPLASH: Waiting for push notification service...');
    await Future.delayed(const Duration(milliseconds: 500));

    final hasPendingNotification = await _checkForPendingNotification();
    debugPrint('hasPendingNotification: $hasPendingNotification');

    if (hasPendingNotification) {
      debugPrint('SPLASH: Pending notification detected');
      AppDI.pushNotificationService.clearPendingNotification();
      emit(SplashNavigateViaNotification());
      return;
    }

    final dashboardRoute = PermissionHelper.getFirstAccessibleDashboardRoute();
    if (dashboardRoute != null) {
      debugPrint('SPLASH: Navigating to first accessible dashboard');
      emit(
        SplashNavigateTo(
          Routes.getRouterPath(dashboardRoute),
          shouldLoadDashboard: true,
        ),
      );
      return;
    }

    final screenRoute = PermissionHelper.getFirstAccessibleScreenRoute();
    if (screenRoute != null) {
      emit(
        SplashNavigateTo(
          Routes.getRouterPath(screenRoute),
          shouldLoadDashboard: false,
        ),
      );
      return;
    }

    loaderService.hideLoader();
    emit(SplashNavigateTo(Routes.getRouterPath(Routes.noAccessScreen)));
  }

  Future<bool> _checkForPendingNotification() async {
    debugPrint('SPLASH: Checking for pending notification...');
    final hasPending = AppDI.pushNotificationService.hasPendingNotification();
    debugPrint('Has pending notification: $hasPending');

    if (hasPending) {
      try {
        AppDI.notificationCubit.loadNotifications();
      } catch (e) {
        debugPrint('Error loading notifications: $e');
      }
    }

    return hasPending;
  }
}

// ---------------------------------------------------------------------------
// SplashCubit listener helper — used by SplashScreen
// ---------------------------------------------------------------------------

void handleSplashState(BuildContext context, SplashState state) {
  if (state is SplashNavigateTo) {
    if (state.shouldLoadDashboard) OnboardingUtils.loadDashboardData();
    context.go(state.route);
  } else if (state is SplashNavigateViaNotification) {
    OnboardingUtils.loadDashboardData();
    AppDI.pushNotificationService.navigatePendingNotification(context);
  }
}
