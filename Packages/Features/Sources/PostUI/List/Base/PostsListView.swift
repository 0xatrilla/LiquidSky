@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import NukeUI
import SwiftUI
import User

// MARK: - Standalone Functions

public func processFeed(
  _ feed: [AppBskyLexicon.Feed.FeedViewPostDefinition], client: ATProtoKit
) async -> [PostItem] {
  var postItems: [PostItem] = []
  var processedCount = 0
  var missingParentURIs = Set<String>()
  var replyToParentMap: [String: String] = [:]  // reply URI -> parent URI

  func insert(
    post: AppBskyLexicon.Feed.PostViewDefinition,
    fromFeedItem: AppBskyLexicon.Feed.FeedViewPostDefinition
  ) {
    // Add safety check to prevent crash if uri is nil
    guard !post.uri.isEmpty else {
      return
    }

    guard !postItems.contains(where: { $0.uri == post.uri }) else {
      return
    }

    // Use the FeedViewPostDefinition.postItem extension to get repost information
    let item = fromFeedItem.postItem
    // hasReply is already set correctly from replyRef in the PostItem initializer
    postItems.append(item)
    processedCount += 1
  }

  // First pass: process all posts and identify missing parents
  for (_, post) in feed.enumerated() {
    // Pass both the post and the feed item to get repost information
    insert(post: post.post, fromFeedItem: post)

    // Check if this is a reply and identify missing parent
    let postItem = post.postItem
    if let replyRef = postItem.replyRef {
      let parentURI = replyParentURI(from: replyRef)
      if let parentURI = parentURI {
        // Check if parent is already in the current feed
        let parentExists = feed.contains { $0.post.uri == parentURI }
        if !parentExists {
          missingParentURIs.insert(parentURI)
          replyToParentMap[postItem.uri] = parentURI
        }
      }
    }

    // Note: The reply field indicates that a reply exists, but doesn't contain the reply post data
    // The main posts already have the reply information they need (isReplyTo, replyRef, etc.)

    // Process repost - simplified to avoid type issues
    if post.reason != nil {
      // TODO: Implement proper reply processing when we understand the type structure
    }
  }

  // Second pass: fetch missing parent posts and insert them above their replies
  if !missingParentURIs.isEmpty {
    do {
      let parentURIs = Array(missingParentURIs)
      let parentPosts = try await client.getPosts(parentURIs)

      // Insert parent posts above their replies
      for (replyURI, parentURI) in replyToParentMap {
        if let parentPost = parentPosts.posts.first(where: { $0.uri == parentURI }) {
          // Find the reply post index
          if let replyIndex = postItems.firstIndex(where: { $0.uri == replyURI }) {
            // Create PostItem from parent post
            let parentPostItem = parentPost.postItem
            postItems.insert(parentPostItem, at: replyIndex)
            processedCount += 1
          }
        }
      }
    } catch {
      // Handle error silently - missing parent posts are not critical
    }
  }

  return postItems
}

private func replyParentURI(from replyRef: AppBskyLexicon.Feed.PostRecord.ReplyReference)
  -> String?
{
  let mirror = Mirror(reflecting: replyRef)

  func extractURI(from value: Any) -> String? {
    let m = Mirror(reflecting: value)
    for child in m.children {
      if let label = child.label {
        if label == "recordURI", let uri = child.value as? String {
          return uri
        }
        if label == "uri", let uri = child.value as? String {
          return uri
        }
      }
    }
    return nil
  }

  // Prefer parent.uri
  if let parentChild = mirror.children.first(where: { $0.label == "parent" }),
    let parentURI = extractURI(from: parentChild.value)
  {
    return parentURI
  }
  // Fallback to root.uri
  if let rootChild = mirror.children.first(where: { $0.label == "root" }),
    let rootURI = extractURI(from: rootChild.value)
  {
    return rootURI
  }

  return nil
}

