import ATProtoKit
import Client
import Models
import SwiftUI

public struct HashtagFeedView: View {
  let hashtag: String
  @State private var selectedSortOption: SortOption = .mostRecent
  @State private var posts: [PostItem] = []
  @State private var isLoading = false
  @State private var error: Error?
  @State private var cursor: String?
  @Environment(BSkyClient.self) private var client

  public init(hashtag: String) {
    self.hashtag = hashtag
  }

  enum SortOption: String, CaseIterable {
    case mostRecent = "Most Recent"
    case hot = "Hot"
    case top = "Top"

    var icon: String {
      switch self {
      case .mostRecent: return "clock"
      case .hot: return "flame"
      case .top: return "star"
      }
    }

    var apiSortRanking: AppBskyLexicon.Feed.SearchPosts.SortRanking {
      switch self {
      case .mostRecent: return .latest
      case .hot: return .latest  // Hot is not directly supported, use latest
      case .top: return .top
      }
    }
  }

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Header with sort options
        VStack(spacing: 0) {
          HStack {
            Text("#\(hashtag)")
              .font(.title2)
              .fontWeight(.bold)
            Spacer()
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)

          // Sort options
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              ForEach(SortOption.allCases, id: \.self) { option in
                Button(action: {
                  selectedSortOption = option
                  loadPosts()
                }) {
                  HStack(spacing: 4) {
                    Image(systemName: option.icon)
                      .font(.caption)
                    Text(option.rawValue)
                      .font(.caption)
                      .fontWeight(.medium)
                  }
                  .foregroundColor(selectedSortOption == option ? .white : .primary)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 6)
                  .background(
                    selectedSortOption == option ? Color.accentColor : Color.gray.opacity(0.2)
                  )
                  .cornerRadius(16)
                }
              }
            }
            .padding(.horizontal, 16)
          }
          .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))

        // Posts list
        if isLoading && posts.isEmpty {
          VStack {
            Spacer()
            ProgressView()
              .scaleEffect(1.2)
            Text("Loading posts...")
              .font(.caption)
              .foregroundColor(.secondary)
              .padding(.top, 8)
            Spacer()
          }
        } else if let error = error {
          VStack {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
              .font(.largeTitle)
              .foregroundColor(.orange)
            Text("Error loading posts")
              .font(.headline)
              .padding(.top, 8)
            Text(error.localizedDescription)
              .font(.caption)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
            Button("Try Again") {
              loadPosts()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 16)
            Spacer()
          }
        } else if posts.isEmpty {
          VStack {
            Spacer()
            Image(systemName: "magnifyingglass")
              .font(.largeTitle)
              .foregroundColor(.secondary)
            Text("No posts found")
              .font(.headline)
              .padding(.top, 8)
            Text("No posts found for #\(hashtag)")
              .font(.caption)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
            Spacer()
          }
        } else {
          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(posts, id: \.id) { post in
                HashtagPostRowView(post: post)
                  .padding(.vertical, 8)
              }

              // Load more button
              if !posts.isEmpty && cursor != nil {
                Button(action: loadMorePosts) {
                  HStack {
                    if isLoading {
                      ProgressView()
                        .scaleEffect(0.8)
                    }
                    Text("Load More")
                      .font(.caption)
                      .fontWeight(.medium)
                  }
                  .foregroundColor(.accentColor)
                  .padding(.vertical, 12)
                }
                .disabled(isLoading)
              }
            }
          }
        }
      }
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        loadPosts()
      }
    }
  }

  private func loadPosts() {
    Task {
      isLoading = true
      error = nil
      cursor = nil

      do {
        let results = try await client.protoClient.searchPosts(
          matching: "#\(hashtag)",
          sortRanking: selectedSortOption.apiSortRanking,
          limit: 25
        )

        posts = results.posts.map { $0.postItem }
        cursor = results.cursor

        #if DEBUG
          print("HashtagFeedView: Loaded \(posts.count) posts for #\(hashtag)")
          print("HashtagFeedView: Cursor: \(cursor ?? "nil")")
        #endif

      } catch {
        self.error = error
        #if DEBUG
          print("HashtagFeedView: Error loading posts: \(error)")
        #endif
      }

      isLoading = false
    }
  }

  private func loadMorePosts() {
    guard !isLoading, let currentCursor = cursor else { return }

    Task {
      isLoading = true

      do {
        let results = try await client.protoClient.searchPosts(
          matching: "#\(hashtag)",
          sortRanking: selectedSortOption.apiSortRanking,
          limit: 25,
          cursor: currentCursor
        )

        let newPosts = results.posts.map { $0.postItem }
        posts.append(contentsOf: newPosts)
        cursor = results.cursor

        #if DEBUG
          print("HashtagFeedView: Loaded \(newPosts.count) more posts")
          print("HashtagFeedView: New cursor: \(cursor ?? "nil")")
        #endif

      } catch {
        self.error = error
        #if DEBUG
          print("HashtagFeedView: Error loading more posts: \(error)")
        #endif
      }

      isLoading = false
    }
  }
}

