import Client
import DesignSystem
import Models
import SwiftUI

public struct FeedDetailView: View {
  let feed: FeedItem
  @Environment(BSkyClient.self) var client
  @State private var posts: [PostItem] = []
  @State private var isLoading = false
  @State private var error: Error?
  @State private var cursor: String?

  public init(feed: FeedItem) {
    self.feed = feed
  }

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Feed Header
        feedHeader

        // Content
        if isLoading && posts.isEmpty {
          loadingView
        } else if let error = error, posts.isEmpty {
          errorView(error)
        } else {
          postsList
        }
      }
      .navigationTitle(feed.displayName)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            // Close the sheet - this will be handled by the parent view
          }
        }
      }
    }
    .onAppear {
      loadFeedPosts()
    }
  }

  // MARK: - Feed Header
  private var feedHeader: some View {
    VStack(spacing: 16) {
      // Avatar and basic info
      HStack(spacing: 16) {
        AsyncImage(url: feed.avatarImageURL) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .scaledToFit()
              .frame(width: 80, height: 80)
              .clipShape(RoundedRectangle(cornerRadius: 16))
              .shadow(color: .shadowPrimary.opacity(0.7), radius: 4)
          default:
            Image(systemName: "antenna.radiowaves.left.and.right")
              .imageScale(.large)
              .foregroundStyle(.white)
              .frame(width: 80, height: 80)
              .background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient.blueskySubtle))
              .clipShape(RoundedRectangle(cornerRadius: 16))
              .shadow(color: .shadowPrimary.opacity(0.7), radius: 4)
          }
        }

        VStack(alignment: .leading, spacing: 8) {
          Text(feed.displayName)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.primary)

          if let description = feed.description {
            Text(description)
              .font(.body)
              .foregroundStyle(.secondary)
              .lineLimit(3)
          }

          HStack(spacing: 16) {
            VStack {
              Text("\(feed.likesCount)")
                .font(.headline)
                .fontWeight(.semibold)
              Text("likes")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            VStack {
              Text("@\(feed.creatorHandle)")
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
          }
        }

        Spacer()
      }
      .padding(.horizontal, 20)

      Divider()
        .padding(.horizontal, 20)
    }
    .padding(.vertical, 20)
  }

  // MARK: - Posts List
  private var postsList: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        ForEach(posts) { post in
          PostRowView(post: post)
            .padding(.horizontal, 20)
        }

        if !posts.isEmpty && cursor != nil {
          loadMoreButton
        }
      }
      .padding(.vertical, 20)
    }
  }

  // MARK: - Loading View
  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)
      Text("Loading feed posts...")
        .font(.body)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Error View
  private func errorView(_ error: Error) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(.orange)

      Text("Failed to load feed")
        .font(.title2)
        .fontWeight(.semibold)

      Text(error.localizedDescription)
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("Try Again") {
        loadFeedPosts()
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Load More Button
  private var loadMoreButton: some View {
    Button(action: loadMorePosts) {
      HStack {
        if isLoading {
          ProgressView()
            .scaleEffect(0.8)
        }
        Text(isLoading ? "Loading..." : "Load More")
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
    }
    .disabled(isLoading)
    .padding(.horizontal, 20)
  }

  // MARK: - Data Loading
  private func loadFeedPosts() {
    guard !isLoading else { return }

    isLoading = true
    error = nil

    Task {
      do {
        let feedData = try await client.protoClient.getFeed(by: feed.uri, cursor: nil)
        // For now, just create placeholder posts since we don't have the PostListView.processFeed method
        let placeholderPosts = createPlaceholderPosts(from: feedData.feed)

        await MainActor.run {
          self.posts = placeholderPosts
          self.cursor = feedData.cursor
          self.isLoading = false
        }
      } catch {
        await MainActor.run {
          self.error = error
          self.isLoading = false
        }
      }
    }
  }

  private func loadMorePosts() {
    guard let cursor = cursor, !isLoading else { return }

    isLoading = true

    Task {
      do {
        let feedData = try await client.protoClient.getFeed(by: feed.uri, cursor: cursor)
        let placeholderPosts = createPlaceholderPosts(from: feedData.feed)

        await MainActor.run {
          self.posts.append(contentsOf: placeholderPosts)
          self.cursor = feedData.cursor
          self.isLoading = false
        }
      } catch {
        await MainActor.run {
          self.error = error
          self.isLoading = false
        }
      }
    }
  }

  // MARK: - Helper Methods
  private func createPlaceholderPosts(from feed: [Any]) -> [PostItem] {
    // For now, create a simple placeholder post since we don't have the complex feed structure
    let placeholderPost = PostItem(
      uri: "placeholder-uri",
      cid: "placeholder-cid",
      indexedAt: Date(),
      author: Profile(
        did: "placeholder-did",
        handle: "placeholder.handle",
        displayName: "Placeholder User",
        avatarImageURL: nil,
        description: "This is a placeholder post",
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        isFollowing: false,
        isFollowedBy: false,
        isBlocked: false,
        isBlocking: false,
        isMuted: false
      ),
      content: "This is a placeholder post content. The actual feed data would be processed here.",
      replyCount: 0,
      repostCount: 0,
      likeCount: 0,
      likeURI: nil,
      repostURI: nil,
      // embed: nil,
      replyRef: nil
    )

    return [placeholderPost]
  }
}

// MARK: - Post Row View
private struct PostRowView: View {
  let post: PostItem

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Author info
      HStack {
        AsyncImage(url: post.author.avatarImageURL) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .scaledToFit()
              .frame(width: 32, height: 32)
              .clipShape(Circle())
          default:
            Image(systemName: "person.circle.fill")
              .font(.title2)
              .foregroundStyle(.secondary)
              .frame(width: 32, height: 32)
          }
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(post.author.displayName ?? post.author.handle)
            .font(.subheadline)
            .fontWeight(.semibold)

          Text("@\(post.author.handle)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Text(post.indexAtFormatted)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }

      // Post content
      Text(post.content)
        .font(.body)
        .lineLimit(6)

      // Post stats
      HStack(spacing: 16) {
        HStack(spacing: 4) {
          Image(systemName: "heart")
            .font(.caption)
          Text("\(post.likeCount)")
            .font(.caption)
        }
        .foregroundStyle(.secondary)

        HStack(spacing: 4) {
          Image(systemName: "arrow.2.squarepath")
            .font(.caption)
          Text("\(post.repostCount)")
            .font(.caption)
        }
        .foregroundStyle(.secondary)

        HStack(spacing: 4) {
          Image(systemName: "bubble.left")
            .font(.caption)
          Text("\(post.replyCount)")
            .font(.caption)
        }
        .foregroundStyle(.secondary)
      }
    }
    .padding()
    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      // Like action (left swipe)
      Button(action: {
        // Note: This would need proper PostContext to work
        // For now, just show the action
      }) {
        Label("Like", systemImage: "heart.fill")
      }
      .tint(.red)

      // Reply action (left swipe)
      Button(action: {
        // Note: This would need proper router to work
        // For now, just show the action
      }) {
        Label("Reply", systemImage: "bubble.left.fill")
      }
      .tint(.blue)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
      // Repost action (right swipe)
      Button(action: {
        // Note: This would need proper PostContext to work
        // For now, just show the action
      }) {
        Label("Repost", systemImage: "quote.bubble.fill")
      }
      .tint(.green)
    }
  }
}
