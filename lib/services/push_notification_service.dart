import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/nav_helper/nav_observer.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/presentation/common/screens/notifications_screen.dart';
import 'package:emergex/helpers/routes.dart';
import '../helpers/nav_helper/nav_helper.dart';

/// Top-level background message handler (required by FCM)
/// Must be a top-level function for background execution
/// IMPORTANT: Cannot access UI or app state here
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background execution
  await Firebase.initializeApp();

  debugPrint('========================================');
  debugPrint('BACKGROUND NOTIFICATION RECEIVED');
  debugPrint('========================================');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Sent Time: ${message.sentTime}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
  debugPrint('From: ${message.from}');
  debugPrint('========================================');

  // Show local notification for data-only notifications (background/terminated state)
  // IMPORTANT: For iOS to work, we also need to show local notifications
  // Backend sends data-only notifications, so we must display them manually
  final String? title = message.data['title'];
  final String? body = message.data['body'];

  if (title != null || body != null) {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'emergex_default_channel',
          'EmergeX Notifications',
          channelDescription: 'Notifications for EmergeX incidents and updates',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF3DA229),
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Store full notification data as JSON in payload for type-based routing
    final payloadData = jsonEncode(message.data);

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title ?? 'Notification',
      body ?? '',
      notificationDetails,
      payload: payloadData,
    );

    debugPrint(
      'Background notification displayed on ${Platform.isAndroid ? 'Android' : 'iOS'}: $title - $body',
    );
    debugPrint('Payload stored: $payloadData');
  } else {
    debugPrint('No title or body found in background notification data');
  }
}

