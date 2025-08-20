import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct SearchView: View {
  @State private var searchService: UnifiedSearchService
  @State private var searchText: String = ""
  @State private var selectedFilters: Set<SearchFilterType> = Set(SearchFilterType.allCases)
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client

  public init() {
    self._searchService = State(initialValue: UnifiedSearchService())
  }

  public var body: some View {
    VStack(spacing: 0) {
      if searchText.isEmpty {
        // Show search suggestions when no search query
        searchSuggestions
      } else if searchService.isSearching {
        // Show loading state
        loadingView
      } else if let error = searchService.searchError {
        // Show error state
        errorView(error: error)
      } else if searchService.searchResults.hasResults {
        // Show search results
        searchResultsView(results: searchService.searchResults)
      } else if !searchText.isEmpty {
        // Show no results
        noResultsView
      }
    }
    .searchable(text: $searchText, prompt: "Search users, posts...")
    .onChange(of: searchText) {
      if !searchText.isEmpty {
        Task {
          await searchService.search(query: searchText)
        }
      }
    }
    .onAppear {
      // Set the client when the view appears
      searchService.client = client
    }
  }

  private var searchSuggestions: some View {
    VStack(spacing: 20) {
      Spacer()

      VStack(spacing: 16) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 48))
          .foregroundStyle(.secondary)

        Text("Search Users & Content")
          .font(.title2)
          .fontWeight(.semibold)

        Text("Find users, discover posts, and explore content across Bluesky")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding()

      Spacer()
    }
  }

  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)
      Text("Searching...")
        .font(.body)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func errorView(error: Error) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(.red)

      Text("Search Error")
        .font(.title2)
        .fontWeight(.semibold)

      Text(error.localizedDescription)
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func searchResultsView(results: SearchResults) -> some View {
    VStack(spacing: 0) {
      if results.hasResults {
        VStack(spacing: 0) {
          // Filter Menu
          HStack {
            Menu {
              // Users filter
              Button(action: {
                if selectedFilters.contains(.users) {
                  if selectedFilters.count > 1 {
                    selectedFilters.remove(.users)
                  }
                } else {
                  selectedFilters.insert(.users)
                }
              }) {
                HStack {
                  Label("Users", systemImage: "person.2")
                  Spacer()
                  if selectedFilters.contains(.users) {
                    Image(systemName: "checkmark")
                      .foregroundColor(.themePrimary)
                      .fontWeight(.semibold)
                  }
                }
              }

              // Feeds filter
              Button(action: {
                if selectedFilters.contains(.feeds) {
                  if selectedFilters.count > 1 {
                    selectedFilters.remove(.feeds)
                  }
                } else {
                  selectedFilters.insert(.feeds)
                }
              }) {
                HStack {
                  Label("Feeds", systemImage: "list.bullet")
                  Spacer()
                  if selectedFilters.contains(.feeds) {
                    Image(systemName: "checkmark")
                      .foregroundColor(.themePrimary)
                      .fontWeight(.semibold)
                  }
                }
              }

              // Posts filter
              Button(action: {
                if selectedFilters.contains(.posts) {
                  if selectedFilters.count > 1 {
                    selectedFilters.remove(.posts)
                  }
                } else {
                  selectedFilters.insert(.posts)
                }
              }) {
                HStack {
                  Label("Posts", systemImage: "doc.text")
                  Spacer()
                  if selectedFilters.contains(.posts) {
                    Image(systemName: "checkmark")
                      .foregroundColor(.themePrimary)
                      .fontWeight(.semibold)
                  }
                }
              }

              Divider()

              Button("Reset Filters") {
                selectedFilters = Set(SearchFilterType.allCases)
              }
            } label: {
              HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                  .font(.system(size: 16))
                Text("Filter")
                  .font(.caption)
                  .fontWeight(.medium)
              }
              .foregroundColor(.themePrimary)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color.themePrimary.opacity(0.1))
              .cornerRadius(16)
            }
            .menuStyle(.borderlessButton)

            Spacer()

            // Active filter count
            if selectedFilters.count < SearchFilterType.allCases.count {
              Text("\(selectedFilters.count) active")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)

          // Filtered Results
          ScrollView {
            LazyVStack(spacing: 16) {
              // Users section
              if selectedFilters.contains(.users) && !results.users.isEmpty {
                SearchSectionHeader(title: "Users", count: results.users.count)
                ForEach(results.users) { user in
                  Button(action: {
                    // Navigate to user profile by switching to profile tab
                    router.selectedTab = .profile
                    // Store the user to navigate to in UserDefaults for now
                    // This is a temporary solution until we can implement proper navigation
                    UserDefaults.standard.set(user.handle, forKey: "search_navigate_to_user")
                    print("Navigate to user: \(user.handle)")
                  }) {
                    UserSearchResultRow(user: user)
                  }
                  .buttonStyle(.plain)
                }
              }

              // Feeds section
              if selectedFilters.contains(.feeds) && !results.feeds.isEmpty {
                SearchSectionHeader(title: "Feeds", count: results.feeds.count)
                ForEach(results.feeds) { feed in
                  Button(action: {
                    // Navigate to feed by switching to feed tab
                    router.selectedTab = .feed
                    // Store the feed to navigate to in UserDefaults for now
                    // This is a temporary solution until we can implement proper navigation
                    UserDefaults.standard.set(feed.uri, forKey: "search_navigate_to_feed")
                    print("Navigate to feed: \(feed.displayName)")
                  }) {
                    FeedSearchResultRow(feed: feed)
                  }
                  .buttonStyle(.plain)
                }
              }

              // Posts section
              if selectedFilters.contains(.posts) && !results.posts.isEmpty {
                SearchSectionHeader(title: "Posts", count: results.posts.count)
                ForEach(results.posts) { post in
                  Button(action: {
                    // Navigate to post by switching to feed tab (posts are displayed in feeds)
                    router.selectedTab = .feed
                    // Store the post to navigate to in UserDefaults for now
                    // This is a temporary solution until we can implement proper navigation
                    UserDefaults.standard.set(post.uri, forKey: "search_navigate_to_post")
                    print("Navigate to post: \(post.uri)")
                  }) {
                    PostSearchResultRow(post: post)
                  }
                  .buttonStyle(.plain)
                }
              }
            }
            .padding(.horizontal, 16)
          }
        }
      } else {
        noResultsView
      }
    }
  }

  private var noResultsView: some View {
    VStack(spacing: 16) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 48))
        .foregroundStyle(.secondary)

      Text("No Results Found")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Try adjusting your search terms or browse different categories")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Search UI Components

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

#Preview {
  NavigationStack {
    SearchView()
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.large)
  }
}
