import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import NukeUI
import SwiftUI

// Note: Avoid importing PostUI to prevent cycles. Render simple rows here.

public struct UnifiedSearchResultsView: View {
  @ObservedObject var searchService: UnifiedSearchService
  @Environment(\.dismiss) private var dismiss
  @Environment(AppRouter.self) var router

  public init(searchService: UnifiedSearchService) {
    self.searchService = searchService
  }

  public var body: some View {
    VStack(spacing: 0) {
      if searchService.isSearching {
        loadingView
      } else if let error = searchService.searchError {
        errorView(error: error)
      } else if !searchService.searchResults.hasResults {
        emptyStateView
      } else {
        searchResultsList
      }
    }
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
        // Retry search
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Empty State

  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 50))
        .foregroundColor(.secondary)

      Text("No Results Found")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Try adjusting your search terms or browse trending content")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Search Results List

  private var searchResultsList: some View {
    List {
      // Users
      if !searchService.searchResults.users.isEmpty {
        Section(header: Text("Users")) {
          ForEach(searchService.searchResults.users, id: \.did) { user in
            Button(action: {
              router[.compose].append(.profile(user))
            }) {
              HStack(spacing: 12) {
                AsyncImage(url: user.avatarImageURL) { phase in
                  switch phase {
                  case .success(let image):
                    image.resizable().scaledToFill()
                  default:
                    Circle().fill(Color.gray.opacity(0.3))
                  }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                  Text(user.displayName ?? user.handle).font(.body).fontWeight(.medium)
                  Text("@\(user.handle)").font(.caption).foregroundStyle(.secondary)
                }

                Spacer()
              }
            }
            .buttonStyle(.plain)
          }
        }
      }

      // Posts
      if !searchService.searchResults.posts.isEmpty {
        Section(header: Text("Posts")) {
          ForEach(searchService.searchResults.posts, id: \.uri) { post in
            Button(action: {
              router[.compose].append(.post(post))
            }) {
              VStack(alignment: .leading, spacing: 6) {
                Text(post.author.displayName ?? post.author.handle)
                  .font(.subheadline).fontWeight(.semibold)
                Text(post.content).font(.body).lineLimit(3)
              }
              .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
          }
        }
      }

      // Feeds
      if !searchService.searchResults.feeds.isEmpty {
        Section(header: Text("Feeds")) {
          ForEach(searchService.searchResults.feeds) { feed in
            Button(action: {
              // Navigate to feed - we'll need to create a feed destination
              // For now, we'll navigate to a hashtag as a placeholder
              router[.compose].append(.hashtag(feed.displayName))
            }) {
              FeedSearchResultRow(feed: feed)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
    .listStyle(.insetGrouped)
  }
}

// MARK: - Feed Search Result Row
struct FeedSearchResultRow: View {
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) private var client

  let feed: FeedSearchResult
  @Namespace private var namespace
  @State private var isLiked: Bool

  public init(feed: FeedSearchResult) {
    self.feed = feed
    self._isLiked = State(initialValue: feed.isLiked)
  }

  var body: some View {
    HStack(spacing: 12) {
      // Feed Icon
      if let avatarURL = feed.avatarURL {
        LazyImage(url: avatarURL) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.blue.opacity(0.3))
              .overlay(
                Image(systemName: "rss")
                  .foregroundColor(.blue)
              )
          }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
          // Navigate to the feed itself since this is not a user profile
          // The feed is already wrapped in a NavigationLink
        }
      } else {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.blue.opacity(0.3))
          .frame(width: 50, height: 50)
          .overlay(
            Image(systemName: "rss")
              .foregroundColor(.blue)
          )
      }

      // Feed Info
      VStack(alignment: .leading, spacing: 4) {
        Text(feed.displayName)
          .font(.headline)
          .fontWeight(.semibold)

        if let description = feed.description, !description.isEmpty {
          Text(description)
            .font(.body)
            .foregroundColor(.primary)
            .lineLimit(2)
        }

        HStack(spacing: 16) {
          Text("By @\(feed.creatorHandle)")
            .font(.caption)
            .foregroundColor(.secondary)

          Label("\(feed.likesCount)", systemImage: "heart")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      // Subscribe Button
      Button(isLiked ? "Liked" : "Like") {
        Task {
          await toggleFeedSubscription()
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(isLiked ? Color.clear : Color.blue)
      .foregroundColor(isLiked ? .secondary : .white)
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(isLiked ? Color.secondary : Color.clear, lineWidth: 1)
      )
      .controlSize(.small)
    }
    .padding(.vertical, 8)
  }

  private func toggleFeedSubscription() async {
    // TODO: Implement actual feed subscription API call using ATProtoKit
    // For now, we'll use optimistic UI updates
    // The isLiked property represents whether the user has liked the feed
    // In a real implementation, you'd call the Bluesky API to like/unlike the feed

    // Optimistically update the UI
    isLiked.toggle()

    // Print debug info
    print("Would \(isLiked ? "like" : "unlike") feed: \(feed.uri)")
  }
}
