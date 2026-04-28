import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/notification/notification_response.dart';
import 'package:emergex/domain/repo/notification_repo.dart';

class NotificationUseCase {
  final NotificationRepository _notificationRepository;

  NotificationUseCase(this._notificationRepository);

  Future<ApiResponse<NotificationsResponse>> getNotifications({
    String? filter,
  }) async {
    try {
      return await _notificationRepository.getNotifications(filter: filter);
    } catch (e) {
      return ApiResponse<NotificationsResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<UnreadCountResponse>> getUnreadCount() async {
    try {
      return await _notificationRepository.getUnreadCount();
    } catch (e) {
      return ApiResponse<UnreadCountResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<MarkReadResponse>> markNotificationsAsRead({
    List<String>? notificationIds,
    required bool isAllRead,
  }) async {
    try {
      return await _notificationRepository.markNotificationsAsRead(
        notificationIds: notificationIds,
        isAllRead: isAllRead,
      );
    } catch (e) {
      return ApiResponse<MarkReadResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }
}