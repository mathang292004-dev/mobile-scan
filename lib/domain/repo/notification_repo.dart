import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/notification/notification_response.dart';

abstract class NotificationRepository {
  Future<ApiResponse<NotificationsResponse>> getNotifications({
    String? filter,
  });

  Future<ApiResponse<UnreadCountResponse>> getUnreadCount();

  Future<ApiResponse<MarkReadResponse>> markNotificationsAsRead({
    List<String>? notificationIds,
    required bool isAllRead,
  });

  Future<ApiResponse<dynamic>> registerFCMToken({
    required String fcmToken,
  });

  Future<ApiResponse<dynamic>> unregisterFCMToken({
    required String fcmToken,
  });
}