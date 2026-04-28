import 'package:emergex/data/model/chat_room/chat_group_response.dart';

class AddMemberResponse {
  final String? message;
  final int? statusCode;
  final String? status;
  final ChatMember? data;

  AddMemberResponse({
    this.message,
    this.statusCode,
    this.status,
    this.data,
  });

  factory AddMemberResponse.fromJson(Map<String, dynamic> json) {
    return AddMemberResponse(
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      status: json['status'] as String?,
      data: json['data'] != null
          ? ChatMember.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'status': status,
      'data': data?.toJson(),
    };
  }
}

class RemoveMemberResponse {
  final String? message;
  final int? statusCode;
  final String? status;
  final RemoveMemberData? data;

  RemoveMemberResponse({
    this.message,
    this.statusCode,
    this.status,
    this.data,
  });

  factory RemoveMemberResponse.fromJson(Map<String, dynamic> json) {
    return RemoveMemberResponse(
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      status: json['status'] as String?,
      data: json['data'] != null
          ? RemoveMemberData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'status': status,
      'data': data?.toJson(),
    };
  }
}

class RemoveMemberData {
  final String? message;
  final ChatMember? member;

  RemoveMemberData({
    this.message,
    this.member,
  });

  factory RemoveMemberData.fromJson(Map<String, dynamic> json) {
    return RemoveMemberData(
      message: json['message'] as String?,
      member: json['member'] != null
          ? ChatMember.fromJson(json['member'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'member': member?.toJson(),
    };
  }
}
