import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI

// MARK: - Search Filter Enum

enum SearchFilter: CaseIterable {
  case all
  case posts
  case users
  case feeds

  var title: String {
    switch self {
    case .all: return "All"
    case .posts: return "Posts"
    case .users: return "Users"
    case .feeds: return "Feeds"
    }
  }
}

public struct EnhancedSearchView: View {
  @State private var searchService: UnifiedSearchService
  @State private var trendingContentService: TrendingContentService
  @State private var searchText = ""
  @State private var selectedFilter: SearchFilter = .all
  @State private var searchHistory: [String] = []
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client

  public init(client: BSkyClient) {
    self._searchService = State(initialValue: UnifiedSearchService(client: client))
    self._trendingContentService = State(initialValue: TrendingContentService(client: client))
  }

  public var body: some View {
    VStack(spacing: 0) {
      filterButtons

      if !searchText.isEmpty {
        searchResultsView
      } else {
        trendingContentView
      }
    }
    .background(Color(.systemBackground))
    .navigationTitle("Search")
    .navigationBarTitleDisplayMode(.large)
    .searchable(text: $searchText, prompt: "Search users, feeds, and posts...")
    .onChange(of: searchText) { _, newValue in
      if !newValue.isEmpty {
        Task {
          await performSearch()
        }
      }
    }
    .onAppear {
      searchService.client = client
      trendingContentService.client = client
      Task {
        await trendingContentService.fetchTrendingContent()
      }

      if !searchText.isEmpty {
        Task {
          await performSearch()
        }
      }
    }
  }

  // MARK: - Fallback Hashtags
  private var fallbackHashtags: [TrendingHashtag] {
    [
      TrendingHashtag(tag: "bluesky", usageCount: 15420, isTrending: true),
      TrendingHashtag(tag: "tech", usageCount: 12340, isTrending: true),
      TrendingHashtag(tag: "art", usageCount: 9870, isTrending: true),
      TrendingHashtag(tag: "music", usageCount: 8760, isTrending: true),
      TrendingHashtag(tag: "photography", usageCount: 7650, isTrending: true),
      TrendingHashtag(tag: "science", usageCount: 6540, isTrending: true),
      TrendingHashtag(tag: "gaming", usageCount: 5430, isTrending: true),
      TrendingHashtag(tag: "food", usageCount: 4320, isTrending: true),
      TrendingHashtag(tag: "travel", usageCount: 3980, isTrending: false),
      TrendingHashtag(tag: "books", usageCount: 3450, isTrending: false),
      TrendingHashtag(tag: "fitness", usageCount: 2980, isTrending: false),
      TrendingHashtag(tag: "cooking", usageCount: 2670, isTrending: false),
    ]
  }

