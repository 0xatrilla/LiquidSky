import SwiftUI
import WidgetKit

enum LiquidSkyWidgetConstants {
  static let appGroupId = "group.com.acxtrilla.LiquidSky"
  static let followersKey = "widget.followers.count"
  static let recentNotificationTitleKey = "widget.recent.notification.title"
  static let recentNotificationSubtitleKey = "widget.recent.notification.subtitle"
}

struct FollowerCountEntry: TimelineEntry {
  let date: Date
  let count: Int
}

struct FollowerCountProvider: TimelineProvider {
  func placeholder(in context: Context) -> FollowerCountEntry {
    FollowerCountEntry(date: .now, count: 1234)
  }

  func getSnapshot(in context: Context, completion: @escaping (FollowerCountEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<FollowerCountEntry>) -> Void
  ) {
    let entry = loadEntry()
    // Refresh every 30 minutes
    let next =
      Calendar.current.date(byAdding: .minute, value: 30, to: Date())
      ?? Date().addingTimeInterval(1800)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func loadEntry() -> FollowerCountEntry {
    let defaults = UserDefaults(suiteName: LiquidSkyWidgetConstants.appGroupId)
    let count = defaults?.integer(forKey: LiquidSkyWidgetConstants.followersKey) ?? 0
    return FollowerCountEntry(date: .now, count: count)
  }
}

struct FollowerCountWidgetView: View {
  var entry: FollowerCountProvider.Entry

  var body: some View {
    ZStack {
      Color(.systemBackground)
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
          Image(systemName: "person.2.fill")
            .foregroundStyle(.tint)
          Text("Followers")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Text("\(entry.count.formatted())")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(.primary)
        Spacer()
      }
      .padding()
    }
  }
}

struct FollowerCountWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "FollowerCountWidget", provider: FollowerCountProvider()) { entry in
      FollowerCountWidgetView(entry: entry)
    }
    .configurationDisplayName("Followers")
    .description("Shows your current follower count.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
