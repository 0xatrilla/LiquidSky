import AppRouter
import Client
import DesignSystem
import Destinations
import FeedUI
import Models
import SwiftUI
import User

public struct SwitchableFeedView: View {
    let feed: FeedItem?
    @Environment(BSkyClient.self) var client
    @Environment(AppRouter.self) var router
    @State private var showingSummary = false
    @State private var summaryText = ""
    @State private var isGeneratingSummary = false

    public init(feed: FeedItem?) {
        self.feed = feed
    }

    public var body: some View {
        Group {
            if let feed = feed {
                CustomFeedView(feed: feed)
            } else {
                PostsTimelineViewNoToolbar()
            }
        }
        .navigationTitle(feed?.displayName ?? "Following")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingSummary) {
            SummarySheetView(
                title: feed?.displayName ?? "Following Summary",
                summary: summaryText,
                itemCount: 0,
                onDismiss: { showingSummary = false }
            )
        }
    }

    private func generateFeedSummary() async {
        isGeneratingSummary = true

        do {
            let summary: String
            if let feed = feed {
                // Fetch posts from custom feed
                let feedResponse = try await client.protoClient.getFeed(by: feed.uri, cursor: nil)
                let processedPosts = await processFeed(
                    feedResponse.feed, client: client.protoClient)
                summary = await FeedSummaryService.shared.summarizeFeedPosts(
                    processedPosts, feedName: feed.displayName)
            } else {
                // Fetch posts from following timeline
                let feed = try await client.protoClient.getTimeline()
                let processedPosts = await processFeed(feed.feed, client: client.protoClient)
                summary = await FeedSummaryService.shared.summarizeFeedPosts(
                    processedPosts, feedName: "Following")
            }
            summaryText = summary
            showingSummary = true
        } catch {
            // Fallback to a simple summary if the service fails
            summaryText =
                "Unable to generate AI summary at this time. Please try again later."
            showingSummary = true
        }

        isGeneratingSummary = false
    }
}

// Custom feed view that displays posts from a specific feed
struct CustomFeedView: View {
    let feed: FeedItem
    @Environment(BSkyClient.self) var client

    var body: some View {
        PostListView(datasource: self)
    }
}

extension CustomFeedView: @MainActor PostsListViewDatasource {
    public var title: String {
        feed.displayName
    }

    public func loadPosts(with state: PostsListViewState) async throws -> PostsListViewState {
        switch state {
        case .uninitialized, .loading, .error:
            do {
                let feedResponse = try await client.protoClient.getFeed(by: feed.uri, cursor: nil)
                let posts = await processFeed(feedResponse.feed, client: client.protoClient)
                return .loaded(posts: posts, cursor: feedResponse.cursor)
            } catch {
                throw error
            }
        case .loaded(let posts, let cursor):
            do {
                let feedResponse = try await client.protoClient.getFeed(
                    by: feed.uri, cursor: cursor)
                let newPosts = await processFeed(feedResponse.feed, client: client.protoClient)
                return .loaded(posts: posts + newPosts, cursor: feedResponse.cursor)
            } catch {
                // For pagination errors, return the existing posts rather than failing completely
                return .loaded(posts: posts, cursor: cursor)
            }
        }
    }
}
