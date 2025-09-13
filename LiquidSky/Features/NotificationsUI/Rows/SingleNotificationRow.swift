import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import PostUI
import SwiftUI

/// Single notification row following IceCubesApp's proven implementation
/// Provides seamless navigation and better user experience
public struct SingleNotificationRow: View {
  let notification: AppBskyLexicon.Notification.Notification
  let postItem: PostItem?

  @Namespace private var namespace
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  let actionText: String

  public init(
    notification: AppBskyLexicon.Notification.Notification, postItem: PostItem?, actionText: String
  ) {
    self.notification = notification
    self.postItem = postItem
    self.actionText = actionText
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Clean avatar row
      HStack(spacing: 8) {
        // Simple avatar
        AsyncImage(url: notification.author.avatarImageURL) { image in
          image
            .resizable()
            .scaledToFit()
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
          .font(.body)
          .foregroundStyle(.primary)

        Spacer()

        Text(notification.indexedAt.formatted(.relative(presentation: .named)))
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      // Post content if available
      if let postItem = postItem, !postItem.content.isEmpty {
        Text(postItem.content)
          .font(.body)
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .padding(.top, 4)
          .onTapGesture {
            handleNotificationTap()
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
    // Add haptic feedback for better UX
    HapticManager.shared.impact(.light)

    switch notification.reason {
    case .follow:
      navigateToProfile()

    case .like, .repost, .reply, .mention, .quote:
      navigateToPost()

    case .starterpackjoined, .verified, .unverified:
      navigateToProfile()

    default:
      // Try post first, fallback to profile
      if postItem != nil {
        navigateToPost()
      } else {
        navigateToProfile()
      }
    }
  }

  private func navigateToProfile() {
    let profile = Profile(
      did: notification.author.actorDID,
      handle: notification.author.actorHandle,
      displayName: notification.author.displayName,
      avatarImageURL: notification.author.avatarImageURL
    )

    // Force navigation within the current tab (notifications)
    // This ensures the profile opens in the notifications tab, not the feed tab
    router[.notification].append(.profile(profile))
  }

  private func navigateToPost() {
    if let postItem {
      // Force navigation within the current tab (notifications)
      // This ensures the post opens in the notifications tab, not the feed tab
      router[.notification].append(.post(postItem))
    } else {
      navigateToProfile()
    }
  }
}
