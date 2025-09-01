import ATProtoKit
import AppRouter
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct EnhancedNotificationRow: View {
  let group: NotificationsGroup
  let router: AppRouter

  public init(group: NotificationsGroup, router: AppRouter) {
    self.group = group
    self.router = router
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      switch group.type {
      case .reply:
        EnhancedSingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "replied to your post",
          router: router
        )
      case .follow:
        EnhancedGroupedNotificationRow(
          group: group,
          actionTextBuilder: { count in
            let firstUser =
              group.notifications.first?.author.displayName ?? group.notifications.first?.author
              .actorHandle ?? "Someone"
            return count == 1
              ? "\(firstUser) followed you" : "\(firstUser) and \(count - 1) others followed you"
          },
          router: router
        )
      case .like:
        EnhancedGroupedNotificationRow(
          group: group,
          actionTextBuilder: { count in
            let firstUser =
              group.notifications.first?.author.displayName ?? group.notifications.first?.author
              .actorHandle ?? "Someone"
            return count == 1
              ? "\(firstUser) liked your post"
              : "\(firstUser) and \(count - 1) others liked your post"
          },
          router: router
        )
      case .repost:
        EnhancedGroupedNotificationRow(
          group: group,
          actionTextBuilder: { count in
            let firstUser =
              group.notifications.first?.author.displayName ?? group.notifications.first?.author
              .actorHandle ?? "Someone"
            return count == 1
              ? "\(firstUser) reposted your post"
              : "\(firstUser) and \(count - 1) others reposted your post"
          },
          router: router
        )
      case .mention:
        EnhancedSingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "mentioned you in a post",
          router: router
        )
      case .quote:
        EnhancedSingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "quoted your post",
          router: router
        )
      case .likeViaRepost:
        EnhancedGroupedNotificationRow(
          group: group,
          actionTextBuilder: { count in
            let firstUser =
              group.notifications.first?.author.displayName ?? group.notifications.first?.author
              .actorHandle ?? "Someone"
            return count == 1
              ? "\(firstUser) liked a repost of your post"
              : "\(firstUser) and \(count - 1) others liked a repost of your post"
          },
          router: router
        )
      case .repostViaRepost:
        EnhancedGroupedNotificationRow(
          group: group,
          actionTextBuilder: { count in
            let firstUser =
              group.notifications.first?.author.displayName ?? group.notifications.first?.author
              .actorHandle ?? "Someone"
            return count == 1
              ? "\(firstUser) reposted a repost of your post"
              : "\(firstUser) and \(count - 1) others reposted a repost of your post"
          },
          router: router
        )
      case .starterpackjoined:
        EnhancedSingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "joined the starter pack",
          router: router
        )
      case .verified:
        EnhancedSingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "verified their account",
          router: router
        )
      case .unverified:
        EnhancedSingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "unverified their account",
          router: router
        )
      case .subscribedPost:
        EnhancedSingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "subscribed to your post",
          router: router
        )
      case .unknown:
        EnhancedSingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "interacted with your post",
          router: router
        )
      }
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    // This would need actual NotificationsGroup data to preview properly
    Text("Enhanced Notification Row Preview")
      .font(.headline)
      .padding()
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
