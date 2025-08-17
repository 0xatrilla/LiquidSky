@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Models
import SwiftUI
import User

public struct FeedsListView: View {
  @Environment(BSkyClient.self) var client
  @Environment(CurrentUser.self) var currentUser

  @State var feeds: [FeedItem] = []
  @State var filter: FeedsListFilter = .suggested
  @State var isLoading: Bool = false

  @State var isRecentFeedExpanded: Bool = true

  @State var isInSearch: Bool = false
  @State var searchText: String = ""
  @StateObject private var searchService: UnifiedSearchService

  @State var error: Error?

  @FocusState var isSearchFocused: Bool

  public init() {
    // Initialize search service without a client initially
    // This will be updated when the view appears
    self._searchService = StateObject(wrappedValue: UnifiedSearchService())
  }

  public var body: some View {
    List {
      headerView
        .padding(.bottom, 16)
      if let error {
        FeedsListErrorView(error: error) {
          await fetchSuggestedFeed()
        }
      }
      if !isInSearch {
        FeedsListRecentSection(isRecentFeedExpanded: $isRecentFeedExpanded)
      }
      feedsSection
    }
    .screenContainer()
    .scrollDismissesKeyboard(.immediately)
    .task(id: filter) {
      guard !isInSearch else { return }
      print("Filter changed to: \(filter)")
      await loadFeedsForCurrentFilter()
    }
    .onAppear {
      // Update search service with the actual client
      searchService.client = client
    }
  }

  private var headerView: some View {
    FeedsListTitleView(
      filter: $filter,
      searchText: $searchText,
      isInSearch: $isInSearch,
      isSearchFocused: $isSearchFocused
    )
    .task(id: searchText) {
      guard !searchText.isEmpty else { return }
      await performUnifiedSearch(query: searchText)
    }
    .onChange(of: isInSearch, initial: false) {
      guard !isInSearch else { return }
      Task { await fetchSuggestedFeed() }
    }
    .onChange(of: currentUser.savedFeeds.count) {
      print("Saved feeds count changed: \(currentUser.savedFeeds.count)")
      switch filter {
      case .suggested:
        feeds = feeds.filter { feed in
          !currentUser.savedFeeds.contains { $0.value == feed.uri }
        }
      case .myFeeds:
        Task { await fetchMyFeeds() }
      }
    }
    .listRowSeparator(.hidden)
  }

  private var feedsSection: some View {
    Section {
      if isLoading {
        HStack {
          ProgressView()
            .scaleEffect(0.8)
          Text("Loading feeds...")
            .font(.body)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
      } else if feeds.isEmpty && searchText.isEmpty {
        VStack(spacing: 16) {
          Image(
            systemName: filter == .myFeeds
              ? "person.crop.rectangle.stack" : "sparkles.rectangle.stack"
          )
          .font(.system(size: 48))
          .foregroundStyle(.secondary)

          Text(filter == .myFeeds ? "No Saved Feeds" : "No Suggested Feeds")
            .font(.title2)
            .fontWeight(.semibold)

          Text(
            filter == .myFeeds
              ? "You haven\'t saved any feeds yet. Try exploring suggested feeds!"
              : "Unable to load suggested feeds. Please try again."
          )
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
      } else {
        // Show search results when searching
        if !searchText.isEmpty {
          searchResultsContent
        } else {
          // Show normal feeds
          ForEach(feeds) { feed in
            FeedRowView(feed: feed)
          }
        }
      }
    }
  }

  private var searchResultsContent: some View {
    VStack(spacing: 16) {
      // Users section
      if !searchService.searchResults.users.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Users (\(searchService.searchResults.users.count))")
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)

          ForEach(searchService.searchResults.users) { user in
            UserSearchResultRow(user: user)
          }
        }
      }

      // Feeds section
      if !searchService.searchResults.feeds.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Feeds (\(searchService.searchResults.feeds.count))")
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)

          ForEach(searchService.searchResults.feeds) { feed in
            SimpleFeedSearchResultRow(feed: feed)
          }
        }
      }

      // Posts section
      if !searchService.searchResults.posts.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Posts (\(searchService.searchResults.posts.count))")
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)

          ForEach(searchService.searchResults.posts) { post in
            PostSearchResultRow(post: post)
          }
        }
      }

      // No results
      if searchService.searchResults.users.isEmpty && searchService.searchResults.feeds.isEmpty
        && searchService.searchResults.posts.isEmpty && !searchText.isEmpty
      {
        VStack(spacing: 16) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 48))
            .foregroundColor(.secondary)

          Text("No results found")
            .font(.title2)
            .fontWeight(.semibold)

          Text("Try adjusting your search terms")
            .font(.body)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
      }
    }
  }

  private func loadFeedsForCurrentFilter() async {
    isLoading = true
    defer { isLoading = false }

    switch filter {
    case .suggested:
      await fetchSuggestedFeed()
    case .myFeeds:
      await fetchMyFeeds()
    }
  }
}

