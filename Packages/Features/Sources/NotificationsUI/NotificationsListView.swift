import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Models
import PostUI
import SwiftUI

/// Notifications list view following IceCubesApp's proven implementation
/// Provides seamless notification handling and better user experience
public struct NotificationsListView: View {
  @Environment(BSkyClient.self) private var client

  @State private var notificationsGroups: [NotificationsGroup] = []
  @State private var cursor: String?
  @State private var isLoading = false
  @State private var error: Error?

  public init() {}

  public var body: some View {
    ZStack {
      // Background
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      if notificationsGroups.isEmpty && !isLoading {
        // Empty state
        VStack(spacing: 20) {
          Image(systemName: "bell.slash")
            .font(.system(size: 48))
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

          Text("No notifications yet")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)

          Text("When you get notifications, they'll appear here")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
      } else if let error = error {
        // Error state
        VStack(spacing: 20) {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 48))
            .foregroundStyle(.red)
            .padding(.bottom, 8)

          Text("Failed to load notifications")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)

          Text(error.localizedDescription)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

          Button("Try Again") {
            Task {
              await fetchNotifications()
            }
          }
          .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
      } else {
        // Notifications list
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(notificationsGroups) { group in
              NotificationRow(group: group)
                .id(group.id)
            }

            // Load more indicator
            if cursor != nil && !isLoading {
              HStack {
                Spacer()
                ProgressView()
                  .scaleEffect(0.8)
                  .padding(.vertical, 16)
                Spacer()
              }
              .padding(.vertical, 20)
              .task {
                await fetchNotifications()
              }
            }
          }
        }
      }
    }
    .navigationTitle("Notifications")
    .navigationBarTitleDisplayMode(.large)
    .task {
      await fetchNotifications()
    }
    .refreshable {
      cursor = nil
      await fetchNotifications()
    }
  }

  private func fetchNotifications() async {
    guard !isLoading else { return }

    isLoading = true
    error = nil

    do {
      if let cursor {
        let response = try await client.protoClient.listNotifications(
          isPriority: false, cursor: cursor)
        self.notificationsGroups.append(
          contentsOf: await NotificationsGroup.groupNotifications(
            client: client, response.notifications)
        )
        self.cursor = response.cursor
      } else {
        let response = try await client.protoClient.listNotifications(isPriority: false)
        self.notificationsGroups = await NotificationsGroup.groupNotifications(
          client: client, response.notifications)
        self.cursor = response.cursor
      }
    } catch {
      print("Failed to fetch notifications: \(error)")
      self.error = error
    }

    isLoading = false
  }
}

// MARK: - Notification Row

struct NotificationRow: View {
  let group: NotificationsGroup

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      switch group.type {
      case .reply:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "replied to your post"
        )
      case .follow:
        GroupedNotificationRow(group: group) { count in
          count == 1 ? " followed you" : " and \(count - 1) others followed you"
        }
      case .like:
        GroupedNotificationRow(group: group) { count in
          count == 1 ? " liked your post" : " and \(count - 1) others liked your post"
        }
      case .repost:
        GroupedNotificationRow(group: group) { count in
          count == 1 ? " reposted your post" : " and \(count - 1) others reposted your post"
        }
      case .mention:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "mentioned you"
        )
      case .quote:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "quoted your post"
        )
      case .likeViaRepost:
        GroupedNotificationRow(group: group) { count in
          count == 1
            ? " liked your post via repost" : " and \(count - 1) others liked your post via repost"
        }
      case .repostViaRepost:
        GroupedNotificationRow(group: group) { count in
          count == 1
            ? " reposted your post via repost"
            : " and \(count - 1) others reposted your post via repost"
        }
      case .starterpackjoined:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "joined the starter pack"
        )
      case .verified:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "verified their account"
        )
      case .unverified:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "unverified their account"
        )
      case .unknown:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "interacted with your post"
        )
      }
    }
  }
}
