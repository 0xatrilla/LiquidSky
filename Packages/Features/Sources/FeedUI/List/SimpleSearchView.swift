import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct SimpleSearchView: View {
  @StateObject private var searchService: UnifiedSearchService
  @State private var searchText = ""
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client

  public init(client: BSkyClient) {
    self._searchService = StateObject(wrappedValue: UnifiedSearchService(client: client))
  }

  public var body: some View {
    List {
      if searchService.isSearching {
        HStack {
          ProgressView()
          Text("Searching...")
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
      } else if !searchText.isEmpty {
        // Users section
        if !searchService.searchResults.users.isEmpty {
          Section("Users") {
            ForEach(searchService.searchResults.users) { user in
              Button {
                // Force navigation within the current tab (search/compose)
                router[.compose].append(.profile(user))
              } label: {
                UserRow(user: user)
              }
              .buttonStyle(.plain)
            }
          }
        }

        // Feeds section
        if !searchService.searchResults.feeds.isEmpty {
          Section("Feeds") {
            ForEach(searchService.searchResults.feeds) { feed in
              Button {
                let feedItem = FeedItem(
                  uri: feed.uri,
                  displayName: feed.displayName,
                  description: feed.description,
                  avatarImageURL: feed.avatarURL,
                  creatorHandle: feed.creatorHandle,
                  likesCount: feed.likesCount,
                  liked: feed.isLiked
                )
                // Force navigation within the current tab (search/compose)
                router[.compose].append(.feed(feedItem))
              } label: {
                FeedRow(feed: feed)
              }
              .buttonStyle(.plain)
            }
          }
        }

        // Posts section
        if !searchService.searchResults.posts.isEmpty {
          Section("Posts") {
            ForEach(searchService.searchResults.posts) { post in
              Button {
                // Force navigation within the current tab (search/compose)
                router[.compose].append(.post(post))
              } label: {
                PostRow(post: post)
              }
              .buttonStyle(.plain)
            }
          }
        }

        // No results
        if searchService.searchResults.users.isEmpty
          && searchService.searchResults.feeds.isEmpty
          && searchService.searchResults.posts.isEmpty
          && !searchService.isSearching
        {
          Text("No results found")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowBackground(Color.clear)
        }
      }
    }
    .listStyle(.insetGrouped)
    .searchable(text: $searchText, prompt: "Search users, feeds, and posts")
    .onSubmit(of: .search) {
      Task {
        await searchService.search(query: searchText)
      }
    }
    .onChange(of: searchText) { _, newValue in
      if newValue.isEmpty {
        searchService.clearSearch()
      } else {
        // Auto-search after typing stops
        Task {
          try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 second delay
          if searchText == newValue {
            await searchService.search(query: searchText)
          }
        }
      }
    }
    .navigationTitle("Search")
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      searchService.client = client
    }
  }
}

// MARK: - Row Views

private struct UserRow: View {
  let user: Profile

  var body: some View {
    HStack {
      AsyncImage(url: user.avatarImageURL) { image in
        image
          .resizable()
          .scaledToFill()
      } placeholder: {
        Circle()
          .fill(Color.gray.opacity(0.3))
      }
      .frame(width: 40, height: 40)
      .clipShape(Circle())

      VStack(alignment: .leading, spacing: 2) {
        Text(user.displayName ?? user.handle)
          .font(.body)
          .lineLimit(1)

        Text("@\(user.handle)")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer()
    }
    .contentShape(Rectangle())
  }
}

private struct FeedRow: View {
  let feed: FeedSearchResult

  var body: some View {
    HStack {
      AsyncImage(url: feed.avatarURL) { image in
        image
          .resizable()
          .scaledToFill()
      } placeholder: {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.gray.opacity(0.3))
      }
      .frame(width: 40, height: 40)
      .clipShape(RoundedRectangle(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 2) {
        Text(feed.displayName)
          .font(.body)
          .lineLimit(1)

        if let description = feed.description {
          Text(description)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 2) {
        Label("\(feed.likesCount)", systemImage: "heart")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .contentShape(Rectangle())
  }
}

private struct PostRow: View {
  let post: PostItem

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Author
      HStack {
        AsyncImage(url: post.author.avatarImageURL) { image in
          image
            .resizable()
            .scaledToFill()
        } placeholder: {
          Circle()
            .fill(Color.gray.opacity(0.3))
        }
        .frame(width: 24, height: 24)
        .clipShape(Circle())

        Text(post.author.displayName ?? post.author.handle)
          .font(.caption)
          .fontWeight(.medium)

        Text("@\(post.author.handle)")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Spacer()
      }

      // Content
      Text(post.content)
        .font(.body)
        .lineLimit(3)

      // Engagement
      HStack(spacing: 16) {
        Label("\(post.replyCount)", systemImage: "bubble.left")
        Label("\(post.repostCount)", systemImage: "arrow.2.squarepath")
        Label("\(post.likeCount)", systemImage: "heart")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .contentShape(Rectangle())
  }
}
