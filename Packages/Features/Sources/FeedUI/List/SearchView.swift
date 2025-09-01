import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct SearchView: View {
  @State private var searchService: UnifiedSearchService
  @State private var searchText = ""
  @State private var searchResults: SearchResults?
  @State private var isLoading = false
  @State private var selectedFilters: Set<SearchFilter> = Set(SearchFilter.allCases)
  @State private var searchHistory: [String] = []
  @State private var showSearchHistory = false
  @State private var searchSuggestions: [String] = []
  @State private var showSuggestions = false
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client

  public init(client: BSkyClient) {
    self._searchService = State(initialValue: UnifiedSearchService(client: client))
  }

  public var body: some View {
    VStack(spacing: 0) {
      // Search header with liquid glass effect
      searchHeader

      // Filter buttons with liquid glass effect
      filterButtons

      // Search results
      searchResultsView
    }
    .navigationTitle("Search")
    .navigationBarTitleDisplayMode(.large)
    .background(
      LinearGradient(
        colors: [.primary, .secondary],
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .onChange(of: searchText) { _, newValue in
      if !newValue.isEmpty {
        generateSearchSuggestions(for: newValue)
        Task {
          await performSearch()
        }
      } else {
        searchSuggestions = []
        showSuggestions = false
        searchResults = nil
      }
    }
    .onAppear {
      // Set the client when the view appears
      searchService.client = client
      if !searchText.isEmpty {
        Task {
          await performSearch()
        }
      }
    }
  }

  // MARK: - Search Header
  private var searchHeader: some View {
    VStack(spacing: 16) {
      // Search bar with liquid glass effect
      HStack(spacing: 12) {
        HStack(spacing: 8) {
          Image(systemName: "magnifyingglass")
            .font(.title2)
            .foregroundStyle(.secondary)

          TextField("Search users, feeds, and posts...", text: $searchText)
            .textFieldStyle(.plain)
            .font(.body)

          if !searchText.isEmpty {
            Button(action: {
              searchText = ""
            }) {
              Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray.opacity(0.1))
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

        // Search button with liquid glass effect
        Button(action: {
          Task {
            await performSearch()
          }
        }) {
          Image(systemName: "sparkles")
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(
              RoundedRectangle(cornerRadius: 22)
                .fill(
                  LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
            )
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
      }

      // Search suggestions with liquid glass effect
      if showSuggestions && !searchSuggestions.isEmpty {
        VStack(spacing: 8) {
          ForEach(searchSuggestions, id: \.self) { suggestion in
            Button(action: {
              searchText = suggestion
              searchSuggestions = []
              showSuggestions = false
              Task {
                await performSearch()
              }
            }) {
              HStack {
                Image(systemName: "magnifyingglass")
                  .font(.caption)
                  .foregroundStyle(.secondary)

                Text(suggestion)
                  .font(.body)
                  .foregroundStyle(.primary)

                Spacer()
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 12)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.gray.opacity(0.1))
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                  )
              )
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
      }

      // Search status with liquid glass effect
      if isLoading {
        HStack(spacing: 8) {
          ProgressView()
            .scaleEffect(0.8)

          Text("Searching...")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.1))
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
        )
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 20)
  }

  // MARK: - Filter Buttons
  private var filterButtons: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(SearchFilter.allCases, id: \.self) { filter in
          FilterButton(
            filter: filter,
            isSelected: selectedFilters.contains(filter)
          ) {
            toggleFilter(filter)
          }
        }
      }
      .padding(.horizontal, 20)
    }
    .padding(.vertical, 16)
  }

  // MARK: - Filter Button
  private struct FilterButton: View {
    let filter: SearchFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
      Button(action: action) {
        HStack(spacing: 6) {
          Image(systemName: filter.iconName)
            .font(.caption)
            .fontWeight(.medium)

          Text(filter.displayName)
            .font(.caption)
            .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(isSelected ? .blue : Color.gray.opacity(0.1))
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? .clear : Color.gray.opacity(0.3), lineWidth: 0.5)
            )
        )
        .foregroundStyle(isSelected ? .white : .primary)
        .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1), radius: 8, x: 0, y: 4)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Search Results View
  private var searchResultsView: some View {
    Group {
      if let results = searchResults, hasAnyFilteredResults(results: results) {
        ScrollView {
          LazyVStack(spacing: 16) {
            // Results summary with liquid glass effect
            HStack {
              Text("Found \(totalResultsCount(results)) results")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

              Spacer()

              if !searchHistory.isEmpty {
                Button("Clear History") {
                  searchHistory.removeAll()
                }
                .font(.caption)
                .foregroundStyle(.blue)
              }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                  RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
            )
            .padding(.horizontal, 20)

            // Users section
            if selectedFilters.contains(.users) && !results.users.isEmpty {
              SearchSectionHeader(title: "Users", count: results.users.count)

              LazyVStack(spacing: 8) {
                ForEach(results.users) { user in
                  Button(action: {
                    // Navigate to user profile within the search tab
                    // The search results already contain Profile objects, so use them directly
                    guard !user.did.isEmpty, !user.handle.isEmpty else {
                      return
                    }

                    // Navigate to profile within the search tab
                    router.navigateTo(.profile(user))
                  }) {
                    UserSearchResultRow(user: user)
                  }
                  .buttonStyle(.plain)
                  .padding(.horizontal, 20)
                }
              }
            }

            // Feeds section
            if selectedFilters.contains(.feeds) && !results.feeds.isEmpty {
              SearchSectionHeader(title: "Feeds", count: results.feeds.count)

              LazyVStack(spacing: 8) {
                ForEach(results.feeds) { feed in
                  Button(action: {
                    // Navigate to feed using proper navigation
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

            // Posts section
            if selectedFilters.contains(.posts) && !results.posts.isEmpty {
              SearchSectionHeader(title: "Posts", count: results.posts.count)

              LazyVStack(spacing: 8) {
                ForEach(results.posts) { post in
                  Button(action: {
                    // Navigate to post using proper navigation
                    // The post is already a PostItem, so we can use it directly
                    router.navigateTo(.post(post))
                  }) {
                    PostSearchResultRow(post: post)
                  }
                  .buttonStyle(.plain)
                  .padding(.horizontal, 20)
                }
              }
            }
          }
          .padding(.bottom, 100)  // Account for tab bar
        }
      } else if !searchText.isEmpty && !isLoading {
        noResultsView
      } else {
        searchPromptView
      }
    }
    .onAppear {
      if !searchText.isEmpty {
        Task {
          await performSearch()
        }
      }
    }
  }

  // MARK: - Search Section Header
  private struct SearchSectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
      HStack {
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Spacer()

        Text("\(count)")
          .font(.caption)
          .fontWeight(.medium)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(.blue.opacity(0.1))
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(.blue.opacity(0.3), lineWidth: 0.5)
              )
          )
          .foregroundStyle(.blue)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 8)
    }
  }

  // MARK: - No Results View
  private var noResultsView: some View {
    VStack(spacing: 20) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 64))
        .foregroundStyle(.secondary)

      Text("No results found")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Try adjusting your search terms or filters")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      // Search suggestions with liquid glass effect
      VStack(spacing: 12) {
        Text("Try these searches:")
          .font(.caption)
          .foregroundStyle(.tertiary)

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
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                      RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                )
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
    .padding()
  }

  // MARK: - Search Prompt View
  private var searchPromptView: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header
        VStack(spacing: 16) {
          Image(systemName: "sparkles")
            .font(.system(size: 64))
            .foregroundStyle(.blue)

          Text("Discover Content")
            .font(.title2)
            .fontWeight(.semibold)

          Text("Search for users, feeds, and posts to explore the Bluesky network")
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }

        // Trending topics with liquid glass effect
        VStack(spacing: 16) {
          Text("Trending Topics")
            .font(.headline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)

          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(trendingTopics, id: \.name) { topic in
              Button(action: {
                searchText = topic.name
                Task {
                  await performSearch()
                }
              }) {
                VStack(spacing: 8) {
                  Image(systemName: topic.icon)
                    .font(.title2)
                    .foregroundStyle(.blue)

                  Text(topic.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                  Text(topic.count)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                      RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                )
                .foregroundStyle(.primary)
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(.horizontal, 20)

        // Search history with liquid glass effect
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
              .foregroundStyle(.blue)
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
                    .background(
                      RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                          RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                    )
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(.horizontal, 20)
        }

        // Popular searches with liquid glass effect
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
                  .background(
                    RoundedRectangle(cornerRadius: 12)
                      .fill(Color.gray.opacity(0.1))
                      .overlay(
                        RoundedRectangle(cornerRadius: 12)
                          .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                      )
                  )
                  .foregroundStyle(.primary)
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

  // MARK: - Search Filter
  enum SearchFilter: CaseIterable {
    case users, feeds, posts

    var displayName: String {
      switch self {
      case .users: return "Users"
      case .feeds: return "Feeds"
      case .posts: return "Posts"
      }
    }

    var iconName: String {
      switch self {
      case .users: return "person.2"
      case .feeds: return "list.bullet"
      case .posts: return "doc.text"
      }
    }
  }

  // MARK: - Methods
  private func toggleFilter(_ filter: SearchFilter) {
    if selectedFilters.contains(filter) {
      if selectedFilters.count > 1 {
        selectedFilters.remove(filter)
      }
    } else {
      selectedFilters.insert(filter)
    }
  }

  private func performSearch() async {
    guard !searchText.isEmpty else { return }

    isLoading = true
    defer { isLoading = false }

    // Save to search history
    let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedQuery.isEmpty {
      addToSearchHistory(trimmedQuery)
    }

    await searchService.search(query: trimmedQuery)
    // The search results will be automatically updated via the @Published property
  }

  private func addToSearchHistory(_ query: String) {
    // Remove if already exists
    searchHistory.removeAll { $0.lowercased() == query.lowercased() }

    // Add to beginning
    searchHistory.insert(query, at: 0)

    // Keep only last 10 searches
    if searchHistory.count > 10 {
      searchHistory = Array(searchHistory.prefix(10))
    }
  }

  private func generateSearchSuggestions(for query: String) {
    guard !query.isEmpty else {
      searchSuggestions = []
      showSuggestions = false
      return
    }

    let lowercasedQuery = query.lowercased()

    // Generate suggestions based on search history, popular searches, and trending topics
    var suggestions: Set<String> = []

    // Add matching search history
    suggestions.formUnion(searchHistory.filter { $0.lowercased().contains(lowercasedQuery) })

    // Add matching popular searches
    suggestions.formUnion(popularSearches.filter { $0.lowercased().contains(lowercasedQuery) })

    // Add matching trending topics
    suggestions.formUnion(
      trendingTopics.map { $0.name }.filter { $0.lowercased().contains(lowercasedQuery) })

    // Add common variations
    if lowercasedQuery.count > 2 {
      suggestions.insert("\(query) news")
      suggestions.insert("\(query) latest")
      suggestions.insert("\(query) updates")
    }

    // Limit suggestions and show them
    searchSuggestions = Array(suggestions.prefix(8))
    showSuggestions = !searchSuggestions.isEmpty
  }

  // MARK: - Search Text Change Handler
  private func handleSearchTextChange() {
    if !searchText.isEmpty {
      Task {
        await performSearch()
      }
    } else {
      searchResults = nil
    }
  }

  // MARK: - Helper Methods
  private func totalResultsCount(_ results: SearchResults) -> Int {
    var count = 0
    if selectedFilters.contains(.users) { count += results.users.count }
    if selectedFilters.contains(.feeds) { count += results.feeds.count }
    if selectedFilters.contains(.posts) { count += results.posts.count }
    return count
  }

  // MARK: - Search Data

  private let popularSearches = [
    "Technology",
    "Science",
    "Art",
    "Music",
    "Gaming",
    "News",
    "Sports",
    "Food",
  ]

  private let trendingTopics = [
    TrendingTopic(name: "AI & Tech", count: "2.3K", icon: "cpu"),
    TrendingTopic(name: "Climate", count: "1.8K", icon: "leaf"),
    TrendingTopic(name: "Space", count: "1.5K", icon: "moon.stars"),
    TrendingTopic(name: "Health", count: "1.2K", icon: "heart"),
    TrendingTopic(name: "Education", count: "980", icon: "book"),
    TrendingTopic(name: "Entertainment", count: "850", icon: "tv"),
  ]

  private let searchCategories = [
    SearchCategory(
      title: "Search Posts",
      description: "Find posts by content",
      icon: "doc.text",
      searchTerm: "posts:"
    ),
    SearchCategory(
      title: "Search Users",
      description: "Find people to follow",
      icon: "person.2",
      searchTerm: "users:"
    ),
    SearchCategory(
      title: "Search Feeds",
      description: "Discover new feeds",
      icon: "list.bullet",
      searchTerm: "feeds:"
    ),
  ]

  // MARK: - Helper Functions

  private func createFeedItem(from feedSearchResult: FeedSearchResult) -> FeedItem {
    return FeedItem(
      uri: feedSearchResult.uri,
      displayName: feedSearchResult.displayName,
      description: feedSearchResult.description,
      avatarImageURL: feedSearchResult.avatarURL,
      creatorHandle: feedSearchResult.creatorHandle,
      likesCount: feedSearchResult.likesCount,
      liked: feedSearchResult.isLiked
    )
  }

  private func hasAnyFilteredResults(results: SearchResults) -> Bool {
    return (selectedFilters.contains(.users) && !results.users.isEmpty)
      || (selectedFilters.contains(.feeds) && !results.feeds.isEmpty)
      || (selectedFilters.contains(.posts) && !results.posts.isEmpty)
  }
}

// MARK: - Search Category Model

private struct SearchCategory {
  let title: String
  let description: String
  let icon: String
  let searchTerm: String
}

// MARK: - Trending Topic Model

private struct TrendingTopic {
  let name: String
  let count: String
  let icon: String
}

// MARK: - Search UI Components

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
          .foregroundStyle(.primary)

        Text("@\(user.handle)")
          .font(.caption)
          .foregroundStyle(.secondary)

        if let description = user.description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }

      Spacer()

      // Follow button with liquid glass effect
      Button(action: {
        // TODO: Implement follow functionality
      }) {
        Text(user.isFollowing ? "Following" : "Follow")
          .font(.caption)
          .fontWeight(.medium)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(user.isFollowing ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(
                    user.isFollowing ? Color.green.opacity(0.3) : Color.blue.opacity(0.3),
                    lineWidth: 0.5)
              )
          )
          .foregroundStyle(user.isFollowing ? .green : .blue)
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.gray.opacity(0.05))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    )
    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    .padding(.top, 8)
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
          .foregroundStyle(.primary)

        Text("@\(user.handle)")
          .font(.caption)
          .foregroundStyle(.secondary)

        if let description = user.description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }

      Spacer()

      // Follow button with liquid glass effect
      Button(action: {
        // TODO: Implement follow functionality
      }) {
        Text("Follow")
          .font(.caption)
          .fontWeight(.medium)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.blue.opacity(0.1))
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
              )
          )
          .foregroundStyle(.blue)
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.gray.opacity(0.05))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    )
    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}

