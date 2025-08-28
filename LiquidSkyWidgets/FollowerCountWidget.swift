import SwiftUI
import WidgetKit

struct FollowerCountWidget: Widget {
  let kind: String = "FollowerCountWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FollowerCountTimelineProvider()) { entry in
      FollowerCountWidgetView(entry: entry)
    }
    .configurationDisplayName("Follower Count")
    .description("Display your current follower count")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct FollowerCountTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> FollowerCountEntry {
    FollowerCountEntry(date: Date(), followerCount: 1234, username: "user.bsky.social")
  }

  func getSnapshot(in context: Context, completion: @escaping (FollowerCountEntry) -> Void) {
    let entry = FollowerCountEntry(date: Date(), followerCount: 1234, username: "user.bsky.social")
    completion(entry)
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<FollowerCountEntry>) -> Void
  ) {
    let defaults = UserDefaults(suiteName: "group.com.acxtrilla.Horizon")
    let followerCount = defaults?.integer(forKey: "widget.follower.count") ?? 0
    let username = defaults?.string(forKey: "widget.username") ?? "user.bsky.social"

    let entry = FollowerCountEntry(date: Date(), followerCount: followerCount, username: username)
    let timeline = Timeline(entries: [entry], policy: .atEnd)
    completion(timeline)
  }
}

struct FollowerCountEntry: TimelineEntry {
  let date: Date
  let followerCount: Int
  let username: String
}

struct FollowerCountWidgetView: View {
  let entry: FollowerCountEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    VStack(spacing: 8) {
      // Follower count
      Text("\(entry.followerCount)")
        .font(fontForFamily())
        .fontWeight(.bold)
        .foregroundColor(.primary)

      // Label
      Text("Followers")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.secondary)

      // Username (only show in medium size)
      if family == .systemMedium {
        Text("@\(entry.username)")
          .font(.caption2)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
    .widgetURL(URL(string: "horizon://profile/\(entry.username)"))
  }

  private func fontForFamily() -> Font {
    switch family {
    case .systemSmall:
      return .system(size: 28, weight: .bold, design: .rounded)
    case .systemMedium:
      return .system(size: 32, weight: .bold, design: .rounded)
    default:
      return .system(size: 28, weight: .bold, design: .rounded)
    }
  }
}

#Preview(as: .systemSmall) {
  FollowerCountWidget()
} timeline: {
  FollowerCountEntry(date: .now, followerCount: 1234, username: "user.bsky.social")
}

#Preview(as: .systemMedium) {
  FollowerCountWidget()
} timeline: {
  FollowerCountEntry(date: .now, followerCount: 1234, username: "user.bsky.social")
}
