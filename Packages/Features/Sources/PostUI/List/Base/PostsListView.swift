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
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client

  // Use singleton directly instead of environment to avoid injection timing issues
  private let postFilterService = PostFilterService.shared

  init(datasource: PostsListViewDatasource) {
    self.datasource = datasource
  }

  public var body: some View {
    VStack(spacing: 0) {
      // Feed view with header inside ScrollView
      feedListView
    }
    .screenContainer()
    .scrollDismissesKeyboard(.immediately)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .task {
      if case .uninitialized = state {
        state = .loading
        state = await datasource.loadPosts(with: state)
      }
    }
    .refreshable {
      // Prevent multiple simultaneous refreshes
      guard case .loaded = state else { return }

      state = .loading
      do {
        state = await datasource.loadPosts(with: state)
      } catch {
        // Handle refresh errors gracefully
        if (error as? CancellationError) != nil {
          // Task was cancelled, don't show error
          return
        }
        state = .error(error)
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

  private func filteredPosts(_ posts: [PostItem]) -> [PostItem] {
    return postFilterService.filterPosts(posts)
  }

  private func groupPostsByReplyChain(_ posts: [PostItem]) -> [PostGroup] {
    var groups: [PostGroup] = []
    var processedURIs = Set<String>()

    // print("PostsListView: Grouping \(posts.count) posts by reply chains")
    // print("PostsListView: Checking each post for reply status:")

    // First pass: identify all reply chains to avoid processing parents twice
    var replyChains: [(parent: PostItem, reply: PostItem)] = []
    for post in posts {
      if post.isReplyTo, let parent = findParentPost(for: post, in: posts) {
        replyChains.append((parent: parent, reply: post))
      }
    }

    // Second pass: create groups, prioritizing reply chains
    for (index, post) in posts.enumerated() {
      // print(
      //   "PostsListView: [\(index)] \(post.author.handle) - isReplyTo: \(post.isReplyTo), hasReply: \(post.hasReply), replyRef: \(post.replyRef != nil)"
      // )

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
          // print(
          //   "PostsListView: Creating reply chain for \(replyChain.parent.author.handle) -> \(replyChain.reply.author.handle)"
          // )
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
    // print("PostsListView: Finding parent for post: \(post.author.handle)")

    // Require a concrete parent URI; do not guess by handle to avoid incorrect threads
    guard let replyRef = post.replyRef else {
      // print("PostsListView: Post has no replyRef")
      return nil
    }

    guard let parentURI = Self.replyParentURI(from: replyRef) else {
      // print("PostsListView: Could not extract parent URI from replyRef")
      return nil
    }

    // print("PostsListView: Looking for parent with URI: \(parentURI)")

    let parent = allPosts.first(where: { $0.uri == parentURI })
    if let parent = parent {
      // print("PostsListView: Found parent post: \(parent.author.handle)")
    } else {
      // print("PostsListView: Parent post not found in current feed")
      // print("PostsListView: Available URIs in feed:")
      // for (index, feedPost) in allPosts.enumerated() {
      //   print("PostsListView: [\(index)] \(feedPost.author.handle): \(feedPost.uri)")
      // }
    }

    return parent
  }

  private static func replyParentURI(from replyRef: AppBskyLexicon.Feed.PostRecord.ReplyReference)
    -> String?
  {
    // print("PostsListView: Extracting parent URI from replyRef: \(replyRef)")

    let mirror = Mirror(reflecting: replyRef)
    // print("PostsListView: ReplyRef mirror children:")
    // for child in mirror.children {
    //   print("PostsListView: - \(child.label ?? \"nil\"): \(child.value)")
    // }

    func extractURI(from value: Any) -> String? {
      let m = Mirror(reflecting: value)
      for child in m.children {
        if let label = child.label {
          if label == "recordURI", let uri = child.value as? String {
            // print("PostsListView: Found recordURI: \(uri)")
            return uri
          }
          if label == "uri", let uri = child.value as? String {
            // print("PostsListView: Found uri: \(uri)")
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
      // print("PostsListView: Using parent.uri: \(parentURI)")
      return parentURI
    }
    // Fallback to root.uri
    if let rootChild = mirror.children.first(where: { $0.label == "root" }),
      let rootURI = extractURI(from: rootChild.value)
    {
      // print("PostsListView: Using root.uri: \(rootURI)")
      return rootURI
    }

    // print("PostsListView: No URI found in replyRef")
    return nil
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
            // Only show thread lines for replies, not for the first post in a thread
            if index < posts.count - 1 && post.isReplyTo {
              Rectangle()
                .fill(LinearGradient.themeGradient)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
                .padding(.top, -20)  // Start well above the avatar to connect with parent post above
                .padding(.bottom, 8)  // Extend to connect with next post
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
            if post.embed != nil {
              PostRowEmbedView(post: post)
            }

            // Actions (use same PostRowActionsView as normal posts for consistency)
            PostRowActionsView(post: post)
              .environment(postDataControllerProvider.get(for: post, client: client))
          }
          .onTapGesture {
            router.navigateTo(.post(post))
          }
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
  public static func processFeed(
    _ feed: [AppBskyLexicon.Feed.FeedViewPostDefinition], client: ATProtoKit
  ) async -> [PostItem] {
    // print("PostsListView: Starting to process feed with \(feed.count) items")
    var postItems: [PostItem] = []
    var processedCount = 0
    var missingParentURIs: Set<String> = []
    var replyToParentMap: [String: String] = [:]  // reply URI -> parent URI

    func insert(
      post: AppBskyLexicon.Feed.PostViewDefinition,
      fromFeedItem: AppBskyLexicon.Feed.FeedViewPostDefinition
    ) {
      // Add safety check to prevent crash if uri is nil
      guard !post.uri.isEmpty else {
        // print("Warning: Skipping post with empty URI")
        return
      }

      guard !postItems.contains(where: { $0.uri == post.uri }) else {
        // print("Warning: Skipping duplicate post with URI: \(post.uri)")
        return
      }

      // Use the FeedViewPostDefinition.postItem extension to get repost information
      let item = fromFeedItem.postItem
      // print(
      //   "PostsListView: Processing post - URI: \(item.uri), Author: \(item.author.handle), Content: \(item.content.prefix(50))..."
      // )
      // hasReply is already set correctly from replyRef in the PostItem initializer
      postItems.append(item)
      processedCount += 1
    }

    // First pass: process all posts and identify missing parents
    for (index, post) in feed.enumerated() {
      // print("PostsListView: Processing feed item \(index): post.uri = \(post.post.uri)")

      // Pass both the post and the feed item to get repost information
      insert(post: post.post, fromFeedItem: post)

      // Check if this is a reply and identify missing parent
      let postItem = post.postItem
      if let replyRef = postItem.replyRef {
        let parentURI = Self.replyParentURI(from: replyRef)
        if let parentURI = parentURI {
          // Check if parent is already in the current feed
          let parentExists = feed.contains { $0.post.uri == parentURI }
          if !parentExists {
            // print(
            //   "PostsListView: Parent post missing for reply \(postItem.uri), parent: \(parentURI)")
            missingParentURIs.insert(parentURI)
            replyToParentMap[postItem.uri] = parentURI
          }
        }
      }

      // Note: The reply field indicates that a reply exists, but doesn't contain the reply post data
      // The main posts already have the reply information they need (isReplyTo, replyRef, etc.)
      if post.reply != nil {
        // print("PostsListView: Reply found for item \(index) - this indicates a reply exists")
      }

      // Process repost - simplified to avoid type issues
      if post.reason != nil {
        // print("PostsListView: Repost found for item \(index) - processing...")
        // TODO: Implement proper reply processing when we understand the type structure
      }
    }

    // Second pass: fetch missing parent posts and insert them above their replies
    if !missingParentURIs.isEmpty {
      // print("PostsListView: Fetching \(missingParentURIs.count) missing parent posts...")

      do {
        let parentURIs = Array(missingParentURIs)
        let parentPosts = try await client.getPosts(parentURIs)

        // print("PostsListView: Successfully fetched \(parentPosts.posts.count) parent posts")

        // Insert parent posts above their replies
        for (replyURI, parentURI) in replyToParentMap {
          if let parentPost = parentPosts.posts.first(where: { $0.uri == parentURI }) {
            // print("PostsListView: Inserting parent post \(parentURI) above reply \(replyURI)")

            // Find the reply post index
            if let replyIndex = postItems.firstIndex(where: { $0.uri == replyURI }) {
              // Create PostItem from parent post
              let parentPostItem = parentPost.postItem
              postItems.insert(parentPostItem, at: replyIndex)
              processedCount += 1
              // print("PostsListView: Successfully inserted parent post above reply")
            }
          }
        }
      } catch {
        // print("PostsListView: Error fetching parent posts: \(error)")
        // Continue without parent posts if fetch fails
      }
    }

    // print(
    //   "PostsListView: Finished processing feed. Total posts: \(postItems.count), Processed: \(processedCount)"
    // )
    return postItems
  }
}