  // MARK: - Filter Buttons
  private var filterButtons: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(SearchFilter.allCases, id: \.self) { filter in
          FilterButton(
            filter: filter,
            isSelected: selectedFilter == filter
          ) {
            toggleFilter(filter)
          }
        }
      }
      .padding(.horizontal, 20)
    }
    .padding(.vertical, 16)
  }

  // MARK: - Trending Content View
  private var trendingContentView: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header
        VStack(spacing: 16) {
          Image(systemName: "sparkles")
            .font(.system(size: 64))
            .foregroundColor(.blue)

          Text("Discover Content")
            .font(.title2)
            .fontWeight(.semibold)

          Text("Search for users, feeds, and posts to explore the Bluesky network")
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }

        // Trending hashtags section
        VStack(spacing: 16) {
          HStack {
            Text("Trending Hashtags")
              .font(.headline)
              .fontWeight(.semibold)

            Spacer()

            if trendingContentService.isLoading {
              ProgressView()
                .scaleEffect(0.8)
            }
          }

          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(fallbackHashtags, id: \.tag) { hashtag in
              Button(action: {
                // Navigate to hashtag feed instead of setting search text
                let hashtagWithoutHash =
                  hashtag.tag.hasPrefix("#") ? String(hashtag.tag.dropFirst()) : hashtag.tag
                router.navigateTo(.hashtag(hashtagWithoutHash))
              }) {
                VStack(spacing: 8) {
                  HStack {
                    Text("#\(hashtag.tag)")
                      .font(.caption)
                      .fontWeight(.medium)
                      .lineLimit(1)

                    if hashtag.isTrending {
                      Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    }
                  }

                  Text("\(hashtag.formattedCount) posts")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .foregroundColor(.primary)
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(.horizontal, 20)

        // Suggested users section
        if !trendingContentService.suggestedUsers.isEmpty {
          VStack(spacing: 16) {
            HStack {
              Text("Suggested Users")
                .font(.headline)
                .fontWeight(.semibold)

              Spacer()
            }

            LazyVStack(spacing: 12) {
              ForEach(trendingContentService.suggestedUsers) { user in
                Button(action: {
                  router.presentedSheet = .profile(user)
                }) {
                  SuggestedUserRow(user: user)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(.horizontal, 20)
        }

        // Search history
        if !searchHistory.isEmpty {
          VStack(spacing: 16) {
            HStack {
              Text("Recent searches")
                .font(.headline)
                .fontWeight(.semibold)

              Spacer()

              Button("Clear") {
                searchHistory.removeAll()
              }
              .font(.caption)
              .foregroundColor(.blue)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
              ForEach(searchHistory.prefix(6), id: \.self) { term in
                Button(action: {
                  searchText = term
                  Task {
                    await performSearch()
                  }
                }) {
                  Text(term)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(.horizontal, 20)
        }

        // Popular searches
        VStack(spacing: 16) {
          Text("Popular searches")
            .font(.headline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)

          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
            ForEach(popularSearches, id: \.self) { term in
              Button(action: {
                searchText = term
                Task {
                  await performSearch()
                }
              }) {
                Text(term)
                  .font(.caption)
                  .fontWeight(.medium)
                  .lineLimit(1)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 8)
                  .frame(maxWidth: .infinity)
                  .background(Color(.systemGray6))
                  .cornerRadius(12)
                  .foregroundColor(.primary)
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(.horizontal, 20)
      }
      .padding(.vertical, 20)
    }
  }

  // MARK: - Search Results View
  private var searchResultsView: some View {
    Group {
      if hasAnyFilteredResults() {
        ScrollView {
          LazyVStack(spacing: 16) {
            // Results summary
            HStack {
              Text("Found \(totalResultsCount()) results")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

              Spacer()

              if !searchHistory.isEmpty {
                Button("Clear History") {
                  searchHistory.removeAll()
                }
                .font(.caption)
                .foregroundColor(.blue)
              }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 20)

            // Users section
            if selectedFilter == .all || selectedFilter == .users {
              if !searchService.searchResults.users.isEmpty {
                SearchSectionHeader(title: "Users", count: searchService.searchResults.users.count)

                LazyVStack(spacing: 8) {
                  ForEach(searchService.searchResults.users) { user in
                    Button(action: {
                      router.presentedSheet = .profile(user)
                    }) {
                      UserSearchResultRow(user: user)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                  }
                }
              }
            }

            // Feeds section
            if selectedFilter == .all || selectedFilter == .feeds {
              if !searchService.searchResults.feeds.isEmpty {
                SearchSectionHeader(title: "Feeds", count: searchService.searchResults.feeds.count)

                LazyVStack(spacing: 8) {
                  ForEach(searchService.searchResults.feeds) { feed in
                    Button(action: {
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
                    }) {
                      FeedSearchResultRow(feed: feed)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                  }
                }
              }
            }

            // Posts section
            if selectedFilter == .all || selectedFilter == .posts {
              if !searchService.searchResults.posts.isEmpty {
                SearchSectionHeader(title: "Posts", count: searchService.searchResults.posts.count)

                LazyVStack(spacing: 8) {
                  ForEach(searchService.searchResults.posts) { post in
                    Button(action: {
                      router.navigateTo(.post(post))
                    }) {
                      PostSearchResultRow(post: post, client: client)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                  }
                }
              }
            }
          }
          .padding(.bottom, 100)
        }
      } else if !searchText.isEmpty {
        noResultsView
      }
    }
  }

  // MARK: - No Results View
  private var noResultsView: some View {
    VStack(spacing: 20) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 64))
        .foregroundColor(.secondary)

      Text("No results found")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Try adjusting your search terms or filters")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      // Search suggestions
      VStack(spacing: 12) {
        Text("Try these searches:")
          .font(.caption)
          .foregroundColor(.secondary)

        HStack(spacing: 8) {
          ForEach(["tech", "art", "music", "news"], id: \.self) { term in
            Button(action: {
              searchText = term
              Task {
                await performSearch()
              }
            }) {
              Text(term)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
    .padding()
  }

  // MARK: - Methods

  private func toggleFilter(_ filter: SearchFilter) {
    if selectedFilter == filter {
      selectedFilter = .all
    } else {
      selectedFilter = filter
    }
  }

  private func performSearch() async {
    guard !searchText.isEmpty else { return }

    Task {
      await searchService.search(query: searchText)
      addToSearchHistory(searchText)
    }
  }

  private func addToSearchHistory(_ query: String) {
    if !searchHistory.contains(query) {
      searchHistory.insert(query, at: 0)
      if searchHistory.count > 10 {
        searchHistory = Array(searchHistory.prefix(10))
      }
    }
  }

  private func generateSearchSuggestions() -> [String] {
    let allSearches = searchHistory + popularSearches
    return allSearches.filter { $0.lowercased().contains(searchText.lowercased()) }
  }

  private func totalResultsCount() -> Int {
    var count = 0
    if selectedFilter == .all || selectedFilter == .posts {
      count += searchService.searchResults.posts.count
    }
    if selectedFilter == .all || selectedFilter == .users {
      count += searchService.searchResults.users.count
    }
    if selectedFilter == .all || selectedFilter == .feeds {
      count += searchService.searchResults.feeds.count
    }
    return count
  }

  private func hasAnyFilteredResults() -> Bool {
    switch selectedFilter {
    case .all:
      return !searchService.searchResults.posts.isEmpty
        || !searchService.searchResults.users.isEmpty || !searchService.searchResults.feeds.isEmpty
    case .posts:
      return !searchService.searchResults.posts.isEmpty
    case .users:
      return !searchService.searchResults.users.isEmpty
    case .feeds:
      return !searchService.searchResults.feeds.isEmpty
    }
  }

  // MARK: - Search Data

  private let popularSearches = [
    "bluesky",
    "tech",
    "art",
    "music",
    "photography",
    "science",
    "gaming",
    "food",
  ]
}

// MARK: - UI Components

private struct FilterButton: View {
  let filter: SearchFilter
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(filter.title)
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(isSelected ? .blue : Color(.systemGray6))
        )
        .foregroundColor(isSelected ? .white : .primary)
    }
    .buttonStyle(.plain)
  }
}

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
        .fontWeight(.medium)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(.blue.opacity(0.1))
        )
        .foregroundColor(.blue)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 8)
  }
}

private struct SuggestedUserRow: View {
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

      // Follow button
      FollowButton(profile: user, size: .small)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color(.systemGray6))
    .cornerRadius(16)
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

      // Follow button
      FollowButton(profile: user, size: .small)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color(.systemGray6))
    .cornerRadius(16)
  }
}

private struct PostSearchResultRow: View {
  let post: PostItem
  @State private var postContext: PostContext
  @Environment(BSkyClient.self) private var client

  public init(post: PostItem, client: BSkyClient) {
    self.post = post
    self._postContext = State(initialValue: PostContext(post: post, client: client))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
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
        .frame(width: 28, height: 28)
        .clipShape(Circle())

        VStack(alignment: .leading, spacing: 1) {
          Text(post.author.displayName ?? post.author.handle)
            .font(.caption)
            .fontWeight(.medium)

          Text("@\(post.author.handle)")
            .font(.caption2)
            .foregroundColor(.secondary)
        }

        Spacer()

        Text(post.indexedAt.relativeFormatted)
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      // Post content
      Text(post.content)
        .font(.body)
        .lineLimit(3)

      // Engagement metrics
      HStack(spacing: 16) {
        HStack(spacing: 4) {
          Image(systemName: "bubble.left")
            .font(.caption2)
            .foregroundColor(.secondary)
          Text("\(post.replyCount)")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
        }

        HStack(spacing: 4) {
          Image(systemName: "arrow.2.squarepath")
            .font(.caption2)
            .foregroundColor(.secondary)
          Text("\(post.replyCount)")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
        }

        HStack(spacing: 4) {
          Image(systemName: "heart")
            .font(.caption2)
            .foregroundColor(.secondary)
          Text("\(postContext.likeCount)")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
        }

        Spacer()

        // Like button
        Button(action: {
          Task {
            await postContext.toggleLike()
          }
        }) {
          Image(systemName: postContext.isLiked ? "heart.fill" : "heart")
            .font(.caption)
            .foregroundColor(postContext.isLiked ? .red : .secondary)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color(.systemGray6))
    .cornerRadius(16)
  }
}
