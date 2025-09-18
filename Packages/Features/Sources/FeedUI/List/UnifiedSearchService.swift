import ATProtoKit
import Client
import Foundation
import Models

@MainActor
public class UnifiedSearchService: ObservableObject {
  @Published public var searchResults: SearchResults = SearchResults()
  @Published public var isSearching = false
  @Published public var searchError: Error?
  @Published public var searchQuery: String = ""

  public var client: BSkyClient?
  private var searchTask: Task<Void, Never>?

  public init(client: BSkyClient? = nil) {
    self.client = client
  }

  public func search(query: String) async {
    guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      searchResults = SearchResults()
      return
    }

    searchQuery = query

    // Cancel any existing search
    searchTask?.cancel()

    searchTask = Task {
      isSearching = true
      searchError = nil

      let looksLikeHandle = query.hasPrefix("@") || query.contains(".")
      var userResults: [Profile] = []
      if looksLikeHandle {
        userResults = await searchUsers(query: query)
        if !userResults.isEmpty {
          if !Task.isCancelled {
            searchResults = SearchResults(posts: [], users: userResults, feeds: [])
            isSearching = false
          }
          return
        }
      }

      // Simpler sequential flow to avoid main-actor isolation overhead
      if !looksLikeHandle {
        userResults = await searchUsers(query: query)
      }
      let postResults = await searchPosts(query: query)
      let feedResults = await searchFeeds(query: query)

      if !Task.isCancelled {
        searchResults = SearchResults(
          posts: postResults,
          users: userResults,
          feeds: feedResults
        )
      }

      if !Task.isCancelled {
        isSearching = false
      }
    }
  }

  public func searchFeedsOnly(query: String) async {
    guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      searchResults = SearchResults()
      return
    }

    searchQuery = query

    // Cancel any existing search
    searchTask?.cancel()

    searchTask = Task {
      isSearching = true
      searchError = nil

      let feedResults = await searchFeeds(query: query)

      if !Task.isCancelled {
        searchResults = SearchResults(
          posts: [],
          users: [],
          feeds: feedResults
        )
      }

      if !Task.isCancelled {
        isSearching = false
      }
    }
  }

  private func searchPosts(query: String) async -> [PostItem] {
    guard let client = client else { return [] }

    do {
      let results = try await client.protoClient.searchPosts(matching: query, limit: 20)
      return results.posts.map { post in
        // Extract embed data using the EmbedDataExtractor
        let embedData = EmbedDataExtractor.extractEmbed(from: post)

        return PostItem(
          uri: post.uri,
          cid: post.cid,
          indexedAt: post.indexedAt,
          author: post.author.profile,
          content: post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.text ?? "",
          replyCount: post.replyCount ?? 0,
          repostCount: post.repostCount ?? 0,
          likeCount: post.likeCount ?? 0,
          likeURI: post.viewer?.likeURI,
          repostURI: post.viewer?.repostURI,
          replyRef: post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.reply,
          embed: embedData
        )
      }
    } catch {
      #if DEBUG
        print("Error searching posts: \(error)")
      #endif
      return []
    }
  }

  private func searchUsers(query: String) async -> [Profile] {
    guard let client = client else { return [] }

    do {
      let exactResults = try await client.protoClient.searchActors(matching: query, limit: 20)
      let exactProfiles = exactResults.actors.map { actor in
        Profile(
          did: actor.actorDID,
          handle: actor.actorHandle,
          displayName: actor.displayName,
          avatarImageURL: actor.avatarImageURL,
          description: actor.description,
          followersCount: 0,
          followingCount: 0,
          postsCount: 0,
          isFollowing: actor.viewer?.followingURI != nil,
          isFollowedBy: actor.viewer?.followedByURI != nil,
          isBlocked: actor.viewer?.isBlocked == true,
          isBlocking: actor.viewer?.blockingURI != nil,
          isMuted: actor.viewer?.isMuted == true
        )
      }
      if query.hasPrefix("@") || query.contains(".") { return exactProfiles }
      let filtered = exactProfiles.filter {
        $0.displayName?.localizedCaseInsensitiveContains(query) == true
      }
      return filtered.isEmpty ? exactProfiles : filtered

    } catch {
      #if DEBUG
        print("Error searching users: \(error)")
      #endif
      return []
    }
  }

  private func searchFeeds(query: String) async -> [FeedSearchResult] {
    guard let client = client else { return [] }

    do {
      let results = try await client.protoClient.getPopularFeedGenerators(matching: query)
      return results.feeds.map { feed in
        FeedSearchResult(
          uri: feed.feedURI,
          displayName: feed.displayName,
          description: feed.description,
          avatarURL: feed.avatarImageURL,
          creatorHandle: feed.creator.actorHandle,
          likesCount: feed.likeCount ?? 0,
          isLiked: feed.viewer?.likeURI != nil
        )
      }
    } catch {
      #if DEBUG
        print("Error searching feeds: \(error)")
      #endif
      return []
    }
  }

  public func clearSearch() {
    searchTask?.cancel()
    searchResults = SearchResults()
    searchError = nil
    isSearching = false
    searchQuery = ""
  }
}

// MARK: - Search Result Models

public struct SearchResults: RandomAccessCollection {
  public let posts: [PostItem]
  public let users: [Profile]
  public let feeds: [FeedSearchResult]

  public init(posts: [PostItem] = [], users: [Profile] = [], feeds: [FeedSearchResult] = []) {
    self.posts = posts
    self.users = users
    self.feeds = feeds
  }

  public var hasResults: Bool {
    !posts.isEmpty || !users.isEmpty || !feeds.isEmpty
  }

  public var totalResults: Int {
    posts.count + users.count + feeds.count
  }

  // MARK: - RandomAccessCollection Conformance
  public typealias Element = Any
  public typealias Index = Int

  public var startIndex: Int { 0 }
  public var endIndex: Int { totalResults }

  public subscript(position: Int) -> Any {
    if position < posts.count {
      return posts[position]
    } else if position < posts.count + users.count {
      return users[position - posts.count]
    } else {
      return feeds[position - posts.count - users.count]
    }
  }
}

public struct FeedSearchResult: Identifiable, Hashable {
  public var id: String { uri }
  public let uri: String
  public let displayName: String
  public let description: String?
  public let avatarURL: URL?
  public let creatorHandle: String
  public let likesCount: Int
  public let isLiked: Bool
}
