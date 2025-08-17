@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import FeedUI
import Models
import SwiftUI
import User

public struct PostListView: View {
  let datasource: PostsListViewDatasource
  @State private var state: PostsListViewState = .uninitialized
  @State private var searchText = ""
  @State private var isSearching = false
  @State private var searchResults = SearchResults()
  @State private var searchService: UnifiedSearchService?
  @Environment(AppRouter.self) var router

  // Use singleton directly instead of environment to avoid injection timing issues
  private let postFilterService = PostFilterService.shared

  init(datasource: PostsListViewDatasource) {
    self.datasource = datasource
  }

  public var body: some View {
    VStack(spacing: 0) {
      // Search Bar
      SearchBar(
        text: $searchText,
        placeholder: "Search posts, users, and feeds...",
        onSearch: {
          Task {
            await performSearch()
          }
        },
        onClear: {
          clearSearch()
        }
      )
      .padding(.horizontal, 16)
      .padding(.vertical, 12)

      // Search Results Overlay (when searching)
      if !searchText.isEmpty {
        searchResultsOverlay
      }

      // Normal feed view (always visible, but can be dimmed)
      feedListView
        .opacity(searchText.isEmpty ? 1.0 : 0.3)
        .allowsHitTesting(searchText.isEmpty)
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
      if searchText.isEmpty {
        state = .loading
        state = await datasource.loadPosts(with: state)
      }
    }
    .onAppear {
      setupSearchService()
    }
    .onChange(of: searchText) { _, newValue in
      if !newValue.isEmpty {
        Task {
          await performSearch()
        }
      } else {
        clearSearch()
      }
    }
  }

  private var feedListView: some View {
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
  }

  private func setupSearchService() {
    // Get the client from environment or datasource
    Task {
      if let client = try? await BSkyClient(configuration: ATProtocolConfiguration()) {
        await MainActor.run {
          searchService = UnifiedSearchService(client: client)
        }
      }
    }
  }

  private func performSearch() async {
    guard let searchService = searchService else { return }

    isSearching = true
    await searchService.search(query: searchText)

    // Update our local state
    await MainActor.run {
      searchResults = searchService.searchResults
      isSearching = false
    }
  }

