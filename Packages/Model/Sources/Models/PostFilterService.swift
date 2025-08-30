import Foundation

// MARK: - Post Filter Service
@MainActor
@Observable
public final class PostFilterService {
  public static let shared = PostFilterService()

  private let settingsService = SettingsService.shared
  private let blockedUsersService = BlockedUsersService.shared

  private init() {}

  // MARK: - Post Filtering
  public func filterPosts(_ posts: [PostItem]) -> [PostItem] {
    return posts.filter { post in
      !blockedUsersService.shouldHidePost(from: post.author)
    }
  }

  // MARK: - Individual Post Checks
  public func shouldShowPost(_ post: PostItem) -> Bool {
    return !blockedUsersService.shouldHidePost(from: post.author)
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

  // MARK: - User Filtering

  public func filterUsers(_ users: [Profile]) -> [Profile] {
    return users.filter { user in
      !blockedUsersService.shouldHidePost(from: user)
    }
  }

  public func shouldShowUser(_ user: Profile) -> Bool {
    return !blockedUsersService.shouldHidePost(from: user)
  }

  // MARK: - Feed Filtering

  public func filterFeed(_ feed: [PostItem]) -> [PostItem] {
    return feed.filter { post in
      !blockedUsersService.shouldHidePost(from: post.author)
    }
  }

  // MARK: - Filter Management

  public func refreshFilters() {
    // This method can be called when blocked/muted users change
    // to refresh any cached filtered results
  }
}