// MARK: - Network
extension FeedsListView {
  private func fetchSuggestedFeed() async {
    error = nil
    do {
      print("Fetching suggested feeds...")
      let feeds = try await client.protoClient.getPopularFeedGenerators(matching: nil)
      print("Suggested feeds API response: \(feeds)")
      print("Suggested feeds received: \(feeds.feeds.count)")

      let feedItems = feeds.feeds.map { $0.feedItem }.filter { feed in
        !currentUser.savedFeeds.contains { $0.value == feed.uri }
      }

      print("Filtered suggested feeds: \(feedItems.count)")
      print("Feed items: \(feedItems.map { $0.displayName })")

      withAnimation {
        self.feeds = feedItems
      }
    } catch {
      print("Error fetching suggested feeds: \(error)")
      self.error = error
    }
  }

  private func fetchMyFeeds() async {
    do {
      print("Fetching my feeds...")
      print("Saved feeds count: \(currentUser.savedFeeds.count)")
      print("Saved feeds URIs: \(currentUser.savedFeeds.map { $0.value })")

      guard !currentUser.savedFeeds.isEmpty else {
        print("No saved feeds to fetch")
        withAnimation {
          self.feeds = []
        }
        return
      }

      let feeds = try await client.protoClient.getFeedGenerators(
        by: currentUser.savedFeeds.map { $0.value })
      print("My feeds API response: \(feeds)")
      print("My feeds received: \(feeds.feeds.count)")

      let feedItems = feeds.feeds.map { $0.feedItem }
      print("Processed my feeds: \(feedItems.count)")
      print("Feed items: \(feedItems.map { $0.displayName })")

      withAnimation {
        self.feeds = feedItems
      }
    } catch {
      print("Error fetching my feeds: \(error)")
      // Don't set error state for my feeds, just show empty state
      withAnimation {
        self.feeds = []
      }
    }
  }

  private func performUnifiedSearch(query: String) async {
    do {
      try await Task.sleep(for: .milliseconds(250))
      await searchService.search(query: query)
    } catch {
      print("Error performing unified search: \(error)")
    }
  }
}

// MARK: - Search Result Components

private struct SimpleFeedSearchResultRow: View {
  let feed: FeedSearchResult

  var body: some View {
    HStack(spacing: 12) {
      // Feed icon
      if let avatarURL = feed.avatarURL {
        AsyncImage(url: avatarURL) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .scaledToFit()
          default:
            Image(systemName: "list.bullet")
              .font(.title3)
              .foregroundColor(.blue)
          }
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
      } else {
        Image(systemName: "list.bullet")
          .font(.title3)
          .foregroundColor(.blue)
          .frame(width: 50, height: 50)
          .background(Color.blue.opacity(0.1))
          .clipShape(Circle())
      }

      // Feed info
      VStack(alignment: .leading, spacing: 4) {
        Text(feed.displayName)
          .font(.headline)
          .fontWeight(.semibold)

        if let description = feed.description, !description.isEmpty {
          Text(description)
            .font(.body)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }

        HStack(spacing: 8) {
          Text("by @\(feed.creatorHandle)")
            .font(.caption)
            .foregroundColor(.secondary)

          Label("\(feed.likesCount)", systemImage: "heart")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      // Arrow indicator
      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
        .font(.caption)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
    )
    .padding(.horizontal, 16)
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
      .frame(width: 50, height: 50)
      .clipShape(Circle())

      // User info
      VStack(alignment: .leading, spacing: 4) {
        Text(user.displayName ?? user.handle)
          .font(.headline)
          .fontWeight(.semibold)

        Text("@\(user.handle)")
          .font(.body)
          .foregroundColor(.secondary)

        if let description = user.description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
      }

      Spacer()

      // Arrow indicator
      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
        .font(.caption)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
    )
    .padding(.horizontal, 16)
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
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
    )
    .padding(.horizontal, 16)
  }
}
