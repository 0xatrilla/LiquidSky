@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Models
import SwiftUI
import User

public struct PostsProfileView: View {
  @Environment(BSkyClient.self) var client

  let profile: Profile
  let filter: PostsProfileViewFilter

  public init(profile: Profile, filter: PostsProfileViewFilter) {
    self.profile = profile
    self.filter = filter
  }

  public var body: some View {
    PostListView(datasource: self)
  }
}

// MARK: - Datasource
extension PostsProfileView: @MainActor PostsListViewDatasource {
  public var title: String {
    "Posts"
  }

  public func loadPosts(with state: PostsListViewState) async throws -> PostsListViewState {
    #if DEBUG
    print("PostsProfileView: Loading posts for profile \(profile.handle) with filter \(filter)")
    print("PostsProfileView: Profile DID: \(profile.did)")
    #endif

    switch state {
    case .uninitialized, .loading, .error:
      #if DEBUG
      print("PostsProfileView: Making initial API call...")
      #endif
      let feed = try await client.protoClient.getAuthorFeed(
        by: profile.did, postFilter: filter.atProtocolFilter)
      #if DEBUG
      print("PostsProfileView: API returned \(feed.feed.count) feed items")
      #endif

      let processedPosts = await processFeed(feed.feed, client: client.protoClient)
      #if DEBUG
      print("PostsProfileView: Processed \(processedPosts.count) posts")
      #endif

      let filteredPosts =
        filter == .userReplies ? processedPosts.filter { $0.isReplyTo } : processedPosts
      #if DEBUG
      print("PostsProfileView: After filtering: \(filteredPosts.count) posts")
      #endif

      return .loaded(posts: filteredPosts, cursor: feed.cursor)
    case .loaded(let posts, let cursor):
      #if DEBUG
      print("PostsProfileView: Loading more posts with cursor...")
      #endif
      let feed = try await client.protoClient.getAuthorFeed(
        by: profile.did, limit: nil, cursor: cursor, postFilter: filter.atProtocolFilter)
      #if DEBUG
      print("PostsProfileView: Loaded \(feed.feed.count) more feed items")
      #endif

      let processedPosts = await processFeed(feed.feed, client: client.protoClient)
      let filteredPosts =
        filter == .userReplies ? processedPosts.filter { $0.isReplyTo } : processedPosts

      return .loaded(posts: posts + filteredPosts, cursor: feed.cursor)
    }
  }
}
