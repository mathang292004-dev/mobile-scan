import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/presentation/common/cubit/notification_cubit.dart';
import 'package:emergex/presentation/common/cubit/notification_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:emergex/di/app_di.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationCubit>().loadNotifications();
      context.read<NotificationCubit>().initPermissions();
    });

    return BlocConsumer<NotificationCubit, NotificationState>(
      listener: (context, state) {
        if (state is NotificationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is NotificationLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: ColorHelper.successColor,
            ),
          );
          context.read<NotificationCubit>().clearSuccessMessage();
        } else if (state is NotificationMarkReadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ColorHelper.successColor,
            ),
          );
        }
      },
      builder: (context, state) {
        final selectedFilter =
            state is NotificationLoaded ? state.selectedFilter : 'All';
        final showPushBanner =
            state is NotificationLoaded ? state.showPushBanner : false;

        return AppScaffold(
          useGradient: true,
          gradientBegin: Alignment.topCenter,
          gradientEnd: Alignment.bottomCenter,
          gradientColors: const [Color(0xFFEAF2E8), Color(0xFFB9C7B5)],
          appBar: AppBarWidget(
            hasNotifications:
                state is NotificationLoaded && state.unreadCount > 0,
            showBackButton: false,
            isOnNotificationsScreen: true,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 10),
                  _buildFilterSection(context, state, selectedFilter),
                  const SizedBox(height: 10),
                  Expanded(child: _buildContent(context, state)),
                ],
              ),
              if (showPushBanner)
                Positioned(
                  bottom: 34,
                  left: 14,
                  right: 14,
                  child: _buildPushNotificationBanner(context),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, NotificationState state) {
    if (state is NotificationLoading) {
      return _buildLoadingState(context);
    } else if (state is NotificationLoaded) {
      if (state.notifications.isEmpty) {
        return _buildEmptyState(context);
      }
      return RefreshIndicator(
        onRefresh: () async {
          await context.read<NotificationCubit>().refresh();
        },
        child: _buildNotificationsList(context, state),
      );
    } else if (state is NotificationError) {
      return _buildErrorState(context, state.message);
    }
    return _buildEmptyState(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: ColorHelper.successColor),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7D7D7D),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 64,
            color: Color(0xFFA9A9A9),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF272727),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7D7D7D),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF272727),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF7D7D7D),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<NotificationCubit>().refresh();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorHelper.successColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: ColorHelper.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF232323),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    NotificationState state,
    String selectedFilter,
  ) {
    final isLoading = state is NotificationLoaded && state.isMarkingAsRead;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFilterToggle(context, selectedFilter),
          GestureDetector(
            onTap: isLoading
                ? null
                : () => context.read<NotificationCubit>().markAllAsRead(),
            child: Row(
              children: [
                if (isLoading)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorHelper.successColor,
                    ),
                  ),
                if (isLoading) const SizedBox(width: 8),
                Text(
                  'Mark all read',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isLoading
                        ? ColorHelper.successColor.withValues(alpha: 0.5)
                        : ColorHelper.successColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggle(BuildContext context, String selectedFilter) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _buildFilterButton(context, 'All', selectedFilter),
          _buildFilterButton(context, 'Unread', selectedFilter),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    String label,
    String selectedFilter,
  ) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => context.read<NotificationCubit>().setFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ColorHelper.successColor : Colors.transparent,
          borderRadius: BorderRadius.circular(110),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : const Color(0xFF525252),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    NotificationLoaded state,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      itemCount: state.notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _buildNotificationCard(context, state.notifications[index]);
      },
    );
  }

  Future<void> _navigateBasedOnNotificationType(
    BuildContext context,
    String? notificationType,
    Map<String, dynamic>? notificationData,
  ) async {
    isFromNotification = true;
    Future.delayed(const Duration(seconds: 2), () {
      isFromNotification = false;
    });

    if (notificationType == null || notificationData == null) {
      if (context.mounted) context.goNamed(Routes.notificationsScreen);
      return;
    }

    final String? incidentId = notificationData['incidentId']?.toString();
    final String? taskId = notificationData['taskId']?.toString();
    final String? projectId = notificationData['projectId']?.toString();

    if (projectId != null && projectId.isNotEmpty) {
      final currentProjectId = AppDI.emergexAppCubit.state.selectedProjectId;
      if (currentProjectId != projectId) {
        final success = await AppDI.emergexAppCubit.updateSelectedProject(
          projectId,
        );
        if (!success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to load project context'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        if (!context.mounted) return;
      }
    }

    final bool isTeamLeader = PermissionHelper.hasViewPermission(
      moduleName: 'ERT Team Leader',
    );
    final bool isApproverFullAccess = PermissionHelper.hasFullAccessPermission(
      moduleName: 'ER Team Approval',
    );

    switch (notificationType) {
      case 'NEW_TASK_ADDED':
      case 'TASK_STATUS_CHANGED':
      case 'NEW_TEAM_MEMBER_ADDED':
      case 'PROJECT_DOCUMENT_REVISED_TASK_UPDATED':
        if (incidentId != null && taskId != null) {
          if (isTeamLeader) {
            openScreen(
              Routes.erTeamApproverTaskDetailsScreen,
              args: {
                'incidentId': incidentId,
                'taskId': taskId,
                'fromNotification': true,
              },
            );
          } else {
            openScreen(
              Routes.erTeamMemberTaskDetailsScreen,
              args: {'taskId': taskId, 'incidentId': incidentId},
            );
          }
        } else if (context.mounted) {
          context.goNamed(Routes.notificationsScreen);
        }
        break;

      case 'TASK_STATUS_SUBMITTED':
        if (incidentId != null && taskId != null) {
          if (isTeamLeader) {
            openScreen(
              Routes.erTeamApproverTaskDetailsScreen,
              args: {'incidentId': incidentId, 'taskId': taskId},
            );
          } else {
            openScreen(
              Routes.erTeamMemberTaskDetailsScreen,
              args: {'taskId': taskId, 'incidentId': incidentId},
            );
          }
        } else if (context.mounted) {
          context.goNamed(Routes.notificationsScreen);
        }
        break;

      case 'INCIDENT_APPROVED':
      case 'ERT_ASSIGNED':
      case 'INCIDENT_RESOLVED':
        if (incidentId != null) {
          if (isApproverFullAccess) {
            openScreen(Routes.incidentApproval, args: {'incidentId': incidentId});
          } else {
            openScreen(
              Routes.incidentReportDetails,
              args: {'incidentId': incidentId},
            );
          }
        } else if (context.mounted) {
          context.goNamed(Routes.notificationsScreen);
        }
        break;

      case 'TASK_APPROVAL':
        if (incidentId != null) {
          if (isApproverFullAccess) {
            if (taskId != null) {
              openScreen(
                Routes.erTeamApproverTaskDetailsScreen,
                args: {'taskId': taskId, 'incidentId': incidentId},
              );
            } else {
              openScreen(
                Routes.erTeamApproverDetailScreen,
                args: {'incidentId': incidentId},
              );
            }
          } else {
            if (taskId != null) {
              openScreen(
                Routes.erTeamMemberTaskDetailsScreen,
                args: {'taskId': taskId, 'incidentId': incidentId},
              );
            } else {
              openScreen(
                Routes.incidentReportDetails,
                args: {'incidentId': incidentId},
              );
            }
          }
        } else if (context.mounted) {
          context.goNamed(Routes.notificationsScreen);
        }
        break;

      case 'NEW_INCIDENT_AWAITING_REVIEW':
      case 'INCIDENT_REPORT_GENERATED':
      case 'INCIDENT_REJECTED':
      case 'INVESTIGATION_TEAM_ASSIGNED':
        if (incidentId != null) {
          openScreen(Routes.incidentApproval, args: {'incidentId': incidentId});
        } else if (context.mounted) {
          context.goNamed(Routes.notificationsScreen);
        }
        break;

      case 'EXTERNAL_USER_JOIN_REQUEST':
      case 'EXTERNAL_MEMBER_JOINED':
      case 'PROJECT_DOCUMENT_REVISED':
      default:
        if (context.mounted) context.goNamed(Routes.notificationsScreen);
        break;
    }
  }

  Widget _buildNotificationCard(BuildContext context, notification) {
    final isRead = notification.isViewed;

    String displayTitle = '';
    if (notification.type != null && notification.type!.isNotEmpty) {
      displayTitle =
          '${notification.type} | ${notification.title ?? 'Notification'}';
    } else {
      displayTitle = notification.title ?? 'Notification';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFF3F7F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF272727),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: ColorHelper.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.body ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7D7D7D),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFA9A9A9),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    _buildViewButton(context, notification),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(BuildContext context, notification) {
    return GestureDetector(
      onTap: () async {
        if (!notification.isViewed && notification.id != null) {
          context.read<NotificationCubit>().markAsRead([notification.id!]);
        }
        await _navigateBasedOnNotificationType(
          context,
          notification.type,
          notification.ids,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF3DA229), Color(0xFF247814)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'View',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPushNotificationBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDF87),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '🔔  Turn on push notifications',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF272727),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                height: 1.87,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              final granted =
                  await context.read<NotificationCubit>().requestPermission();
              if (!granted && context.mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Enable Notifications'),
                    content: const Text(
                      'Please enable notifications in app settings to receive important updates.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          openAppSettings();
                        },
                        child: const Text('Open Settings'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: ColorHelper.successColor,
                borderRadius: BorderRadius.circular(7992),
              ),
              child: Text(
                'Allow',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.read<NotificationCubit>().hidePushBanner(),
            child: const Icon(Icons.close, size: 20, color: Color(0xFF272727)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins min${mins != 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hrs = difference.inHours;
      return '$hrs hr${hrs != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days != 1 ? 's' : ''} ago';
    } else {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}.';
    }
  }
}
