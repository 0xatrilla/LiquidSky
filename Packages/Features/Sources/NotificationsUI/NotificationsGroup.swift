import ATProtoKit
import Client
import Foundation
import Models
import SwiftUI

/// Notification group following IceCubesApp's proven implementation
/// Provides smart grouping and better user experience
public struct NotificationsGroup: Identifiable {
  public let id: String
  public let timestamp: Date
  public let type: AppBskyLexicon.Notification.Notification.Reason
  public let notifications: [AppBskyLexicon.Notification.Notification]
  public let postItem: PostItem?
  public let isRead: Bool

  public static func groupNotifications(
    client: BSkyClient,
    _ notifications: [AppBskyLexicon.Notification.Notification]
  ) async -> [NotificationsGroup] {
    var groups: [NotificationsGroup] = []
    var groupedNotifications:
      [AppBskyLexicon.Notification.Notification.Reason: [String: [AppBskyLexicon.Notification
        .Notification]]] = [:]

    // Sort notifications by date (newest first)
    let sortedNotifications = notifications.sorted { $0.indexedAt > $1.indexedAt }

    // Fetch post data for post-related notifications
    let postsURIs =
      Array(
        Set(
          sortedNotifications
            .filter { $0.reason != .follow && $0.reason != .starterpackjoined }
            .compactMap { $0.reasonSubjectURI }
        ))

    var postItems: [PostItem] = []
    if !postsURIs.isEmpty {
      do {
        postItems = try await client.protoClient.getPosts(postsURIs).posts.map { $0.postItem }
      } catch {
        print("Failed to fetch post items: \(error)")
        postItems = []
      }
    }

    // Group notifications by type and subject
    for notification in sortedNotifications {
      let reason = notification.reason

      if reason.shouldGroup {
        // Group notifications by type and subject
        let key = notification.reasonSubjectURI ?? "general"
        groupedNotifications[reason, default: [:]][key, default: []].append(notification)
      } else {
        // Create individual groups for non-grouped notifications
        let postItem = postItems.first(where: { $0.uri == notification.reasonSubjectURI })

        groups.append(
          NotificationsGroup(
            id: notification.uri,
            timestamp: notification.indexedAt,
            type: reason,
            notifications: [notification],
            postItem: postItem,
            isRead: false
          ))
      }
    }

    // Add grouped notifications
    for (reason, subjectGroups) in groupedNotifications {
      for (subjectURI, notifications) in subjectGroups {
        let postItem = postItems.first(where: { $0.uri == subjectURI })

        groups.append(
          NotificationsGroup(
            id: "\(reason)-\(subjectURI)-\(notifications[0].indexedAt.timeIntervalSince1970)",
            timestamp: notifications[0].indexedAt,
            type: reason,
            notifications: notifications,
            postItem: postItem,
            isRead: false
          ))
      }
    }

    // Sort all groups by timestamp (newest first)
    return groups.sorted { $0.timestamp > $1.timestamp }
  }
}

// MARK: - Extensions

extension AppBskyLexicon.Notification.Notification.Reason: @retroactive Hashable,
  @retroactive
  Equatable
{
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.rawValue)
  }

  public static func == (
    lhs: AppBskyLexicon.Notification.Notification.Reason,
    rhs: AppBskyLexicon.Notification.Notification.Reason
  ) -> Bool {
    lhs.rawValue == rhs.rawValue
  }
}

extension AppBskyLexicon.Notification.Notification {
  fileprivate var postURI: String? {
    switch reason {
    case .follow, .starterpackjoined: return nil
    case .like, .repost, .reply, .mention, .quote: return reasonSubjectURI
    default: return nil
    }
  }
}

extension AppBskyLexicon.Notification.Notification.Reason {
  fileprivate var shouldGroup: Bool {
    switch self {
    case .like, .follow, .repost:
      return true
    case .reply, .mention, .quote, .starterpackjoined:
      return false
    default:
      return false
    }
  }

  var iconName: String {
    switch self {
    case .like: return "heart.fill"
    case .follow: return "person.fill.badge.plus"
    case .repost: return "quote.opening"
    case .mention: return "at"
    case .quote: return "quote.opening"
    case .reply: return "arrowshape.turn.up.left.fill"
    case .starterpackjoined: return "star"
    default: return "bell.fill"
    }
  }

  var color: Color {
    switch self {
    case .like: return .pink
    case .follow: return .blue
    case .repost: return .green
    case .mention: return .blue
    case .quote: return .orange
    case .reply: return .teal
    case .starterpackjoined: return .yellow
    default: return .gray
    }
  }

  var displayName: String {
    switch self {
    case .like: return "Like"
    case .follow: return "Follow"
    case .repost: return "Repost"
    case .mention: return "Mention"
    case .quote: return "Quote"
    case .reply: return "Reply"
    case .starterpackjoined: return "Starter Pack"
    default: return "Notification"
    }
  }
}
