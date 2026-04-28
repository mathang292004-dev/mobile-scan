import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/notification/notification_response.dart';
import 'package:emergex/data/remote_data_source/notification_remote_data_source.dart';
import 'package:emergex/domain/repo/notification_repo.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<NotificationsResponse>> getNotifications({
    String? filter,
  }) async {
    try {
      return await _remoteDataSource.getNotifications(filter: filter);
    } catch (e) {
      return ApiResponse<NotificationsResponse>.error(
        'Failed to get notifications: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<UnreadCountResponse>> getUnreadCount() async {
    try {
      return await _remoteDataSource.getUnreadCount();
    } catch (e) {
      return ApiResponse<UnreadCountResponse>.error(
        'Failed to get unread count: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<MarkReadResponse>> markNotificationsAsRead({
    List<String>? notificationIds,
    required bool isAllRead,
  }) async {
    try {
      return await _remoteDataSource.markNotificationsAsRead(
        notificationIds: notificationIds,
        isAllRead: isAllRead,
      );
    } catch (e) {
      return ApiResponse<MarkReadResponse>.error(
        'Failed to mark notifications as read: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<dynamic>> registerFCMToken({
    required String fcmToken,
  }) async {
    try {
      return await _remoteDataSource.registerFCMToken(fcmToken: fcmToken);
    } catch (e) {
      return ApiResponse<dynamic>.error(
        'Failed to register FCM token: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<dynamic>> unregisterFCMToken({
    required String fcmToken,
  }) async {
    try {
      return await _remoteDataSource.unregisterFCMToken(fcmToken: fcmToken);
    } catch (e) {
      return ApiResponse<dynamic>.error(
        'Failed to unregister FCM token: ${e.toString()}',
      );
    }
  }
}