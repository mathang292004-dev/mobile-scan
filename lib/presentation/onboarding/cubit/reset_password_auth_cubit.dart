import 'package:emergex/base/cubit/emergex_app_cubit.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/preference_helper.dart';
import 'package:emergex/presentation/onboarding/model/reset_password_request_model.dart';
import 'package:emergex/presentation/onboarding/use_cases/reset_password_auth_use_case.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResetPasswordAuthState extends Equatable {
  final ProcessState status;
  final String? errorMessage;
  final bool obscureCurrentPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;

  const ResetPasswordAuthState({
    this.status = ProcessState.none,
    this.errorMessage,
    this.obscureCurrentPassword = true,
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
  });

  ResetPasswordAuthState copyWith({
    ProcessState? status,
    String? errorMessage,
    bool? obscureCurrentPassword,
    bool? obscureNewPassword,
    bool? obscureConfirmPassword,
  }) {
    return ResetPasswordAuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      obscureCurrentPassword: obscureCurrentPassword ?? this.obscureCurrentPassword,
      obscureNewPassword: obscureNewPassword ?? this.obscureNewPassword,
      obscureConfirmPassword: obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        obscureCurrentPassword,
        obscureNewPassword,
        obscureConfirmPassword,
      ];
}

class ResetPasswordAuthCubit extends Cubit<ResetPasswordAuthState> {
  final ResetPasswordAuthUseCase _resetPasswordUseCase;

  final formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  ResetPasswordAuthCubit(this._resetPasswordUseCase)
      : super(const ResetPasswordAuthState());

  void toggleObscureCurrent() => emit(
        state.copyWith(obscureCurrentPassword: !state.obscureCurrentPassword),
      );
  void toggleObscureNew() =>
      emit(state.copyWith(obscureNewPassword: !state.obscureNewPassword));
  void toggleObscureConfirm() => emit(
        state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword),
      );

  String? validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) return TextHelper.passwordRequired;
    if (value.contains(' ')) return TextHelper.passwordNoSpaces;
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return TextHelper.passwordRequired;
    if (value.contains(' ')) return TextHelper.passwordNoSpaces;
    if (value == currentPasswordController.text) return TextHelper.passwordMustDiffer;
    final isValid = value.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'[a-z]').hasMatch(value) &&
        RegExp(r'[0-9]').hasMatch(value) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value);
    return isValid ? null : TextHelper.passwordStrengthHint;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return TextHelper.passwordRequired;
    if (value.contains(' ')) return TextHelper.passwordNoSpaces;
    if (value != newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> handleResetPassword() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    emit(state.copyWith(status: ProcessState.loading));

    // For authenticated reset, we use the current user's email if needed by API,
    // or the API might infer it from the Bearer token.
    // Based on requirements from previous turns, email is part of the payload.
    // In a real app, this would come from a Session/Auth Cubit.
    // Assuming for now it's passed or available.
    
    final request = ResetPasswordRequestModel(
      email: AppDI.emergexAppCubit.state.userPermissions?.email ?? "", // This should be populated from session if needed, or inferred by backend
      currentPassword: currentPasswordController.text,
      newPassword: newPasswordController.text,
    );

    try {
      final response = await _resetPasswordUseCase.execute(request);
      if (response.success == true) {
        emit(state.copyWith(status: ProcessState.done));
      } else {
        emit(
          state.copyWith(
            status: ProcessState.error,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: ProcessState.error, errorMessage: e.toString()),
      );
    }
  }

  void clearFields() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    emit(const ResetPasswordAuthState());
  }

  void reset() async{
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
     await PreferenceHelper().clearAll();
    emit(const ResetPasswordAuthState());
  }

  @override
  Future<void> close() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    return super.close();
  }
}
