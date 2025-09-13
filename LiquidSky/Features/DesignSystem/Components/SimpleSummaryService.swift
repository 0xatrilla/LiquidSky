import Foundation
import SwiftUI

@MainActor
public class SimpleSummaryService: ObservableObject {
    
    // MARK: - Properties
    @Published public var isSummarizing = false
    @Published public var summaryError: String?
    
    // MARK: - Initializer
    public init() {}
    
    // MARK: - Simple Summarization

  /// Creates a simple summary of new posts
  /// - Parameter newPostsCount: Number of new posts
  /// - Returns: A simple summary string
  public func summarizeNewPosts(_ newPostsCount: Int) async -> String? {
    guard newPostsCount >= 10 else { return nil }

    isSummarizing = true
    summaryError = nil

    defer { isSummarizing = false }

    // Simple summary based on count
    if newPostsCount >= 20 {
      return
        "You have \(newPostsCount) new posts in your feed! This includes updates from developers, tech discussions, and project updates from the community."
    } else if newPostsCount >= 15 {
      return
        "You have \(newPostsCount) new posts waiting for you, including developer updates and tech discussions."
    } else {
      return "You have \(newPostsCount) new posts in your feed with updates from your network."
    }
  }

  /// Creates a simple summary of new notifications
  /// - Parameter newNotificationsCount: Number of new notifications
  /// - Returns: A simple summary string
  public func summarizeNewNotifications(_ newNotificationsCount: Int) async -> String? {
    guard newNotificationsCount >= 10 else { return nil }

    isSummarizing = true
    summaryError = nil

    defer { isSummarizing = false }

    // Simple summary based on count
    if newNotificationsCount >= 20 {
      return
        "You have \(newNotificationsCount) new notifications! This includes replies, likes, follows, and other interactions from your network."
    } else if newNotificationsCount >= 15 {
      return
        "You have \(newNotificationsCount) new notifications waiting, including replies and social interactions."
    } else {
      return "You have \(newNotificationsCount) new notifications with updates from your network."
    }
  }
}