/// Push Notification Service
/// Handles Firebase Cloud Messaging integration including:
/// - FCM token generation and refresh
/// - Foreground, background, and terminated state notifications
/// - Permission requests
/// - Backend token registration
/// - Navigation on notification tap
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream controller for token updates
  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();
  Stream<String> get tokenStream => _tokenController.stream;

  String? _currentToken;
  bool _isInitialized = false;
  RemoteMessage? _pendingNotificationMessage;
  Map<String, dynamic>?
  _pendingNotificationData; // Store notification data from local notifications

  String? get currentToken => _currentToken;
  bool get isInitialized => _isInitialized;

  /// Check if there's a pending notification from terminated state
  bool hasPendingNotification() {
    final hasPending =
        _pendingNotificationMessage != null || _pendingNotificationData != null;
    debugPrint('========================================');
    debugPrint('hasPendingNotification() called');
    debugPrint('_pendingNotificationMessage: $_pendingNotificationMessage');
    debugPrint('_pendingNotificationData: $_pendingNotificationData');
    debugPrint('Has pending: $hasPending');
    debugPrint('========================================');

    if (_pendingNotificationMessage != null) {
      debugPrint('Pending FCM message details:');
      debugPrint('  - Message ID: ${_pendingNotificationMessage!.messageId}');
      debugPrint(
        '  - Title: ${_pendingNotificationMessage!.notification?.title ?? _pendingNotificationMessage!.data['title']}',
      );
      debugPrint(
        '  - Body: ${_pendingNotificationMessage!.notification?.body ?? _pendingNotificationMessage!.data['body']}',
      );
    }

    if (_pendingNotificationData != null) {
      debugPrint('Pending local notification data:');
      debugPrint('  - Type: ${_pendingNotificationData!['type']}');
      debugPrint('  - Title: ${_pendingNotificationData!['title']}');
      debugPrint('  - Body: ${_pendingNotificationData!['body']}');
    }

    return hasPending;
  }

  /// Clear the pending notification message (call after handling it)
  void clearPendingNotification() {
    debugPrint('clearPendingNotification() called - clearing stored messages');
    _pendingNotificationMessage = null;
    _pendingNotificationData = null;
  }

  /// Initialize Firebase Messaging and notification channels
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('PushNotificationService already initialized');
      return;
    }

    try {
      debugPrint('========================================');
      debugPrint('INITIALIZING PUSH NOTIFICATION SERVICE');
      debugPrint('========================================');

      // Configure background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('Background message handler configured');

      // Request notification permissions
      final NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      debugPrint('Permission status: ${settings.authorizationStatus}');
      debugPrint('   - Alert: ${settings.alert}');
      debugPrint('   - Badge: ${settings.badge}');
      debugPrint('   - Sound: ${settings.sound}');

      // Initialize local notifications for both Android and iOS
      debugPrint('Initializing local notifications...');
      await _initializeLocalNotifications();
      debugPrint('Local notifications initialized');

      // Get FCM token
      await _retrieveFCMToken();

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('========================================');
        debugPrint('FCM TOKEN REFRESHED');
        debugPrint('========================================');
        debugPrint('New Token: $newToken');
        debugPrint('========================================');
        _currentToken = newToken;
        _tokenController.add(newToken);

        // Register new token with backend ONLY if user is logged in
        final preferenceHelper = AppDI.preferenceHelper;
        final token = await preferenceHelper.getUserToken();
        if (token.isNotEmpty) {
          _registerTokenWithBackend(newToken);
        } else {
          debugPrint(
            'User not logged in - skipping backend token registration',
          );
        }
      });

      // Handle foreground messages
      debugPrint('Listening for foreground messages...');
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      debugPrint('Listening for notification taps (background)...');
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification (terminated state)
      debugPrint('========================================');
      debugPrint('Checking for initial message (terminated state)...');
      debugPrint('========================================');

      final RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();

      debugPrint('========================================');
      debugPrint('getInitialMessage() completed');
      debugPrint('Initial message: $initialMessage');
      debugPrint('Initial message is null: ${initialMessage == null}');
      debugPrint('========================================');

      if (initialMessage != null) {
        debugPrint('========================================');
        debugPrint('APP OPENED FROM NOTIFICATION (TERMINATED STATE)');
        debugPrint('Message ID: ${initialMessage.messageId}');
        debugPrint(
          'Title: ${initialMessage.notification?.title ?? initialMessage.data['title']}',
        );
        debugPrint(
          'Body: ${initialMessage.notification?.body ?? initialMessage.data['body']}',
        );
        debugPrint('Data: ${initialMessage.data}');
        debugPrint(
          'Storing message in _pendingNotificationMessage variable...',
        );
        debugPrint('========================================');
        // Store the message to handle after app is fully initialized
        _pendingNotificationMessage = initialMessage;
        debugPrint(
          'Message stored successfully! _pendingNotificationMessage is now: $_pendingNotificationMessage',
        );
      } else {
        debugPrint('========================================');
        debugPrint('NO INITIAL MESSAGE - App not opened from notification');
        debugPrint('This is a normal app launch');
        debugPrint('========================================');
      }

      _isInitialized = true;
      debugPrint('========================================');
      debugPrint('PUSH NOTIFICATION SERVICE READY');
      debugPrint('========================================');
    } catch (e) {
      debugPrint('========================================');
      debugPrint('ERROR INITIALIZING PUSH NOTIFICATION SERVICE');
      debugPrint('========================================');
      debugPrint('Error: $e');
      debugPrint('========================================');
    }
  }

  /// Initialize Android notification channels
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // CRITICAL for iOS: Request notification permissions and configure presentation options
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    debugPrint('========================================');
    debugPrint('Initializing local notifications with iOS support...');
    debugPrint('========================================');

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap from local notification
        debugPrint('========================================');
        debugPrint('LOCAL NOTIFICATION TAPPED (iOS/Android)');
        debugPrint('Payload: ${response.payload}');
        debugPrint('Action ID: ${response.actionId}');
        debugPrint('Notification ID: ${response.id}');
        debugPrint('========================================');

        // Refresh notifications
        try {
          AppDI.notificationCubit.loadNotifications();
          debugPrint('Notifications refreshed');
        } catch (e) {
          debugPrint('Error refreshing notifications: $e');
        }

        // Parse payload and navigate based on type
        try {
          if (response.payload != null && response.payload!.isNotEmpty) {
            // Parse JSON payload to get notification data
            final notificationData =
                jsonDecode(response.payload!) as Map<String, dynamic>;
            debugPrint('Parsed notification data: $notificationData');

            // Navigate based on notification type
            _navigateBasedOnType(notificationData);
          } else {
            debugPrint(
              'No payload data - falling back to notifications screen',
            );
            _navigateToNotifications();
          }
        } catch (e) {
          debugPrint('Error parsing payload: $e');
          debugPrint('Falling back to notifications screen');
          _navigateToNotifications();
        }
      },
    );

    debugPrint('Local notifications initialized successfully');

    // iOS-specific: Request permission to show notifications while app is in foreground
    if (Platform.isIOS) {
      debugPrint('========================================');
      debugPrint('Configuring iOS foreground notification presentation...');
      debugPrint('========================================');

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      debugPrint('iOS notification permissions requested');
    }

    // Check if app was launched from a local notification (terminated state)
    debugPrint('========================================');
    debugPrint('Checking if app was launched from local notification...');
    debugPrint('========================================');

    final notificationAppLaunchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp == true) {
      debugPrint('========================================');
      debugPrint('APP LAUNCHED FROM LOCAL NOTIFICATION (TERMINATED STATE)');
      debugPrint(
        'Notification Response: ${notificationAppLaunchDetails?.notificationResponse}',
      );
      debugPrint(
        'Payload: ${notificationAppLaunchDetails?.notificationResponse?.payload}',
      );
      debugPrint('========================================');

      // Store payload in a temporary variable to be handled after UI is ready
      final payload =
          notificationAppLaunchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        try {
          // Parse the JSON payload to get notification data
          final notificationData = jsonDecode(payload) as Map<String, dynamic>;
          debugPrint('Parsed notification data from launch: $notificationData');

          // Store notification data directly
          // This allows the splash screen to detect and handle it
          _pendingNotificationData = notificationData;

          debugPrint(
            'Stored notification data in _pendingNotificationData for splash screen handling',
          );
        } catch (e) {
          debugPrint('Error parsing launch notification payload: $e');
        }
      }
    } else {
      debugPrint('App was NOT launched from local notification');
    }

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'emergex_default_channel', // id
      'EmergeX Notifications', // name
      description: 'Notifications for EmergeX incidents and updates',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Retrieve FCM token (called on app startup)
  Future<void> _retrieveFCMToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('========================================');
        debugPrint('FCM TOKEN GENERATED');
        debugPrint('========================================');
        debugPrint('Token: $token');
        debugPrint('Platform: ${Platform.isAndroid ? 'Android' : 'iOS'}');
        debugPrint('========================================');
        debugPrint(
          'COPY THIS TOKEN TO SEND TEST NOTIFICATIONS FROM FIREBASE CONSOLE',
        );
        debugPrint('========================================');
        _currentToken = token;
        _tokenController.add(token);
        // NOTE: Token will be registered with backend after user logs in
      } else {
        debugPrint('FCM token is null - check Firebase setup');
      }
    } catch (e) {
      debugPrint('Error retrieving FCM token: $e');
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      debugPrint('========================================');
      debugPrint('REGISTERING FCM TOKEN WITH BACKEND');
      debugPrint('========================================');
      debugPrint('Token: $token');
      debugPrint('Platform: ${Platform.isAndroid ? 'Android' : 'iOS'}');

      // Call backend API to register token
      final response = await AppDI.notificationRepo.registerFCMToken(
        fcmToken: token,
      );

      if (response.success == true) {
        debugPrint('FCM token registered with backend successfully');
        debugPrint('========================================');
      } else {
        debugPrint('Failed to register FCM token: ${response.message}');
        debugPrint('========================================');
      }
    } catch (e) {
      debugPrint('Error registering FCM token with backend: $e');
      debugPrint('========================================');
      // Silent fail, will retry on next app launch or token refresh
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('========================================');
    debugPrint('FOREGROUND NOTIFICATION RECEIVED');
    debugPrint('========================================');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Sent Time: ${message.sentTime}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
    debugPrint('From: ${message.from}');
    debugPrint('Category: ${message.category}');
    debugPrint('========================================');

    // Show local notification for foreground messages
    debugPrint('Showing local notification');
    _showLocalNotification(message);
  }

  /// Show local notification for foreground messages (Android & iOS)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Backend sends everything in data field (data-only notification)
    final String? title = message.data['title'];
    final String? body = message.data['body'];

    // Only show if we have at least a title or body
    if (title != null || body != null) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'emergex_default_channel',
            'EmergeX Notifications',
            channelDescription:
                'Notifications for EmergeX incidents and updates',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF3DA229),
            playSound: true,
            enableVibration: true,
          );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Store full notification data as JSON in payload for type-based routing
      final payloadData = jsonEncode(message.data);

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
        title ?? 'Notification',
        body ?? '',
        notificationDetails,
        payload: payloadData,
      );

      debugPrint('Local notification shown: $title - $body');
      debugPrint('Payload stored: $payloadData');
    } else {
      debugPrint('No title or body found in data payload');
    }
  }

  /// Handle notification tap (from background or terminated state)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('========================================');
    debugPrint('NOTIFICATION TAPPED');
    debugPrint('========================================');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
    debugPrint('========================================');

    // CRITICAL: Just store the notification data, don't try to navigate yet
    // The splash screen will handle navigation after UI is ready
    debugPrint('Storing notification data as pending...');
    _pendingNotificationData = message.data;
    debugPrint('Pending notification stored - splash screen will handle it');
    debugPrint('========================================');
  }

  /// Navigate to notifications screen using global navigator key
  void _navigateToNotifications() {
    try {
      debugPrint('========================================');
      debugPrint('_navigateToNotifications() CALLED');
      debugPrint('========================================');
      debugPrint('NavObserver.navKey: ${NavObserver.navKey}');
      debugPrint(
        'NavObserver.navKey.currentState: ${NavObserver.navKey.currentState}',
      );
      debugPrint(
        'NavObserver.navKey.currentContext: ${NavObserver.navKey.currentContext}',
      );

      final navigatorState = NavObserver.navKey.currentState;
      if (navigatorState != null) {
        debugPrint('Navigator state is available, pushing route...');
        navigatorState.push(
          MaterialPageRoute(
            builder: (context) {
              debugPrint('Building NotificationsScreen widget...');
              return NotificationsScreen();
            },
          ),
        );
        debugPrint('Navigation to notifications screen completed successfully');
      } else {
        debugPrint('========================================');
        debugPrint('ERROR: Navigator state is NULL');
        debugPrint('Cannot navigate - navigator not yet initialized');
        debugPrint('========================================');
      }
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('ERROR navigating to notifications screen');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('========================================');
    }
  }

  /// Navigate based on notification type
  /// Routes to different screens based on the 'type' field in notification data
  /// Implements role-based routing matching the web implementation
  void _navigateBasedOnType(Map<String, dynamic> notificationData) {
    try {
      debugPrint('========================================');
      debugPrint('_navigateBasedOnType() CALLED');
      debugPrint('Notification Data: $notificationData');
      debugPrint('========================================');

      final String notificationType = notificationData['type'] ?? 'UNKNOWN';
      final String? incidentId = notificationData['incidentId']?.toString();
      final String? taskId = notificationData['taskId']?.toString();

      debugPrint('Notification Type: $notificationType');
      debugPrint('Incident ID: $incidentId');
      debugPrint('Task ID: $taskId');

      final navigatorState = NavObserver.navKey.currentState;
      if (navigatorState == null) {
        debugPrint('ERROR: Navigator state is NULL - cannot navigate');
        return;
      }

      // Check user permissions for role-based routing
      final bool isTeamLeader = PermissionHelper.hasViewPermission(
        moduleName: "ERT Team Leader",
      );
      final bool isApproverFullAccess =
          PermissionHelper.hasFullAccessPermission(
            moduleName: "ER Team Approval",
          );

      debugPrint(
        'User Roles - Team Leader: $isTeamLeader, Approver Full Access: $isApproverFullAccess',
      );

      // Route based on notification type
      switch (notificationType) {
        // Task-related notifications (Team Leader vs Team Member routing)
        case 'NEW_TASK_ADDED':
        case 'TASK_STATUS_CHANGED':
        case 'NEW_TEAM_MEMBER_ADDED':
        case 'PROJECT_DOCUMENT_REVISED_TASK_UPDATED':
          _handleTaskNotification(
            context: navigatorState.context,
            incidentId: incidentId,
            taskId: taskId,
            isTeamLeader: isTeamLeader,
            notificationType: notificationType,
          );
          break;

        // Incident notifications with Approver vs Non-Approver routing
        case 'INCIDENT_APPROVED':
        case 'ERT_ASSIGNED':
        case 'INCIDENT_RESOLVED':
        case 'TASK_APPROVAL':
          _handleIncidentNotificationWithApproval(
            context: navigatorState.context,
            incidentId: incidentId,
            notificationType: notificationType,
            isApproverFullAccess: isApproverFullAccess,
          );
          break;

        // Incident notifications (always to approval screen)
        case 'NEW_INCIDENT_AWAITING_REVIEW':
        case 'INCIDENT_REPORT_GENERATED':
        case 'INCIDENT_REJECTED':
        case 'INVESTIGATION_TEAM_ASSIGNED':
          _handleIncidentApprovalNotification(
            context: navigatorState.context,
            incidentId: incidentId,
            notificationType: notificationType,
          );
          break;

        // External user/member notifications
        case 'EXTERNAL_USER_JOIN_REQUEST':
        case 'EXTERNAL_MEMBER_JOINED':
          debugPrint(
            'External user notification - navigating to notifications screen',
          );
          navigatorState.push(
            MaterialPageRoute(builder: (context) => NotificationsScreen()),
          );
          break;

        // Document revision notifications
        case 'PROJECT_DOCUMENT_REVISED':
          debugPrint(
            'Document revised notification - navigating to notifications screen',
          );
          navigatorState.push(
            MaterialPageRoute(builder: (context) => NotificationsScreen()),
          );
          break;

        default:
          // For unknown notifications, navigate to notifications screen
          debugPrint(
            'Unknown notification type - navigating to notifications screen',
          );
          navigatorState.push(
            MaterialPageRoute(builder: (context) => NotificationsScreen()),
          );
          break;
      }

      debugPrint(
        'Navigation completed successfully for type: $notificationType',
      );
      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('ERROR in _navigateBasedOnType');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('========================================');
      // Fallback to notifications screen
      _navigateToNotifications();
    }
  }

  /// Centralized helper for Task Navigation
  /// Handles routing logic for both Team Leaders and Members
  /// Supports both direct navigation (openScreen) and backstack synthesis (_navigateWithBackStack)
  Future<void> _navigateToTaskDetail({
    required BuildContext context,
    required String? incidentId,
    required String? taskId,
    required bool isTeamLeader,
    required String notificationType,
    required bool useBackStack,
  }) async {
    debugPrint('========================================');
    debugPrint('Navigating to Task Detail');
    debugPrint('Type: $notificationType');
    debugPrint('Incident ID: $incidentId, Task ID: $taskId');
    debugPrint('Is Team Leader: $isTeamLeader, Use Back Stack: $useBackStack');

    if (incidentId == null || taskId == null) {
      debugPrint('ERROR: Missing required IDs - incidentId or taskId is null');
      if (useBackStack) {
        _fallbackToNotifications(context);
      } else {
        _navigateToNotifications();
      }
      return;
    }

    String targetRoute;
    Map<String, dynamic> args = {'incidentId': incidentId, 'taskId': taskId};

    // Determine target route based on role and notification type
    // Logic aligned with NotificationsScreen._navigateBasedOnNotificationType
    if (notificationType == 'TASK_STATUS_SUBMITTED') {
      if (isTeamLeader) {
        // Team Leader -> Approver Task Details
        targetRoute = Routes.erTeamApproverTaskDetailsScreen;
      } else {
        // Team Member -> Task Details
        targetRoute = Routes.erTeamMemberTaskDetailsScreen;
      }
    } else {
      // NEW_TASK_ADDED, TASK_STATUS_CHANGED, etc.
      if (isTeamLeader) {
        // Team Leader -> Approver Task Details
        targetRoute = Routes.erTeamApproverTaskDetailsScreen;
        args['fromNotification'] = true;
      } else {
        // Team Member -> Task Details
        targetRoute = Routes.erTeamMemberTaskDetailsScreen;
      }
    }

    debugPrint('Target Route: $targetRoute');
    debugPrint('Args: $args');

    if (useBackStack) {
      await _navigateWithBackStack(context, targetRoute, args: args);
    } else {
      openScreen(targetRoute, args: args, clearOldStacks: false);
    }
    debugPrint('========================================');
  }

  /// Handle task-related notifications (Adapter for _navigateBasedOnType)
  void _handleTaskNotification({
    required BuildContext context,
    required String? incidentId,
    required String? taskId,
    required bool isTeamLeader,
    required String notificationType,
  }) {
    _navigateToTaskDetail(
      context: context,
      incidentId: incidentId,
      taskId: taskId,
      isTeamLeader: isTeamLeader,
      notificationType: notificationType,
      useBackStack: false, // Direct navigation for foreground/background taps
    );
  }

  /// Handle incident notifications with Approver Full Access check
  /// Approver with Full Access: Navigate to specific approval screen based on type
  /// Non-Approver: Navigate to incident details screen
  void _handleIncidentNotificationWithApproval({
    required BuildContext context,
    required String? incidentId,
    required String notificationType,
    required bool isApproverFullAccess,
  }) {
    debugPrint('========================================');
    debugPrint(
      'Handling Incident Notification with Approval: $notificationType',
    );
    debugPrint('Incident ID: $incidentId');
    debugPrint('Is Approver Full Access: $isApproverFullAccess');

    if (incidentId == null) {
      debugPrint('ERROR: Missing incidentId');
      debugPrint('Falling back to notifications screen');
      _navigateToNotifications();
      return;
    }

    if (isApproverFullAccess) {
      // Approver with Full Access
      if (notificationType == 'TASK_APPROVAL') {
        // Web: /er-handle-report/{incidentId}
        // Mobile: Routes.erTeamApproverDetailScreen
        debugPrint('Navigating to ER Team Approver Detail screen $incidentId');
        openScreen(
          Routes.erTeamApproverDetailScreen,
          args: {'incidentId': incidentId},
        );
      } else {
        // For other types (INCIDENT_APPROVED, ERT_ASSIGNED, INCIDENT_RESOLVED)
        // Web: /incident-approval/{incidentId}
        // Mobile: Routes.incidentApproval
        debugPrint('Navigating to Incident Approval screen');
        openScreen(Routes.incidentApproval, args: {'incidentId': incidentId});
      }
    } else {
      // Non-Approver: Navigate to incident details
      // Web: /incident-details/{incidentId}
      // Mobile: Routes.incidentReportDetails
      debugPrint('Navigating to Incident Report Details screen (Non-Approver)');
      openScreen(
        Routes.incidentReportDetails,
        args: {'incidentId': incidentId},
      );
    }
    debugPrint('========================================');
  }

  /// Handle incident approval notifications
  /// Always navigate to incident approval screen
  void _handleIncidentApprovalNotification({
    required BuildContext context,
    required String? incidentId,
    required String notificationType,
  }) {
    debugPrint('========================================');
    debugPrint('Handling Incident Approval Notification: $notificationType');
    debugPrint('Incident ID: $incidentId');

    if (incidentId == null) {
      debugPrint('ERROR: Missing incidentId');
      debugPrint('Falling back to notifications screen');
      _navigateToNotifications();
      return;
    }

    // Web: /incident-approval/{incidentId}
    // Mobile: Routes.incidentApproval
    debugPrint('Navigating to Incident Approval screen');
    openScreen(Routes.incidentApproval, args: {'incidentId': incidentId});
    debugPrint('========================================');
  }

  /// Get the notification type from pending notification (if any)
  String? getNotificationType() {
    if (_pendingNotificationMessage != null) {
      return _pendingNotificationMessage!.data['type'];
    }
    if (_pendingNotificationData != null) {
      return _pendingNotificationData!['type'];
    }
    return null;
  }

  /// Get the full notification data from pending notification (if any)
  Map<String, dynamic>? getPendingNotificationData() {
    if (_pendingNotificationMessage != null) {
      return _pendingNotificationMessage!.data;
    }
    if (_pendingNotificationData != null) {
      return _pendingNotificationData;
    }
    return null;
  }

  /// Process pending notification and navigate to the target screen
  /// This method consolidates logic from SplashScreen including:
  /// - Project context switching
  /// - Role-based routing
  /// - Backstack synthesis (Dashboard -> Target)
  Future<void> navigatePendingNotification(BuildContext context) async {
    debugPrint('========================================');
    debugPrint('PushNotificationService: navigatePendingNotification called');

    final notificationType = getNotificationType();
    final notificationData = getPendingNotificationData();

    if (notificationType == null || notificationData == null) {
      debugPrint('No pending notification data found');
      clearPendingNotification();
      return;
    }

    // Clear pending state immediately to prevent loops
    clearPendingNotification();

    // 🚩 Prevent app reset during project switch
    isFromNotification = true;

    // Schedule reset of flag after navigation transition
    Future.delayed(const Duration(seconds: 2), () {
      isFromNotification = false;
    });

    final String? incidentId = notificationData['incidentId']?.toString();
    final String? taskId = notificationData['taskId']?.toString();
    // 🔍 Extract Project ID and switch context if needed
    final String? projectId = notificationData['projectId']?.toString();

    debugPrint(
      'Notification Type: $notificationType, Incident Id: $incidentId, Task Id: $taskId, Project Id: $projectId',
    );

    if (projectId != null && projectId.isNotEmpty) {
      final currentProjectId = AppDI.emergexAppCubit.state.selectedProjectId;
      if (currentProjectId != projectId) {
        debugPrint(
          'Switching project context from $currentProjectId to $projectId',
        );
        final success = await AppDI.emergexAppCubit.updateSelectedProject(
          projectId,
        );

        if (!success) {
          debugPrint('Failed to switch project context');
        }
      }
    }

    // Check user permissions for role-based routing
    final bool isTeamLeader = PermissionHelper.hasViewPermission(
      moduleName: "ERT Team Leader",
    );
    final bool isApproverFullAccess = PermissionHelper.hasFullAccessPermission(
      moduleName: "ER Team Approval",
    );

    debugPrint(
      'User Roles - Team Leader: $isTeamLeader, Approver Full Access: $isApproverFullAccess',
    );

    // Route based on notification type
    switch (notificationType) {
      // Task-related notifications (Team Leader vs Team Member routing)
      // Task-related notifications (Team Leader vs Team Member routing)
      case 'NEW_TASK_ADDED':
      case 'TASK_STATUS_CHANGED':
      case 'NEW_TEAM_MEMBER_ADDED':
      case 'PROJECT_DOCUMENT_REVISED_TASK_UPDATED':
        await _navigateToTaskDetail(
          context: context,
          incidentId: incidentId,
          taskId: taskId,
          isTeamLeader: isTeamLeader,
          notificationType: notificationType,
          useBackStack: true, // Synthesize backstack for pending flow
        );
        break;

      case 'TASK_STATUS_SUBMITTED':
        if (incidentId != null && taskId != null) {
          if (isTeamLeader) {
            await _navigateWithBackStack(
              context,
              Routes.erTeamApproverTaskDetailsScreen,
              args: {'incidentId': incidentId, 'taskId': taskId},
            );
          } else {
            await _navigateWithBackStack(
              context,
              Routes.erTeamMemberTaskDetailsScreen,
              args: {'taskId': taskId, 'incidentId': incidentId},
            );
          }
        } else {
          _fallbackToNotifications(context);
        }
        break;

      // Incident notifications with Approver vs Non-Approver routing
      case 'INCIDENT_APPROVED':
      case 'ERT_ASSIGNED':
      case 'INCIDENT_RESOLVED':
      case 'TASK_APPROVAL':
        if (incidentId != null) {
          if (isApproverFullAccess) {
            if (notificationType == 'TASK_APPROVAL') {
              debugPrint('Navigating to ER Team Approver Detail screen');
              await _navigateWithBackStack(
                context,
                Routes.erTeamApproverDetailScreen,
                args: {'incidentId': incidentId},
              );
            } else {
              debugPrint('Navigating to Incident Approval screen');
              await _navigateWithBackStack(
                context,
                Routes.incidentApproval,
                args: {'incidentId': incidentId},
              );
            }
          } else {
            debugPrint(
              'Navigating to Incident Report Details screen (Non-Approver)',
            );
            await _navigateWithBackStack(
              context,
              Routes.incidentReportDetails,
              args: {'incidentId': incidentId},
            );
          }
        } else {
          _fallbackToNotifications(context);
        }
        break;

      // Incident notifications (always to approval screen)
      case 'NEW_INCIDENT_AWAITING_REVIEW':
      case 'INCIDENT_REPORT_GENERATED':
      case 'INCIDENT_REJECTED':
      case 'INVESTIGATION_TEAM_ASSIGNED':
        if (incidentId != null) {
          debugPrint('Navigating to Incident Approval screen');
          await _navigateWithBackStack(
            context,
            Routes.incidentApproval,
            args: {'incidentId': incidentId},
          );
        } else {
          _fallbackToNotifications(context);
        }
        break;

      // External user/member notifications, documents, and unknown types
      case 'EXTERNAL_USER_JOIN_REQUEST':
      case 'EXTERNAL_MEMBER_JOINED':
      case 'PROJECT_DOCUMENT_REVISED':
      default:
        debugPrint(
          'Navigating to notifications screen for type: $notificationType',
        );
        context.goNamed(Routes.notificationsScreen);
        break;
    }
    debugPrint('========================================');
  }

  void _fallbackToNotifications(BuildContext context) {
    debugPrint('Missing required IDs - falling back to notifications screen');
    context.goNamed(Routes.notificationsScreen);
  }

  /// Helper to establish a valid back stack (Dashboard) before pushing the target screen.
  Future<void> _navigateWithBackStack(
    BuildContext context,
    String targetRouteName, {
    Map<String, dynamic>? args,
  }) async {
    // 1. Identify the base dashboard route for the user
    final String baseRouteName =
        PermissionHelper.getFirstAccessibleDashboardRoute() ??
        Routes.homeScreen;
    final String baseRoutePath = Routes.getRouterPath(baseRouteName);

    debugPrint(
      'Synthesizing Stack: Go($baseRoutePath) -> Push($targetRouteName)',
    );

    // 2. Clear stack and go to Dashboard
    context.go(baseRoutePath);

    // 3. Wait for the router to settle and dashboard to mount
    await Future.delayed(const Duration(milliseconds: 500));

    // 4. Push the target screen on top of Dashboard
    openScreen(targetRouteName, args: args);
  }

  /// Handle pending notification from terminated state
  /// Call this method after the app UI is fully initialized
  Future<void> handlePendingNotification() async {
    debugPrint('========================================');
    debugPrint('handlePendingNotification() CALLED');
    debugPrint('Has pending message: ${_pendingNotificationMessage != null}');
    debugPrint('========================================');

    if (_pendingNotificationMessage != null) {
      debugPrint('========================================');
      debugPrint('HANDLING PENDING NOTIFICATION FROM TERMINATED STATE');
      debugPrint('Message ID: ${_pendingNotificationMessage!.messageId}');
      debugPrint('========================================');

      _pendingNotificationMessage = null; // Clear the pending message

      // Wait for the UI to be fully ready before navigating
      debugPrint('Waiting 2 seconds for UI to be ready...');
      await Future.delayed(const Duration(milliseconds: 2000));
      debugPrint('Wait complete, proceeding with navigation...');

      // Refresh notifications
      try {
        debugPrint('Refreshing notifications...');
        AppDI.notificationCubit.loadNotifications();
        debugPrint('Notifications refreshed successfully');
      } catch (e) {
        debugPrint('Error refreshing notifications: $e');
      }

      // Navigate to notifications screen
      debugPrint('Calling _navigateToNotifications()...');
      _navigateToNotifications();

      debugPrint('========================================');
      debugPrint('PENDING NOTIFICATION HANDLED');
      debugPrint('========================================');
    } else {
      debugPrint('No pending notification message to handle');
    }
  }

  /// Request notification permissions (called from UI)
  Future<bool> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final isGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (isGranted && _currentToken == null) {
      await _retrieveFCMToken();
    }

    return isGranted;
  }

  /// Check if notification permissions are granted
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Register FCM token with backend (called after successful login)
  Future<void> registerToken() async {
    if (_currentToken == null) {
      debugPrint('No FCM token to register - retrieving now...');
      await _retrieveFCMToken();
    }

    if (_currentToken != null) {
      await _registerTokenWithBackend(_currentToken!);
    } else {
      debugPrint('Failed to retrieve FCM token for registration');
    }
  }

  /// Unregister FCM token from backend (called on logout)
  Future<void> unregisterToken() async {
    if (_currentToken == null) {
      debugPrint('No FCM token to unregister');
      return;
    }

    try {
      debugPrint('========================================');
      debugPrint('UNREGISTERING FCM TOKEN FROM BACKEND');
      debugPrint('========================================');
      debugPrint('Token: $_currentToken');

      final response = await AppDI.notificationRepo.unregisterFCMToken(
        fcmToken: _currentToken!,
      );

      if (response.success == true) {
        debugPrint('FCM token unregistered successfully');
        _currentToken = null; // Clear the token
        debugPrint('========================================');
      } else {
        debugPrint('Failed to unregister FCM token: ${response.message}');
        debugPrint('========================================');
      }
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
      debugPrint('========================================');
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenController.close();
  }
}
