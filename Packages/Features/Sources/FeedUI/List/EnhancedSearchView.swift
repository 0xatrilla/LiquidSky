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
  @State private var semanticSearchService: SemanticSearchService
  @State private var searchText = ""
  @State private var selectedFilter: SearchFilter = .all
  @State private var searchHistory: [String] = []
  @State private var debounceTask: Task<Void, Never>?
  @State private var searchIntent: SearchIntent?
  @State private var semanticResults: [SemanticSearchResult] = []
  @State private var isSemanticSearchEnabled = true
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @Environment(\.currentTab) var currentTab

  public init(client: BSkyClient) {
    self._searchService = State(initialValue: UnifiedSearchService(client: client))
    self._trendingContentService = State(initialValue: TrendingContentService(client: client))
    self._semanticSearchService = State(initialValue: SemanticSearchService.shared)
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
      // Debounce to avoid firing a request on every keystroke
      debounceTask?.cancel()
      guard !newValue.isEmpty else { return }
      debounceTask = Task { @MainActor in
        try? await Task.sleep(nanoseconds: 300_000_000)
        if !Task.isCancelled { await performSearch() }
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

            Button(action: {
              Task {
                await trendingContentService.fetchTrendingContent()
              }
            }) {
              Image(systemName: "arrow.clockwise")
                .font(.caption)
                .foregroundColor(.blue)
            }
            .disabled(trendingContentService.isLoading)

            if trendingContentService.isLoading {
              ProgressView()
                .scaleEffect(0.8)
            }
          }

          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(trendingContentService.trendingHashtags.isEmpty ? fallbackHashtags : trendingContentService.trendingHashtags, id: \.tag) { hashtag in
              Button(action: {
                let hashtagWithoutHash =
                  hashtag.tag.hasPrefix("#") ? String(hashtag.tag.dropFirst()) : hashtag.tag
                // Force navigation within the current tab (search/compose)
                router[.compose].append(.hashtag(hashtagWithoutHash))
              }) {
                VStack(spacing: 8) {
                  HStack {
                    Text("#\(hashtag.tag)")
                      .font(.caption)
                      .fontWeight(.medium)
                      .lineLimit(1)

                    Spacer()

                    if hashtag.isTrending {
                      Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    }
                  }

                  Text("\(hashtag.usageCount) posts")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
              }
              .buttonStyle(.plain)
            }
          }
        }

        // Suggested users section
        VStack(spacing: 16) {
          HStack {
            Text("Suggested Users")
              .font(.headline)
              .fontWeight(.semibold)

            Spacer()

            Button(action: {
              Task {
                await trendingContentService.fetchTrendingContent()
              }
            }) {
              Image(systemName: "arrow.clockwise")
                .font(.caption)
                .foregroundColor(.blue)
            }
            .disabled(trendingContentService.isLoading)

            if trendingContentService.isLoading {
              ProgressView()
                .scaleEffect(0.8)
            }
          }

          if trendingContentService.isLoading {
            HStack {
              ProgressView()
              Text("Loading suggested users...")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
          } else if !trendingContentService.suggestedUsers.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 12) {
                ForEach(trendingContentService.suggestedUsers.prefix(8)) { user in
                  SuggestedUserCard(
                    user: user,
                    onProfileTap: {
                      router[.compose].append(.profile(user))
                    },
                    onFollowTap: {
                      Task {
                        await toggleFollow(user: user)
                      }
                    }
                  )
                }
              }
              .padding(.horizontal, 20)
            }
          } else {
            Text("No suggested users available")
              .font(.caption)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity)
              .padding()
          }
        }

        // Popular searches section
        VStack(spacing: 16) {
          HStack {
            Text("Popular Searches")
              .font(.headline)
              .fontWeight(.semibold)

            Spacer()
          }

          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(popularSearches, id: \.self) { search in
              Button(action: {
                searchText = search
                Task {
                  await performSearch()
                }
              }) {
                HStack {
                  Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.secondary)

                  Text(search)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                  Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
              }
              .buttonStyle(.plain)
            }
          }
        }

        // Search history section
        if !searchHistory.isEmpty {
          VStack(spacing: 16) {
            HStack {
              Text("Recent Searches")
                .font(.headline)
                .fontWeight(.semibold)

              Spacer()

              Button("Clear") {
                searchHistory.removeAll()
              }
              .font(.caption)
              .foregroundColor(.blue)
            }

            LazyVStack(spacing: 8) {
              ForEach(searchHistory.prefix(5), id: \.self) { query in
                Button(action: {
                  searchText = query
                  Task {
                    await performSearch()
                  }
                }) {
                  HStack {
                    Image(systemName: "clock")
                      .font(.caption)
                      .foregroundColor(.secondary)

                    Text(query)
                      .font(.body)
                      .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "arrow.up.left")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  .padding(.vertical, 8)
                  .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
              }
            }
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 40)
    }
    .refreshable {
      await trendingContentService.fetchTrendingContent()
    }
  }

  // MARK: - Search Results View
  private var searchResultsView: some View {
    Group {
      if searchService.isSearching {
        loadingView
      } else if let error = searchService.searchError {
        errorView(error: error)
      } else if !searchService.searchResults.hasResults && semanticResults.isEmpty {
        noResultsView
      } else {
        VStack(spacing: 0) {
          // Semantic Search Results
          if isSemanticSearchEnabled && !semanticResults.isEmpty {
            semanticSearchResultsView
          }
          
          // Traditional Search Results
          if searchService.searchResults.hasResults {
            UnifiedSearchResultsView(searchService: searchService)
          }
        }
      }
    }
  }
  
  // MARK: - Semantic Search Results View
  private var semanticSearchResultsView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "sparkles")
          .foregroundColor(.blue)
        Text("AI-Powered Results")
          .font(.headline)
          .fontWeight(.semibold)
        
        Spacer()
        
        Button("Hide") {
          isSemanticSearchEnabled = false
        }
        .font(.caption)
        .foregroundColor(.secondary)
      }
      .padding(.horizontal)
      .padding(.top)
      
      if let intent = searchIntent {
        HStack {
          Text("Looking for: \(intent.intent.rawValue.capitalized)")
            .font(.caption)
            .foregroundColor(.secondary)
          
          if intent.isQuestion {
            Text("• Question")
              .font(.caption)
              .foregroundColor(.blue)
          }
          
          Spacer()
        }
        .padding(.horizontal)
      }
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(semanticResults.prefix(5)) { result in
            SemanticSearchResultCard(result: result) {
              handleSemanticResultTap(result)
            }
          }
        }
        .padding(.horizontal)
      }
    }
    .background(Color(.systemGray6))
    .cornerRadius(12)
    .padding(.horizontal)
  }

  // MARK: - Loading View
  private var loadingView: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)

      Text("Searching...")
        .font(.headline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Error View
  private func errorView(error: Error) -> some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 64))
        .foregroundColor(.orange)

      Text("Search Error")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Unable to search at the moment. Please check your connection and try again.")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button("Try Again") {
        Task {
          await performSearch()
        }
      }
      .buttonStyle(.borderedProminent)
      
      Button("Browse Trending Content") {
        searchText = ""
      }
      .buttonStyle(.bordered)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 40)
  }

  // MARK: - No Results View
  private var noResultsView: some View {
    VStack(spacing: 20) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 64))
        .foregroundColor(.secondary)

      Text("No Results Found")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Try adjusting your search terms or browse trending content below")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      VStack(spacing: 12) {
        Button("Clear Search") {
          searchText = ""
        }
        .buttonStyle(.borderedProminent)
        
        Button("Browse Trending Content") {
          searchText = ""
        }
        .buttonStyle(.bordered)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 40)
  }

  // MARK: - Helper Methods
  private func toggleFilter(_ filter: SearchFilter) {
    selectedFilter = filter
    if !searchText.isEmpty {
      Task {
        await performSearch()
      }
    }
  }

  private func performSearch() async {
    guard !searchText.isEmpty else { return }

    addToSearchHistory(searchText)

    // Perform traditional search
    await searchService.search(query: searchText)
    
    // Perform semantic search if enabled
    if isSemanticSearchEnabled {
      await performSemanticSearch()
    }
  }
  
  private func performSemanticSearch() async {
    // Get available posts and users for semantic search
    let posts = searchService.searchResults.posts
    let users = searchService.searchResults.users
    
    // Analyze search intent
    searchIntent = await semanticSearchService.extractSearchIntent(from: searchText)
    
    // Perform semantic search
    semanticResults = await semanticSearchService.performSemanticSearch(
      query: searchText,
      posts: posts,
      users: users
    )
  }
  
  private func handleSemanticResultTap(_ result: SemanticSearchResult) {
    switch result.type {
    case .post:
      if let post = result.post {
        router[currentTab].append(.post(post))
      }
    case .user:
      if let user = result.user {
        router[currentTab].append(.profile(user))
      }
    case .topic:
      // Handle topic search
      searchText = result.matchedContent
      Task { await performSearch() }
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
    // Generate search suggestions based on current text
    let suggestions = popularSearches.filter { $0.lowercased().contains(searchText.lowercased()) }
    return Array(suggestions.prefix(5))
  }

  private func totalResultsCount() -> Int {
    searchService.searchResults.posts.count + searchService.searchResults.users.count
      + searchService.searchResults.feeds.count
  }

  private func hasAnyFilteredResults() -> Bool {
    switch selectedFilter {
    case .all:
      return totalResultsCount() > 0
    case .posts:
      return !searchService.searchResults.posts.isEmpty
    case .users:
      return !searchService.searchResults.users.isEmpty
    case .feeds:
      return !searchService.searchResults.feeds.isEmpty
    }
  }

  private let popularSearches = [
    "bluesky", "tech", "art", "music", "photography",
    "science", "gaming", "food", "travel", "books",
    "fitness", "cooking", "design", "writing", "podcasts",
  ]
  
  // MARK: - Follow Functionality
  private func toggleFollow(user: Profile) async {
    do {
      if user.isFollowing {
        // Unfollow user - get the follow URI first
        let profileData = try await client.protoClient.getProfile(for: user.did)
        if let followingURI = profileData.viewer?.followingURI {
          try await client.blueskyClient.deleteRecord(.recordURI(atURI: followingURI))
          
          // Update the user in the suggested users list
          if let index = trendingContentService.suggestedUsers.firstIndex(where: { $0.did == user.did }) {
            let updatedUser = Profile(
              did: user.did,
              handle: user.handle,
              displayName: user.displayName,
              avatarImageURL: user.avatarImageURL,
              description: user.description,
              followersCount: user.followersCount,
              followingCount: user.followingCount,
              postsCount: user.postsCount,
              isFollowing: false,
              isFollowedBy: user.isFollowedBy,
              isBlocked: user.isBlocked,
              isBlocking: user.isBlocking,
              isMuted: user.isMuted
            )
            trendingContentService.suggestedUsers[index] = updatedUser
          }
        }
      } else {
        // Follow user using existing service logic to avoid SDK inconsistencies
        let service = ListMemberActionsService(client: client)
        _ = try await service.followUser(did: user.did)

        // Update the user in the suggested users list
        if let index = trendingContentService.suggestedUsers.firstIndex(where: { $0.did == user.did }) {
          let updatedUser = Profile(
            did: user.did,
            handle: user.handle,
            displayName: user.displayName,
            avatarImageURL: user.avatarImageURL,
            description: user.description,
            followersCount: user.followersCount,
            followingCount: user.followingCount,
            postsCount: user.postsCount,
            isFollowing: true,
            isFollowedBy: user.isFollowedBy,
            isBlocked: user.isBlocked,
            isBlocking: user.isBlocking,
            isMuted: user.isMuted
          )
          trendingContentService.suggestedUsers[index] = updatedUser
        }
      }
    } catch {
      #if DEBUG
      print("EnhancedSearchView: Failed to toggle follow: \(error)")
      #endif
    }
  }
}

