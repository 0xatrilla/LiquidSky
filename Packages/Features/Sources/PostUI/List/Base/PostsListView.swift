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
  @State private var isInSearch = false
  @State private var searchResults = SearchResults()
  @State private var isSearching = false
  @State private var searchService: UnifiedSearchService?
  @FocusState var isSearchFocused: Bool
  @State private var scrollOffset: CGFloat = 0
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client

  // Use singleton directly instead of environment to avoid injection timing issues
  private let postFilterService = PostFilterService.shared

  init(datasource: PostsListViewDatasource) {
    self.datasource = datasource
  }

  public var body: some View {
    ZStack(alignment: .top) {
      // Feed content in the background
      VStack(spacing: 0) {
        // Invisible spacer to push content down behind header
        Color.clear
          .frame(height: 120) // Adjust based on header height
        
        feedListView
          .opacity(searchText.isEmpty ? 1.0 : 0.3)
          .allowsHitTesting(searchText.isEmpty)
      }
      
      // Liquid glass header overlay
      VStack(spacing: 0) {
        headerView
          .padding(.horizontal, 16)
          .padding(.top, 8)
          .padding(.bottom, 16)
          .background(
            // Liquid glass effect with blur and material
            RoundedRectangle(cornerRadius: 0)
              .fill(.ultraThinMaterial)
              .overlay(
                // Subtle border for definition
                Rectangle()
                  .stroke(.white.opacity(0.1), lineWidth: 0.5)
              )
              .background(
                // Additional blur for depth
                Rectangle()
                  .fill(.ultraThinMaterial)
                  .blur(radius: 20)
              )
          )
          .clipShape(Rectangle())
        
        Spacer()
      }
    }
    .screenContainer()
    .scrollDismissesKeyboard(.immediately)
    .task {
      if case .uninitialized = state {
        state = .loading
        state = await datasource.loadPosts(with: state)
      }
    }
    .onAppear {
      setupSearchService()
    }
    .refreshable {
      state = .loading
      state = await datasource.loadPosts(with: state)
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

  private var headerView: some View {
    HStack(alignment: .center) {
      // Title on the left (shrinks to top when scrolling)
      VStack(alignment: .leading, spacing: 2) {
        Text(datasource.title)
          .headerTitleShadow()
          .font(.system(size: max(28, 34 - scrollOffset * 0.1), weight: .bold))
          .scaleEffect(max(0.8, 1.0 - scrollOffset * 0.002))
          .opacity(max(0.6, 1.0 - scrollOffset * 0.003))
      }
      .offset(x: isInSearch ? -200 : 0)
      .opacity(isInSearch ? 0 : 1)

      Spacer()

      // Search bar on the right (shrinks to magnifying glass when scrolling)
      searchBarView
        .padding(.leading, isInSearch ? -120 : 0)
        .contentShape(Rectangle())
        .onTapGesture {
          withAnimation(.bouncy) {
            isInSearch.toggle()
            isSearchFocused = true
          }
        }
        .transition(.slide)
    }
    .animation(.bouncy, value: isInSearch)
    .animation(.easeOut(duration: 0.2), value: scrollOffset)
  }

  private var searchBarView: some View {
    Group {
      if scrollOffset > 50 && !isInSearch {
        // Shrunken magnifying glass icon when scrolling
        Button {
          withAnimation(.bouncy) {
            isInSearch = true
            isSearchFocused = true
          }
        } label: {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.blue)
            .frame(width: 44, height: 44)
            .glassEffect(in: Circle())
        }
        .buttonStyle(.plain)
      } else {
        // Full search bar when not scrolling or when focused
        GlassEffectContainer {
          HStack {
            HStack {
              Image(systemName: "magnifyingglass")
              TextField("Search Users...", text: $searchText)
                .focused($isSearchFocused)
                .allowsHitTesting(isInSearch)
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
            .frame(maxWidth: isInSearch ? .infinity : 100)
            .padding()
            .glassEffect(in: Capsule())

            if isInSearch {
              Button {
                withAnimation {
                  isInSearch.toggle()
                  isSearchFocused = false
                  searchText = ""
                  clearSearch()
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
      }
    }
  }

  private var feedListView: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 16) {
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
        .padding(.horizontal, 16)
      }
      .onAppear {
        scrollOffset = 0
      }
      .simultaneousGesture(
        DragGesture()
          .onChanged { value in
            let newOffset = max(0, -value.translation.height)
            scrollOffset = newOffset
          }
          .onEnded { value in
            // Keep the final scroll offset for visual effects
            let finalOffset = max(0, -value.translation.height)
            scrollOffset = finalOffset
          }
      )
    }
  }

  private func setupSearchService() {
    // Use the client from environment
    searchService = UnifiedSearchService(client: client)
  }

  private func performSearch() async {
    guard let searchService = searchService else { return }

    isSearching = true

    // Search for all types but we'll only display users
    await searchService.search(query: searchText)

    // Update our local state with only user results
    await MainActor.run {
      searchResults = SearchResults(
        posts: [],
        users: searchService.searchResults.users,
        feeds: []
      )
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
            // Users section only
            if !searchResults.users.isEmpty {
              SearchSectionHeader(title: "Users", count: searchResults.users.count)
              ForEach(searchResults.users) { user in
                UserSearchResultRow(user: user)
                  .onTapGesture {
                    onUserTap(user)
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
