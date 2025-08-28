import SwiftUI
import WidgetKit

struct RecentNotificationWidget: Widget {
  let kind: String = "RecentNotificationWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RecentNotificationTimelineProvider()) { entry in
      RecentNotificationWidgetView(entry: entry)
    }
    .configurationDisplayName("Recent Notification")
    .description("Shows your most recent Bluesky notification")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct RecentNotificationTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> RecentNotificationEntry {
    RecentNotificationEntry(
      date: Date(),
      title: "New follower",
      subtitle: "@username started following you",
      type: .follow
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (RecentNotificationEntry) -> Void) {
    let entry = RecentNotificationEntry(
      date: Date(),
      title: "New follower",
      subtitle: "@username started following you",
      type: .follow
    )
    completion(entry)
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<RecentNotificationEntry>) -> Void
  ) {
    let defaults = UserDefaults(suiteName: "group.com.acxtrilla.LiquidSky")
    let title = defaults?.string(forKey: "widget.recent.notification.title") ?? "No notifications"
    let subtitle =
      defaults?.string(forKey: "widget.recent.notification.subtitle") ?? "Check back later"

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
    } else if lowercased.contains("reply") || lowercased.contains("mention") {
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
  case follow
  case like
  case repost
  case reply
  case general

  var icon: String {
    switch self {
    case .follow:
      return "person.badge.plus"
    case .like:
      return "heart.fill"
    case .repost:
      return "arrow.2.squarepath"
    case .reply:
      return "bubble.left.fill"
    case .general:
      return "bell.fill"
    }
  }

  var color: Color {
    switch self {
    case .follow:
      return .blue
    case .like:
      return .red
    case .repost:
      return .green
    case .reply:
      return .orange
    case .general:
      return .gray
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
        // Header with icon and type
        HStack {
          Image(systemName: entry.type.icon)
            .font(.system(size: 16))
            .foregroundColor(entry.type.color)

          Text(entry.type == .general ? "Notification" : String(describing: entry.type).capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)

          Spacer()
        }

        // Title
        Text(entry.title)
          .font(.system(size: family == .systemSmall ? 14 : 16, weight: .semibold))
          .foregroundColor(.primary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)

        // Subtitle
        Text(entry.subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(family == .systemSmall ? 1 : 2)
          .multilineTextAlignment(.leading)

        Spacer()

        // Timestamp
        HStack {
          Image(systemName: "clock")
            .font(.caption2)
            .foregroundColor(.tertiary)

          Text(entry.date, style: .relative)
            .font(.caption2)
            .foregroundColor(.tertiary)

          Spacer()
        }
      }
      .padding()
    }
    .widgetURL(URL(string: "liquidsky://notifications"))
  }
}

#Preview(as: .systemSmall) {
  RecentNotificationWidget()
} timeline: {
  RecentNotificationEntry(
    date: Date(),
    title: "New follower",
    subtitle: "@username started following you",
    type: .follow
  )
  RecentNotificationEntry(
    date: Date(),
    title: "Post liked",
    subtitle: "@user liked your post",
    type: .like
  )
}

#Preview(as: .systemMedium) {
  RecentNotificationWidget()
} timeline: {
  RecentNotificationEntry(
    date: Date(),
    title: "New follower",
    subtitle: "@username started following you",
    type: .follow
  )
}
