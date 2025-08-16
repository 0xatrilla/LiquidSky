import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Models
import PostUI
import SwiftUI

public struct NotificationsListView: View {
  @Environment(BSkyClient.self) private var client

  @State private var notificationsGroups: [NotificationsGroup] = []
  @State private var cursor: String?

  public init() {}

  public var body: some View {
    NavigationView {
      List {
        // Header section
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("Notifications")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundStyle(.primary)

            Text("Stay updated with your latest activity")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 8)
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
        }

        // Notifications content
        Section {
          if notificationsGroups.isEmpty {
            // Empty state - IceCubesApp style
            VStack(spacing: 16) {
              Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

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
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
          } else {
            // Notifications list - IceCubesApp style
            ForEach(notificationsGroups, id: \.id) { group in
              NotificationRow(group: group)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // Load more indicator - IceCubesApp style
            if cursor != nil {
              HStack {
                Spacer()
                ProgressView()
                  .scaleEffect(0.8)
                Spacer()
              }
              .padding(.vertical, 20)
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)
              .task {
                await fetchNotifications()
              }
            }
          }
        }
      }
      .listStyle(.plain)
      .background(Color(uiColor: .systemGroupedBackground))
      .navigationBarHidden(true)
      .task {
        cursor = nil
        await fetchNotifications()
      }
      .refreshable {
        cursor = nil
        await fetchNotifications()
      }
    }
  }

  private func fetchNotifications() async {
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
      print(error)
    }
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
