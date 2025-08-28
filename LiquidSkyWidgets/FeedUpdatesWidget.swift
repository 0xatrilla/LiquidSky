import SwiftUI
import WidgetKit

struct FeedUpdatesWidget: Widget {
  let kind: String = "FeedUpdatesWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FeedUpdatesTimelineProvider()) { entry in
      FeedUpdatesWidgetView(entry: entry)
    }
    .configurationDisplayName("Feed Activity")
    .description("Monitor activity from your favorite feeds")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

struct FeedUpdatesTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> FeedUpdatesEntry {
    FeedUpdatesEntry(
      date: Date(),
      feedName: "Following",
      recentPosts: 5,
      newFollowers: 2,
      totalActivity: 12
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (FeedUpdatesEntry) -> Void) {
    let entry = FeedUpdatesEntry(
      date: Date(),
      feedName: "Following",
      recentPosts: 5,
      newFollowers: 2,
      totalActivity: 12
    )
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<FeedUpdatesEntry>) -> Void)
  {
    let defaults = UserDefaults(suiteName: "group.com.acxtrilla.Horizon")
    let feedName = defaults?.string(forKey: "widget.feed.name") ?? "Following"
    let recentPosts = defaults?.integer(forKey: "widget.feed.recent.posts") ?? 0
    let newFollowers = defaults?.integer(forKey: "widget.feed.new.followers") ?? 0
    let totalActivity = defaults?.integer(forKey: "widget.feed.total.activity") ?? 0

    let entry = FeedUpdatesEntry(
      date: Date(),
      feedName: feedName,
      recentPosts: recentPosts,
      newFollowers: newFollowers,
      totalActivity: totalActivity
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
  let totalActivity: Int
}

struct FeedUpdatesWidgetView: View {
  let entry: FeedUpdatesEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header
      HStack {
        Image(systemName: "chart.line.uptrend.xyaxis")
          .font(.title2)
          .foregroundColor(.blue)

        Text(entry.feedName)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        Spacer()

        Text(entry.date, style: .time)
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      Spacer()

      // Activity stats
      if family == .systemLarge {
        VStack(spacing: 12) {
          ActivityRow(
            icon: "doc.text",
            label: "Recent Posts",
            value: entry.recentPosts,
            color: .primary
          )

          ActivityRow(
            icon: "person.badge.plus",
            label: "New Followers",
            value: entry.newFollowers,
            color: .primary
          )

          ActivityRow(
            icon: "chart.bar",
            label: "Total Activity",
            value: entry.totalActivity,
            color: .primary
          )
        }
      } else {
        // Compact view for small/medium
        HStack(spacing: 16) {
          VStack {
            Text("\(entry.recentPosts)")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.primary)
            Text("Posts")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          VStack {
            Text("\(entry.newFollowers)")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.primary)
            Text("Followers")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          if family == .systemMedium {
            VStack {
              Text("\(entry.totalActivity)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
              Text("Activity")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }
      }

      Spacer()

      // Action hint
      HStack {
        Text("Tap to view feed")
          .font(.caption2)
          .foregroundColor(.blue)
        Spacer()
        Image(systemName: "arrow.right")
          .font(.caption2)
          .foregroundColor(.blue)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(.systemBackground))
    .widgetURL(URL(string: "horizon://feed/\(entry.feedName)"))
  }
}

struct ActivityRow: View {
  let icon: String
  let label: String
  let value: Int
  let color: Color

  var body: some View {
    HStack {
      Image(systemName: icon)
        .font(.caption)
        .foregroundColor(color)
        .frame(width: 16)

      Text(label)
        .font(.caption)
        .foregroundColor(color.opacity(0.8))

      Spacer()

      Text("\(value)")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(color)
    }
  }
}

#Preview(as: .systemSmall) {
  FeedUpdatesWidget()
} timeline: {
  FeedUpdatesEntry(
    date: .now,
    feedName: "Following",
    recentPosts: 5,
    newFollowers: 2,
    totalActivity: 12
  )
}

#Preview(as: .systemMedium) {
  FeedUpdatesWidget()
} timeline: {
  FeedUpdatesEntry(
    date: .now,
    feedName: "Following",
    recentPosts: 5,
    newFollowers: 2,
    totalActivity: 12
  )
}

#Preview(as: .systemLarge) {
  FeedUpdatesWidget()
} timeline: {
  FeedUpdatesEntry(
    date: .now,
    feedName: "Following",
    recentPosts: 5,
    newFollowers: 2,
    totalActivity: 12
  )
}
