import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import PostUI
import SwiftUI

public struct SingleNotificationRow: View {
  let notification: AppBskyLexicon.Notification.Notification
  let postItem: PostItem?

  @Namespace private var namespace
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @Environment(PostContextProvider.self) var postDataControllerProvider
  let actionText: String

  public init(
    notification: AppBskyLexicon.Notification.Notification, postItem: PostItem?, actionText: String
  ) {
    self.notification = notification
    self.postItem = postItem
    self.actionText = actionText
  }

  public var body: some View {
    HStack(alignment: .top, spacing: 8) {
      // Avatar
      AsyncImage(url: notification.author.avatarImageURL) { image in
        image
          .resizable()
          .scaledToFit()
          .frame(width: 40, height: 40)
          .clipShape(Circle())
      } placeholder: {
        Circle()
          .fill(.gray.opacity(0.2))
          .frame(width: 40, height: 40)
      }
      .overlay {
        Circle()
          .stroke(LinearGradient.avatarBorder, lineWidth: 1)
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

      // Content
      VStack(alignment: .leading, spacing: 8) {
        // Header with name, action, and timestamp
        HStack(alignment: .firstTextBaseline) {
          Text(notification.author.displayName ?? notification.author.actorHandle)
            .font(.callout)
            .foregroundStyle(.primary)
            .fontWeight(.semibold)
            + Text("  \(actionText)")
            .font(.footnote)
            .foregroundStyle(.tertiary)

          Spacer()

          Text(notification.indexedAt.formatted(.relative(presentation: .named)))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .lineLimit(1)

        // Post content if available
        if let postItem {
          PostRowBodyView(post: postItem)
          PostRowEmbedView(post: postItem)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
    .onTapGesture {
      if let postItem {
        router.navigateTo(.post(postItem))
      }
    }
  }
}
