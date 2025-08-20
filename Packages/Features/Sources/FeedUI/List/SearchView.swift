import ATProtoKit
import Client
import DesignSystem
import Models
import SwiftUI

public struct SearchView: View {
  @State private var searchService: UnifiedSearchService
  @State private var searchText: String = ""

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
        SearchResultsView(
          searchResults: results,
          onUserTap: { user in
            // Handle user tap - navigate to profile
            print("User tapped: \(user.handle)")
          },
          onFeedTap: { feed in
            // Handle feed tap - navigate to feed
            print("Feed tapped: \(feed.displayName)")
          },
          onPostTap: { post in
            // Handle post tap - navigate to post detail
            print("Post tapped: \(post.uri)")
          }
        )
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
}

// MARK: - Search Category Model

private struct SearchCategory {
  let title: String
  let description: String
  let icon: String
  let searchTerm: String
}

#Preview {
  NavigationStack {
    SearchView()
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.large)
  }
}
