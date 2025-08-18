import ATProtoKit
import AppRouter
import DesignSystem
import Destinations
import Models
import PostUI
import SwiftUI

public struct GroupedNotificationRow: View {
  let group: NotificationsGroup

  @Namespace private var namespace
  @Environment(AppRouter.self) var router
  let actionText: (Int) -> String  // Closure to generate action text based on count

  public init(group: NotificationsGroup, actionText: @escaping (Int) -> String) {
    self.group = group
    self.actionText = actionText
  }

  public var body: some View {
    HStack(alignment: .top, spacing: 8) {
      // Avatar stack
      ZStack(alignment: .bottomTrailing) {
        avatarsView

        // Notification type icon
        NotificationIconView(
          icon: group.type.iconName,
          color: group.type.color
        )
        .background(
          Circle()
            .fill(.white)
            .shadow(color: .shadowPrimary.opacity(0.3), radius: 2)
        )
      }

      // Content
      VStack(alignment: .leading, spacing: 8) {
        // Action text and timestamp
        HStack(alignment: .firstTextBaseline) {
          Text(actionText(group.notifications.count))
            .font(.callout)
            .foregroundStyle(.primary)

          Spacer()

          if let firstNotification = group.notifications.first {
            Text(firstNotification.indexedAt.formatted(.relative(presentation: .named)))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .lineLimit(1)

        // Post content if available
        if let post = group.postItem {
          PostRowBodyView(post: post)
          PostRowEmbedView(post: post)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
    .onTapGesture {
      handleNotificationTap()
    }
  }

  private func handleNotificationTap() {
    switch group.type {
    case .follow:
      // Handle follower notifications
      if group.notifications.count == 1 {
        // Single follower - navigate directly to their profile
        let notification = group.notifications[0]
        let profile = Profile(
          did: notification.author.actorDID,
          handle: notification.author.actorHandle,
          displayName: notification.author.displayName,
          avatarImageURL: notification.author.avatarImageURL
        )
        router.navigateTo(.profile(profile))
      } else {
        // Multiple followers - navigate to the first follower's profile for now
        // TODO: Implement proper followers list view in the future
        let notification = group.notifications[0]
        let profile = Profile(
          did: notification.author.actorDID,
          handle: notification.author.actorHandle,
          displayName: notification.author.displayName,
          avatarImageURL: notification.author.avatarImageURL
        )
        router.navigateTo(.profile(profile))
      }
    case .like, .repost, .reply, .mention, .quote:
      // Handle post-related notifications
      if let post = group.postItem {
        router.navigateTo(.post(post))
      }
    default:
      // Handle other notification types
      break
    }
  }

  @ViewBuilder
  private var avatarsView: some View {
    let maxAvatars = 3
    let avatarCount = min(group.notifications.count, maxAvatars)

    HStack(spacing: -8) {
      ForEach(Array(group.notifications.prefix(avatarCount).enumerated()), id: \.offset) {
        index, notification in
        AsyncImage(url: notification.author.avatarImageURL) { image in
          image
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .clipShape(Circle())
        } placeholder: {
          Circle()
            .fill(.gray.opacity(0.2))
            .frame(width: 32, height: 32)
        }
        .overlay {
          Circle()
            .stroke(.white, lineWidth: 2)
        }
        .shadow(color: .shadowPrimary.opacity(0.3), radius: 2)
        .onTapGesture {
          let profile = Profile(
            did: notification.author.actorDID,
            handle: notification.author.actorHandle,
            displayName: notification.author.displayName,
            avatarImageURL: notification.author.avatarImageURL
          )
          router.navigateTo(.profile(profile))
        }
      }
    }
  }
}
