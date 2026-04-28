import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:emergex/presentation/emergex_onboarding/use_cases/upload_doc_use_case/upload_doc_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleDetailsState extends Equatable {
  const RoleDetailsState({
    this.roleDetailsResponse,
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.errorMessage,
    this.sessionSelectedUsers = const {},
    this.confirmSelectionIndexes = const {},
    this.assignedUsers = const [],

  });

  final RoleDetailsResponse? roleDetailsResponse;
  final ProcessState processState;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, Map<String, String>> sessionSelectedUsers;
  final Set<int> confirmSelectionIndexes;
  final List<AssignedUser>? assignedUsers;


  factory RoleDetailsState.initial() => const RoleDetailsState(
    processState: ProcessState.none,
    sessionSelectedUsers: {},
    confirmSelectionIndexes: {},
    assignedUsers: [],

  );

  RoleDetailsState copyWith({
    RoleDetailsResponse? roleDetailsResponse,
    ProcessState? processState,
    bool? isLoading,
    String? errorMessage,
    Map<String, Map<String, String>>? sessionSelectedUsers,
    Set<int>? confirmSelectionIndexes,
    bool clearError = false,
    List<AssignedUser>? assignedUsers,
  }) {
    return RoleDetailsState(
      roleDetailsResponse: roleDetailsResponse ?? this.roleDetailsResponse,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sessionSelectedUsers: sessionSelectedUsers ?? this.sessionSelectedUsers,
      confirmSelectionIndexes:
          confirmSelectionIndexes ?? this.confirmSelectionIndexes,
          assignedUsers: assignedUsers ?? this.assignedUsers,
    );
  }

  @override
  List<Object?> get props => [
    roleDetailsResponse,
    processState,
    isLoading,
    errorMessage,
    sessionSelectedUsers,
    confirmSelectionIndexes,
    assignedUsers,
  ];
}

class RoleDetailsCubit extends Cubit<RoleDetailsState> {
  final OnboardingOrganizationStructureUseCase _useCase;

  RoleDetailsCubit(this._useCase) : super(RoleDetailsState.initial());

  /// Get role details by roleId
  Future<void> getRoleDetails(String roleId) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _useCase.getRoleDetails(roleId);

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            roleDetailsResponse: response.data,
            assignedUsers: response.data?.assignedUsers ?? [],
            processState: ProcessState.done,
            isLoading: false,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ??
                response.message ??
                'Failed to get role details',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to get role details: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  /// Delete assigned user from role (API call)
  Future<void> deleteAssignedUser(String roleId, String userId) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _useCase.deleteAssignedUser(roleId, userId);

      if (response.success == true) {
        // Refresh role details to get updated assigned users list
        await getRoleDetails(roleId);
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ??
                response.message ??
                'Failed to delete assigned user',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to delete assigned user: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  /// Remove member from assigned users list (local state only, no API call)
  void removeMember(String userId) {
    final currentResponse = state.roleDetailsResponse;
    if (currentResponse == null) return;

    final updatedAssignedUsers = currentResponse.assignedUsers
        .where((user) => user.userId != userId)
        .toList();

    final updatedResponse = RoleDetailsResponse(
      roleDetails: currentResponse.roleDetails,
      assignedUsers: updatedAssignedUsers,
    );

    emit(state.copyWith(roleDetailsResponse: updatedResponse));
  }

  /// Add member to assigned users list (local state only, no API call)
  void addMember(String userId, String userName, String email) {
    final currentResponse = state.roleDetailsResponse;
    if (currentResponse == null) return;

    // Check if user already exists
    final userExists = currentResponse.assignedUsers.any(
      (user) => user.userId == userId,
    );

    if (userExists) return;

    final newUser = AssignedUser(userId: userId, name: userName, email: email);

    final updatedAssignedUsers = [...currentResponse.assignedUsers, newUser];

    final updatedResponse = RoleDetailsResponse(
      roleDetails: currentResponse.roleDetails,
      assignedUsers: updatedAssignedUsers,
    );

    emit(state.copyWith(roleDetailsResponse: updatedResponse));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void reset() {
    emit(RoleDetailsState.initial());
  }

  void addToSessionSelection(String userId, Map<String, String> userData) {
    final updatedSelections = Map<String, Map<String, String>>.from(
      state.sessionSelectedUsers,
    );
    updatedSelections[userId] = userData;
    emit(state.copyWith(sessionSelectedUsers: updatedSelections));
  }

  void removeFromSessionSelection(String userId) {
    final updatedSelections = Map<String, Map<String, String>>.from(
      state.sessionSelectedUsers,
    );
    updatedSelections.remove(userId);
    emit(state.copyWith(sessionSelectedUsers: updatedSelections));
  }

  void clearSessionSelections() {
    emit(state.copyWith(sessionSelectedUsers: {}));
  }

  void commitAllSessionSelections() {
    final currentResponse = state.roleDetailsResponse;
    if (currentResponse == null) return;

    final newAssignedUsers = <AssignedUser>[];
    state.sessionSelectedUsers.forEach((userId, userData) {
      final userName = userData["name"] ?? '';
      final email = userData["email"] ?? userData["role"] ?? '';

      if (userId.isNotEmpty && userName.isNotEmpty) {
        final userExists = currentResponse.assignedUsers.any(
          (user) => user.userId == userId,
        );

        if (!userExists) {
          newAssignedUsers.add(
            AssignedUser(userId: userId, name: userName, email: email),
          );
        }
      }
    });

    final updatedAssignedUsers = [
      ...currentResponse.assignedUsers,
      ...newAssignedUsers,
    ];

    final updatedResponse = RoleDetailsResponse(
      roleDetails: currentResponse.roleDetails,
      assignedUsers: updatedAssignedUsers,
    );

    emit(
      state.copyWith(
        roleDetailsResponse: updatedResponse,
        sessionSelectedUsers: {},
      ),
    );
  }

  void addConfirmSelectionIndex(int index) {
    final updatedIndexes = Set<int>.from(state.confirmSelectionIndexes);
    updatedIndexes.add(index);
    emit(state.copyWith(confirmSelectionIndexes: updatedIndexes));
  }

  void removeConfirmSelectionIndex(int index) {
    final updatedIndexes = Set<int>.from(state.confirmSelectionIndexes);
    updatedIndexes.remove(index);
    emit(state.copyWith(confirmSelectionIndexes: updatedIndexes));
  }

  bool isSessionSelected(String userId) {
    return state.sessionSelectedUsers.containsKey(userId);
  }

  bool isConfirming(int index) {
    return state.confirmSelectionIndexes.contains(index);
  }
}
