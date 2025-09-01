import ATProtoKit
import AppRouter
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct EnhancedGroupedNotificationRow: View {
  let group: NotificationsGroup
  let actionTextBuilder: (Int) -> String
  let router: AppRouter

  @State private var showingFollowersList = false

  public init(
    group: NotificationsGroup,
    actionTextBuilder: @escaping (Int) -> String,
    router: AppRouter
  ) {
    self.group = group
    self.actionTextBuilder = actionTextBuilder
    self.router = router
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Clean avatar row
      HStack(spacing: 8) {
        // Simple avatar stack
        HStack(spacing: 2) {
          ForEach(Array(group.notifications.prefix(3).enumerated()), id: \.offset) {
            index, notification in
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
              navigateToProfile(notification.author.actorHandle)
            }
          }
        }

        // Count badge if more than 3
        if group.notifications.count > 3 {
          Text("+\(group.notifications.count - 3)")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              Capsule()
                .fill(.secondary.opacity(0.1))
            )
        }

        Spacer()

        // Simple notification type indicator
        Image(systemName: group.type.iconName)
          .font(.caption)
          .foregroundStyle(group.type.color)
      }

      // Clean action text
      HStack {
        Text(actionTextBuilder(group.notifications.count))
          .font(.subheadline)
          .foregroundStyle(.primary)

        Spacer()

        if let firstNotification = group.notifications.first {
          Text(firstNotification.indexedAt.formatted(.relative(presentation: .named)))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      // Post content if available
      if let postItem = group.postItem, !postItem.content.isEmpty {
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
    switch group.type {
    case .follow:
      // Show followers list for multiple followers
      if group.notifications.count > 1 {
        showingFollowersList = true
      } else {
        // Navigate to single user's profile
        if let firstNotification = group.notifications.first {
          navigateToProfile(firstNotification.author.actorHandle)
        }
      }
    case .like, .repost:
      // Navigate to post
      navigateToPost()
    default:
      // Default to post navigation
      navigateToPost()
    }
  }

  // MARK: - Navigation Functions

  private func navigateToProfile(_ handle: String) {
    // Find the notification for this specific user
    guard let notification = group.notifications.first(where: { $0.author.actorHandle == handle })
    else {
      return
    }

    let profile = Profile(
      did: notification.author.actorDID,
      handle: notification.author.actorHandle,
      displayName: notification.author.displayName,
      avatarImageURL: notification.author.avatarImageURL
    )

    router[.notification].append(.profile(profile))
  }

  private func navigateToPost() {
    if let postItem = group.postItem {
      router[.notification].append(.post(postItem))
    }
  }
}
