import ATProtoKit
import AppRouter
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct EnhancedSingleNotificationRow: View {
  let notification: AppBskyLexicon.Notification.Notification
  let postItem: PostItem?
  let actionText: String
  let router: AppRouter

  public init(
    notification: AppBskyLexicon.Notification.Notification,
    postItem: PostItem?,
    actionText: String,
    router: AppRouter
  ) {
    self.notification = notification
    self.postItem = postItem
    self.actionText = actionText
    self.router = router
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Clean avatar row
      HStack(spacing: 8) {
        // Simple avatar
        AsyncImage(url: notification.author.avatarImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(.secondary.opacity(0.2))
        }
        .frame(width: 28, height: 28)
        .clipShape(Circle())
        .onTapGesture {
          navigateToProfile()
        }

        Spacer()

        // Simple notification type indicator
        Image(systemName: notification.reason.iconName)
          .font(.caption)
          .foregroundStyle(notification.reason.color)
      }

      // Clean action text
      HStack {
        Text("\(notification.author.displayName ?? notification.author.actorHandle) \(actionText)")
          .font(.subheadline)
          .foregroundStyle(.primary)

        Spacer()

        Text(notification.indexedAt.formatted(.relative(presentation: .named)))
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      // Post content if available
      if let postItem = postItem, !postItem.content.isEmpty {
        Text(postItem.content)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .padding(.top, 4)
          .onTapGesture {
            navigateToPost()
          }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(.systemBackground))
    .contentShape(Rectangle())
    .onTapGesture {
      handleNotificationTap()
    }
  }

  private func handleNotificationTap() {
    switch notification.reason {
    case .follow:
      navigateToProfile()
    case .like, .repost, .reply, .mention, .quote:
      navigateToPost()
    default:
      navigateToPost()
    }
  }

  // MARK: - Navigation Functions

  private func navigateToProfile() {
    let profile = Profile(
      did: notification.author.actorDID,
      handle: notification.author.actorHandle,
      displayName: notification.author.displayName,
      avatarImageURL: notification.author.avatarImageURL
    )

    router[.notification].append(.profile(profile))
  }

  private func navigateToPost() {
    if let postItem = postItem {
      router[.notification].append(.post(postItem))
    }
  }
}
