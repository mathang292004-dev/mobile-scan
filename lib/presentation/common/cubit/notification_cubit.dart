import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/common/use_cases/notification_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationUseCase _notificationUseCase;

  NotificationCubit(this._notificationUseCase) : super(NotificationInitial());

  /// Load notifications with optional filter
  Future<void> loadNotifications({String? filter}) async {
    emit(NotificationLoading());

    try {
      final response = await _notificationUseCase.getNotifications(
        filter: filter,
      );

      if (response.success == true && response.data != null) {
        final notifications = response.data!.data ?? [];
        final unreadCount = notifications.where((n) => !n.isViewed).length;

        emit(
          NotificationLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
            currentFilter: filter,
          ),
        );
      } else {
        emit(
          NotificationError(
            response.error ??
                response.message ??
                'Failed to load notifications',
          ),
        );
      }
    } catch (e) {
      emit(NotificationError('Failed to load notifications: ${e.toString()}'));
    }
  }

  /// Get unread count
  Future<void> getUnreadCount() async {
    try {
      final response = await _notificationUseCase.getUnreadCount();

      if (response.success == true && response.data != null) {
        final count = response.data!.data?.count ?? 0;

        // Update the current state with the new unread count
        final currentState = state;
        if (currentState is NotificationLoaded) {
          emit(currentState.copyWith(unreadCount: count));
        }
      }
      // Silently fail for unread count if error occurs
    } catch (e) {
      // Silently fail for unread count
    }
  }

  /// Mark specific notifications as read
  Future<void> markAsRead(List<String> notificationIds) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    // Show loading indicator
    emit(currentState.copyWith(isMarkingAsRead: true));

    try {
      final response = await _notificationUseCase.markNotificationsAsRead(
        notificationIds: notificationIds,
        isAllRead: false,
      );

      if (response.success == true) {
        // Update local state - mark the specific notifications as read
        final updatedNotifications = currentState.notifications.map((n) {
          if (notificationIds.contains(n.id)) {
            return n.copyWith(isViewed: true, viewedAt: DateTime.now());
          }
          return n;
        }).toList();

        final unreadCount = updatedNotifications
            .where((n) => !n.isViewed)
            .length;

        emit(
          currentState.copyWith(
            notifications: updatedNotifications,
            unreadCount: unreadCount,
            isMarkingAsRead: false,
          ),
        );
      } else {
        emit(currentState.copyWith(isMarkingAsRead: false));
        emit(
          NotificationError(
            response.error ?? response.message ?? 'Failed to mark as read',
          ),
        );
      }
    } catch (e) {
      emit(currentState.copyWith(isMarkingAsRead: false));
      emit(NotificationError('Failed to mark as read: ${e.toString()}'));
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    // Show loading indicator
    emit(currentState.copyWith(isMarkingAsRead: true));

    try {
      final response = await _notificationUseCase.markNotificationsAsRead(
        isAllRead: true,
      );

      if (response.success == true) {
        // Update local state - mark all notifications as read
        final updatedNotifications = currentState.notifications.map((n) {
          return n.copyWith(isViewed: true, viewedAt: DateTime.now());
        }).toList();

        // Emit single state with success message included
        // This avoids multiple state emissions that cause duplicate listener callbacks
        emit(
          NotificationLoaded(
            notifications: updatedNotifications,
            unreadCount: 0,
            currentFilter: currentState.currentFilter,
            isMarkingAsRead: false,
            successMessage: 'All notifications marked as read',
          ),
        );
      } else {
        emit(currentState.copyWith(isMarkingAsRead: false));
        emit(
          NotificationError(
            response.error ?? response.message ?? 'Failed to mark all as read',
          ),
        );
      }
    } catch (e) {
      emit(currentState.copyWith(isMarkingAsRead: false));
      emit(NotificationError('Failed to mark all as read: ${e.toString()}'));
    }
  }

  /// Apply filter to notifications
  void applyFilter(String? filter) {
    loadNotifications(filter: filter);
  }

  /// Refresh notifications
  Future<void> refresh() async {
    final currentState = state;
    String? currentFilter;

    if (currentState is NotificationLoaded) {
      currentFilter = currentState.currentFilter;
    }

    await loadNotifications(filter: currentFilter);
  }

  /// Clear cache and reset to initial state
  void clearCache() {
    emit(NotificationInitial());
  }

  /// Clear success message from current state
  void clearSuccessMessage() {
    final currentState = state;
    if (currentState is NotificationLoaded && currentState.successMessage != null) {
      emit(currentState.copyWith(clearSuccessMessage: true));
    }
  }

  /// Set the UI filter label ('All' or 'Unread') and reload
  void setFilter(String label) {
    final currentState = state;
    final apiFilter = label == 'Unread' ? 'unread' : null;
    if (currentState is NotificationLoaded) {
      emit(currentState.copyWith(selectedFilter: label));
    }
    loadNotifications(filter: apiFilter);
  }

  /// Check notification permission on screen open; show banner if denied
  Future<void> initPermissions() async {
    const permKey = 'notification_permission_granted';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(permKey) ?? false) return;

    final status = await Permission.notification.status;
    if (status.isGranted) {
      await prefs.setBool(permKey, true);
      return;
    }

    // Auto-request on first open
    final granted = await AppDI.pushNotificationService.requestPermission();
    if (granted) {
      await prefs.setBool(permKey, true);
    } else {
      final current = state;
      if (current is NotificationLoaded) {
        emit(current.copyWith(showPushBanner: true));
      }
    }
  }

  /// Request permission explicitly (from banner Allow button)
  Future<bool> requestPermission() async {
    const permKey = 'notification_permission_granted';
    final granted = await AppDI.pushNotificationService.requestPermission();
    if (granted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(permKey, true);
      hidePushBanner();
    }
    return granted;
  }

  /// Hide push notification banner
  void hidePushBanner() {
    final current = state;
    if (current is NotificationLoaded) {
      emit(current.copyWith(showPushBanner: false));
    }
  }
}
