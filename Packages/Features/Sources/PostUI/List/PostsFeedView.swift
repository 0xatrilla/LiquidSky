@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import FeedUI
import Models
import SwiftData
import SwiftUI
import User

public struct PostsFeedView: View {
  @Environment(BSkyClient.self) var client
  @Environment(\.modelContext) var modelContext
  @Environment(AppRouter.self) var router
  @State private var isGeneratingSummary = false
  @State private var showingSummary = false
  @State private var currentSummary: String?

  private let feedItem: FeedItem

  public init(feedItem: FeedItem) {
    self.feedItem = feedItem
  }

  public var body: some View {
    PostListView(datasource: self)
      .navigationTitle(feedItem.displayName)
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          // Summarize button
          Button(action: {
            Task {
              await generateSummary()
            }
          }) {
            if isGeneratingSummary {
              HStack(spacing: 6) {
                ProgressView()
                  .scaleEffect(0.7)
                Text("Analyzing...")
                  .font(.caption2)
                  .fontWeight(.medium)
              }
              .foregroundStyle(.secondary)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(.ultraThinMaterial)
              .clipShape(Capsule())
            } else {
              Image(systemName: "doc.text.magnifyingglass")
                .font(.title2)
                .foregroundColor(.themePrimary)
            }
          }
          .disabled(isGeneratingSummary)
          
          // Compose button
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
      .sheet(isPresented: $showingSummary) {
        if let summary = currentSummary {
          FeedSummaryView(
            summary: summary,
            feedName: feedItem.displayName,
            postCount: getCurrentPostCount(),
            onDismiss: {
              showingSummary = false
            }
          )
        }
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
  
  private func generateSummary() async {
    isGeneratingSummary = true
    defer { isGeneratingSummary = false }
    
    // Get current posts from the PostListView datasource
    do {
      let state = try await loadPosts(with: .uninitialized)
      if case .loaded(let posts, _) = state {
        let summary = await FeedSummaryService.shared.summarizeFeedPosts(posts, feedName: feedItem.displayName)
        await MainActor.run {
          currentSummary = summary
          showingSummary = true
        }
      }
    } catch {
      print("Failed to generate summary: \(error)")
      await MainActor.run {
        currentSummary = "Unable to generate summary at this time. Please try again later."
        showingSummary = true
      }
    }
  }
  
  private func getCurrentPostCount() -> Int {
    // This is a simple fallback - in a real implementation you might want to track this
    return 0
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
