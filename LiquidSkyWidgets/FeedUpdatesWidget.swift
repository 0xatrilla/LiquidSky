import SwiftUI
import WidgetKit

struct FeedUpdatesWidget: Widget {
  let kind: String = "FeedUpdatesWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FeedUpdatesTimelineProvider()) { entry in
      FeedUpdatesWidgetView(entry: entry)
    }
    .configurationDisplayName("Feed Updates")
    .description("Shows recent activity from your feeds")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct FeedUpdatesTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> FeedUpdatesEntry {
    FeedUpdatesEntry(
      date: Date(),
      feedName: "Following",
      recentPosts: 5,
      newFollowers: 2,
      unreadCount: 8
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (FeedUpdatesEntry) -> Void) {
    let entry = FeedUpdatesEntry(
      date: Date(),
      feedName: "Following",
      recentPosts: 5,
      newFollowers: 2,
      unreadCount: 8
    )
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<FeedUpdatesEntry>) -> Void)
  {
    let defaults = UserDefaults(suiteName: "group.com.acxtrilla.LiquidSky")
    let feedName = defaults?.string(forKey: "widget.feed.name") ?? "Following"
    let recentPosts = defaults?.integer(forKey: "widget.feed.recent.posts") ?? 0
    let newFollowers = defaults?.integer(forKey: "widget.feed.new.followers") ?? 0
    let unreadCount = defaults?.integer(forKey: "widget.feed.unread.count") ?? 0

    let entry = FeedUpdatesEntry(
      date: Date(),
      feedName: feedName,
      recentPosts: recentPosts,
      newFollowers: newFollowers,
      unreadCount: unreadCount
    )

    let timeline = Timeline(entries: [entry], policy: .atEnd)
    completion(timeline)
  }
}

struct FeedUpdatesEntry: TimelineEntry {
  let date: Date
  let feedName: String
  let recentPosts: Int
  let newFollowers: Int
  let unreadCount: Int
}

struct FeedUpdatesWidgetView: View {
  let entry: FeedUpdatesEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    ZStack {
      // Background
      Color(.systemBackground)

      VStack(alignment: .leading, spacing: 12) {
        // Header
        HStack {
          Image(systemName: "list.bullet.circle.fill")
            .font(.title2)
            .foregroundColor(.blue)

          Text(entry.feedName)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)

          Spacer()

          if entry.unreadCount > 0 {
            Text("\(entry.unreadCount)")
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(.white)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.red)
              .clipShape(Capsule())
          }
        }

        if family == .systemLarge {
          // Large widget shows more details
          VStack(spacing: 16) {
            // Recent posts
            HStack {
              Image(systemName: "doc.text")
                .foregroundColor(.green)
              VStack(alignment: .leading) {
                Text("\(entry.recentPosts)")
                  .font(.title2)
                  .fontWeight(.bold)
                Text("Recent Posts")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              Spacer()
            }

            // New followers
            HStack {
              Image(systemName: "person.badge.plus")
                .foregroundColor(.blue)
              VStack(alignment: .leading) {
                Text("\(entry.newFollowers)")
                  .font(.title2)
                  .fontWeight(.bold)
                Text("New Followers")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              Spacer()
            }

            // Activity chart placeholder
            HStack {
              ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                  .fill(Color.blue.opacity(Double.random(in: 0.3...1.0)))
                  .frame(height: 40)
              }
            }
            .padding(.top, 8)
          }
        } else {
          // Medium widget shows compact info
          HStack(spacing: 20) {
            VStack {
              Text("\(entry.recentPosts)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
              Text("Posts")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            VStack {
              Text("\(entry.newFollowers)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
              Text("Followers")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
          }
        }

        Spacer()

        // Footer
        HStack {
          Text("Last updated")
            .font(.caption2)
            .foregroundColor(.tertiary)

          Text(entry.date, style: .relative)
            .font(.caption2)
            .foregroundColor(.tertiary)

          Spacer()

          Image(systemName: "arrow.up.right")
            .font(.caption2)
            .foregroundColor(.blue)
        }
      }
      .padding()
    }
    .widgetURL(URL(string: "liquidsky://feed"))
  }
}

#Preview(as: .systemMedium) {
  FeedUpdatesWidget()
} timeline: {
  FeedUpdatesEntry(
    date: Date(),
    feedName: "Following",
    recentPosts: 5,
    newFollowers: 2,
    unreadCount: 8
  )
}

#Preview(as: .systemLarge) {
  FeedUpdatesWidget()
} timeline: {
  FeedUpdatesEntry(
    date: Date(),
    feedName: "Following",
    recentPosts: 5,
    newFollowers: 2,
    unreadCount: 8
  )
}

