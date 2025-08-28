import SwiftUI
import WidgetKit

struct FollowerCountWidget: Widget {
  let kind: String = "FollowerCountWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FollowerCountTimelineProvider()) { entry in
      FollowerCountWidgetView(entry: entry)
    }
    .configurationDisplayName("Follower Count")
    .description("Shows your current follower count on Bluesky")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct FollowerCountTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> FollowerCountEntry {
    FollowerCountEntry(date: Date(), followerCount: 1234, username: "@username")
  }

  func getSnapshot(in context: Context, completion: @escaping (FollowerCountEntry) -> Void) {
    let entry = FollowerCountEntry(date: Date(), followerCount: 1234, username: "@username")
    completion(entry)
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<FollowerCountEntry>) -> Void
  ) {
    let defaults = UserDefaults(suiteName: "group.com.acxtrilla.LiquidSky")
    let followerCount = defaults?.integer(forKey: "widget.followers.count") ?? 0
    let username = defaults?.string(forKey: "widget.username") ?? "@username"

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
    ZStack {
      // Background with gradient
      LinearGradient(
        colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      VStack(spacing: 8) {
        // Username
        Text(entry.username)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.white.opacity(0.9))
          .lineLimit(1)

        // Follower count
        Text("\(entry.followerCount)")
          .font(.system(size: family == .systemSmall ? 32 : 40, weight: .bold, design: .rounded))
          .foregroundColor(.white)
          .minimumScaleFactor(0.5)

        // Label
        Text("followers")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.white.opacity(0.8))
          .textCase(.uppercase)
          .tracking(0.5)

        // Bluesky logo or icon
        Image(systemName: "person.3.fill")
          .font(.system(size: family == .systemSmall ? 16 : 20))
          .foregroundColor(.white.opacity(0.7))
          .padding(.top, 4)
      }
      .padding()
    }
    .widgetURL(URL(string: "liquidsky://profile"))
  }
}

#Preview(as: .systemSmall) {
  FollowerCountWidget()
} timeline: {
  FollowerCountEntry(date: Date(), followerCount: 1234, username: "@username")
  FollowerCountEntry(date: Date(), followerCount: 5678, username: "@testuser")
}

#Preview(as: .systemMedium) {
  FollowerCountWidget()
} timeline: {
  FollowerCountEntry(date: Date(), followerCount: 1234, username: "@username")
}

