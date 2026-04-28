import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingUtils {
  OnboardingUtils._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return TextHelper.emailRequired;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return TextHelper.validEmailAddress;
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return TextHelper.passwordRequired;
    }
    return null;
  }

  static void loadDashboardData() {
    AppDI.dashboardCubit.refreshWithTodayDate(true);
  }

  /// Returns the route path to navigate to after successful authentication.
  /// Handles permission checking and route priority.
  static String getPostAuthRoute() {
    if (!PermissionHelper.hasAnyScreenAccess()) {
      return Routes.getRouterPath(Routes.noAccessScreen);
    }

    final dashboardRoute = PermissionHelper.getFirstAccessibleDashboardRoute();
    if (dashboardRoute != null) {
      return Routes.getRouterPath(dashboardRoute);
    }

    final screenRoute = PermissionHelper.getFirstAccessibleScreenRoute();
    if (screenRoute != null) {
      return Routes.getRouterPath(screenRoute);
    }

    return Routes.getRouterPath(Routes.noAccessScreen);
  }

  /// Navigates after successful authentication. Hides the loader and routes
  /// to the appropriate screen based on user permissions.
  static Future<void> navigateAfterAuth(BuildContext context) async {
    if (!PermissionHelper.hasAnyScreenAccess()) {
      loaderService.hideLoader();
      context.go(Routes.getRouterPath(Routes.noAccessScreen));
      return;
    }

    // Check for pending notification — redirect based on notification type
    if (AppDI.pushNotificationService.hasPendingNotification()) {
      loaderService.hideLoader();
      loadDashboardData();
      AppDI.pushNotificationService.clearPendingNotification();
      await AppDI.pushNotificationService.navigatePendingNotification(context);
      return;
    }

    final dashboardRoute = PermissionHelper.getFirstAccessibleDashboardRoute();
    if (dashboardRoute != null) {
      loaderService.hideLoader();
      loadDashboardData();
      context.go(Routes.getRouterPath(dashboardRoute));
      return;
    }

    final screenRoute = PermissionHelper.getFirstAccessibleScreenRoute();
    if (screenRoute != null) {
      loaderService.hideLoader();
      context.go(Routes.getRouterPath(screenRoute));
      return;
    }

    loaderService.hideLoader();
    context.go(Routes.getRouterPath(Routes.noAccessScreen));
  }
}
