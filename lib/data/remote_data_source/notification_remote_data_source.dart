import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/notification/notification_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

abstract class NotificationRemoteDataSource {
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

class NotificationRemoteDataSourceImpl
    implements NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<NotificationsResponse>> getNotifications({
    String? filter,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (filter != null && filter.isNotEmpty) {
        queryParams['filter'] = filter;
      }

      return await _apiClient.request<NotificationsResponse>(
        ApiEndpoints.getNotifications,
        method: HttpMethod.get,
        requiresAuth: true,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic>) {
            return NotificationsResponse.fromJson(json);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<NotificationsResponse>.error(
        'Failed to get notifications: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<UnreadCountResponse>> getUnreadCount() async {
    try {
      return await _apiClient.request<UnreadCountResponse>(
        ApiEndpoints.getUnreadCount,
        method: HttpMethod.get,
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic>) {
            return UnreadCountResponse.fromJson(json);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
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
      final body = <String, dynamic>{
        'isAllRead': isAllRead,
      };

      if (!isAllRead && notificationIds != null) {
        body['notificationIds'] = notificationIds;
      }

      return await _apiClient.request<MarkReadResponse>(
        ApiEndpoints.markNotificationsAsRead,
        method: HttpMethod.put,
        requiresAuth: true,
        data: body,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic>) {
            return MarkReadResponse.fromJson(json);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
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
      final body = <String, dynamic>{
        'fcmToken': fcmToken,
      };

      return await _apiClient.request<dynamic>(
        ApiEndpoints.registerFCMToken,
        method: HttpMethod.post,
        requiresAuth: true,
        data: body,
        fromJson: (json) => json,
      );
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
      final body = <String, dynamic>{
        'fcmToken': fcmToken,
      };

      return await _apiClient.request<dynamic>(
        ApiEndpoints.unregisterFCMToken,
        method: HttpMethod.post,
        requiresAuth: true,
        data: body,
        fromJson: (json) => json,
      );
    } catch (e) {
      return ApiResponse<dynamic>.error(
        'Failed to unregister FCM token: ${e.toString()}',
      );
    }
  }
}