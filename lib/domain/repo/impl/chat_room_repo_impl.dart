import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/chat_room/chat_group_response.dart';
import 'package:emergex/data/model/chat_room/chat_message_response.dart';
import 'package:emergex/data/model/chat_room/chat_member_response.dart';
import 'package:emergex/data/model/chat_room/incident_user_response.dart';
import 'package:emergex/data/model/chat_room/chat_request.dart';
import 'package:emergex/data/remote_data_source/chat_room_remote_data_source.dart';
import 'package:emergex/domain/repo/chat_room_repo.dart';

class ChatRoomRepositoryImpl implements ChatRoomRepository {
  final ChatRoomRemoteDataSource _remoteDataSource;

  ChatRoomRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<CreateChatGroupResponse>> createChatGroup(
    CreateChatGroupRequest request,
  ) async {
    try {
      return await _remoteDataSource.createChatGroup(request);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<ChatMessageResponse>> getChatMessages({
    required String groupId,
    int? before,
    int? after,
  }) async {
    try {
      return await _remoteDataSource.getChatMessages(
        groupId: groupId,
        before: before,
        after: after,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<AddMemberResponse>> addMember(
    AddMemberRequest request,
  ) async {
    try {
      return await _remoteDataSource.addMember(request);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<RemoveMemberResponse>> removeMember(
    RemoveMemberRequest request,
  ) async {
    try {
      return await _remoteDataSource.removeMember(request);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<IncidentUserResponse>> getIncidentUsers({
    required String incidentId,
    String? groupId,
  }) async {
    try {
      return await _remoteDataSource.getIncidentUsers(
        incidentId: incidentId,
        groupId: groupId,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
