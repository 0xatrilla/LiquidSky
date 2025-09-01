import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import PostUI
import SwiftUI

/// Grouped notification row following IceCubesApp's proven implementation
/// Provides seamless navigation and better user experience for grouped notifications
public struct GroupedNotificationRow: View {
  let group: NotificationsGroup

  @Namespace private var namespace
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  let actionText: (Int) -> String
  @State private var showingFollowersList = false

  public init(group: NotificationsGroup, actionText: @escaping (Int) -> String) {
    self.group = group
    self.actionText = actionText
  }

  public var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // Avatar stack with notification type indicator
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
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(2)

          Spacer()

          if let firstNotification = group.notifications.first {
            Text(firstNotification.indexedAt.formatted(.relative(presentation: .named)))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        // Post content if available
        if let postItem = group.postItem {
          // For reply notifications, show the reply content, not the original post
          if group.type == .reply {
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
      #if DEBUG
        print("🔍 Debug: GroupedNotificationRow tapped!")
      #endif
      handleNotificationTap()
    }
    .sheet(isPresented: $showingFollowersList) {
      FollowersListView(
        followers: group.notifications.map { notification in
          notification.author
        }
      )
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)
    }
  }

  private func handleNotificationTap() {
    #if DEBUG
      print("🔍 Debug: GroupedNotificationRow handleNotificationTap called for type: \(group.type)")
    #endif

    // Special handling for multiple followers (show sheet)
    if group.type == .follow && group.notifications.count > 1 {
      showingFollowersList = true
      return
    }

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
        #if DEBUG
          print("🔍 Debug: Navigating directly to profile: \(profile.handle)")
        #endif
        // Force navigation within the current tab (notifications)
        router[.notification].append(.profile(profile))
      }

    case .like, .repost:
      // Handle post-related notifications with direct navigation
      if let postItem = group.postItem {
        #if DEBUG
          print("🔍 Debug: Navigating directly to post: \(postItem.uri)")
        #endif
        // Force navigation within the current tab (notifications)
        router[.notification].append(.post(postItem))
      } else {
        // Fallback to profile of first user
        if let firstNotification = group.notifications.first {
          let profile = Profile(
            did: firstNotification.author.actorDID,
            handle: firstNotification.author.actorHandle,
            displayName: firstNotification.author.displayName,
            avatarImageURL: firstNotification.author.avatarImageURL
          )
          router.navigateTo(.profile(profile))
        }
      }

    default:
      // Handle other notification types
      if let postItem = group.postItem {
        // Navigate directly to post (no sheet)
        print("🔍 Debug: Navigating directly to post: \(postItem.uri)")
        // Force navigation within the current tab (notifications)
        router[.notification].append(.post(postItem))
      } else {
        // Fallback to profile of first user
        if let firstNotification = group.notifications.first {
          let profile = Profile(
            did: firstNotification.author.actorDID,
            handle: firstNotification.author.actorHandle,
            displayName: firstNotification.author.displayName,
            avatarImageURL: firstNotification.author.avatarImageURL
          )
          // Force navigation within the current tab (notifications)
          router[.notification].append(.profile(profile))
        }
      }
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
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } placeholder: {
          Circle()
            .fill(.gray.opacity(0.2))
            .frame(width: 36, height: 36)
        }
        .overlay {
          Circle()
            .stroke(.white, lineWidth: 2)
        }
        .shadow(color: .shadowPrimary.opacity(0.3), radius: 2)
        .onTapGesture {
          // Allow avatar taps for profile navigation
          let profile = Profile(
            did: notification.author.actorDID,
            handle: notification.author.actorHandle,
            displayName: notification.author.displayName,
            avatarImageURL: notification.author.avatarImageURL
          )
          #if DEBUG
            print("🔍 Debug: Navigating directly to profile: \(profile.handle)")
          #endif
          // Force navigation within the current tab (notifications)
          router[.notification].append(.profile(profile))
        }
      }
    }
  }
}
