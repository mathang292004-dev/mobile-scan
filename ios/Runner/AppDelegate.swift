import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Track if app was launched from notification to prevent double-forwarding
  private var launchedFromNotification = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("========================================")
    print("🚀 iOS APP STARTING")
    print("========================================")

    // Initialize Firebase
    FirebaseApp.configure()
    print("✅ Firebase configured")

    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      print("✅ Notification delegate set")
    }

    // Set Firebase Messaging delegate
    Messaging.messaging().delegate = self
    print("✅ Firebase Messaging delegate set")

    // Register for remote notifications
    application.registerForRemoteNotifications()
    print("✅ Registered for remote notifications")

    // Check if app was launched from a notification (terminated state)
    if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      print("========================================")
      print("🔥 APP LAUNCHED FROM NOTIFICATION (TERMINATED STATE)")
      print("========================================")
      print("Launch notification data: \(userInfo)")

      // CRITICAL: Manually forward to Firebase Messaging since FirebaseAppDelegateProxyEnabled = false
      // This ensures Firebase's getInitialMessage() will work properly
      Messaging.messaging().appDidReceiveMessage(userInfo)
      print("✅ Manually forwarded launch notification to Firebase Messaging")

      // Print all data fields for debugging
      if let data = userInfo as? [String: Any] {
        print("Data fields in launch notification:")
        for (key, value) in data {
          print("  \(key): \(value)")
        }
      }

      // CRITICAL: Set flag to prevent double-forwarding in userNotificationCenter:didReceive:
      // iOS will call BOTH didFinishLaunchingWithOptions AND userNotificationCenter:didReceive:
      // We already forwarded here, so skip forwarding in the tap handler
      self.launchedFromNotification = true
      print("✅ Set launchedFromNotification=true to prevent double-forwarding")
      print("========================================")
    } else {
      print("ℹ️ Normal app launch (not from notification)")
    }

    print("========================================")

    GeneratedPluginRegistrant.register(with: self)

    // IMPORTANT: Call super.application with launchOptions
    // This passes the notification to Flutter's firebase_messaging plugin
    // So getInitialMessage() will work properly
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle APNs token registration
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    print("APNs token registered: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
  }

  // Handle registration failure
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
  }

  // CRITICAL: Handle incoming remote notifications
  // Since FirebaseAppDelegateProxyEnabled = false, we must manually forward to Firebase
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("========================================")
    print("📬 REMOTE NOTIFICATION RECEIVED (iOS)")
    print("========================================")
    print("User Info: \(userInfo)")

    // Forward to Firebase Messaging
    Messaging.messaging().appDidReceiveMessage(userInfo)
    print("✅ Forwarded to Firebase Messaging")

    // Call parent implementation to ensure Flutter plugin receives it
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    print("✅ Forwarded to Flutter plugin")
    print("========================================")
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")

    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate {
  // Handle notification presentation when app is in foreground
    override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo

    print("========================================")
    print("FOREGROUND NOTIFICATION RECEIVED (iOS)")
    print("========================================")
    print("Title: \(notification.request.content.title)")
    print("Body: \(notification.request.content.body)")
    print("User Info: \(userInfo)")
    print("Badge: \(notification.request.content.badge ?? 0)")
    print("Sound: \(notification.request.content.sound?.description ?? "none")")

    // Check if this is a Firebase message
    if let messageID = userInfo["gcm.message_id"] as? String {
      print("Firebase Message ID: \(messageID)")
    }

    // Print all data fields
    if let data = userInfo as? [String: Any] {
      print("Data fields:")
      for (key, value) in data {
        print("  \(key): \(value)")
      }
    }
    print("========================================")

    // Show banner, play sound, and update badge when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  // Handle notification tap
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo

    print("========================================")
    print("🔔 NOTIFICATION TAPPED (iOS)")
    print("========================================")
    print("Action: \(response.actionIdentifier)")
    print("Title: \(response.notification.request.content.title)")
    print("Body: \(response.notification.request.content.body)")
    print("User Info: \(userInfo)")

    // Print all data fields
    if let data = userInfo as? [String: Any] {
      print("Data fields:")
      for (key, value) in data {
        print("  \(key): \(value)")
      }
    }

    // CRITICAL FIX: Check if app was launched from notification (terminated state)
    // When app launches from terminated state, iOS calls BOTH:
    //   1. didFinishLaunchingWithOptions (with notification in launchOptions)
    //   2. userNotificationCenter:didReceive: (this method)
    // If we forward in both places, the second forward tries to use invalidated connection → SIGSEGV crash
    // Solution: Only forward here if app was NOT launched from notification
    if self.launchedFromNotification {
      print("========================================")
      print("⚠️ App launched from TERMINATED state")
      print("Notification already forwarded via launchOptions in didFinishLaunchingWithOptions")
      print("Skipping manual forwarding to prevent double-processing and SIGSEGV crash")
      print("Firebase Messaging will handle this via getInitialMessage()")

      // Reset the flag for future notifications
      self.launchedFromNotification = false

      print("✅ Flag reset - future notifications will forward normally")
      print("========================================")

      // Complete immediately without forwarding
      completionHandler()
      return
    }

    print("========================================")
    print("✅ App was NOT launched from notification (background/foreground tap)")
    print("Forwarding to Flutter plugin normally...")
    print("========================================")

    // Forward to parent implementation (background/foreground case)
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)

    print("✅ Forwarded to Flutter plugin")
    print("========================================")
  }
}
