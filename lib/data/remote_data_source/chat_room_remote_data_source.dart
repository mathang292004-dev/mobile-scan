import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/chat_room/chat_group_response.dart';
import 'package:emergex/data/model/chat_room/chat_message_response.dart';
import 'package:emergex/data/model/chat_room/chat_member_response.dart';
import 'package:emergex/data/model/chat_room/incident_user_response.dart';
import 'package:emergex/data/model/chat_room/chat_request.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

abstract class ChatRoomRemoteDataSource {
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

class ChatRoomRemoteDataSourceImpl implements ChatRoomRemoteDataSource {
  final ApiClient _apiClient;

  ChatRoomRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<CreateChatGroupResponse>> createChatGroup(
    CreateChatGroupRequest request,
  ) async {
    return await _apiClient.request<CreateChatGroupResponse>(
      ApiEndpoints.createChatGroup,
      method: HttpMethod.post,
      data: request.toJson(),
      requiresAuth: true,
      requiresProjectId: true,
      fromJson: (json) {
        final data = json['data'] ?? json;
        return CreateChatGroupResponse.fromJson(data);
      },
    );
  }

  @override
  Future<ApiResponse<ChatMessageResponse>> getChatMessages({
    required String groupId,
    int? before,
    int? after,
  }) async {
    final queryParameters = <String, dynamic>{
      'groupId': groupId,
    };

    if (before != null) {
      queryParameters['before'] = before;
    }
    if (after != null) {
      queryParameters['after'] = after;
    }

    return await _apiClient.request<ChatMessageResponse>(
      ApiEndpoints.getChatMessages,
      method: HttpMethod.get,
      queryParameters: queryParameters,
      requiresAuth: true,
      requiresProjectId: true,
      fromJson: (json) => ChatMessageResponse.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<AddMemberResponse>> addMember(
    AddMemberRequest request,
  ) async {
    return await _apiClient.request<AddMemberResponse>(
      ApiEndpoints.addChatMember,
      method: HttpMethod.post,
      data: request.toJson(),
      requiresAuth: true,
      requiresProjectId: true,
      fromJson: (json) => AddMemberResponse.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<RemoveMemberResponse>> removeMember(
    RemoveMemberRequest request,
  ) async {
    return await _apiClient.request<RemoveMemberResponse>(
      ApiEndpoints.removeChatMember,
      method: HttpMethod.post,
      data: request.toJson(),
      requiresAuth: true,
      requiresProjectId: true,
      fromJson: (json) => RemoveMemberResponse.fromJson(json),
    );
  }

  @override
  Future<ApiResponse<IncidentUserResponse>> getIncidentUsers({
    required String incidentId,
    String? groupId,
  }) async {
    final endpoint =
        ApiEndpoints.getIncidentUsers.replaceAll('{incidentId}', incidentId);

    final queryParameters = <String, dynamic>{};
    if (groupId != null) {
      queryParameters['groupId'] = groupId;
    }

    return await _apiClient.request<IncidentUserResponse>(
      endpoint,
      method: HttpMethod.get,
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      requiresAuth: true,
      requiresProjectId: true,
      fromJson: (json) => IncidentUserResponse.fromJson(json),
    );
  }
}
