import SwiftUI
import WidgetKit

struct RecentNotificationWidget: Widget {
  let kind: String = "RecentNotificationWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RecentNotificationTimelineProvider()) { entry in
      RecentNotificationWidgetView(entry: entry)
    }
    .configurationDisplayName("Recent Activity")
    .description("Show your latest Bluesky activity")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct RecentNotificationTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> RecentNotificationEntry {
    RecentNotificationEntry(
      date: Date(),
      title: "New follower",
      subtitle: "@user.bsky.social started following you",
      type: .follow
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (RecentNotificationEntry) -> Void) {
    let entry = RecentNotificationEntry(
      date: Date(),
      title: "New follower",
      subtitle: "@user.bsky.social started following you",
      type: .follow
    )
    completion(entry)
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<RecentNotificationEntry>) -> Void
  ) {
    let defaults = UserDefaults(suiteName: "group.com.acxtrilla.Horizon")
    let title = defaults?.string(forKey: "widget.recent.notification.title") ?? "No recent activity"
    let subtitle =
      defaults?.string(forKey: "widget.recent.notification.subtitle") ?? "Check your notifications"

    // Determine notification type from title
    let type = determineNotificationType(from: title)

    let entry = RecentNotificationEntry(
      date: Date(),
      title: title,
      subtitle: subtitle,
      type: type
    )
    let timeline = Timeline(entries: [entry], policy: .atEnd)
    completion(timeline)
  }

  private func determineNotificationType(from title: String) -> NotificationType {
    let lowercased = title.lowercased()
    if lowercased.contains("follow") {
      return .follow
    } else if lowercased.contains("like") {
      return .like
    } else if lowercased.contains("repost") {
      return .repost
    } else if lowercased.contains("reply") {
      return .reply
    } else {
      return .general
    }
  }
}

struct RecentNotificationEntry: TimelineEntry {
  let date: Date
  let title: String
  let subtitle: String
  let type: NotificationType
}

enum NotificationType {
  case follow, like, repost, reply, general

  var icon: String {
    switch self {
    case .follow: return "person.badge.plus"
    case .like: return "heart.fill"
    case .repost: return "arrow.2.squarepath"
    case .reply: return "bubble.left"
    case .general: return "bell"
    }
  }

  var color: Color {
    switch self {
    case .follow: return .green
    case .like: return .red
    case .repost: return .blue
    case .reply: return .orange
    case .general: return .gray
    }
  }
}

struct RecentNotificationWidgetView: View {
  let entry: RecentNotificationEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    ZStack {
      // Background
      Color(.systemBackground)

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          // Icon
          Image(systemName: entry.type.icon)
            .font(.title2)
            .foregroundColor(entry.type.color)

          Spacer()

          // Time
          Text(entry.date, style: .time)
            .font(.caption2)
            .foregroundColor(.secondary)
        }

        // Title
        Text(entry.title)
          .font(.headline)
          .fontWeight(.semibold)
          .lineLimit(2)
          .foregroundColor(.primary)

        // Subtitle
        Text(entry.subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(family == .systemSmall ? 2 : 3)

        Spacer()

        // Action hint
        HStack {
          Text("Tap to view")
            .font(.caption2)
            .foregroundColor(.blue)
          Spacer()
          Image(systemName: "arrow.right")
            .font(.caption2)
            .foregroundColor(.blue)
        }
      }
      .padding()
    }
    .widgetURL(URL(string: "horizon://notifications"))
  }
}

#Preview(as: .systemSmall) {
  RecentNotificationWidget()
} timeline: {
  RecentNotificationEntry(
    date: .now,
    title: "New follower",
    subtitle: "@user.bsky.social started following you",
    type: .follow
  )
}

#Preview(as: .systemMedium) {
  RecentNotificationWidget()
} timeline: {
  RecentNotificationEntry(
    date: .now,
    title: "New follower",
    subtitle: "@user.bsky.social started following you",
    type: .follow
  )
}
