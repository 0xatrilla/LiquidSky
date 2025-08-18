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
  var title: String {
    "Likes"
  }

  func loadPosts(with state: PostsListViewState) async -> PostsListViewState {
    do {
      switch state {
      case .uninitialized, .loading, .error:
        let feed = try await client.protoClient.getActorLikes(by: profile.did)
        return .loaded(
          posts: await PostListView.processFeed(feed.feed, client: client.protoClient),
          cursor: feed.cursor)
      case .loaded(let posts, let cursor):
        let feed = try await client.protoClient.getActorLikes(
          by: profile.did, limit: nil, cursor: cursor)
        let newPosts = await PostListView.processFeed(feed.feed, client: client.protoClient)
        return .loaded(posts: posts + newPosts, cursor: feed.cursor)
      }
    } catch {
      return .error(error)
    }
  }
}
