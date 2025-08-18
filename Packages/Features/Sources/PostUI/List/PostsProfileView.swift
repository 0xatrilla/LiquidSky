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
  var title: String {
    "Posts"
  }

  func loadPosts(with state: PostsListViewState) async -> PostsListViewState {
    do {
      print("PostsProfileView: Loading posts for profile \(profile.handle) with filter \(filter)")
      print("PostsProfileView: Profile DID: \(profile.did)")

      switch state {
      case .uninitialized, .loading, .error:
        print("PostsProfileView: Making initial API call...")
        let feed = try await client.protoClient.getAuthorFeed(
          by: profile.did, postFilter: filter.atProtocolFilter)
        print("PostsProfileView: API returned \(feed.feed.count) feed items")

        let processedPosts = PostListView.processFeed(feed.feed)
        print("PostsProfileView: Processed \(processedPosts.count) posts")

        let filteredPosts =
          filter == .userReplies ? processedPosts.filter { $0.isReplyTo } : processedPosts
        print("PostsProfileView: After filtering: \(filteredPosts.count) posts")

        return .loaded(posts: filteredPosts, cursor: feed.cursor)
      case .loaded(let posts, let cursor):
        print("PostsProfileView: Loading more posts with cursor...")
        let feed = try await client.protoClient.getAuthorFeed(
          by: profile.did, limit: nil, cursor: cursor, postFilter: filter.atProtocolFilter)
        print("PostsProfileView: Loaded \(feed.feed.count) more feed items")

        let processedPosts = PostListView.processFeed(feed.feed)
        let filteredPosts =
          filter == .userReplies ? processedPosts.filter { $0.isReplyTo } : processedPosts

        return .loaded(posts: posts + filteredPosts, cursor: feed.cursor)
      }
    } catch {
      print("PostsProfileView: Error loading posts: \(error)")
      return .error(error)
    }
  }
}
