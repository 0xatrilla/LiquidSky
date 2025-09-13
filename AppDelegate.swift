import UIKit
import UserNotifications
import WidgetKit

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    return true
  }

  // MARK: - Push Notifications

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Update the push notification service with the device token
    PushNotificationService.shared.updateDeviceToken(deviceToken)
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error)")
  }

  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Handle remote notification when app is in background
    print("Received remote notification: \(userInfo)")

    // Update widget data if needed
    if let title = userInfo["title"] as? String,
      let subtitle = userInfo["subtitle"] as? String
    {
      let defaults = UserDefaults(suiteName: "group.com.acxtrilla.Horizon")
      defaults?.set(title, forKey: "widget.recent.notification.title")
      defaults?.set(subtitle, forKey: "widget.recent.notification.subtitle")

      // Reload widget timeline
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadTimelines(ofKind: "RecentNotificationWidget")
      }
    }

    completionHandler(.newData)
  }
}
