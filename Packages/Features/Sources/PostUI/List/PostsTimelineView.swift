@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import FeedUI
import Models
import SwiftUI
import UIKit
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
                    // New posts indicator
                    NewPostsIndicatorView {
                        // Scroll to top when tapped
                        if let windowScene = UIApplication.shared.connectedScenes.first
                            as? UIWindowScene,
                            let window = windowScene.windows.first
                        {
                            // Find the first scroll view and scroll to top
                            findAndScrollToTop(in: window)
                        }
                    }

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
            .sheet(isPresented: $showingSummary) {
                SummarySheetView(
                    title: "Following Summary",
                    summary: summaryText,
                    itemCount: 0,
                    onDismiss: { showingSummary = false },
                    onViewAll: {
                        // Scroll to top of the timeline
                        // This will be handled by the timeline view itself
                    }
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
            do {
                #if DEBUG
                    print("TimelineView: Attempting to fetch timeline...")
                    print(
                        "TimelineView: Client state - configuration: \(client.protoClient.sessionConfiguration != nil ? "exists" : "nil")"
                    )
                #endif

                let feed = try await client.protoClient.getTimeline()

                // Debug logging to identify the issue
                #if DEBUG
                    print("TimelineView: Timeline feed received: \(feed.feed.count) posts")
                    print("TimelineView: Feed cursor: \(feed.cursor ?? "nil")")
                    if let firstPost = feed.feed.first {
                        print("TimelineView: First post structure: \(firstPost)")
                        print("TimelineView: First post URI: \(firstPost.post.postItem.uri)")
                        print(
                            "TimelineView: First post author: \(firstPost.post.author.actorHandle)")
                    }
                #endif

                // Validate feed data before processing
                guard !feed.feed.isEmpty else {
                    #if DEBUG
                        print("TimelineView: Timeline feed is empty")
                    #endif
                    throw NSError(
                        domain: "TimelineError", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "No posts found in timeline"])
                }

                // Validate that the feed data structure is complete
                let validPosts = feed.feed.filter { post in
                    // Check if the post has all required fields
                    return !post.post.uri.isEmpty && !post.post.cid.isEmpty
                        && !post.post.author.actorHandle.isEmpty
                }

                #if DEBUG
                    print(
                        "TimelineView: Valid posts after filtering: \(validPosts.count) out of \(feed.feed.count)"
                    )
                #endif

                guard !validPosts.isEmpty else {
                    #if DEBUG
                        print("TimelineView: No valid posts found in timeline data")
                    #endif
                    throw NSError(
                        domain: "TimelineError", code: 2,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Timeline data is incomplete. Please try again."
                        ])
                }

                // Try to process the feed with enhanced error handling using validated posts
                let posts = await processFeed(validPosts, client: client.protoClient)

                // Validate that we got some posts back
                guard !posts.isEmpty else {
                    #if DEBUG
                        print("TimelineView: No posts were successfully processed from timeline")
                    #endif
                    throw NSError(
                        domain: "TimelineError", code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to process timeline posts"])
                }

                // Trigger per-account post notifications for new posts
                PostNotificationManager.shared.process(posts: posts)
                #if DEBUG
                    print("TimelineView: Successfully processed \(posts.count) posts from timeline")
                #endif

                // Check for new posts using the feed position service
                Task {
                    await FeedPositionService.shared.checkForNewPosts(currentPosts: posts)
                }

                return .loaded(posts: posts, cursor: feed.cursor)
            } catch {
                #if DEBUG
                    print("TimelineView: Error loading timeline: \(error)")
                    print("TimelineView: Error type: \(type(of: error))")
                    print("TimelineView: Error description: \(error.localizedDescription)")
                #endif

                // Try to refresh the session and retry once
                do {
                    #if DEBUG
                        print("TimelineView: Attempting to refresh session and retry...")
                    #endif

                    try await client.protoClient.sessionConfiguration?.refreshSession()
                    let feed = try await client.protoClient.getTimeline()

                    #if DEBUG
                        print("TimelineView: Retry successful after session refresh")
                    #endif

                    // Validate the retry data as well
                    let validPosts = feed.feed.filter { post in
                        return !post.post.uri.isEmpty && !post.post.cid.isEmpty
                            && !post.post.author.actorHandle.isEmpty
                    }

                    guard !validPosts.isEmpty else {
                        #if DEBUG
                            print("TimelineView: Retry data is also invalid")
                        #endif
                        throw NSError(
                            domain: "TimelineError", code: 6,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Timeline data is incomplete. Please try again."
                            ])
                    }

                    let posts = await processFeed(validPosts, client: client.protoClient)
                    PostNotificationManager.shared.process(posts: posts)

                    return .loaded(posts: posts, cursor: feed.cursor)
                } catch {
                    #if DEBUG
                        print("TimelineView: Retry after session refresh also failed: \(error)")
                    #endif
                }

                // Try alternative approach - load with different parameters
                do {
                    #if DEBUG
                        print("TimelineView: Trying alternative timeline loading approach...")
                    #endif

                    // Try loading with a limit parameter to see if that helps
                    let feed = try await client.protoClient.getTimeline(limit: 25)

                    let validPosts = feed.feed.filter { post in
                        return !post.post.uri.isEmpty && !post.post.cid.isEmpty
                            && !post.post.author.actorHandle.isEmpty
                    }

                    if !validPosts.isEmpty {
                        #if DEBUG
                            print(
                                "TimelineView: Alternative approach successful with \(validPosts.count) posts"
                            )
                        #endif
                        let posts = await processFeed(validPosts, client: client.protoClient)
                        PostNotificationManager.shared.process(posts: posts)
                        return .loaded(posts: posts, cursor: feed.cursor)
                    }
                } catch {
                    #if DEBUG
                        print("TimelineView: Alternative approach also failed: \(error)")
                    #endif
                }

                // Provide more specific error messages
                if error.localizedDescription.contains("data couldn't be read") {
                    throw NSError(
                        domain: "TimelineError", code: 3,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Unable to load timeline data. Please check your connection and try again."
                        ])
                } else if error.localizedDescription.contains("missing")
                    || error.localizedDescription.contains("incomplete")
                {
                    throw NSError(
                        domain: "TimelineError", code: 4,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Timeline data is incomplete. Please try again."
                        ])
                } else {
                    // Re-throw the original error with more context
                    throw NSError(
                        domain: "TimelineError", code: 5,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Failed to load timeline: \(error.localizedDescription)"
                        ])
                }
            }
        case .loaded(let posts, let cursor):
            do {
                let feed = try await client.protoClient.getTimeline(cursor: cursor)
                let newPosts = await processFeed(feed.feed, client: client.protoClient)
                PostNotificationManager.shared.process(posts: newPosts)
                return .loaded(posts: posts + newPosts, cursor: feed.cursor)
            } catch {
                #if DEBUG
                    print("TimelineView: Error loading more posts: \(error)")
                #endif
                // For pagination errors, return the existing posts rather than failing completely
                return .loaded(posts: posts, cursor: cursor)
            }
        }
    }

    private func findAndScrollToTop(in view: UIView) {
        if let scrollView = findScrollView(in: view) {
            scrollView.setContentOffset(.zero, animated: true)
        }
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }

        for subview in view.subviews {
            if let found = findScrollView(in: subview) {
                return found
            }
        }

        return nil
    }
}
