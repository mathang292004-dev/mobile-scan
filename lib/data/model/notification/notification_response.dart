import 'package:equatable/equatable.dart';

/// Notification Item Model
class NotificationItem extends Equatable {
  final String? id;
  final String? type;
  final String? title;
  final String? body;
  final DateTime? viewedAt;
  final bool isViewed;
  final DateTime? createdAt;
final Map<String, dynamic>? ids;
  const NotificationItem({
    this.id,
    this.type,
    this.title,
    this.body,
    this.viewedAt,
    this.isViewed = false,
    this.createdAt,
     this.ids,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String?,
      type: json['type'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      ids: json['ids'] as Map<String, dynamic>?,
      viewedAt: json['viewedAt'] != null
          ? DateTime.parse(json['viewedAt'] as String)
          : null,
      isViewed: json['isViewed'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'ids': ids,
      'viewedAt': viewedAt?.toIso8601String(),
      'isViewed': isViewed,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
     Map<String, dynamic>? ids,
    DateTime? viewedAt,
    bool? isViewed,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      ids: ids ?? this.ids,
      viewedAt: viewedAt ?? this.viewedAt,
      isViewed: isViewed ?? this.isViewed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, ids, viewedAt, isViewed, createdAt];
}

/// Get Notifications Response
class NotificationsResponse extends Equatable {
  final String? message;
  final int? statusCode;
  final String? status;
  final List<NotificationItem>? data;

  const NotificationsResponse({
    this.message,
    this.statusCode,
    this.status,
    this.data,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      status: json['status'] as String?,
      data: json['data'] is List
          ? (json['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => NotificationItem.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'status': status,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [message, statusCode, status, data];
}

/// Unread Count Response
class UnreadCountResponse extends Equatable {
  final String? message;
  final int? statusCode;
  final String? status;
  final UnreadCountData? data;

  const UnreadCountResponse({
    this.message,
    this.statusCode,
    this.status,
    this.data,
  });

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      status: json['status'] as String?,
      data: json['data'] != null
          ? UnreadCountData.fromJson(json['data'] as Map<String, dynamic>)
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

  @override
  List<Object?> get props => [message, statusCode, status, data];
}

class UnreadCountData extends Equatable {
  final int count;

  const UnreadCountData({this.count = 0});

  factory UnreadCountData.fromJson(Map<String, dynamic> json) {
    return UnreadCountData(
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
    };
  }

  @override
  List<Object?> get props => [count];
}

/// Mark as Read Response
class MarkReadResponse extends Equatable {
  final String? message;
  final int? statusCode;
  final String? status;
  final dynamic data;

  const MarkReadResponse({
    this.message,
    this.statusCode,
    this.status,
    this.data,
  });

  factory MarkReadResponse.fromJson(Map<String, dynamic> json) {
    return MarkReadResponse(
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      status: json['status'] as String?,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'status': status,
      'data': data,
    };
  }

  @override
  List<Object?> get props => [message, statusCode, status, data];
}