import 'package:json_annotation/json_annotation.dart';

part 'call_models.g.dart';

/// Call types
enum CallType {
  @JsonValue('audio')
  audio,
  @JsonValue('video')
  video,
}

/// Call status - matches backend CallStatus enum
enum CallStatus {
  @JsonValue('ongoing')
  ongoing,
  @JsonValue('ended')
  ended,
  @JsonValue('missed')
  missed,
  @JsonValue('failed')
  failed,
}

/// Start call data
@JsonSerializable()
class StartCallData {
  final String chatGroup;
  final String? incident;
  final String initiatedBy;
  final CallType callType;
  final String roomId;

  StartCallData({
    required this.chatGroup,
    this.incident,
    required this.initiatedBy,
    required this.callType,
    required this.roomId,
  });

  factory StartCallData.fromJson(Map<String, dynamic> json) =>
      _$StartCallDataFromJson(json);

  Map<String, dynamic> toJson() => _$StartCallDataToJson(this);
}

/// Start call response
@JsonSerializable()
class StartCallResponse {
  final bool success;
  final String callId;
  final String roomId;
  final bool isExisting; // true if joined existing call, false if new call

  StartCallResponse({
    required this.success,
    required this.callId,
    required this.roomId,
    this.isExisting = false,
  });

  factory StartCallResponse.fromJson(Map<String, dynamic> json) =>
      _$StartCallResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StartCallResponseToJson(this);
}

/// Join call data - per reference: { callId, userId }
@JsonSerializable()
class JoinCallData {
  final String callId;
  final String userId;

  JoinCallData({
    required this.callId,
    required this.userId,
  });

  factory JoinCallData.fromJson(Map<String, dynamic> json) =>
      _$JoinCallDataFromJson(json);

  Map<String, dynamic> toJson() => _$JoinCallDataToJson(this);
}

/// Join call response
@JsonSerializable()
class JoinCallResponse {
  final bool success;

  JoinCallResponse({required this.success});

  factory JoinCallResponse.fromJson(Map<String, dynamic> json) =>
      _$JoinCallResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JoinCallResponseToJson(this);
}

/// End call data
@JsonSerializable()
class EndCallData {
  final String callId;
  final String status;

  EndCallData({
    required this.callId,
    required this.status,
  });

  factory EndCallData.fromJson(Map<String, dynamic> json) =>
      _$EndCallDataFromJson(json);

  Map<String, dynamic> toJson() => _$EndCallDataToJson(this);
}

/// Leave call data
@JsonSerializable()
class LeaveCallData {
  final String callId;
  final String userId;

  LeaveCallData({
    required this.callId,
    required this.userId,
  });

  factory LeaveCallData.fromJson(Map<String, dynamic> json) =>
      _$LeaveCallDataFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveCallDataToJson(this);
}

/// Incoming call data
@JsonSerializable()
class IncomingCallData {
  final String callId;
  final String roomId;
  final String chatGroup;
  final String? incident;
  final String? initiatedBy;
  final CallType callType;

  IncomingCallData({
    required this.callId,
    required this.roomId,
    required this.chatGroup,
    this.incident,
    this.initiatedBy,
    required this.callType,
  });

  factory IncomingCallData.fromJson(Map<String, dynamic> json) =>
      _$IncomingCallDataFromJson(json);

  Map<String, dynamic> toJson() => _$IncomingCallDataToJson(this);
}

/// New producer data - per reference includes mediaType and paused state
@JsonSerializable()
class NewProducerData {
  final String producerId;
  final String peerId;
  final String? userId;
  final String? userName;
  final String kind; // 'audio' or 'video'
  final String? mediaType; // 'audio' | 'camera' | 'screen'
  final bool paused; // Whether producer started in muted/paused state
  final bool? isFrontCamera; // Whether using front or back camera

  NewProducerData({
    required this.producerId,
    required this.peerId,
    this.userId,
    this.userName,
    required this.kind,
    this.mediaType,
    this.paused = false,
    this.isFrontCamera,
  });

  factory NewProducerData.fromJson(Map<String, dynamic> json) =>
      _$NewProducerDataFromJson(json);

  Map<String, dynamic> toJson() => _$NewProducerDataToJson(this);
}

/// Producer status data - per reference includes userId, mediaType, userName
@JsonSerializable()
class ProducerStatusData {
  final String producerId;
  final String? peerId;
  final String? userId;
  final String? userName;
  final String? kind; // 'audio' | 'video'
  final String? mediaType; // 'audio' | 'camera' | 'screen'

  ProducerStatusData({
    required this.producerId,
    this.peerId,
    this.userId,
    this.userName,
    this.kind,
    this.mediaType,
  });

  factory ProducerStatusData.fromJson(Map<String, dynamic> json) =>
      _$ProducerStatusDataFromJson(json);

  Map<String, dynamic> toJson() => _$ProducerStatusDataToJson(this);
}

/// Participant event data - for peerClosed events
@JsonSerializable()
class ParticipantEventData {
  final String? peerId;
  final String? userId;
  final String? userName;