public struct PostListView<T: PostsListViewDatasource>: View {
  @Environment(BSkyClient.self) var client
  @Environment(PostContextProvider.self) var postDataControllerProvider
  @Environment(PostFilterService.self) var postFilterService
  @Environment(AppRouter.self) var router

  let datasource: T
  @State private var state: PostsListViewState = .uninitialized
  @State private var showingSummary = false
  @State private var summaryText: String?
  @State private var newPostsCount = 0
  @State private var previousPostsCount = 0

  @StateObject private var simpleSummaryService = SimpleSummaryService()

  public init(datasource: T) {
    self.datasource = datasource
  }

  public var body: some View {
    feedListView
      .scrollDismissesKeyboard(.immediately)
      .scrollContentBackground(.hidden)
      .scrollIndicators(.hidden)
      .task {
        if case .uninitialized = state {
          state = .loading
          do {
            state = try await datasource.loadPosts(with: state)
          } catch {
            state = .error(error)
          }
        }
      }
      .onAppear {
        // Handle any onAppear logic if needed
      }
      .refreshable {
        // Prevent multiple simultaneous refreshes
        guard case .loaded(let currentPosts, let currentCursor) = state else { return }

        // Track previous post count to detect new posts
        previousPostsCount = currentPosts.count

        do {
          state = .loading
          state = try await datasource.loadPosts(with: state)

          // Check for new posts and offer summary if 10+
          if case .loaded(let newPosts, _) = state {
            newPostsCount = newPosts.count - previousPostsCount
            if newPostsCount >= 10 {
              await offerSummary(for: Array(newPosts.prefix(newPostsCount)))
            }
          }
        } catch {
          // Handle refresh errors gracefully - restore previous state for all errors
          // Pull-to-refresh should be resilient to network issues and not show errors
          if (error as? CancellationError) != nil {
            // Task was cancelled, restore previous loaded state
            state = .loaded(posts: currentPosts, cursor: currentCursor)
            return
          }
          // For other errors during pull-to-refresh, restore previous state
          // Users expect pull-to-refresh to be resilient to temporary network issues
          state = .loaded(posts: currentPosts, cursor: currentCursor)
        }
      }
      .sheet(isPresented: $showingSummary) {
        if let summaryText = summaryText {
          SummarySheetView(
            title: "Feed Summary",
            summary: summaryText,
            itemCount: newPostsCount,
            onDismiss: { showingSummary = false }
          )
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
            // Show summary button if there are 10+ new posts
            if newPostsCount >= 10 {
              SummaryButtonView(itemCount: newPostsCount) {
                showingSummary = true
              }
              .padding(.horizontal, 16)
            }

            // Group posts by reply chains and render with proper threading
            let filteredPosts = filteredPosts(posts)
            let postGroups = groupPostsByReplyChain(filteredPosts)

            ForEach(postGroups, id: \.id) { postGroup in
              if postGroup.isReplyChain {
                // Render reply chain with visual connectors
                ReplyChainView(posts: postGroup.posts)
              } else {
                // Render single post normally with NavigationLink for proper navigation
                NavigationLink(value: RouterDestination.post(postGroup.posts.first!)) {
                  PostRowView(post: postGroup.posts.first!)
                    .environment(\.handleOwnNavigation, false)
                }
                .buttonStyle(.plain)
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

              // Don't show "cancelled" for cancellation errors
              if (error as? CancellationError) == nil {
                Text(error.localizedDescription)
                  .font(.body)
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.center)
              }

              Button("Try Again") {
                Task {
                  state = .loading
                  do {
                    state = try await datasource.loadPosts(with: state)
                  } catch {
                    state = .error(error)
                  }
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

  private func filteredPosts(_ posts: [PostItem]) -> [PostItem] {
    return postFilterService.filterPosts(posts)
  }

  private func groupPostsByReplyChain(_ posts: [PostItem]) -> [PostGroup] {
    var groups: [PostGroup] = []
    var processedURIs = Set<String>()

    // First pass: identify all reply chains to avoid processing parents twice
    var replyChains: [(parent: PostItem, reply: PostItem)] = []
    for post in posts {
      if post.isReplyTo, let parent = findParentPost(for: post, in: posts) {
        replyChains.append((parent: parent, reply: post))
      }
    }

    // Second pass: create groups, prioritizing reply chains
    for post in posts {

      if processedURIs.contains(post.uri) {
        continue
      }

      // Check if this post is part of a reply chain
      if let replyChain = replyChains.first(where: {
        $0.parent.uri == post.uri || $0.reply.uri == post.uri
      }) {
        if !processedURIs.contains(replyChain.parent.uri)
          && !processedURIs.contains(replyChain.reply.uri)
        {
          groups.append(
            PostGroup(posts: [replyChain.parent, replyChain.reply], isReplyChain: true))
          processedURIs.insert(replyChain.parent.uri)
          processedURIs.insert(replyChain.reply.uri)
        }
      } else {
        // Not part of a reply chain, add as single post
        groups.append(PostGroup(posts: [post], isReplyChain: false))
        processedURIs.insert(post.uri)
      }
    }

    // print("PostsListView: Created \(groups.count) groups")
    return groups
  }

  private func findParentPost(for post: PostItem, in allPosts: [PostItem]) -> PostItem? {
    // Require a concrete parent URI; do not guess by handle to avoid incorrect threads
    guard let replyRef = post.replyRef else {
      return nil
    }

    guard let parentURI = replyParentURI(from: replyRef) else {
      return nil
    }

    let parent = allPosts.first(where: { $0.uri == parentURI })
    return parent
  }

  private struct PostGroup: Identifiable {
    let id = UUID()
    let posts: [PostItem]
    let isReplyChain: Bool

    init(posts: [PostItem], isReplyChain: Bool) {
      self.posts = posts
      self.isReplyChain = isReplyChain
    }
  }

  private var nextPageView: some View {
    HStack {
      ProgressView()
    }
    .task {
      do {
        state = try await datasource.loadPosts(with: state)
      } catch {
        state = .error(error)
      }
    }
  }

  private var placeholderView: some View {
    ForEach(PostItem.placeholders) { post in
      PostRowView(post: post)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }
  }

  private func offerSummary(for newPosts: [PostItem]) async {
    let summary = await simpleSummaryService.summarizeNewPosts(newPosts.count)
    summaryText = summary
    showingSummary = true
  }
}

// MARK: - Reply Chain View

private struct ReplyChainView: View {
  let posts: [PostItem]
  @Environment(AppRouter.self) var router
  @Environment(PostContextProvider.self) var postDataControllerProvider
  @Environment(BSkyClient.self) var client

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

            // Thread line connector (theme-aware line connecting posts in the chain)
            // Show thread lines for posts that have replies below them
            // The line should connect downward from a parent post to its reply
            if index < posts.count - 1 && post.hasReply {
              Rectangle()
                .fill(LinearGradient.themeGradient)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
                .padding(.top, 8)  // Start below the avatar
                .padding(.bottom, -20)  // Extend well below to connect with reply post above
            }
          }
          .frame(width: 40)  // Ensure consistent width for avatar column

          // Post content wrapped in NavigationLink for proper navigation
          NavigationLink(value: RouterDestination.post(post)) {
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

              // Repost indicator
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

              // Post text
              Text(post.content)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

              // Embed content (proper media display)
              PostRowEmbedView(post: post)

              // Actions (use same PostRowActionsView as normal posts for consistency)
              PostRowActionsView(post: post)
                .environment(postDataControllerProvider.get(for: post, client: client))
            }
          }
          .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
      }
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 8)
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

private struct PostSearchResultRow: View {
  let post: PostItem

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Author info
      HStack(spacing: 8) {
        LazyImage(url: post.author.avatarImageURL) { state in
          if let image = state.image {
            image
              .resizable()
              .scaledToFit()
          } else {
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
  // This extension is intentionally empty as the processFeed function was moved to be standalone
}
