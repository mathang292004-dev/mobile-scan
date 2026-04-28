import 'dart:io';

import 'package:emergex/data/model/user_management/add_bulk_users_request.dart';
import 'package:emergex/data/model/user_management/validate_csv_request.dart';
import 'package:emergex/data/model/user_management/validate_csv_response.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/domain/repo/user_management_repo.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum AddMultiUserStatus {
  initial,
  picking,
  validating,
  validated,
  uploading,
  success,
  error,
}

class AddMultiUserState extends Equatable {
  final AddMultiUserStatus status;
  final PlatformFile? selectedFile;
  final bool isFileUploaded;
  final List<ValidatedUser> validUsers;
  final List<dynamic> existingUsers;
  final List<dynamic> validationErrors;
  final bool hasUploadError;
  final String? errorMessage;

  const AddMultiUserState({
    this.status = AddMultiUserStatus.initial,
    this.selectedFile,
    this.isFileUploaded = false,
    this.validUsers = const [],
    this.existingUsers = const [],
    this.validationErrors = const [],
    this.hasUploadError = false,
    this.errorMessage,
  });

  AddMultiUserState copyWith({
    AddMultiUserStatus? status,
    PlatformFile? selectedFile,
    bool? isFileUploaded,
    List<ValidatedUser>? validUsers,
    List<dynamic>? existingUsers,
    List<dynamic>? validationErrors,
    bool? hasUploadError,
    String? errorMessage,
    bool clearFile = false,
  }) {
    return AddMultiUserState(
      status: status ?? this.status,
      selectedFile: clearFile ? null : (selectedFile ?? this.selectedFile),
      isFileUploaded: isFileUploaded ?? this.isFileUploaded,
      validUsers: validUsers ?? this.validUsers,
      existingUsers: existingUsers ?? this.existingUsers,
      validationErrors: validationErrors ?? this.validationErrors,
      hasUploadError: hasUploadError ?? this.hasUploadError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedFile,
    isFileUploaded,
    validUsers,
    existingUsers,
    validationErrors,
    hasUploadError,
    errorMessage,
  ];
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class AddMultiUserCubit extends Cubit<AddMultiUserState> {
  final UserManagementRepo _repo;

  AddMultiUserCubit(this._repo) : super(const AddMultiUserState());

  String get _clientId =>
      AppDI.emergexAppCubit.state.userPermissions?.permissions
          .firstOrNull?.clientId ??
      '';

  Future<void> pickFile() async {
    emit(state.copyWith(status: AddMultiUserStatus.picking));

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileSizeMB = file.size / (1024 * 1024);

        if (fileSizeMB > 10) {
          emit(state.copyWith(
            status: AddMultiUserStatus.error,
            hasUploadError: true,
            errorMessage: 'File size exceeds 10 MB limit.',
          ));
          return;
        }

        emit(state.copyWith(
          selectedFile: file,
          isFileUploaded: true,
          hasUploadError: false,
          errorMessage: null,
        ));

        // Immediately validate the CSV
        await _validateCsv(file);
      } else {
        emit(state.copyWith(status: AddMultiUserStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AddMultiUserStatus.error,
        hasUploadError: true,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _validateCsv(PlatformFile platformFile) async {
    if (platformFile.path == null) {
      emit(state.copyWith(
        status: AddMultiUserStatus.error,
        hasUploadError: true,
        errorMessage: 'Could not read file path',
      ));
      return;
    }

    emit(state.copyWith(status: AddMultiUserStatus.validating));

    try {
      final request = ValidateCsvRequest(
        clientId: _clientId,
        file: File(platformFile.path!),
      );

      final response = await _repo.validateCsvUsers(request);

      if (response.success == true && response.data != null) {
        final data = response.data!;
        // When no valid users, store the backend message so the UI can show it
        final noValidUsers = data.validUsers.isEmpty;
        emit(state.copyWith(
          status: AddMultiUserStatus.validated,
          validUsers: data.validUsers,
          existingUsers: data.existingUsers,
          validationErrors: data.errors,
          hasUploadError: false,
          errorMessage: noValidUsers
              ? (response.message?.isNotEmpty == true
                  ? response.message
                  : null)
              : null,
        ));
      } else {
        emit(state.copyWith(
          status: AddMultiUserStatus.error,
          hasUploadError: true,
          errorMessage:
              response.error ?? response.message ?? 'CSV validation failed',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AddMultiUserStatus.error,
        hasUploadError: true,
        errorMessage: 'CSV validation failed: ${e.toString()}',
      ));
    }
  }

  Future<void> uploadUsers() async {
    if (state.validUsers.isEmpty) return;

    emit(state.copyWith(status: AddMultiUserStatus.uploading));

    try {
      final request = AddBulkUsersRequest(
        users: state.validUsers,
        clientId: _clientId,
      );

      final response = await _repo.addBulkUsers(request);

      if (response.success == true && response.data != null) {
        emit(state.copyWith(status: AddMultiUserStatus.success));
      } else {
        emit(state.copyWith(
          status: AddMultiUserStatus.error,
          hasUploadError: true,
          errorMessage:
              response.error ?? response.message ?? 'Failed to add users',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AddMultiUserStatus.error,
        hasUploadError: true,
        errorMessage: e.toString(),
      ));
    }
  }

  void removeFile() {
    emit(const AddMultiUserState());
  }

  void resetForm() {
    emit(const AddMultiUserState());
  }

  String formatFileSize(int bytes, {String? filePath}) {
    int size = bytes;

    // FilePicker returns size=0 on some platforms — fall back to reading from path
    if (size == 0 && filePath != null) {
      try {
        size = File(filePath).lengthSync();
      } catch (_) {}
    }

    if (size <= 0) return '0KB';

    if (size < 1024 * 1024) {
      final kb = size / 1024;
      return '${kb.toStringAsFixed(2)}KB';
    }

    final mb = size / (1024 * 1024);
    return '${mb.toStringAsFixed(2)}MB';
  }
}
