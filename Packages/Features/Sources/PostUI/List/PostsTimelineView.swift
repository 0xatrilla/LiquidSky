@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import FeedUI
import Models
import SwiftUI
import User

public struct PostsTimelineView: View {
  @Environment(BSkyClient.self) var client
  @Environment(AppRouter.self) var router
  @State private var showingSummary = false
  @State private var summaryText = ""
  @State private var isGeneratingSummary = false

  public init() {}

  public var body: some View {
    PostListView(datasource: self)
      .navigationTitle("Following")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          // Summary button
          Button(action: {
            Task {
              await generateTimelineSummary()
            }
          }) {
            if isGeneratingSummary {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.themeSecondary)
            } else {
              Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.themeSecondary)
            }
          }
          .disabled(isGeneratingSummary)

          // Post creation button
          Button(action: {
            router.presentedSheet = .composer(mode: .newPost)
          }) {
            Image(systemName: "square.and.pencil")
              .font(.title2)
              .foregroundColor(.themePrimary)
          }
        }
      }
      .sheet(isPresented: $showingSummary) {
        SummarySheetView(
          title: "Following Summary",
          summary: summaryText,
          itemCount: 0,
          onDismiss: { showingSummary = false }
        )
      }
  }

  private func generateTimelineSummary() async {
    isGeneratingSummary = true

    do {
      // Fetch recent posts from timeline
      let feed = try await client.protoClient.getTimeline()
      let processedPosts = await processFeed(feed.feed, client: client.protoClient)

      // Use FeedSummaryService to generate AI summary
      let summary = await FeedSummaryService.shared.summarizeFeedPosts(
        processedPosts, feedName: "Following")
      summaryText = summary
      showingSummary = true
    } catch {
      // Fallback to a simple summary if the service fails
      summaryText =
        "Unable to generate AI summary for your Following timeline at this time. Please try again later."
      showingSummary = true
    }

    isGeneratingSummary = false
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
      // Trigger per-account post notifications for new posts
      PostNotificationManager.shared.process(posts: posts)
      #if DEBUG
        print("Successfully processed \(posts.count) posts from timeline")
      #endif

      return .loaded(posts: posts, cursor: feed.cursor)
    case .loaded(let posts, let cursor):
      let feed = try await client.protoClient.getTimeline(cursor: cursor)
      let newPosts = await processFeed(feed.feed, client: client.protoClient)
      PostNotificationManager.shared.process(posts: newPosts)
      return .loaded(posts: posts + newPosts, cursor: feed.cursor)
    }
  }
}
