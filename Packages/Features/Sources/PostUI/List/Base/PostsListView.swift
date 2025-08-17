@preconcurrency import ATProtoKit
import Client
import DesignSystem
import Models
import SwiftUI
import User

public struct PostListView: View {
  let datasource: PostsListViewDatasource
  @State private var state: PostsListViewState = .uninitialized

  // Use singleton directly instead of environment to avoid injection timing issues
  private let postFilterService = PostFilterService.shared

  init(datasource: PostsListViewDatasource) {
    self.datasource = datasource
  }

  public var body: some View {
    List {
      switch state {
      case .loading, .uninitialized:
        placeholderView
      case .loaded(let posts, let cursor):
        ForEach(filteredPosts(posts)) { post in
          PostRowView(post: post)
        }
        if cursor != nil {
          nextPageView
        }
      case .error(let error):
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 48))
            .foregroundStyle(.red)

          Text("Error Loading Feed")
            .font(.title2)
            .fontWeight(.semibold)

          Text(error.localizedDescription)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

          Button("Try Again") {
            Task {
              state = .loading
              state = await datasource.loadPosts(with: state)
            }
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .navigationTitle(datasource.title)
    .screenContainer()
    .task {
      if case .uninitialized = state {
        state = .loading
        state = await datasource.loadPosts(with: state)
      }
    }
    .refreshable {
      state = .loading
      state = await datasource.loadPosts(with: state)
    }
  }

  private func filteredPosts(_ posts: [PostItem]) -> [PostItem] {
    return postFilterService.filterPosts(posts)
  }

  private var nextPageView: some View {
    HStack {
      ProgressView()
    }
    .task {
      state = await datasource.loadPosts(with: state)
    }
  }

  private var placeholderView: some View {
    ForEach(PostItem.placeholders) { post in
      PostRowView(post: post)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }
  }
}

// MARK: - Data
extension PostListView {
  public static func processFeed(_ feed: [AppBskyLexicon.Feed.FeedViewPostDefinition]) -> [PostItem]
  {
    print("PostsListView: Starting to process feed with \(feed.count) items")
    var postItems: [PostItem] = []
    var processedCount = 0

    func insert(
      post: AppBskyLexicon.Feed.PostViewDefinition,
      fromFeedItem: AppBskyLexicon.Feed.FeedViewPostDefinition
    ) {
      // Add safety check to prevent crash if uri is nil
      guard !post.uri.isEmpty else {
        print("Warning: Skipping post with empty URI")
        return
      }

      guard !postItems.contains(where: { $0.uri == post.uri }) else {
        print("Warning: Skipping duplicate post with URI: \(post.uri)")
        return
      }

      // Use the FeedViewPostDefinition.postItem extension to get repost information
      let item = fromFeedItem.postItem
      print(
        "PostsListView: Processing post - URI: \(item.uri), Author: \(item.author.handle), Content: \(item.content.prefix(50))..."
      )
      // hasReply is already set correctly from replyRef in the PostItem initializer
      postItems.append(item)
      processedCount += 1
    }

    for (index, post) in feed.enumerated() {
      // Debug: Print the structure to understand what we're working with
      print("PostsListView: Processing feed item \(index): post.uri = \(post.post.uri)")

      // Pass both the post and the feed item to get repost information
      insert(post: post.post, fromFeedItem: post)

      // Process replies - simplified to avoid type issues
      if post.reply != nil {
        print("PostsListView: Reply found for item \(index) - processing...")
        // TODO: Implement proper reply processing when we understand the type structure
      }

      // Process repost - simplified to avoid type issues
      if post.reason != nil {
        print("PostsListView: Repost found for item \(index) - processing...")
        // TODO: Implement proper reply processing when we understand the type structure
      }
    }

    print(
      "PostsListView: Finished processing feed. Total posts: \(postItems.count), Processed: \(processedCount)"
    )
    return postItems
  }
}
