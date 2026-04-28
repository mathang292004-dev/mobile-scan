// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartCallData _$StartCallDataFromJson(Map<String, dynamic> json) =>
    StartCallData(
      chatGroup: json['chatGroup'] as String,
      incident: json['incident'] as String?,
      initiatedBy: json['initiatedBy'] as String,
      callType: $enumDecode(_$CallTypeEnumMap, json['callType']),
      roomId: json['roomId'] as String,
    );

Map<String, dynamic> _$StartCallDataToJson(StartCallData instance) =>
    <String, dynamic>{
      'chatGroup': instance.chatGroup,
      'incident': instance.incident,
      'initiatedBy': instance.initiatedBy,
      'callType': _$CallTypeEnumMap[instance.callType]!,
      'roomId': instance.roomId,
    };

const _$CallTypeEnumMap = {CallType.audio: 'audio', CallType.video: 'video'};

StartCallResponse _$StartCallResponseFromJson(Map<String, dynamic> json) =>
    StartCallResponse(
      success: json['success'] as bool,
      callId: json['callId'] as String,
      roomId: json['roomId'] as String,
      isExisting: json['isExisting'] as bool? ?? false,
    );

Map<String, dynamic> _$StartCallResponseToJson(StartCallResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'callId': instance.callId,
      'roomId': instance.roomId,
      'isExisting': instance.isExisting,
    };

JoinCallData _$JoinCallDataFromJson(Map<String, dynamic> json) => JoinCallData(
  callId: json['callId'] as String,
  userId: json['userId'] as String,
);

Map<String, dynamic> _$JoinCallDataToJson(JoinCallData instance) =>
    <String, dynamic>{'callId': instance.callId, 'userId': instance.userId};

JoinCallResponse _$JoinCallResponseFromJson(Map<String, dynamic> json) =>
    JoinCallResponse(success: json['success'] as bool);

Map<String, dynamic> _$JoinCallResponseToJson(JoinCallResponse instance) =>
    <String, dynamic>{'success': instance.success};

