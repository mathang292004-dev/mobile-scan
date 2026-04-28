import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/chat_room/chat_group_response.dart';
import 'package:emergex/data/model/chat_room/chat_message_response.dart';
import 'package:emergex/data/model/chat_room/chat_member_response.dart';
import 'package:emergex/data/model/chat_room/incident_user_response.dart';
import 'package:emergex/data/model/chat_room/chat_request.dart';

abstract class ChatRoomRepository {
  /// Creates a new chat group for an incident
  Future<ApiResponse<CreateChatGroupResponse>> createChatGroup(
    CreateChatGroupRequest request,
  );

  /// Gets chat messages with pagination
  /// Use [before] to scroll up (older messages) or [after] to scroll down (newer messages)
  /// Do not use both together
  Future<ApiResponse<ChatMessageResponse>> getChatMessages({
    required String groupId,
    int? before,
    int? after,
  });

  /// Adds a member to a chat group
  Future<ApiResponse<AddMemberResponse>> addMember(
    AddMemberRequest request,
  );

  /// Removes a member from a chat group
  Future<ApiResponse<RemoveMemberResponse>> removeMember(
    RemoveMemberRequest request,
  );

  /// Gets users associated with an incident
  /// If [groupId] is provided, filters out users already in the group
  Future<ApiResponse<IncidentUserResponse>> getIncidentUsers({
    required String incidentId,
    String? groupId,
  });
}