  private func clearSearch() {
    searchText = ""
    searchResults = SearchResults()
    searchService?.clearSearch()
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

  private var searchResultsOverlay: some View {
    VStack(spacing: 0) {
      if isSearching {
        // Loading state
        HStack(spacing: 12) {
          ProgressView()
            .scaleEffect(0.8)
          Text("Searching...")
            .font(.body)
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
      } else if searchResults.hasResults {
        // Search results
        ScrollView {
          LazyVStack(spacing: 0) {
            // Users section
            if !searchResults.users.isEmpty {
              SearchSectionHeader(title: "Users", count: searchResults.users.count)
              ForEach(searchResults.users) { user in
                UserSearchResultRow(user: user)
                  .onTapGesture {
                    onUserTap(user)
                  }
              }
            }

            // Feeds section
            if !searchResults.feeds.isEmpty {
              SearchSectionHeader(title: "Feeds", count: searchResults.feeds.count)
              ForEach(searchResults.feeds) { feed in
                FeedSearchResultRow(feed: feed)
                  .onTapGesture {
                    onFeedTap(feed)
                  }
              }
            }

            // Posts section
            if !searchResults.posts.isEmpty {
              SearchSectionHeader(title: "Posts", count: searchResults.posts.count)
              ForEach(searchResults.posts) { post in
                PostSearchResultRow(post: post)
                  .onTapGesture {
                    onPostTap(post)
                  }
              }
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(maxHeight: 400)
      } else if !searchText.isEmpty {
        // No results state
        HStack(spacing: 12) {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)
          Text("No results found")
            .font(.body)
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
      }
    }
  }

  // MARK: - Search Result Row Components

  private func onUserTap(_ user: Profile) {
    // Navigate to user profile
    print("Navigate to user: \(user.handle)")
    // Clear search and navigate to profile
    clearSearch()
    router.navigateTo(.profile(user))
  }

  private func onFeedTap(_ feed: FeedSearchResult) {
    // Navigate to feed
    print("Navigate to feed: \(feed.displayName)")
    // Clear search and navigate to feed
    clearSearch()
    // Create FeedItem from search result and navigate
    let feedItem = FeedItem(
      uri: feed.uri,
      displayName: feed.displayName,
      description: feed.description,
      avatarImageURL: feed.avatarURL,
      creatorHandle: feed.creatorHandle,
      likesCount: feed.likesCount,
      liked: feed.isLiked
    )
    router.navigateTo(.feed(feedItem))
  }

  private func onPostTap(_ post: PostItem) {
    // Navigate to post
    print("Navigate to post: \(post.uri)")
    // Clear search and navigate to post detail
    clearSearch()
    router.navigateTo(.post(post))
  }
}

// MARK: - Search Result Components

private struct SearchSectionHeader: View {
  let title: String
  let count: Int

  var body: some View {
    HStack {
      Text(title)
        .font(.headline)
        .fontWeight(.semibold)

      Spacer()

      Text("\(count)")
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    .padding(.top, 8)
    .padding(.bottom, 4)
  }
}

private struct UserSearchResultRow: View {
  let user: Profile

  var body: some View {
    HStack(spacing: 12) {
      // Avatar
      AsyncImage(url: user.avatarImageURL) { phase in
        switch phase {
        case .success(let image):
          image
            .resizable()
            .scaledToFit()
        default:
          Circle()
            .fill(Color.gray.opacity(0.3))
        }
      }
      .frame(width: 40, height: 40)
      .clipShape(Circle())

      // User info
      VStack(alignment: .leading, spacing: 2) {
        Text(user.displayName ?? user.handle)
          .font(.body)
          .fontWeight(.medium)

        Text("@\(user.handle)")
          .font(.caption)
          .foregroundColor(.secondary)

        if let description = user.description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
      }

      Spacer()
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
    )
  }
}

private struct FeedSearchResultRow: View {
  let feed: FeedSearchResult

  var body: some View {
    HStack(spacing: 12) {
      // Feed icon
      Image(systemName: "list.bullet")
        .font(.title2)
        .foregroundColor(.blue)
        .frame(width: 40, height: 40)
        .background(Color.blue.opacity(0.1))
        .clipShape(Circle())

      // Feed info
      VStack(alignment: .leading, spacing: 2) {
        Text(feed.displayName)
          .font(.body)
          .fontWeight(.medium)

        Text("by @\(feed.creatorHandle)")
          .font(.caption)
          .foregroundColor(.secondary)

        if let description = feed.description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }

        HStack(spacing: 8) {
          Label("\(feed.likesCount)", systemImage: "heart.fill")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
    )
  }
}

private struct PostSearchResultRow: View {
  let post: PostItem

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Author info
      HStack(spacing: 8) {
        AsyncImage(url: post.author.avatarImageURL) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .scaledToFit()
          default:
            Circle()
              .fill(Color.gray.opacity(0.3))
          }
        }
        .frame(width: 24, height: 24)
        .clipShape(Circle())

        Text(post.author.displayName ?? post.author.handle)
          .font(.caption)
          .fontWeight(.medium)

        Text("@\(post.author.handle)")
          .font(.caption)
          .foregroundColor(.secondary)

        Spacer()

        Text(post.indexedAt.relativeFormatted)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      // Post content
      Text(post.content)
        .font(.body)
        .lineLimit(3)

      // Engagement metrics
      HStack(spacing: 16) {
        Label("\(post.replyCount)", systemImage: "bubble.left")
          .font(.caption)
          .foregroundColor(.secondary)

        Label("\(post.repostCount)", systemImage: "arrow.2.squarepath")
          .font(.caption)
          .foregroundColor(.secondary)

        Label("\(post.likeCount)", systemImage: "heart")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
    )
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
