import Models
import SwiftUI

public struct SearchResultsView: View {
  let searchResults: SearchResults
  let onUserTap: (Profile) -> Void
  let onFeedTap: (FeedSearchResult) -> Void
  let onPostTap: (PostItem) -> Void

  public init(
    searchResults: SearchResults,
    onUserTap: @escaping (Profile) -> Void = { _ in },
    onFeedTap: @escaping (FeedSearchResult) -> Void = { _ in },
    onPostTap: @escaping (PostItem) -> Void = { _ in }
  ) {
    self.searchResults = searchResults
    self.onUserTap = onUserTap
    self.onFeedTap = onFeedTap
    self.onPostTap = onPostTap
  }

  public var body: some View {
    if searchResults.hasResults {
      LazyVStack(spacing: 16) {
        // Users section
        if !searchResults.users.isEmpty {
          SearchSectionHeader(title: "Users", count: searchResults.users.count)
          ForEach(searchResults.users) { user in
            UserSearchResultRow(user: user)
              .onTapGesture {
                onUserTap(user)
              }
          }
        }

        // Feeds section
        if !searchResults.feeds.isEmpty {
          SearchSectionHeader(title: "Feeds", count: searchResults.feeds.count)
          ForEach(searchResults.feeds) { feed in
            FeedSearchResultRow(feed: feed)
              .onTapGesture {
                onFeedTap(feed)
              }
          }
        }

        // Posts section
        if !searchResults.posts.isEmpty {
          SearchSectionHeader(title: "Posts", count: searchResults.posts.count)
          ForEach(searchResults.posts) { post in
            PostSearchResultRow(post: post)
              .onTapGesture {
                onPostTap(post)
              }
          }
        }
      }
      .padding(.horizontal, 16)
    } else {
      VStack(spacing: 16) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 48))
          .foregroundColor(.secondary)

        Text("No results found")
          .font(.title3)
          .fontWeight(.medium)

        Text("Try adjusting your search terms")
          .font(.body)
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding()
    }
  }
}

// MARK: - Section Header
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
  }
}

// MARK: - User Search Result Row
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

// MARK: - Post Search Result Row
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

#Preview {
  SearchResultsView(searchResults: SearchResults())
}
