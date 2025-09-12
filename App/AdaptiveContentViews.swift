import FeedUI
import Foundation
import Models
import NotificationsUI
import ProfileUI
import SettingsUI
import SwiftUI

@available(iPadOS 26.0, *)
struct AdaptiveGridView<Item: Identifiable, Content: View>: View {
  let items: [Item]
  let content: (Item) -> Content

  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @Environment(\.verticalSizeClass) var verticalSizeClass

  private var columns: [GridItem] {
    let columnCount: Int

    switch (horizontalSizeClass, verticalSizeClass) {
    case (.regular, .regular):
      columnCount = 3  // Three columns on large iPads
    case (.regular, .compact):
      columnCount = 2  // Two columns in landscape
    default:
      columnCount = 1  // Single column on compact sizes
    }

    return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 16) {
      ForEach(items) { item in
        GlassCard(cornerRadius: 12, isInteractive: true) {
          content(item)
        }
      }
    }
    .padding()
  }
}

@available(iPadOS 26.0, *)
struct EnhancedFeedGridView: View {
  @State private var feeds: [FeedItem] = []
  @State private var isLoading = false
  @State private var error: Error?

  var body: some View {
    Group {
      if isLoading && feeds.isEmpty {
        GlassLoadingView(message: "Loading feeds...")
      } else if let error = error {
        GlassErrorView(
          message: error.localizedDescription
        ) {
          Task { await loadFeeds() }
        }
      } else if feeds.isEmpty {
        GlassCard(cornerRadius: 16, isInteractive: true) {
          ContentUnavailableView(
            "No feeds available",
            systemImage: "square.stack",
            description: Text("Check back later for new content")
          )
        }
      } else {
        AdaptiveGridView(items: feeds) { feed in
          FeedCardView(feed: feed)
        }
      }
    }
    .task {
      await loadFeeds()
    }
    .refreshable {
      await loadFeeds()
    }
  }

  private func loadFeeds() async {
    isLoading = true
    error = nil

    do {
      // Simulate loading feeds
      try await Task.sleep(nanoseconds: 1_000_000_000)

      // Mock feed data
      feeds = [
        FeedItem(
          uri: "at://did:plc:example1/app.bsky.feed.generator/feed1",
          displayName: "Discover",
          description: "Popular posts from across the network",
          avatarImageURL: nil,
          creatorHandle: "bsky.app",
          likesCount: 1250,
          liked: false
        ),
        FeedItem(
          uri: "at://did:plc:example2/app.bsky.feed.generator/feed2",
          displayName: "Following",
          description: "Posts from people you follow",
          avatarImageURL: nil,
          creatorHandle: "bsky.app",
          likesCount: 890,
          liked: true
        ),
      ]
    } catch {
      self.error = error
    }

    isLoading = false
  }
}

