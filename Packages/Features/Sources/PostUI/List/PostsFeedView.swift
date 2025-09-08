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

  private let feedItem: FeedItem
  @State private var showingSummary = false
  @State private var summaryText = ""
  @State private var isGeneratingSummary = false

  public init(feedItem: FeedItem) {
    self.feedItem = feedItem
  }

  public var body: some View {
    PostListView(datasource: self)
      .navigationTitle(feedItem.displayName)
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          // Summary button
          Button(action: {
            Task {
              await generateFeedSummary()
            }
          }) {
            if isGeneratingSummary {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.themeSecondary)
            } else {
              Image(systemName: "sparkles")
                .foregroundColor(.themeSecondary)
            }
          }
          .disabled(isGeneratingSummary)

          // Post creation button
          Button(action: {
            router.presentedSheet = .composer(mode: .newPost)
          }) {
            Image(systemName: "square.and.pencil")
              .foregroundColor(.themePrimary)
          }
        }
      }
      .onAppear {
        updateRecentlyViewed()
      }
      .sheet(isPresented: $showingSummary) {
        SummarySheetView(
          title: "\(feedItem.displayName) Summary",
          summary: summaryText,
          itemCount: 0,
          onDismiss: { showingSummary = false }
        )
      }
  }

  private func updateRecentlyViewed() {
    // Safely update recently viewed feeds
    Task { @MainActor in
      do {
        // First, try to find existing items to delete
        let fetchDescriptor = FetchDescriptor<RecentFeedItem>(
          predicate: #Predicate<RecentFeedItem> { item in
            item.uri == feedItem.uri
          }
        )

        let existingItems = try modelContext.fetch(fetchDescriptor)

        // Delete existing items if found
        for item in existingItems {
          modelContext.delete(item)
        }

        // Insert new item
        let newItem = RecentFeedItem(
          uri: feedItem.uri,
          name: feedItem.displayName,
          avatarImageURL: feedItem.avatarImageURL,
          lastViewedAt: Date()
        )
        modelContext.insert(newItem)

        // Save changes
        try modelContext.save()

        #if DEBUG
          print("PostsFeedView: Successfully updated recently viewed feed: \(feedItem.displayName)")
        #endif
      } catch {
        #if DEBUG
          print("PostsFeedView: Failed to update recently viewed feed: \(error)")
        #endif
        // Don't crash the app if this fails - it's not critical functionality
      }
    }
  }

  private func generateFeedSummary() async {
    isGeneratingSummary = true

    do {
      // Fetch recent posts for this specific feed
      let feed = try await client.protoClient.getFeed(by: feedItem.uri, cursor: nil)
      let processedPosts = await processFeed(feed.feed, client: client.protoClient)

      // Use FeedSummaryService to generate AI summary
      let summary = await FeedSummaryService.shared.summarizeFeedPosts(
        processedPosts, feedName: feedItem.displayName)
      summaryText = summary
      showingSummary = true
    } catch {
      // Fallback to a simple summary if the service fails
      summaryText =
        "Unable to generate AI summary for \(feedItem.displayName) at this time. Please try again later."
      showingSummary = true
    }

    isGeneratingSummary = false
  }

}

// MARK: - Datasource
extension PostsFeedView: @MainActor PostsListViewDatasource {
  public var title: String {
    feedItem.displayName
  }

  public func loadPosts(with state: PostsListViewState) async throws -> PostsListViewState {
    #if DEBUG
      print("PostsFeedView: Starting to load posts for feed: \(feedItem.displayName)")
      print("PostsFeedView: Feed URI: \(feedItem.uri)")
      print("PostsFeedView: Current state: \(state)")
      print("PostsFeedView: About to call getFeed API")
    #endif

    switch state {
    case .uninitialized, .loading, .error:
      #if DEBUG
        print("PostsFeedView: Fetching initial feed data...")
      #endif
      let feed = try await client.protoClient.getFeed(by: feedItem.uri, cursor: nil)
      #if DEBUG
        print("PostsFeedView: Successfully fetched feed with \(feed.feed.count) posts")
        print("PostsFeedView: Feed response: \(feed)")
        if feed.feed.isEmpty {
          print("PostsFeedView: WARNING - Feed is empty!")
        }
      #endif
      let processedPosts = await processFeed(feed.feed, client: client.protoClient)
      #if DEBUG
        print("PostsFeedView: Processed \(processedPosts.count) posts")
      #endif
      return .loaded(posts: processedPosts, cursor: feed.cursor)
    case .loaded(let posts, let cursor):
      #if DEBUG
        print("PostsFeedView: Loading more posts with cursor: \(cursor ?? "nil")")
      #endif
      let feed = try await client.protoClient.getFeed(by: feedItem.uri, cursor: cursor)
      #if DEBUG
        print("PostsFeedView: Successfully fetched more posts: \(feed.feed.count)")
      #endif
      let processedPosts = await processFeed(feed.feed, client: client.protoClient)
      #if DEBUG
        print("PostsFeedView: Processed \(processedPosts.count) additional posts")
      #endif
      return .loaded(posts: posts + processedPosts, cursor: feed.cursor)
    }
  }
}
