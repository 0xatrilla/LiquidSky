import ATProtoKit
import Foundation
import UserNotifications

@Observable
class PushNotificationService: NSObject {
  static let shared = PushNotificationService()

  var isRegistered = false
  var authorizationStatus: UNAuthorizationStatus = .notDetermined
  var deviceToken: String?

  private override init() {
    super.init()
    UNUserNotificationCenter.current().delegate = self
    checkAuthorizationStatus()
  }

  func requestPermission() async -> Bool {
    do {
      let granted = try await UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .badge, .sound, .provisional]
      )

      await MainActor.run {
        self.authorizationStatus = granted ? .authorized : .denied
      }

      if granted {
        await registerForRemoteNotifications()
      }

      return granted
    } catch {
      print("PushNotificationService: Failed to request permission: \(error)")
      return false
    }
  }

  func registerForRemoteNotifications() async {
    await MainActor.run {
      UIApplication.shared.registerForRemoteNotifications()
    }
  }

  func unregisterForRemoteNotifications() {
    UIApplication.shared.unregisterForRemoteNotifications()
    deviceToken = nil
    isRegistered = false
  }

  func checkAuthorizationStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        self.authorizationStatus = settings.authorizationStatus
      }
    }
  }

  func updateDeviceToken(_ deviceToken: Data) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    self.deviceToken = tokenString

    // Store in UserDefaults for widget access
    let defaults = UserDefaults(suiteName: "group.com.acxtrilla.LiquidSky")
    defaults?.set(tokenString, forKey: "push.device.token")

    // TODO: Send device token to your Bluesky notification service
    // This would typically involve calling your backend API
    print("PushNotificationService: Device token updated: \(tokenString)")
  }

  func scheduleLocalNotification(title: String, body: String, timeInterval: TimeInterval = 5.0) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
    let request = UNNotificationRequest(
      identifier: UUID().uuidString, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("PushNotificationService: Failed to schedule notification: \(error)")
      }
    }
  }

  func sendTestNotification() {
    scheduleLocalNotification(
      title: "LiquidSky Test",
      body: "This is a test push notification from LiquidSky!",
      timeInterval: 2.0
    )
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification even when app is in foreground
    completionHandler([.banner, .sound, .badge])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // Handle notification tap
    let userInfo = response.notification.request.content.userInfo

    // Post notification for app to handle
    NotificationCenter.default.post(
      name: .notificationTapped,
      object: nil,
      userInfo: userInfo
    )

    completionHandler()
  }
}

// MARK: - Notification Names
extension Notification.Name {
  static let notificationTapped = Notification.Name("notificationTapped")
}