// MARK: - Hashtag Post Row View
private struct HashtagPostRowView: View {
  let post: PostItem
  @Environment(BSkyClient.self) private var client
  @State private var isLiked = false
  @State private var isReposted = false
  @State private var likeCount: Int
  @State private var repostCount: Int
  @State private var replyCount: Int

  init(post: PostItem) {
    self.post = post
    self._likeCount = State(initialValue: post.likeCount)
    self._repostCount = State(initialValue: post.repostCount)
    self._replyCount = State(initialValue: post.replyCount)
    self._isLiked = State(initialValue: post.likeURI != nil)
    self._isReposted = State(initialValue: post.repostURI != nil)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Author info
      HStack {
        AsyncImage(url: post.author.avatarImageURL) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          default:
            Image(systemName: "person.circle.fill")
              .foregroundColor(.secondary)
          }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())

        VStack(alignment: .leading, spacing: 2) {
          Text(post.author.displayName ?? "")
            .font(.callout)
            .fontWeight(.semibold)

          Text("@\(post.author.handle)")
            .font(.footnote)
            .foregroundColor(.secondary)
        }

        Spacer()

        Text(post.indexedAt, style: .relative)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      // Post content
      if !post.content.isEmpty {
        Text(post.content)
          .font(.body)
          .lineLimit(nil)
          .multilineTextAlignment(.leading)
      }

      // Media embeds
      if let embed = post.embed {
        switch embed {
        case .images(let imagesView):
          if let firstImage = imagesView.images.first {
            AsyncImage(url: firstImage.fullSizeImageURL) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            } placeholder: {
              Rectangle()
                .fill(Color.gray.opacity(0.3))
            }
            .frame(maxHeight: 300)
            .clipped()
            .cornerRadius(8)
          }
        case .videos(_):
          Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 200)
            .overlay(
              Image(systemName: "play.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.white)
            )
            .cornerRadius(8)
        case .external(let externalView):
          VStack(alignment: .leading, spacing: 4) {
            Text(externalView.external.title)
              .font(.caption)
              .fontWeight(.medium)
            Text(externalView.external.description)
              .font(.caption2)
              .foregroundColor(.secondary)
              .lineLimit(2)
          }
          .padding(12)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(8)
        case .quotedPost(_):
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Image(systemName: "quote.bubble")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("Quoted post")
                .font(.caption)
                .foregroundColor(.secondary)
              Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
          }
        case .none:
          EmptyView()
        }
      }

      // Interactive actions
      HStack(spacing: 20) {
        Button(action: {
          Task {
            await toggleLike()
          }
        }) {
          HStack(spacing: 4) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
              .font(.caption)
              .foregroundColor(isLiked ? .red : .secondary)
            Text("\(likeCount)")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .buttonStyle(.plain)

        Button(action: {
          Task {
            await toggleRepost()
          }
        }) {
          HStack(spacing: 4) {
            Image(systemName: isReposted ? "arrow.2.squarepath.fill" : "arrow.2.squarepath")
              .font(.caption)
              .foregroundColor(isReposted ? .green : .secondary)
            Text("\(repostCount)")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .buttonStyle(.plain)

        Button(action: {
          // Reply action - navigate to post details for reply
          // This would typically open the composer, but for now we'll just show an alert
        }) {
          HStack(spacing: 4) {
            Image(systemName: "bubble.left")
              .font(.caption)
            Text("\(replyCount)")
              .font(.caption)
          }
          .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)

        Spacer()
      }
      .padding(.top, 8)
    }
    .padding(.horizontal, 16)
  }

  // MARK: - Post Actions
  private func toggleLike() async {
    do {
      if isLiked {
        // Unlike
        if let likeURI = post.likeURI {
          try await client.blueskyClient.deleteRecord(.recordURI(atURI: likeURI))
          likeCount = max(0, likeCount - 1)
          isLiked = false
        }
      } else {
        // Like
        let likeRecord = try await client.blueskyClient.createLikeRecord(
          .init(recordURI: post.uri, cidHash: post.cid)
        )
        likeCount += 1
        isLiked = true
      }
    } catch {
      print("Error toggling like: \(error)")
    }
  }

  private func toggleRepost() async {
    do {
      if isReposted {
        // Remove repost
        if let repostURI = post.repostURI {
          try await client.blueskyClient.deleteRecord(.recordURI(atURI: repostURI))
          repostCount = max(0, repostCount - 1)
          isReposted = false
        }
      } else {
        // Repost
        let repostRecord = try await client.blueskyClient.createRepostRecord(
          .init(recordURI: post.uri, cidHash: post.cid)
        )
        repostCount += 1
        isReposted = true
      }
    } catch {
      print("Error toggling repost: \(error)")
    }
  }
}