EndCallData _$EndCallDataFromJson(Map<String, dynamic> json) => EndCallData(
  callId: json['callId'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$EndCallDataToJson(EndCallData instance) =>
    <String, dynamic>{'callId': instance.callId, 'status': instance.status};

LeaveCallData _$LeaveCallDataFromJson(Map<String, dynamic> json) =>
    LeaveCallData(
      callId: json['callId'] as String,
      userId: json['userId'] as String,
    );

Map<String, dynamic> _$LeaveCallDataToJson(LeaveCallData instance) =>
    <String, dynamic>{'callId': instance.callId, 'userId': instance.userId};

IncomingCallData _$IncomingCallDataFromJson(Map<String, dynamic> json) =>
    IncomingCallData(
      callId: json['callId'] as String,
      roomId: json['roomId'] as String,
      chatGroup: json['chatGroup'] as String,
      incident: json['incident'] as String?,
      initiatedBy: json['initiatedBy'] as String?,
      callType: $enumDecode(_$CallTypeEnumMap, json['callType']),
    );

Map<String, dynamic> _$IncomingCallDataToJson(IncomingCallData instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'roomId': instance.roomId,
      'chatGroup': instance.chatGroup,
      'incident': instance.incident,
      'initiatedBy': instance.initiatedBy,
      'callType': _$CallTypeEnumMap[instance.callType]!,
    };

NewProducerData _$NewProducerDataFromJson(Map<String, dynamic> json) =>
    NewProducerData(
      producerId: json['producerId'] as String,
      peerId: json['peerId'] as String,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      kind: json['kind'] as String,
      mediaType: json['mediaType'] as String?,
      paused: json['paused'] as bool? ?? false,
      isFrontCamera: json['isFrontCamera'] as bool?,
    );

Map<String, dynamic> _$NewProducerDataToJson(NewProducerData instance) =>
    <String, dynamic>{
      'producerId': instance.producerId,
      'peerId': instance.peerId,
      'userId': instance.userId,
      'userName': instance.userName,
      'kind': instance.kind,
      'mediaType': instance.mediaType,
      'paused': instance.paused,
      'isFrontCamera': instance.isFrontCamera,
    };

ProducerStatusData _$ProducerStatusDataFromJson(Map<String, dynamic> json) =>
    ProducerStatusData(
      producerId: json['producerId'] as String,
      peerId: json['peerId'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      kind: json['kind'] as String?,
      mediaType: json['mediaType'] as String?,
    );

Map<String, dynamic> _$ProducerStatusDataToJson(ProducerStatusData instance) =>
    <String, dynamic>{
      'producerId': instance.producerId,
      'peerId': instance.peerId,
      'userId': instance.userId,
      'userName': instance.userName,
      'kind': instance.kind,
      'mediaType': instance.mediaType,
    };

ParticipantEventData _$ParticipantEventDataFromJson(
  Map<String, dynamic> json,
) => ParticipantEventData(
  peerId: json['peerId'] as String?,
  userId: json['userId'] as String?,
  userName: json['userName'] as String?,
);

Map<String, dynamic> _$ParticipantEventDataToJson(
  ParticipantEventData instance,
) => <String, dynamic>{
  'peerId': instance.peerId,
  'userId': instance.userId,
  'userName': instance.userName,
};

ParticipantJoinedData _$ParticipantJoinedDataFromJson(
  Map<String, dynamic> json,
) => ParticipantJoinedData(
  callId: json['callId'] as String?,
  userId: json['userId'] as String?,
  userName: json['userName'] as String?,
  currentParticipants: (json['currentParticipants'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ParticipantJoinedDataToJson(
  ParticipantJoinedData instance,
) => <String, dynamic>{
  'callId': instance.callId,
  'userId': instance.userId,
  'userName': instance.userName,
  'currentParticipants': instance.currentParticipants,
};

ParticipantLeftData _$ParticipantLeftDataFromJson(Map<String, dynamic> json) =>
    ParticipantLeftData(
      callId: json['callId'] as String?,
      userId: json['userId'] as String?,
      peerId: json['peerId'] as String?,
      remainingParticipants:
          (json['remainingParticipants'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ParticipantLeftDataToJson(
  ParticipantLeftData instance,
) => <String, dynamic>{
  'callId': instance.callId,
  'userId': instance.userId,
  'peerId': instance.peerId,
  'remainingParticipants': instance.remainingParticipants,
};

CallEndedEventData _$CallEndedEventDataFromJson(Map<String, dynamic> json) =>
    CallEndedEventData(
      callId: json['callId'] as String,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$CallEndedEventDataToJson(CallEndedEventData instance) =>
    <String, dynamic>{'callId': instance.callId, 'status': instance.status};

RouterRtpCapabilitiesResponse _$RouterRtpCapabilitiesResponseFromJson(
  Map<String, dynamic> json,
) => RouterRtpCapabilitiesResponse(
  rtpCapabilities: json['rtpCapabilities'] as Map<String, dynamic>,
);

Map<String, dynamic> _$RouterRtpCapabilitiesResponseToJson(
  RouterRtpCapabilitiesResponse instance,
) => <String, dynamic>{'rtpCapabilities': instance.rtpCapabilities};

JoinRoomResponse _$JoinRoomResponseFromJson(Map<String, dynamic> json) =>
    JoinRoomResponse(
      producers: (json['producers'] as List<dynamic>?)
          ?.map((e) => ProducerInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JoinRoomResponseToJson(JoinRoomResponse instance) =>
    <String, dynamic>{'producers': instance.producers};

ProducerInfo _$ProducerInfoFromJson(Map<String, dynamic> json) => ProducerInfo(
  producerId: json['producerId'] as String,
  peerId: json['peerId'] as String?,
  kind: json['kind'] as String?,
  isFrontCamera: json['isFrontCamera'] as bool?,
);

Map<String, dynamic> _$ProducerInfoToJson(ProducerInfo instance) =>
    <String, dynamic>{
      'producerId': instance.producerId,
      'peerId': instance.peerId,
      'kind': instance.kind,
      'isFrontCamera': instance.isFrontCamera,
    };

CallParticipant _$CallParticipantFromJson(Map<String, dynamic> json) =>
    CallParticipant(
      id: json['id'] as String?,
      user: json['user'] as String?,
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
      leftAt: json['leftAt'] == null
          ? null
          : DateTime.parse(json['leftAt'] as String),
      role: json['role'] as String?,
      connectionStatus: json['connectionStatus'] as String?,
    );

Map<String, dynamic> _$CallParticipantToJson(CallParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'joinedAt': instance.joinedAt?.toIso8601String(),
      'leftAt': instance.leftAt?.toIso8601String(),
      'role': instance.role,
      'connectionStatus': instance.connectionStatus,
    };

ActiveCall _$ActiveCallFromJson(Map<String, dynamic> json) => ActiveCall(
  callId: json['callId'] as String?,
  chatGroup: json['chatGroup'] as String?,
  callType: $enumDecodeNullable(_$CallTypeEnumMap, json['callType']),
  status: $enumDecodeNullable(_$CallStatusEnumMap, json['status']),
  roomId: json['roomId'] as String?,
  initiatedBy: json['initiatedBy'] as String?,
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
  participants: (json['participants'] as List<dynamic>?)
      ?.map((e) => CallParticipant.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ActiveCallToJson(ActiveCall instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'chatGroup': instance.chatGroup,
      'callType': _$CallTypeEnumMap[instance.callType],
      'status': _$CallStatusEnumMap[instance.status],
      'roomId': instance.roomId,
      'initiatedBy': instance.initiatedBy,
      'startedAt': instance.startedAt?.toIso8601String(),
      'participants': instance.participants,
    };

const _$CallStatusEnumMap = {
  CallStatus.ongoing: 'ongoing',
  CallStatus.ended: 'ended',
  CallStatus.missed: 'missed',
  CallStatus.failed: 'failed',
};
