@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftData
import SwiftUI
import User

public struct PostsFeedView: View {
  @Environment(BSkyClient.self) var client
  @Environment(\.modelContext) var modelContext
  @Environment(AppRouter.self) var router

  private let feedItem: FeedItem

  public init(feedItem: FeedItem) {
    self.feedItem = feedItem
  }

  public var body: some View {
    PostListView(datasource: self)
      .navigationTitle(feedItem.displayName)
      .navigationBarTitleDisplayMode(.large)
      .toolbar(.visible, for: .tabBar)
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
      .onAppear {
        updateRecentlyViewed()
      }
  }

  private func updateRecentlyViewed() {
    do {
      try modelContext.delete(
        model: RecentFeedItem.self,
        where: #Predicate { feed in
          feed.uri == feedItem.uri
        })
      modelContext.insert(
        RecentFeedItem(
          uri: feedItem.uri,
          name: feedItem.displayName,
          avatarImageURL: feedItem.avatarImageURL,
          lastViewedAt: Date()
        )
      )
      try modelContext.save()
    } catch {}
  }
}

// MARK: - Datasource
extension PostsFeedView: @MainActor PostsListViewDatasource {
  public var title: String {
    feedItem.displayName
  }

  public func loadPosts(with state: PostsListViewState) async throws -> PostsListViewState {
    print("PostsFeedView: Starting to load posts for feed: \(feedItem.displayName)")
    print("PostsFeedView: Feed URI: \(feedItem.uri)")
    print("PostsFeedView: Current state: \(state)")

    switch state {
    case .uninitialized, .loading, .error:
      print("PostsFeedView: Fetching initial feed data...")
      let feed = try await client.protoClient.getFeed(by: feedItem.uri, cursor: nil)
      print("PostsFeedView: Successfully fetched feed with \(feed.feed.count) posts")
      let processedPosts = await processFeed(feed.feed, client: client.protoClient)
      print("PostsFeedView: Processed \(processedPosts.count) posts")
      return .loaded(posts: processedPosts, cursor: feed.cursor)
    case .loaded(let posts, let cursor):
      print("PostsFeedView: Loading more posts with cursor: \(cursor ?? "nil")")
      let feed = try await client.protoClient.getFeed(by: feedItem.uri, cursor: cursor)
      print("PostsFeedView: Successfully fetched more posts: \(feed.feed.count)")
      let processedPosts = await processFeed(feed.feed, client: client.protoClient)
      print("PostsFeedView: Processed \(processedPosts.count) additional posts")
      return .loaded(posts: posts + processedPosts, cursor: feed.cursor)
    }
  }
}
