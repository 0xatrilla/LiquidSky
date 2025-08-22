@preconcurrency import ATProtoKit
import Client
import DesignSystem
import Models
import SwiftUI
import User

public struct PostsLikesView: View {
  @Environment(BSkyClient.self) var client

  let profile: Profile

  public init(profile: Profile) {
    self.profile = profile
  }

  public var body: some View {
    PostListView(datasource: self)
  }
}

// MARK: - Datasource
extension PostsLikesView: @MainActor PostsListViewDatasource {
  public var title: String {
    "Likes"
  }

  public func loadPosts(with state: PostsListViewState) async throws -> PostsListViewState {
    switch state {
    case .uninitialized, .loading, .error:
      let feed = try await client.protoClient.getActorLikes(by: profile.did)
      return .loaded(
        posts: await processFeed(feed.feed, client: client.protoClient),
        cursor: feed.cursor)
    case .loaded(let posts, let cursor):
      let feed = try await client.protoClient.getActorLikes(
        by: profile.did, limit: nil, cursor: cursor)
      let newPosts = await processFeed(feed.feed, client: client.protoClient)
      return .loaded(posts: posts + newPosts, cursor: feed.cursor)
    }
  }
}
