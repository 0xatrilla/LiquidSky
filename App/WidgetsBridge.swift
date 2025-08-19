import Foundation
import WidgetKit

enum WidgetDataPublisher {
  static let appGroupId = "group.com.acxtrilla.LiquidSky"

  static func publishFollowerCount(_ count: Int) {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set(count, forKey: "widget.followers.count")

    // Only reload timelines if WidgetKit is available (widget extension is installed)
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: "FollowerCountWidget")
    }
  }

  static func publishRecentNotification(title: String, subtitle: String?) {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set(title, forKey: "widget.recent.notification.title")
    defaults?.set(subtitle ?? "", forKey: "widget.recent.notification.subtitle")

    // Only reload timelines if WidgetKit is available (widget extension is installed)
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: "RecentNotificationWidget")
    }
  }

  // Helper method to get stored data (useful for debugging)
  static func getStoredFollowerCount() -> Int {
    let defaults = UserDefaults(suiteName: appGroupId)
    return defaults?.integer(forKey: "widget.followers.count") ?? 0
  }

  static func getStoredRecentNotification() -> (title: String, subtitle: String) {
    let defaults = UserDefaults(suiteName: appGroupId)
    let title = defaults?.string(forKey: "widget.recent.notification.title") ?? "No notifications"
    let subtitle = defaults?.string(forKey: "widget.recent.notification.subtitle") ?? ""
    return (title, subtitle)
  }
}
