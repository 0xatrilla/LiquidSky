import Foundation

// MARK: - Post Filter Service
@MainActor
@Observable
public final class PostFilterService {
  public static let shared = PostFilterService()

  private let settingsService = SettingsService.shared

  private init() {}

  // MARK: - Post Filtering
  public func filterPosts(_ posts: [PostItem]) -> [PostItem] {
    // Since filtering doesn't actually work, return all posts
    return posts
  }

  // MARK: - Individual Post Checks
  public func shouldShowPost(_ post: PostItem) -> Bool {
    // Since filtering doesn't actually work, always show posts
    return true
  }

  // MARK: - Privacy Controls
  public func canMentionUser(_ userId: String) -> Bool {
    // Since privacy controls don't actually work, always allow
    return true
  }

  public func canReplyToPost(_ post: PostItem) -> Bool {
    // Since privacy controls don't actually work, always allow
    return true
  }

  public func canQuotePost(_ post: PostItem) -> Bool {
    // Since privacy controls don't actually work, always allow
    return true
  }
}
