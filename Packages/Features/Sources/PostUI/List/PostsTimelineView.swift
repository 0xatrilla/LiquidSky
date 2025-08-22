@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI
import User

public struct PostsTimelineView: View {
  @Environment(BSkyClient.self) var client
  @Environment(AppRouter.self) var router

  public init() {}

  public var body: some View {
    PostListView(datasource: self)
      .navigationTitle("Following")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: {
            router.presentedSheet = .composer(mode: .newPost)
          }) {
            Image(systemName: "square.and.pencil")
              .font(.title2)
              .foregroundColor(.themePrimary)
          }
        }
      }
  }
}

// MARK: - Datasource
extension PostsTimelineView: @MainActor PostsListViewDatasource {
  public var title: String {
    "Following"
  }

  public func loadPosts(with state: PostsListViewState) async throws -> PostsListViewState {
    switch state {
    case .uninitialized, .loading, .error:
      let feed = try await client.protoClient.getTimeline()

      // Debug logging to identify the issue
      #if DEBUG
      print("Timeline feed received: \(feed.feed.count) posts")
      if let firstPost = feed.feed.first {
        print("First post structure: \(firstPost)")
        print("First post URI: \(firstPost.post.postItem.uri)")
        print("First post author: \(firstPost.post.author.actorHandle)")
      }
      #endif

      // Validate feed data before processing
      guard !feed.feed.isEmpty else {
        #if DEBUG
        print("Timeline feed is empty")
        #endif
        throw NSError(
          domain: "TimelineError", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "No posts found in timeline"])
      }

      // Try to process the feed with enhanced error handling
      let posts = await processFeed(feed.feed, client: client.protoClient)
      #if DEBUG
      print("Successfully processed \(posts.count) posts from timeline")
      #endif

      return .loaded(posts: posts, cursor: feed.cursor)
    case .loaded(let posts, let cursor):
      let feed = try await client.protoClient.getTimeline(cursor: cursor)
      let newPosts = await processFeed(feed.feed, client: client.protoClient)
      return .loaded(posts: posts + newPosts, cursor: feed.cursor)
    }
  }
}