// MARK: - Filter Button
struct FilterButton: View {
  let filter: SearchFilter
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(filter.title)
        .font(.caption)
        .fontWeight(.medium)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(isSelected ? Color.blue : Color(.systemGray5))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Suggested User Card
struct SuggestedUserCard: View {
  let user: Profile
  let onProfileTap: () -> Void
  let onFollowTap: () -> Void
  
  @State private var isFollowing = false
  
  var body: some View {
    VStack(spacing: 8) {
      Button(action: onProfileTap) {
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
      }
      .buttonStyle(.plain)

      VStack(spacing: 2) {
        Text(user.displayName ?? user.handle)
          .font(.caption)
          .fontWeight(.medium)
          .lineLimit(1)

        Text("@\(user.handle)")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      
      Button(action: onFollowTap) {
        Text(user.isFollowing ? "Following" : "Follow")
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundColor(user.isFollowing ? .secondary : .white)
          .padding(.horizontal, 12)
          .padding(.vertical, 4)
          .background(
            RoundedRectangle(cornerRadius: 6)
              .fill(user.isFollowing ? Color(.systemGray5) : Color.blue)
          )
      }
      .buttonStyle(.plain)
    }
    .frame(width: 80)
    .padding(.vertical, 8)
    .background(Color(.systemGray6))
    .cornerRadius(12)
    .onAppear {
      isFollowing = user.isFollowing
    }
    .onChange(of: user.isFollowing) { _, newValue in
      isFollowing = newValue
    }
  }
}