private struct PostSearchResultRow: View {
  let post: PostItem

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
            .foregroundStyle(.primary)

          Text("@\(post.author.handle)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Text(post.indexedAt.relativeFormatted)
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }

      // Post content with search highlighting
      Text(post.content)
        .font(.body)
        .lineLimit(3)
        .foregroundStyle(.primary)

      // Engagement metrics with liquid glass effect
      HStack(spacing: 16) {
        HStack(spacing: 4) {
          Image(systemName: "bubble.left")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text("\(post.replyCount)")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
        }

        HStack(spacing: 4) {
          Image(systemName: "arrow.2.squarepath")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text("\(post.repostCount)")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
        }

        HStack(spacing: 4) {
          Image(systemName: "heart")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text("\(post.likeCount)")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
        }

        Spacer()

        // Like button with liquid glass effect
        Button(action: {
          // TODO: Implement like functionality
        }) {
          Image(systemName: post.likeURI != nil ? "heart.fill" : "heart")
            .font(.caption)
            .foregroundStyle(post.likeURI != nil ? .red : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(post.likeURI != nil ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(
                      post.likeURI != nil ? Color.red.opacity(0.3) : Color.gray.opacity(0.3),
                      lineWidth: 0.5)
                )
            )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.gray.opacity(0.05))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    )
    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}

// MARK: - Search Filter Types

enum SearchFilterType: String, CaseIterable {
  case users = "Users"
  case feeds = "Feeds"
  case posts = "Posts"

  var icon: String {
    switch self {
    case .users:
      return "person.2"
    case .feeds:
      return "list.bullet"
    case .posts:
      return "doc.text"
    }
  }
}
