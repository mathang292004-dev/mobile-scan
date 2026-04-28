import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class UserFilterState extends Equatable {
  final String userName;
  final String role;
  final String mailId;
  final String project;

  const UserFilterState({
    this.userName = '',
    this.role = '',
    this.mailId = '',
    this.project = '',
  });

  factory UserFilterState.initial() => const UserFilterState();

  UserFilterState copyWith({
    String? userName,
    String? role,
    String? mailId,
    String? project,
  }) {
    return UserFilterState(
      userName: userName ?? this.userName,
      role: role ?? this.role,
      mailId: mailId ?? this.mailId,
      project: project ?? this.project,
    );
  }

  @override
  List<Object?> get props => [userName, role, mailId, project];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class UserFilterCubit extends Cubit<UserFilterState> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController mailIdController = TextEditingController();
  final TextEditingController projectController = TextEditingController();
  final UserFilterState _initialState;

  UserFilterCubit({UserFilterState? initialState})
      : _initialState = initialState ?? UserFilterState.initial(),
        super(initialState ?? UserFilterState.initial()) {
    if (initialState != null) {
      userNameController.text = initialState.userName;
      roleController.text = initialState.role;
      mailIdController.text = initialState.mailId;
      projectController.text = initialState.project;
    }
  }

  void updateUserName(String value) => emit(state.copyWith(userName: value));
  void updateRole(String value) => emit(state.copyWith(role: value));
  void updateMailId(String value) => emit(state.copyWith(mailId: value));
  void updateProject(String value) => emit(state.copyWith(project: value));

  bool hasChanges() {
    return state.userName.trim() != _initialState.userName.trim() ||
        state.role.trim() != _initialState.role.trim() ||
        state.mailId.trim() != _initialState.mailId.trim() ||
        state.project.trim() != _initialState.project.trim();
  }

  bool isInitialStateEmpty() {
    return _initialState.userName.isEmpty &&
        _initialState.role.isEmpty &&
        _initialState.mailId.isEmpty &&
        _initialState.project.isEmpty;
  }

  void applyFilters() {
    AppDI.userManagementCubit.applyAdvancedFilters(
      userName: state.userName.trim(),
      role: state.role.trim(),
      email: state.mailId.trim(),
      project: state.project.trim(),
    );
    back();
  }

  void resetFilters() {
    if (isInitialStateEmpty()) {
      back();
    } else {
      userNameController.clear();
      roleController.clear();
      mailIdController.clear();
      projectController.clear();
      emit(UserFilterState.initial());
      AppDI.userManagementCubit.clearAdvancedFilters();
      back();
    }
  }

  @override
  Future<void> close() {
    userNameController.dispose();
    roleController.dispose();
    mailIdController.dispose();
    projectController.dispose();
    return super.close();
  }
}
