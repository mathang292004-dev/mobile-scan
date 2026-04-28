import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_observer.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart'; // For ImageFilter
import 'package:emergex/helpers/widgets/feedback/app_loader.dart' show loaderService;

class SessionExpiredScreen extends StatelessWidget {
  final double size; // overall size of the loader
  final bool canPop; // whether user can pop/back when loader is shown

  const SessionExpiredScreen({super.key, this.size = 75, this.canPop = true});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image
                        Image.asset(Assets.sessionExpiredImg, height: 200),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          TextHelper.sessionExpiredTitle,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: ColorHelper.primaryColor,
                              ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          TextHelper.sessionExpiredMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                letterSpacing: -0.2,
                                height: 20 / 12, // line-height ratio
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Button
                        EmergexButton(
                          text: TextHelper.logInBtnTxt,
                          fontWeight: FontWeight.w600,
                          onPressed: () {
                            sessionProvider.startSession();
                            openScreen(Routes.login, clearOldStacks: true);
                          },
                          width: MediaQuery.of(context).size.width * 0.3,
                          borderRadius: 8,
                          textColor: Colors.white,
                          colors: const [
                            Color(0xFF3DA229), // gradient start
                            Color(0xFF247814), // gradient end
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SessionProvider extends ChangeNotifier {
  static final SessionProvider _instance = SessionProvider._internal();
  factory SessionProvider() => _instance;
  SessionProvider._internal();

  bool _isSessionExpired = false;

  void expireSession() {
    if (!_isSessionExpired) {
      _isSessionExpired = true;

      // Unregister FCM token on session expiry
      try {
        AppDI.pushNotificationService.unregisterToken();
      } catch (e) {
        debugPrint('Error unregistering FCM token on session expiry: $e');
      }

      // Reset any cubits that may have open dialogs or in-progress uploads
      try { AppDI.addMultiUserCubit.resetForm(); } catch (_) {}
      try { AppDI.userManagementCubit.reset(); } catch (_) {}

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Close any open dialogs/overlays (PopupRoutes like showDialog)
        // before navigating to login, so stale dialog UI doesn't persist.
        try {
          final navigatorState = NavObserver.navKey.currentState;
          if (navigatorState != null) {
            navigatorState.popUntil((route) => route is! PopupRoute);
          }
        } catch (_) {}

        // Force-hide the loader so its internal state is clean for next login
        loaderService.hideLoader();

        notifyListeners();
        // Navigate to login and clear the entire navigation stack
        openScreen(Routes.login, clearOldStacks: true);
      });
    }
  }

  void startSession() {
    if (_isSessionExpired) {
      _isSessionExpired = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  bool get isSessionExpired => _isSessionExpired;
}

final sessionProvider = SessionProvider();
