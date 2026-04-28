import 'dart:io';

import 'package:emergex/data/model/user_management/add_user_request.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/country_code_data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/presentation/user_onboarding/use_cases/add_user_use_case.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum AddSingleUserStatus { initial, loading, success, error }

class AddSingleUserState extends Equatable {
  final AddSingleUserStatus status;
  final String? errorMessage;

  // Form fields
  final String name;
  final String email;
  final String phone;
  final Country selectedCountry;
  final String? nameError;
  final String? emailError;
  final String? phoneError;

  // Profile image
  final File? profileImage;
  final String? profileImagePath;

  const AddSingleUserState({
    this.status = AddSingleUserStatus.initial,
    this.errorMessage,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.selectedCountry = kDefaultCountry,
    this.nameError,
    this.emailError,
    this.phoneError,
    this.profileImage,
    this.profileImagePath,
  });

  bool get isFormValid =>
      name.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      phone.trim().isNotEmpty;

  bool get hasImage => profileImage != null || profileImagePath != null;

  AddSingleUserState copyWith({
    AddSingleUserStatus? status,
    String? errorMessage,
    String? name,
    String? email,
    String? phone,
    Country? selectedCountry,
    String? nameError,
    String? emailError,
    String? phoneError,
    File? profileImage,
    String? profileImagePath,
    bool clearNameError = false,
    bool clearEmailError = false,
    bool clearPhoneError = false,
    bool clearImage = false,
  }) {
    return AddSingleUserState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      profileImage: clearImage ? null : (profileImage ?? this.profileImage),
      profileImagePath:
          clearImage ? null : (profileImagePath ?? this.profileImagePath),
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    name,
    email,
    phone,
    selectedCountry,
    nameError,
    emailError,
    phoneError,
    profileImage,
    profileImagePath,
  ];
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class AddSingleUserCubit extends Cubit<AddSingleUserState> {
  final AddUserUseCase _addUserUseCase;

  AddSingleUserCubit(this._addUserUseCase)
      : super(const AddSingleUserState());

  // Persistent controllers — survive widget rebuilds
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  // ── Form field updates ──

  void updateName(String value) {
    emit(state.copyWith(name: value, clearNameError: true));
  }

  void updateEmail(String value) {
    emit(state.copyWith(email: value, clearEmailError: true));
  }

  void updatePhone(String value) {
    // Strip any non-digit characters defensively (the widget already enforces
    // this, but keep the state canonical).
    final digits = value.replaceAll(RegExp(r'\D'), '');
    emit(state.copyWith(phone: digits, clearPhoneError: true));
  }

  void updateCountry(Country country) {
    emit(state.copyWith(selectedCountry: country, clearPhoneError: true));
  }

  // ── Profile image ──

  void setProfileImage(File image, String path) {
    emit(state.copyWith(profileImage: image, profileImagePath: path));
  }

  void clearProfileImage() {
    emit(state.copyWith(clearImage: true));
  }

  // ── Validation ──

  bool validateForm() {
    bool isValid = true;
    String? nameError;
    String? emailError;
    String? phoneError;

    if (state.name.trim().isEmpty) {
      nameError = 'Full Name is required';
      isValid = false;
    }

    if (state.email.trim().isEmpty) {
      emailError = 'Email is required';
      isValid = false;
    } else if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
        .hasMatch(state.email.trim())) {
      emailError = 'Enter a valid email address';
      isValid = false;
    }

    final digits = state.phone.trim();
    if (digits.isEmpty) {
      phoneError = 'Phone Number is required';
      isValid = false;
    } else if (digits.length < 6 ||
        digits.length > 15 ||
        !RegExp(r'^\d+$').hasMatch(digits)) {
      phoneError = TextHelper.invalidPhoneNumber;
      isValid = false;
    }

    emit(state.copyWith(
      nameError: nameError,
      emailError: emailError,
      phoneError: phoneError,
    ));

    return isValid;
  }

  // ── API call ──

  Future<void> addUser() async {
    if (!validateForm()) return;

    emit(state.copyWith(status: AddSingleUserStatus.loading));

    try {
      final clientId =
          AppDI.emergexAppCubit.state.userPermissions?.permissions
              .firstOrNull?.clientId ??
          '';

      final request = AddUserRequest(
        name: state.name.trim(),
        email: state.email.trim(),
        phone: state.phone.trim(),
        dialCode: state.selectedCountry.dialCode,
        status: 'Draft',
        clientId: clientId,
        profileImage: state.profileImage,
      );

      final response = await _addUserUseCase.execute(request);

      if (response.success == true && response.data != null) {
        emit(state.copyWith(status: AddSingleUserStatus.success));
      } else {
        emit(
          state.copyWith(
            status: AddSingleUserStatus.error,
            errorMessage:
                response.error ?? response.message ?? 'Failed to add user',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AddSingleUserStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // ── Reset ──

  void resetState() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    emit(const AddSingleUserState());
  }

  @override
  Future<void> close() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    return super.close();
  }
}
