import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct UserSearchView: View {
  @StateObject private var searchService: UserSearchService
  @State private var searchText = ""
  @Environment(\.dismiss) private var dismiss

  public init(client: BSkyClient) {
    self._searchService = StateObject(wrappedValue: UserSearchService(client: client))
  }

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Search Bar
        searchBar

        // Results
        if searchService.isSearching {
          loadingView
        } else if let error = searchService.searchError {
          errorView(error: error)
        } else if searchService.searchResults.isEmpty && !searchText.isEmpty {
          emptyStateView
        } else if searchService.searchResults.isEmpty {
          initialStateView
        } else {
          searchResultsList
        }
      }
      .navigationTitle("Search Users")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        #if os(iOS)
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
              dismiss()
            }
          }
        #else
          ToolbarItem(placement: .primaryAction) {
            Button("Done") {
              dismiss()
            }
          }
        #endif
      }
    }
  }

  // MARK: - Search Bar

  private var searchBar: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)

      TextField("Search users...", text: $searchText)
        .textFieldStyle(.plain)
        .onSubmit {
          Task {
            await searchService.search(query: searchText)
          }
        }

      if !searchText.isEmpty {
        Button("Clear") {
          searchText = ""
          searchService.clearSearch()
        }
        .foregroundColor(.secondary)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.gray.opacity(0.1))
    .cornerRadius(10)
    .padding(.horizontal)
    .padding(.top)
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
        .font(.system(size: 50))
        .foregroundColor(.red)

      Text("Search Error")
        .font(.title2)
        .fontWeight(.semibold)

      Text(error.localizedDescription)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button("Try Again") {
        Task {
          await searchService.search(query: searchText)
        }
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Empty State

  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "person.2")
        .font(.system(size: 50))
        .foregroundColor(.secondary)

      Text("No Users Found")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Try adjusting your search terms")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Initial State

  private var initialStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 50))
        .foregroundColor(.secondary)

      Text("Search for Users")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Enter a username or display name to find users")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Search Results List

  private var searchResultsList: some View {
    List(searchService.searchResults) { profile in
      UserSearchResultView(profile: profile)
    }
    .listStyle(.plain)
  }
}

#Preview {
  Text("UserSearchView Preview")
    .padding()
}