  ParticipantEventData({
    this.peerId,
    this.userId,
    this.userName,
  });

  factory ParticipantEventData.fromJson(Map<String, dynamic> json) =>
      _$ParticipantEventDataFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantEventDataToJson(this);
}

/// Participant joined event data - per reference: { callId, userId, currentParticipants }
@JsonSerializable()
class ParticipantJoinedData {
  final String? callId;
  final String? userId;
  final String? userName;
  final int currentParticipants; // Authoritative count from backend

  ParticipantJoinedData({
    this.callId,
    this.userId,
    this.userName,
    this.currentParticipants = 0,
  });

  factory ParticipantJoinedData.fromJson(Map<String, dynamic> json) =>
      _$ParticipantJoinedDataFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantJoinedDataToJson(this);
}

/// Participant left event data - per reference: { callId, userId, remainingParticipants }
@JsonSerializable()
class ParticipantLeftData {
  final String? callId;
  final String? userId;
  final String? peerId;
  final int remainingParticipants; // Authoritative count from backend

  ParticipantLeftData({
    this.callId,
    this.userId,
    this.peerId,
    this.remainingParticipants = 0,
  });

  factory ParticipantLeftData.fromJson(Map<String, dynamic> json) =>
      _$ParticipantLeftDataFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantLeftDataToJson(this);
}

/// Call ended event data
@JsonSerializable()
class CallEndedEventData {
  final String callId;
  final String? status;

  CallEndedEventData({
    required this.callId,
    this.status,
  });

  factory CallEndedEventData.fromJson(Map<String, dynamic> json) =>
      _$CallEndedEventDataFromJson(json);

  Map<String, dynamic> toJson() => _$CallEndedEventDataToJson(this);
}

/// Remote participant status
class RemoteParticipantStatus {
  final String peerId;
  final String name;
  final bool isAudioMuted;
  final bool isVideoOff;
  final bool isFrontCamera; // Track which camera the participant is using
  final bool isMobile; // Track if participant is on mobile device

  RemoteParticipantStatus({
    required this.peerId,
    required this.name,
    required this.isAudioMuted,
    required this.isVideoOff,
    this.isFrontCamera = true, // Default to front camera
    this.isMobile = false, // Default to web (no rotation needed)
  });

  RemoteParticipantStatus copyWith({
    String? peerId,
    String? name,
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isFrontCamera,
    bool? isMobile,
  }) {
    return RemoteParticipantStatus(
      peerId: peerId ?? this.peerId,
      name: name ?? this.name,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isMobile: isMobile ?? this.isMobile,
    );
  }
}

/// Router RTP Capabilities
@JsonSerializable()
class RouterRtpCapabilitiesResponse {
  final Map<String, dynamic> rtpCapabilities;

  RouterRtpCapabilitiesResponse({required this.rtpCapabilities});

  factory RouterRtpCapabilitiesResponse.fromJson(Map<String, dynamic> json) =>
      _$RouterRtpCapabilitiesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RouterRtpCapabilitiesResponseToJson(this);
}

/// Join room response
@JsonSerializable()
class JoinRoomResponse {
  final List<ProducerInfo>? producers;

  JoinRoomResponse({this.producers});

  factory JoinRoomResponse.fromJson(Map<String, dynamic> json) =>
      _$JoinRoomResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRoomResponseToJson(this);
}

/// Producer info
@JsonSerializable()
class ProducerInfo {
  final String producerId;
  final String? peerId;
  final String? kind;
  final bool? isFrontCamera; // Whether using front or back camera

  ProducerInfo({
    required this.producerId,
    this.peerId,
    this.kind,
    this.isFrontCamera,
  });

  factory ProducerInfo.fromJson(Map<String, dynamic> json) =>
      _$ProducerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ProducerInfoToJson(this);
}

/// Call participant info from API
@JsonSerializable()
class CallParticipant {
  final String? id;
  final String? user;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final String? role;
  final String? connectionStatus;

  CallParticipant({
    this.id,
    this.user,
    this.joinedAt,
    this.leftAt,
    this.role,
    this.connectionStatus,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) =>
      _$CallParticipantFromJson(json);

  Map<String, dynamic> toJson() => _$CallParticipantToJson(this);
}

/// Active call info returned from chat group API
@JsonSerializable()
class ActiveCall {
  final String? callId;
  final String? chatGroup;
  final CallType? callType;
  final CallStatus? status;
  final String? roomId;
  final String? initiatedBy;
  final DateTime? startedAt;
  final List<CallParticipant>? participants;

  ActiveCall({
    this.callId,
    this.chatGroup,
    this.callType,
    this.status,
    this.roomId,
    this.initiatedBy,
    this.startedAt,
    this.participants,
  });

  factory ActiveCall.fromJson(Map<String, dynamic> json) =>
      _$ActiveCallFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveCallToJson(this);

  /// Get the count of active participants (those who haven't left)
  int get activeParticipantCount =>
      participants?.where((p) => p.leftAt == null).length ?? 0;
}
