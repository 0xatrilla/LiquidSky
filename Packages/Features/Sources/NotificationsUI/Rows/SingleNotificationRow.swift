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
    HStack(alignment: .top, spacing: 12) {
      // Avatar with notification type indicator
      ZStack(alignment: .bottomTrailing) {
        AsyncImage(url: notification.author.avatarImageURL) { image in
          image
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44)
            .clipShape(Circle())
        } placeholder: {
          Circle()
            .fill(.gray.opacity(0.2))
            .frame(width: 44, height: 44)
        }
        .overlay {
          Circle()
            .stroke(LinearGradient.avatarBorder, lineWidth: 1)
        }
        .shadow(color: .shadowPrimary.opacity(0.3), radius: 2)

        // Notification type icon
        NotificationIconView(
          icon: notification.reason.iconName,
          color: notification.reason.color
        )
        .background(
          Circle()
            .fill(.white)
            .shadow(color: .shadowPrimary.opacity(0.3), radius: 2)
        )
      }
      .onTapGesture {
        // Allow avatar taps for profile navigation
        navigateToProfile()
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
          // For reply notifications, show the reply content, not the original post
          if notification.reason == .reply {
            // Show the reply content (the actual reply, not what was replied to)
            if !postItem.content.isEmpty {
              Text(postItem.content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            }
          } else {
            // For other notification types, show the post content as before
            PostRowBodyView(post: postItem)
              .lineLimit(3)
            PostRowEmbedView(post: postItem)
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(.systemBackground))
    .contentShape(Rectangle())
    .onTapGesture {
      print("🔍 Debug: SingleNotificationRow tapped!")
      handleNotificationTap()
    }
  }

  private func handleNotificationTap() {
    print(
      "🔍 Debug: SingleNotificationRow handleNotificationTap called for reason: \(notification.reason)"
    )

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

    // Direct navigation should now work with unified navigation stack
    print("🔍 Debug: Navigating directly to profile: \(profile.handle)")
    router.navigateTo(.profile(profile))
  }

  private func navigateToPost() {
    if let postItem {
      print("🔍 Debug: Navigating directly to post: \(postItem.uri)")

      // Direct navigation should now work with unified navigation stack
      router.navigateTo(.post(postItem))
    } else {
      print("🔍 Debug: No postItem found, falling back to profile")
      navigateToProfile()
    }
  }
}
