import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/chat_room/chat_request.dart';
import 'package:emergex/data/model/chat_room/chat_group_response.dart';
import 'package:emergex/data/model/chat_room/chat_message_response.dart';
import 'package:emergex/data/model/chat_room/incident_user_response.dart'
    as api;
import 'package:emergex/presentation/chat/use_cases/chat_room_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ChatRoomState extends Equatable {
  final ProcessState processState;
  final bool isLoading;
  final String? errorMessage;
  final CreateChatGroupResponse? chatGroupResponse;
  final ChatGroup? chatGroup;
  final bool alreadyExists;
  final List<ChatMessage> messages;
  final bool hasMore;
  final List<api.IncidentUser> incidentUsers;
  final String? successMessage;

  const ChatRoomState({
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.errorMessage,
    this.chatGroupResponse,
    this.chatGroup,
    this.alreadyExists = false,
    this.messages = const [],
    this.hasMore = true,
    this.incidentUsers = const [],
    this.successMessage,
  });

  factory ChatRoomState.initial() =>
      const ChatRoomState(processState: ProcessState.none);

  ChatRoomState copyWith({
    ProcessState? processState,
    bool? isLoading,
    String? errorMessage,
    CreateChatGroupResponse? chatGroupResponse,
    ChatGroup? chatGroup,
    bool? alreadyExists,
    List<ChatMessage>? messages,
    bool? hasMore,
    List<api.IncidentUser>? incidentUsers,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ChatRoomState(
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      chatGroupResponse: chatGroupResponse ?? this.chatGroupResponse,
      chatGroup: chatGroup ?? this.chatGroup,
      alreadyExists: alreadyExists ?? this.alreadyExists,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      incidentUsers: incidentUsers ?? this.incidentUsers,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        processState,
        isLoading,
        errorMessage,
        chatGroupResponse,
        chatGroup,
        alreadyExists,
        messages,
        hasMore,
        incidentUsers,
        successMessage,
      ];
}

class ChatRoomCubit extends Cubit<ChatRoomState> {
  final ChatRoomUseCase _chatRoomUseCase;

  ChatRoomCubit(this._chatRoomUseCase) : super(ChatRoomState.initial());

  /// Clear cache and reset to initial state
  void clearCache() {
    emit(ChatRoomState.initial());
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null, clearError: true));
  }

  /// Clear success message
  void clearSuccess() {
    emit(state.copyWith(successMessage: null, clearSuccess: true));
  }

  /// Create chat group for incident
  Future<void> createChatGroup(String incidentId) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _chatRoomUseCase.createChatGroup(
        CreateChatGroupRequest(incidentId: incidentId),
      );

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            chatGroupResponse: response.data,
            chatGroup: response.data!.chatGroup,
            alreadyExists: response.data!.alreadyExists ?? false,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage: response.error ?? 'Failed to create chat group',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to create chat group: ${e.toString()}',
        ),
      );
    }
  }

  /// Get chat messages with pagination
  Future<void> getChatMessages({
    required String groupId,
    int? before,
    int? after,
  }) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _chatRoomUseCase.getChatMessages(
        groupId: groupId,
        before: before,
        after: after,
      );

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            messages: response.data!.data ?? [],
            hasMore: (response.data!.data?.length ?? 0) > 0,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage: response.error ?? 'Failed to load messages',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to load messages: ${e.toString()}',
        ),
      );
    }
  }

  /// Add member to chat group
  Future<void> addMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _chatRoomUseCase.addMember(
        AddMemberRequest(groupId: groupId, userId: userId),
      );

      if (response.success == true) {
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            successMessage: response.data?.message ?? 'Member added successfully',
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage: response.error ?? 'Failed to add member',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to add member: ${e.toString()}',
        ),
      );
    }
  }

  /// Remove member from chat group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _chatRoomUseCase.removeMember(
        RemoveMemberRequest(groupId: groupId, userId: userId),
      );

      if (response.success == true) {
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            successMessage: response.data?.message ?? 'Member removed successfully',
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage: response.error ?? 'Failed to remove member',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to remove member: ${e.toString()}',
        ),
      );
    }
  }

  /// Get incident users for chat group
  Future<void> getIncidentUsers({
    required String incidentId,
    String? groupId,
  }) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _chatRoomUseCase.getIncidentUsers(
        incidentId: incidentId,
        groupId: groupId,
      );

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            incidentUsers: response.data!.data ?? [],
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage: response.error ?? 'Failed to load users',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to load users: ${e.toString()}',
        ),
      );
    }
  }

  /// Reset to initial state
  void reset() {
    emit(ChatRoomState.initial());
  }
}
