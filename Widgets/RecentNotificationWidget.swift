import SwiftUI
import WidgetKit

struct RecentNotificationEntry: TimelineEntry {
  let date: Date
  let title: String
  let subtitle: String
}

struct RecentNotificationProvider: TimelineProvider {
  func placeholder(in context: Context) -> RecentNotificationEntry {
    RecentNotificationEntry(date: .now, title: "New like", subtitle: "@someone liked your post")
  }

  func getSnapshot(in context: Context, completion: @escaping (RecentNotificationEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(
    in context: Context, completion: @escaping (Timeline<RecentNotificationEntry>) -> Void
  ) {
    let entry = loadEntry()
    // Refresh every 15 minutes
    let next =
      Calendar.current.date(byAdding: .minute, value: 15, to: Date())
      ?? Date().addingTimeInterval(900)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func loadEntry() -> RecentNotificationEntry {
    let defaults = UserDefaults(suiteName: LiquidSkyWidgetConstants.appGroupId)
    let title =
      defaults?.string(forKey: LiquidSkyWidgetConstants.recentNotificationTitleKey)
      ?? "No recent notifications"
    let subtitle =
      defaults?.string(forKey: LiquidSkyWidgetConstants.recentNotificationSubtitleKey) ?? ""
    return RecentNotificationEntry(date: .now, title: title, subtitle: subtitle)
  }
}

struct RecentNotificationWidgetView: View {
  var entry: RecentNotificationProvider.Entry

  var body: some View {
    ZStack {
      Color(.systemBackground)
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
          Image(systemName: "bell.fill")
            .foregroundStyle(.tint)
          Text("Latest Notification")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Text(entry.title)
          .font(.headline)
          .lineLimit(1)
          .foregroundStyle(.primary)
        if !entry.subtitle.isEmpty {
          Text(entry.subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        Spacer()
      }
      .padding()
    }
  }
}

struct RecentNotificationWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "RecentNotificationWidget", provider: RecentNotificationProvider()) {
      entry in
      RecentNotificationWidgetView(entry: entry)
    }
    .configurationDisplayName("Recent Notification")
    .description("Shows your most recent Bluesky notification.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
