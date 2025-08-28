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
      recentPosts: Int.random(in: 3...15),
      newFollowers: Int.random(in: 0...5),
      totalActivity: Int.random(in: 8...25)
    )
  }

  // Publish real notification data
  static func publishNotificationData(title: String, subtitle: String) {
    publishRecentNotification(title: title, subtitle: subtitle)
  }

  // Publish real feed data when available
  static func publishRealFeedData(feedName: String, postCount: Int, followerCount: Int) {
    let totalActivity = postCount + followerCount
    publishFeedActivity(
      feedName: feedName,
      recentPosts: postCount,
      newFollowers: followerCount,
      totalActivity: totalActivity
    )
  }

  // Start continuous widget updates to simulate real-time data
  static func startContinuousUpdates() {
    Task {
      while true {
        try? await Task.sleep(nanoseconds: 30_000_000_000)  // 30 seconds

        // Update follower count with some variation
        let currentFollowers = getStoredFollowerCount()
        let variation = Int.random(in: -2...3)
        let newFollowerCount = max(0, currentFollowers + variation)
        publishFollowerCount(newFollowerCount)

        // Update feed activity
        publishRealFeedData(
          feedName: "Following",
          postCount: Int.random(in: 3...25),
          followerCount: Int.random(in: 0...6)
        )

        // Update notification with recent activity
        let activities = [
          ("New follower", "@user.bsky.social started following you"),
          ("Post liked", "Someone liked your recent post"),
          ("New reply", "You received a reply to your post"),
          ("Feed update", "Your Following feed has new posts"),
        ]

        let randomActivity = activities.randomElement() ?? ("Activity", "New activity detected")
        publishRecentNotification(title: randomActivity.0, subtitle: randomActivity.1)
      }
    }
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
