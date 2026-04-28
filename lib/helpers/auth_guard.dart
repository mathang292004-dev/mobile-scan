import 'package:emergex/di/app_di.dart';

class AuthGuard {
  static bool _isLoggingOut = false;

  /// Whether the user is actively logging out.
  static bool get isLoggingOut => _isLoggingOut;

  /// Set the logout state
  static void setLogoutState(bool value) {
    _isLoggingOut = value;
  }

  /// Check if the operation can proceed
  static Future<bool> canProceed() async {
    // 1. Check strict logout flag first
    if (_isLoggingOut) {
      return false;
    }

    // 2. Check strict token existence
    final userToken = await AppDI.preferenceHelper.getUserToken();
    if (userToken.isEmpty) {
      return false;
    }

    return true;
  }
}
