@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import FeedUI
import Models
import PostUI
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
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client

  // Use singleton directly instead of environment to avoid injection timing issues
  private let postFilterService = PostFilterService.shared

  init(datasource: PostsListViewDatasource) {
    self.datasource = datasource
  }

  public var body: some View {
    VStack(spacing: 0) {
      // Search Results Overlay (when searching)
      if !searchText.isEmpty {
        searchResultsOverlay
      }

      // Feed view with header inside ScrollView
      feedListView
        .opacity(searchText.isEmpty ? 1.0 : 0.3)
        .allowsHitTesting(searchText.isEmpty)
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
      // Title on the left (static, no shrinking)
      VStack(alignment: .leading, spacing: 2) {
        Text(datasource.title)
          .headerTitleShadow()
          .font(.system(size: 34, weight: .bold))
      }
      .offset(x: isInSearch ? -200 : 0)
      .opacity(isInSearch ? 0 : 1)

      Spacer()

      // Search bar on the right (static, no shrinking)
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
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }

  private var searchBarView: some View {
    // Always show the full search bar instead of collapsing
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

  private var feedListView: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 16) {
          // Header at the top of the ScrollView
          headerView

          switch state {
          case .loading, .uninitialized:
            placeholderView
          case .loaded(let posts, let cursor):
            // Group posts by reply chains and render with proper threading
            ForEach(groupPostsByReplyChain(filteredPosts(posts)), id: \.id) { postGroup in
              if postGroup.isReplyChain {
                // Render reply chain with visual connectors
                ReplyChainView(posts: postGroup.posts)
              } else {
                // Render single post normally
                PostRowView(post: postGroup.posts.first!)
              }
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
        // Header will scroll naturally with content
      }
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

  // MARK: - Reply Chain Grouping

  private struct PostGroup: Identifiable {
    let id = UUID()
    let posts: [PostItem]
    let isReplyChain: Bool

    init(posts: [PostItem]) {
      self.posts = posts
      self.isReplyChain = posts.count > 1
    }
  }

  private func groupPostsByReplyChain(_ posts: [PostItem]) -> [PostGroup] {
    var groups: [PostGroup] = []
    var processedURIs = Set<String>()

    for post in posts {
      if processedURIs.contains(post.uri) {
        continue
      }

      if post.isReplyTo {
        // Find the reply chain
        let chain = findReplyChain(for: post, in: posts)
        groups.append(PostGroup(posts: chain))
        // Mark all posts in the chain as processed
        for chainPost in chain {
          processedURIs.insert(chainPost.uri)
        }
      } else {
        // Single post, not part of a reply chain
        groups.append(PostGroup(posts: [post]))
        processedURIs.insert(post.uri)
      }
    }

    return groups
  }

  private func findReplyChain(for post: PostItem, in allPosts: [PostItem]) -> [PostItem] {
    var chain: [PostItem] = []
    var currentPost = post

    // Find the root post (the one that's not a reply)
    while currentPost.isReplyTo {
      if let parent = findParentPost(for: currentPost, in: allPosts) {
        chain.insert(parent, at: 0)
        currentPost = parent
      } else {
        break
      }
    }

    // Add the reply post
    chain.append(post)

    return chain
  }

  private func findParentPost(for post: PostItem, in allPosts: [PostItem]) -> PostItem? {
    // Try to find the parent post using the replyRef if available
    // For now, we'll use a more sophisticated approach that looks for posts
    // that this post might be replying to
    return allPosts.first { potentialParent in
      // Check if this could be the parent based on handle and timing
      potentialParent.uri != post.uri && potentialParent.indexedAt < post.indexedAt
        && (post.inReplyToHandle == nil || potentialParent.author.handle == post.inReplyToHandle)
    }
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

// MARK: - Reply Chain View

private struct ReplyChainView: View {
  let posts: [PostItem]
  @Environment(AppRouter.self) var router

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(posts.enumerated()), id: \.element.uri) { index, post in
        HStack(alignment: .top, spacing: 8) {
          // Avatar column with thread line
          VStack(spacing: 0) {
            // Avatar
            AsyncImage(url: post.author.avatarImageURL) { phase in
              switch phase {
              case .success(let image):
                image
                  .resizable()
                  .scaledToFit()
                  .frame(width: 40, height: 40)
                  .clipShape(Circle())
              default:
                Circle()
                  .fill(.gray.opacity(0.2))
                  .frame(width: 40, height: 40)
              }
            }
            .overlay {
              Circle()
                .stroke(
                  post.hasReply ? LinearGradient.avatarBorderReversed : LinearGradient.avatarBorder,
                  lineWidth: 1)
            }
            .shadow(color: .shadowPrimary.opacity(0.3), radius: 2)
            .onTapGesture {
              router.navigateTo(.profile(post.author))
            }

            // Thread line connector (blue line connecting posts in the chain)
            if index < posts.count - 1 {
              // Create a curved connector line that looks more natural
              Path { path in
                path.move(to: CGPoint(x: 20, y: 40))  // Start at bottom center of avatar
                path.addLine(to: CGPoint(x: 20, y: 56))  // Go down to connect to next post
              }
              .stroke(LinearGradient.blueskyGradient, lineWidth: 2)
              .frame(width: 40, height: 16)
            }
          }
          .frame(width: 40)  // Ensure consistent width for avatar column

          // Post content
          VStack(alignment: .leading, spacing: 8) {
            // Author info
            HStack(alignment: .firstTextBaseline) {
              Text("\(post.author.displayName ?? "")  @\(post.author.handle)")
                .font(.callout)
                .foregroundStyle(.primary)
                .fontWeight(.semibold)
              Spacer()
              Text(post.indexedAt.relativeFormatted)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .onTapGesture {
              router.navigateTo(.profile(post.author))
            }

            // Reply indicator
            if post.isReplyTo, let toHandle = post.inReplyToHandle {
              Text("Replying to @\(toHandle)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Repost indicator - show who reposted this content
            if post.isReposted, let repostedBy = post.repostedBy {
              HStack(spacing: 4) {
                Image(systemName: "arrow.2.squarepath")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                Text("Reposted by \(repostedBy.displayName ?? repostedBy.handle)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }

            // Post content
            if !post.content.isEmpty {
              Text(post.content)
                .font(.body)
                .foregroundStyle(.primary)
            }

            // Embed content (images, videos, etc.)
            if post.embed != nil {
              // Simple embed indicator without complex property access
              HStack(spacing: 8) {
                Image(systemName: "paperclip")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                Text("Media")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .padding(8)
              .background(.ultraThinMaterial)
              .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Simple actions display (only for the last post in the chain)
            if index == posts.count - 1 {
              HStack(spacing: 16) {
                // Reply count
                Label("\(post.replyCount)", systemImage: "bubble.left")
                  .font(.caption)
                  .foregroundStyle(.secondary)

                // Repost count
                Label("\(post.repostCount)", systemImage: "arrow.2.squarepath")
                  .font(.caption)
                  .foregroundStyle(.secondary)

                // Like count
                Label("\(post.likeCount)", systemImage: "heart")
                  .font(.caption)
                  .foregroundStyle(.secondary)

                Spacer()
              }
              .padding(.top, 8)
            }
          }
          .padding(.bottom, 18)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(
          .init(top: 0, leading: 14, bottom: 0, trailing: 14)
        )
        .contentShape(Rectangle())
        .onTapGesture {
          router.navigateTo(.post(post))
        }
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(.quaternary, lineWidth: 0.5)
        )
    )
    .padding(.horizontal, 4)
    .padding(.vertical, 8)
  }
}
