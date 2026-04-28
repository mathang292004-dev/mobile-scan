import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserSelectionState extends Equatable {
  const UserSelectionState({
    this.selectedUserIds = const {},
    this.initialUserIds = const {},
    this.sessionSelectedUserIds = const {},
    this.searchQuery = '',
  });

  final Set<String> selectedUserIds; // All selected (initial + session)
  final Set<String> initialUserIds; // Initially assigned users
  final Set<String> sessionSelectedUserIds; // Only current session selections
  final String searchQuery;

  factory UserSelectionState.initial() => const UserSelectionState();

  UserSelectionState copyWith({
    Set<String>? selectedUserIds,
    Set<String>? initialUserIds,
    Set<String>? sessionSelectedUserIds,
    String? searchQuery,
  }) {
    return UserSelectionState(
      selectedUserIds: selectedUserIds ?? this.selectedUserIds,
      initialUserIds: initialUserIds ?? this.initialUserIds,
      sessionSelectedUserIds:
          sessionSelectedUserIds ?? this.sessionSelectedUserIds,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    selectedUserIds,
    initialUserIds,
    sessionSelectedUserIds,
    searchQuery,
  ];
}

class UserSelectionCubit extends Cubit<UserSelectionState> {
  UserSelectionCubit({List<AssignedUser>? initialUsers})
    : super(UserSelectionState.initial()) {
    if (initialUsers != null) {
      final initialIds = initialUsers
          .map((user) => user.userId)
          .whereType<String>()
          .toSet();
      emit(
        state.copyWith(
          selectedUserIds: initialIds,
          initialUserIds: initialIds,
          sessionSelectedUserIds: {},
        ),
      );
    }
  }

  void addUser(String userId) {
    final updatedSelectedIds = Set<String>.from(state.selectedUserIds)
      ..add(userId);
    final updatedSessionIds = Set<String>.from(state.sessionSelectedUserIds)
      ..add(userId);

    emit(
      state.copyWith(
        selectedUserIds: updatedSelectedIds,
        sessionSelectedUserIds: updatedSessionIds,
      ),
    );
  }

  void removeUser(String userId) {
    final updatedSelectedIds = Set<String>.from(state.selectedUserIds)
      ..remove(userId);
    final updatedSessionIds = Set<String>.from(state.sessionSelectedUserIds)
      ..remove(userId);

    emit(
      state.copyWith(
        selectedUserIds: updatedSelectedIds,
        sessionSelectedUserIds: updatedSessionIds,
      ),
    );
  }

  void reset() {
    emit(UserSelectionState.initial());
  }

  void initialize(List<AssignedUser> users) {
    final initialIds = users
        .map((user) => user.userId)
        .whereType<String>()
        .toSet();
    emit(
      state.copyWith(
        selectedUserIds: initialIds,
        initialUserIds: initialIds,
        sessionSelectedUserIds: {},
      ),
    );
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  bool isInitialUser(String userId) {
    return state.initialUserIds.contains(userId);
  }

  bool isSessionSelected(String userId) {
    return state.sessionSelectedUserIds.contains(userId);
  }
}
