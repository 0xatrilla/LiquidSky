import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import NukeUI
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
          List {
            ForEach(posts, id: \.id) { post in
              HashtagPostRowView(post: post)
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
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
            }
          }
          .listStyle(.plain)
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
  @Environment(AppRouter.self) private var router

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
            .foregroundColor(.primary)

          Text(post.author.handle)
            .font(.caption)
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
          .foregroundColor(.primary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .multilineTextAlignment(.leading)
      }

      // Embed content
      if let embed = post.embed {
        HashtagPostEmbedView(embed: embed)
      }

      // Action buttons
      HStack(spacing: 20) {
        Button(action: {
          // Handle reply
        }) {
          HStack(spacing: 4) {
            Image(systemName: "bubble.left")
              .font(.caption)
            Text("\(post.replyCount)")
              .font(.caption)
          }
          .foregroundColor(.secondary)
        }

        Button(action: {
          // Handle repost
        }) {
          HStack(spacing: 4) {
            Image(systemName: "arrow.2.squarepath")
              .font(.caption)
            Text("\(post.repostCount)")
              .font(.caption)
          }
          .foregroundColor(.secondary)
        }

        Button(action: {
          // Handle like
        }) {
          HStack(spacing: 4) {
            Image(systemName: post.likeURI != nil ? "heart.fill" : "heart")
              .font(.caption)
            Text("\(post.likeCount)")
              .font(.caption)
          }
          .foregroundColor(post.likeURI != nil ? .red : .secondary)
        }

        Spacer()
      }
      .padding(.top, 8)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    .onTapGesture {
      router.navigateTo(.post(post))
    }
    .listRowSeparator(.hidden)
  }
}

// MARK: - Hashtag Post Embed View
private struct HashtagPostEmbedView: View {
  let embed: EmbedData

  var body: some View {
    switch embed {
    case .images(let imagesEmbed):
      HashtagPostImagesView(images: imagesEmbed)
    case .videos(let videoEmbed):
      HashtagPostVideosView(videos: videoEmbed)
    case .external(let externalEmbed):
      HashtagPostExternalView(externalView: externalEmbed)
    case .quotedPost(let quotedPostData):
      HashtagPostQuotedView(quotedPostData: quotedPostData)
    case .none:
      EmptyView()
    }
  }
}

// MARK: - Hashtag Post Images View
private struct HashtagPostImagesView: View {
  let images: AppBskyLexicon.Embed.ImagesDefinition.View

  var body: some View {
    LazyVGrid(
      columns: Array(
        repeating: GridItem(.flexible(), spacing: 4), count: min(images.images.count, 3)),
      spacing: 4
    ) {
      ForEach(Array(images.images.prefix(3).enumerated()), id: \.offset) { index, image in
        LazyImage(url: image.fullSizeImageURL) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(height: 120)
              .clipped()
              .cornerRadius(8)
          } else {
            Rectangle()
              .fill(Color.gray.opacity(0.2))
              .frame(height: 120)
              .cornerRadius(8)
          }
        }
      }
    }
  }
}

// MARK: - Hashtag Post Videos View
private struct HashtagPostVideosView: View {
  let videos: AppBskyLexicon.Embed.VideoDefinition.View

  var body: some View {
    VStack(spacing: 8) {
      LazyImage(url: videos.thumbnailImageURL.flatMap { URL(string: $0) }) { state in
        if let image = state.image {
          ZStack {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(height: 200)
              .clipped()
              .cornerRadius(8)

            Image(systemName: "play.circle.fill")
              .font(.system(size: 48))
              .foregroundColor(.white)
          }
        } else {
          Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 200)
            .cornerRadius(8)
        }
      }
    }
  }
}

// MARK: - Hashtag Post External View
private struct HashtagPostExternalView: View {
  let externalView: AppBskyLexicon.Embed.ExternalDefinition.View

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let imageURL = externalView.external.thumbnailImageURL {
        LazyImage(url: imageURL) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(height: 120)
              .clipped()
              .cornerRadius(8)
          } else {
            Rectangle()
              .fill(Color.gray.opacity(0.2))
              .frame(height: 120)
              .cornerRadius(8)
          }
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(externalView.external.title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .lineLimit(2)

        if !externalView.external.description.isEmpty {
          Text(externalView.external.description)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }

        Text(externalView.external.uri)
          .font(.caption)
          .foregroundStyle(.blue)
          .lineLimit(1)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.gray.opacity(0.1))
      .cornerRadius(8)
    }
  }
}

// MARK: - Hashtag Post Quoted View
private struct HashtagPostQuotedView: View {
  let quotedPostData: QuotedPostData
  @Environment(AppRouter.self) private var router

  var body: some View {
    Button(action: {
      // Navigate to the quoted post detail view
      let postItem = PostItem(
        uri: quotedPostData.uri,
        cid: quotedPostData.cid,
        indexedAt: quotedPostData.indexedAt,
        author: quotedPostData.author,
        content: quotedPostData.content,
        replyCount: 0,
        repostCount: 0,
        likeCount: 0,
        likeURI: nil,
        repostURI: nil,
        replyRef: nil,
        inReplyToHandle: nil,
        repostedBy: nil,
        embed: nil
      )
      router.navigateTo(.post(postItem))
    }) {
      VStack(alignment: .leading, spacing: 8) {
        // Quoted post header
        HStack(spacing: 8) {
          Image(systemName: "quote.bubble")
            .font(.caption)
            .foregroundColor(.secondary)
          Text("Quoted post")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }

        // Quoted post content area - now using the extracted data directly
        VStack(alignment: .leading, spacing: 8) {
          // Display author information
          HStack(spacing: 8) {
            if let avatarURL = quotedPostData.author.avatarImageURL {
              AsyncImage(url: avatarURL) { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
              } placeholder: {
                Image(systemName: "person.circle.fill")
                  .foregroundColor(.secondary)
              }
              .frame(width: 24, height: 24)
              .clipShape(Circle())
            } else {
              Image(systemName: "person.circle.fill")
                .foregroundColor(.secondary)
                .font(.title2)
            }

            Text(quotedPostData.author.displayName ?? quotedPostData.author.handle)
              .font(.subheadline)
              .fontWeight(.semibold)
              .lineLimit(1)

            Text("@\(quotedPostData.author.handle)")
              .font(.footnote)
              .foregroundColor(.secondary)
              .lineLimit(1)

            Spacer()
          }

          // Display quoted post content
          Text(quotedPostData.content)
            .font(.subheadline)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.gray.opacity(0.05))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.gray.opacity(0.2), lineWidth: 1)
      )
      .padding(.horizontal, 12)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
