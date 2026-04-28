import 'package:emergex/data/model/notification/notification_response.dart';
import 'package:equatable/equatable.dart';

// Notification States
abstract class NotificationState extends Equatable {
  const NotificationState();
}

class NotificationInitial extends NotificationState {
  @override
  List<Object?> get props => [];
}

class NotificationLoading extends NotificationState {
  @override
  List<Object?> get props => [];
}

class NotificationLoaded extends NotificationState {
  final List<NotificationItem> notifications;
  final int unreadCount;
  final String? currentFilter;
  final bool isMarkingAsRead;
  final String? successMessage;
  final String selectedFilter;
  final bool showPushBanner;

  const NotificationLoaded({
    required this.notifications,
    this.unreadCount = 0,
    this.currentFilter,
    this.isMarkingAsRead = false,
    this.successMessage,
    this.selectedFilter = 'All',
    this.showPushBanner = false,
  });

  NotificationLoaded copyWith({
    List<NotificationItem>? notifications,
    int? unreadCount,
    String? currentFilter,
    bool? isMarkingAsRead,
    String? successMessage,
    bool clearSuccessMessage = false,
    String? selectedFilter,
    bool? showPushBanner,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      currentFilter: currentFilter ?? this.currentFilter,
      isMarkingAsRead: isMarkingAsRead ?? this.isMarkingAsRead,
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      showPushBanner: showPushBanner ?? this.showPushBanner,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        unreadCount,
        currentFilter,
        isMarkingAsRead,
        successMessage,
        selectedFilter,
        showPushBanner,
      ];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationMarkReadSuccess extends NotificationState {
  final String message;

  const NotificationMarkReadSuccess(this.message);

  @override
  List<Object?> get props => [message];
}