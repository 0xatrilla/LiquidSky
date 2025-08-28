import Foundation
import WidgetKit

enum WidgetDataPublisher {
  static let appGroupId = "group.com.acxtrilla.Horizon"

  static func publishFollowerCount(_ count: Int) {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set(count, forKey: "widget.follower.count")
    defaults?.set("user.bsky.social", forKey: "widget.username")

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

  static func publishFeedActivity(
    feedName: String, recentPosts: Int, newFollowers: Int, totalActivity: Int
  ) {
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set(feedName, forKey: "widget.feed.name")
    defaults?.set(recentPosts, forKey: "widget.feed.recent.posts")
    defaults?.set(newFollowers, forKey: "widget.feed.new.followers")
    defaults?.set(totalActivity, forKey: "widget.feed.total.activity")

    // Only reload timelines if WidgetKit is available (widget extension is installed)
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: "FeedUpdatesWidget")
    }
  }

  // Publish sample feed activity for testing
  static func publishSampleFeedActivity() {
    publishFeedActivity(
      feedName: "Following",
      recentPosts: 5,
      newFollowers: 2,
      totalActivity: 12
    )
  }

  // Helper method to get stored data (useful for debugging)
  static func getStoredFollowerCount() -> Int {
    let defaults = UserDefaults(suiteName: appGroupId)
    return defaults?.integer(forKey: "widget.follower.count") ?? 0
  }

  static func getStoredRecentNotification() -> (title: String, subtitle: String) {
    let defaults = UserDefaults(suiteName: appGroupId)
    let title = defaults?.string(forKey: "widget.recent.notification.title") ?? "No notifications"
    let subtitle = defaults?.string(forKey: "widget.recent.notification.subtitle") ?? ""
    return (title, subtitle)
  }
}
