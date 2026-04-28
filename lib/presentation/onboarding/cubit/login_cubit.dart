import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/onboarding/user_profile.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/auth_guard.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/presentation/onboarding/use_cases/login_use_cases.dart';
import 'package:emergex/presentation/onboarding/utils/onboarding_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginCubit extends Cubit<EmergexAppState> {
  final LoginUseCase loginUseCase;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  LoginCubit(this.loginUseCase) : super(EmergexAppState());

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void toggleRememberMe() {
    emit(state.copyWith(rememberMe: !state.rememberMe));
  }

  /// Validates the form, performs login, then navigates based on permissions.
  Future<void> handleLogin(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (!(formKey.currentState?.validate() ?? false)) return;

    // Allow API calls for login (reset any prior logout guard)
    AuthGuard.setLogoutState(false);

    final user = LoginUser(
      email: emailController.text.trim(),
      password: passwordController.text,
      rememberMe: state.rememberMe,
    );

    try {
      await login(user);

      if (state.onboardingState == ProcessState.done) {
        if (!context.mounted) return;
        showSnackBar(context, TextHelper.loginSuccessful);
        await OnboardingUtils.navigateAfterAuth(context);
        _resetForm();
      }
    } catch (error) {
      if (!context.mounted) return;
      showSnackBar(
        context,
        error.toString().split(':').last.trim(),
        isSuccess: false,
      );
    }
  }

  Future<void> login(LoginUser user) async {
    try {
      loaderService.showLoader();
      emit(state.copyWith(onboardingState: ProcessState.loading));

      final response = await loginUseCase.login(user);

      if (response.success! ||
          (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300)) {
        // Fetch user permissions after successful login
        await AppDI.emergexAppCubit.fetchUserPermissions();

        // Register FCM token with backend after successful login
        try {
          await AppDI.pushNotificationService.registerToken();
        } catch (e) {
          // Silent fail — don't block login if FCM registration fails
          debugPrint('Failed to register FCM token: $e');
        }

        emit(state.copyWith(onboardingState: ProcessState.done));
        // Loader is hidden by navigateAfterAuth / dashboard screen
      } else {
        emit(state.copyWith(onboardingState: ProcessState.error));
        loaderService.hideLoader();
        throw Exception('${response.error}');
      }
    } catch (e) {
      emit(state.copyWith(onboardingState: ProcessState.error));
      loaderService.hideLoader();
      rethrow;
    }
  }

  void _resetForm() {
    emailController.clear();
    passwordController.clear();
    emit(state.copyWith(rememberMe: false, isPasswordVisible: true));
  }

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
