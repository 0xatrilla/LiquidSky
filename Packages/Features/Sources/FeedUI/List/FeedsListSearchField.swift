import Client
import DesignSystem
import FeedUI
import Models
import SwiftUI

public struct FeedsListSearchField: View {
  @Binding var searchText: String
  @Binding var isInSearch: Bool
  var isSearchFocused: FocusState<Bool>.Binding

  @StateObject private var searchService: UnifiedSearchService

  public init(
    searchText: Binding<String>,
    isInSearch: Binding<Bool>,
    isSearchFocused: FocusState<Bool>.Binding,
    client: BSkyClient
  ) {
    _searchText = searchText
    _isInSearch = isInSearch
    self.isSearchFocused = isSearchFocused
    self._searchService = StateObject(wrappedValue: UnifiedSearchService(client: client))
  }

  public var body: some View {
    VStack(spacing: 0) {
      GlassEffectContainer {
        HStack {
          HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search users, posts, feeds...", text: $searchText)
              .focused(isSearchFocused)
              .allowsHitTesting(isInSearch)
              .onChange(of: searchText) { _, newValue in
                if !newValue.isEmpty {
                  Task {
                    await searchService.search(query: newValue)
                  }
                } else {
                  searchService.clearSearch()
                }
              }
          }
          .frame(maxWidth: isInSearch ? .infinity : 100)
          .padding()
          .glassEffect(in: Capsule())

          if isInSearch {
            Button {
              withAnimation {
                isInSearch.toggle()
                isSearchFocused.wrappedValue = false
                searchText = ""
                searchService.clearSearch()
              }
            } label: {
              Image(systemName: "xmark")
                .frame(width: 50, height: 50)
                .foregroundStyle(.blue)
                .glassEffect(in: Circle())
            }
          }
        }
      }
      
      // Search results overlay when searching
      if !searchText.isEmpty && searchService.searchResults.hasResults {
        searchResultsOverlay
      }
    }
  }
  
  private var searchResultsOverlay: some View {
    VStack(spacing: 0) {
      if searchService.isSearching {
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
      } else if searchService.searchResults.hasResults {
        // Search results
        VStack(spacing: 8) {
          // Users section
          if !searchService.searchResults.users.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
              Text("Users (\(searchService.searchResults.users.count))")
                .font(.headline)
                .fontWeight(.semibold)
              ForEach(searchService.searchResults.users) { user in
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
                  .frame(width: 32, height: 32)
                  .clipShape(Circle())
                  
                  // User info
                  VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName ?? user.handle)
                      .font(.body)
                      .fontWeight(.medium)
                    Text("@\(user.handle)")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  
                  Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .onTapGesture {
                  onUserTap(user)
                }
              }
            }
          }
          
          // Feeds section
          if !searchService.searchResults.feeds.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
              Text("Feeds (\(searchService.searchResults.feeds.count))")
                .font(.headline)
                .fontWeight(.semibold)
              ForEach(searchService.searchResults.feeds) { feed in
                HStack(spacing: 12) {
                  // Feed icon
                  Image(systemName: "list.bullet")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
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
                  }
                  
                  Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .onTapGesture {
                  onFeedTap(feed)
                }
              }
            }
          }
          
          // Posts section
          if !searchService.searchResults.posts.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
              Text("Posts (\(searchService.searchResults.posts.count))")
                .font(.headline)
                .fontWeight(.semibold)
              ForEach(searchService.searchResults.posts) { post in
                VStack(alignment: .leading, spacing: 4) {
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
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                    
                    Text(post.author.displayName ?? post.author.handle)
                      .font(.caption)
                      .fontWeight(.medium)
                    Text("@\(post.author.handle)")
                      .font(.caption)
                      .foregroundColor(.secondary)
                    Spacer()
                  }
                  Text(post.content)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .onTapGesture {
                  onPostTap(post)
                }
              }
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(maxHeight: 400)
      }
    }
  }
  
  // MARK: - Search Result Handlers
  
  private func onUserTap(_ user: Profile) {
    // Navigate to user profile
    print("Navigate to user: \(user.handle)")
    // Clear search and navigate to profile
    clearSearch()
    // TODO: Implement navigation using router
  }
  
  private func onFeedTap(_ feed: FeedSearchResult) {
    // Navigate to feed
    print("Navigate to feed: \(feed.displayName)")
    // Clear search and navigate to feed
    clearSearch()
    // TODO: Implement navigation using router
  }
  
  private func onPostTap(_ post: PostItem) {
    // Navigate to post
    print("Navigate to post: \(post.uri)")
    // Clear search and navigate to post detail
    clearSearch()
    // TODO: Implement navigation using router
  }
  
  private func clearSearch() {
    searchText = ""
    searchService.clearSearch()
  }
}