@available(iPadOS 26.0, *)
struct FeedCardView: View {
  let feed: FeedItem
  @State private var isHovered = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Feed header
      HStack {
        AsyncImage(url: feed.avatarImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(.blue.gradient)
            .overlay {
              Image(systemName: "square.stack")
                .foregroundStyle(.white)
                .font(.title3)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())

        VStack(alignment: .leading, spacing: 2) {
          Text(feed.displayName)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)

          Text("by @\(feed.creatorHandle)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }

      // Feed description
      if let description = feed.description {
        Text(description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(3)
      }

      // Feed stats
      HStack {
        HStack(spacing: 4) {
          Image(systemName: feed.liked ? "heart.fill" : "heart")
            .foregroundStyle(feed.liked ? .red : .secondary)
          Text("\(feed.likesCount)")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }

        Spacer()

        GlassButton("View", systemImage: "arrow.right", style: .interactive) {
          // Handle feed selection
        }
      }
    }
    .padding()
    .scaleEffect(isHovered ? 1.02 : 1.0)
    .animation(.smooth(duration: 0.2), value: isHovered)
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

@available(iPadOS 26.0, *)
struct EnhancedNotificationGridView: View {
  @State private var notifications: [NotificationGroup] = []
  @State private var isLoading = false
  @State private var error: Error?

  var body: some View {
    Group {
      if isLoading && notifications.isEmpty {
        GlassLoadingView(message: "Loading notifications...")
      } else if let error = error {
        GlassErrorView(
          message: error.localizedDescription
        ) {
          Task { await loadNotifications() }
        }
      } else if notifications.isEmpty {
        GlassCard(cornerRadius: 16, isInteractive: true) {
          ContentUnavailableView(
            "All caught up!",
            systemImage: "checkmark.circle",
            description: Text("You're up to date with all notifications")
          )
        }
      } else {
        LazyVStack(spacing: 12) {
          ForEach(notifications) { notification in
            NotificationCardView(notification: notification)
          }
        }
        .padding()
      }
    }
    .task {
      await loadNotifications()
    }
    .refreshable {
      await loadNotifications()
    }
  }

  private func loadNotifications() async {
    isLoading = true
    error = nil

    do {
      // Simulate loading notifications
      try await Task.sleep(nanoseconds: 1_000_000_000)

      // Mock notification data would go here
      notifications = []
    } catch {
      self.error = error
    }

    isLoading = false
  }
}

@available(iPadOS 26.0, *)
struct NotificationCardView: View {
  let notification: NotificationGroup
  @State private var isHovered = false

  var body: some View {
    GlassCard(cornerRadius: 12, isInteractive: true) {
      HStack(spacing: 12) {
        // Notification icon
        Image(systemName: notificationIcon)
          .font(.title2)
          .foregroundStyle(notificationColor)
          .frame(width: 32, height: 32)

        VStack(alignment: .leading, spacing: 4) {
          Text(notificationTitle)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)

          Text(notificationSubtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        Spacer()

        Text(timeAgo)
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      .padding(.vertical, 8)
    }
    .scaleEffect(isHovered ? 1.01 : 1.0)
    .animation(.smooth(duration: 0.2), value: isHovered)
    .onHover { hovering in
      isHovered = hovering
    }
  }

  private var notificationIcon: String {
    switch notification.type {
    case .like: return "heart.fill"
    case .repost: return "arrow.2.squarepath"
    case .follow: return "person.badge.plus"
    case .reply: return "bubble.left"
    case .mention: return "at"
    default: return "bell"
    }
  }

  private var notificationColor: Color {
    switch notification.type {
    case .like: return .red
    case .repost: return .green
    case .follow: return .blue
    case .reply: return .orange
    case .mention: return .purple
    default: return .secondary
    }
  }

  private var notificationTitle: String {
    let count = notification.notifications.count
    let firstName = notification.notifications.first?.author.displayName ?? "Someone"

    switch notification.type {
    case .like:
      return count == 1
        ? "\(firstName) liked your post" : "\(firstName) and \(count - 1) others liked your post"
    case .repost:
      return count == 1
        ? "\(firstName) reposted your post"
        : "\(firstName) and \(count - 1) others reposted your post"
    case .follow:
      return count == 1
        ? "\(firstName) followed you" : "\(firstName) and \(count - 1) others followed you"
    case .reply:
      return "\(firstName) replied to your post"
    case .mention:
      return "\(firstName) mentioned you"
    default:
      return "New notification"
    }
  }

  private var notificationSubtitle: String {
    return notification.postItem?.content ?? "Tap to view details"
  }

  private var timeAgo: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: notification.timestamp, relativeTo: Date())
  }
}

// Mock notification group for compilation
struct NotificationGroup: Identifiable {
  let id = UUID()
  let type: NotificationType
  let notifications: [MockNotification]
  let timestamp: Date
  let postItem: MockPostItem?

  enum NotificationType {
    case like, repost, follow, reply, mention
  }
}

struct MockNotification {
  let author: MockAuthor
}

struct MockAuthor {
  let displayName: String
}

struct MockPostItem {
  let content: String
}
