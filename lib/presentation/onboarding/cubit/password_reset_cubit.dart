import 'package:emergex/data/remote_data_source/password_reset_remote_data_source.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


enum PasswordResetStatus {
  initial,
  loading,
  otpSent,
  otpVerified,
  passwordUpdated,
  error,
}

class PasswordResetState extends Equatable {
  final PasswordResetStatus status;
  final String? email;
  final String? resetToken;
  final String? errorMessage;
  final String? errorSource;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final int otpUpdateCount;

  const PasswordResetState({
    this.status = PasswordResetStatus.initial,
    this.email,
    this.resetToken,
    this.errorMessage,
    this.errorSource,
    this.obscureNewPassword = true,
    this.obscureConfirmPassword = true,
    this.otpUpdateCount = 0,
  });

  bool get isLoading => status == PasswordResetStatus.loading;

  PasswordResetState copyWith({
    PasswordResetStatus? status,
    String? email,
    String? resetToken,
    String? errorMessage,
    String? errorSource,
    bool? obscureNewPassword,
    bool? obscureConfirmPassword,
    int? otpUpdateCount,
  }) {
    return PasswordResetState(
      status: status ?? this.status,
      email: email ?? this.email,
      resetToken: resetToken ?? this.resetToken,
      errorMessage: errorMessage ?? this.errorMessage,
      errorSource: errorSource ?? this.errorSource,
      obscureNewPassword: obscureNewPassword ?? this.obscureNewPassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      otpUpdateCount: otpUpdateCount ?? this.otpUpdateCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        email,
        resetToken,
        errorMessage,
        errorSource,
        obscureNewPassword,
        obscureConfirmPassword,
        otpUpdateCount,
      ];
}


class PasswordResetCubit extends Cubit<PasswordResetState> {
  final PasswordResetRemoteDataSource _dataSource;

  // ── UI-owned objects (not in state — disposed in close()) ────────────────
  final emailController = TextEditingController();

  final otpControllers = List.generate(6, (_) => TextEditingController());
  final otpFocusNodes = List.generate(6, (_) => FocusNode());

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  PasswordResetCubit(this._dataSource) : super(const PasswordResetState());

  String get currentOtp => otpControllers.map((c) => c.text).join();
  bool get isOtpComplete => currentOtp.length == 6;

  @override
  Future<void> close() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in otpFocusNodes) {
      f.dispose();
    }
    return super.close();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return TextHelper.emailRequired;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) return TextHelper.validEmailAddress;
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return TextHelper.passwordRequired;
    if (value.contains(' ')) return TextHelper.passwordNoSpaces;
    final isValid = value.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'[a-z]').hasMatch(value) &&
        RegExp(r'[0-9]').hasMatch(value) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value);
    return isValid ? null : TextHelper.passwordStrengthHint;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return TextHelper.passwordRequired;
    if (value != newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  void validateAndSendOtp(GlobalKey<FormState> formKey) {
    if (formKey.currentState?.validate() ?? false) {
      sendOtp(emailController.text.trim());
    }
  }

  Future<void> sendOtp(String email) async {
    emit(state.copyWith(status: PasswordResetStatus.loading));
    final result = await _dataSource.sendOtp(email);
    if (result.success == true) {
      emit(state.copyWith(status: PasswordResetStatus.otpSent, email: email));
    } else {
      emit(
        state.copyWith(
          status: PasswordResetStatus.error,
          errorMessage: result.message ?? 'Failed to send OTP',
          errorSource: 'sendOtp',
        ),
      );
    }
  }

  void onOtpChanged(String value, int index) {
    // Strip any non-digit characters that passed through the formatter
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length >= 6) {
      // Full OTP pasted — distribute one digit per field
      for (int i = 0; i < 6; i++) {
        otpControllers[i].text = digits[i];
      }
      otpFocusNodes[5].requestFocus();
      emit(state.copyWith(otpUpdateCount: state.otpUpdateCount + 1));
      return;
    }

    // Normal single-digit entry (or backfill on an already-filled box)
    if (digits.isNotEmpty) {
      // Keep only the last digit if two ended up in one box
      final single = digits[digits.length - 1];
      if (otpControllers[index].text != single) {
        otpControllers[index].text = single;
      }
      if (index < 5) otpFocusNodes[index + 1].requestFocus();
    }

    emit(state.copyWith(otpUpdateCount: state.otpUpdateCount + 1));
  }

  void onOtpKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        otpControllers[index].text.isEmpty &&
        index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
  }

  void handleResend() {
    for (final c in otpControllers) {
      c.clear();
    }
    emit(state.copyWith(otpUpdateCount: state.otpUpdateCount + 1));
    otpFocusNodes[0].requestFocus();
    sendOtp(state.email ?? '');
  }

  Future<void> verifyOtp(String otp) async {
    final email = state.email;
    if (email == null || email.isEmpty) return;

    emit(state.copyWith(status: PasswordResetStatus.loading));
    final result = await _dataSource.verifyOtp(email, otp);
    if (result.success == true && result.data != null) {
      emit(
        state.copyWith(
          status: PasswordResetStatus.otpVerified,
          resetToken: result.data,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: PasswordResetStatus.error,
          errorMessage: result.message ?? TextHelper.invalidOtp,
          errorSource: 'verifyOtp',
        ),
      );
    }
  }

  void toggleObscureNew() =>
      emit(state.copyWith(obscureNewPassword: !state.obscureNewPassword));

  void toggleObscureConfirm() => emit(
        state.copyWith(
          obscureConfirmPassword: !state.obscureConfirmPassword,
        ),
      );

  void validateAndUpdatePassword(GlobalKey<FormState> formKey) {
    if (formKey.currentState?.validate() ?? false) {
      updatePassword(newPasswordController.text);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final resetToken = state.resetToken;
    if (resetToken == null || resetToken.isEmpty) return;

    emit(state.copyWith(status: PasswordResetStatus.loading));
    final result = await _dataSource.updatePassword(resetToken, newPassword);
    if (result.success == true) {
      emit(state.copyWith(status: PasswordResetStatus.passwordUpdated));
    } else {
      emit(
        state.copyWith(
          status: PasswordResetStatus.error,
          errorMessage: result.message ?? 'Failed to update password',
          errorSource: 'updatePassword',
        ),
      );
    }
  }
  void clearOtpFields() {
    for (final c in otpControllers) {
      c.clear();
    }
    emit(state.copyWith(otpUpdateCount: state.otpUpdateCount + 1));
  }

  void clearPasswordFields() {
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  void reset() {
    emailController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    for (final c in otpControllers) {
      c.clear();
    }
    emit(const PasswordResetState());
  }
}
