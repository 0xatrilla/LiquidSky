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
                // Simple post display for now
                VStack(alignment: .leading, spacing: 8) {
                  HStack {
                    if let avatar = post.author.avatarImageURL {
                      AsyncImage(url: avatar) { image in
                        image
                          .resizable()
                          .aspectRatio(contentMode: .fill)
                      } placeholder: {
                        Image(systemName: "person.circle.fill")
                          .foregroundColor(.secondary)
                      }
                      .frame(width: 32, height: 32)
                      .clipShape(Circle())
                    } else {
                      Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                      Text(post.author.displayName ?? post.author.handle)
                        .font(.caption)
                        .fontWeight(.medium)
                      Text("@\(post.author.handle)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(post.indexedAt, style: .relative)
                      .font(.caption2)
                      .foregroundColor(.secondary)
                  }
                  .padding(.horizontal, 12)

                  if !post.content.isEmpty {
                    Text(post.content)
                      .font(.body)
                      .lineLimit(3)
                      .padding(.horizontal, 12)
                  }

                  // Simple embed display
                  if let embed = post.embed {
                    switch embed {
                    case .images(let imagesView):
                      if let firstImage = imagesView.images.first {
                        AsyncImage(url: firstImage.fullSizeImageURL) { image in
                          image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        } placeholder: {
                          Rectangle()
                            .fill(Color.gray.opacity(0.3))
                        }
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
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
                        .padding(.horizontal, 16)
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
                      .padding(.horizontal, 12)
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
                        .padding(.horizontal, 12)
                      }
                    case .none:
                      EmptyView()
                    }
                  }

                  Divider()
                    .padding(.top, 8)
                }
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
