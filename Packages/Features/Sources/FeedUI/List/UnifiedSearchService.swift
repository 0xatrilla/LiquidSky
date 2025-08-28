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

      do {
        let postResults = await searchPosts(query: query)
        let userResults = await searchUsers(query: query)
        let feedResults = await searchFeeds(query: query)

        if !Task.isCancelled {
          searchResults = SearchResults(
            posts: postResults,
            users: userResults,
            feeds: feedResults
          )
        }
      } catch {
        if !Task.isCancelled {
          searchError = error
        }
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

      do {
        let feedResults = await searchFeeds(query: query)

        if !Task.isCancelled {
          searchResults = SearchResults(
            posts: [],
            users: [],
            feeds: feedResults
          )
        }
      } catch {
        if !Task.isCancelled {
          searchError = error
        }
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
        PostItem(
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
          // embed: post.embed,
          replyRef: post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.reply
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
      var allResults: [Profile] = []

      // First, search by the exact query (this will find exact handle matches and some display name matches)
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
      allResults.append(contentsOf: exactProfiles)

      // If the query doesn't look like a handle (doesn't start with @ and doesn't contain .),
      // also search for it as a potential display name
      if !query.hasPrefix("@") && !query.contains(".") && query.count > 2 {
        // Search for display names that might contain the query
        // Note: This is a workaround since Bluesky API doesn't directly support display name search
        // We'll search for variations that might match display names
        let displayNameVariations = [
          query,
          query.lowercased(),
          query.capitalized,
        ]

        for variation in displayNameVariations {
          do {
            let displayResults = try await client.protoClient.searchActors(
              matching: variation, limit: 10)
            let displayProfiles = displayResults.actors.map { actor in
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

            // Only add profiles that aren't already in our results and have matching display names
            for profile in displayProfiles {
              if !allResults.contains(where: { $0.did == profile.did })
                && profile.displayName?.localizedCaseInsensitiveContains(query) == true
              {
                allResults.append(profile)
              }
            }
          } catch {
            // Continue with other variations if one fails
            continue
          }
        }
      }

      // Remove duplicates and limit results
      let uniqueResults = Array(Set(allResults.map { $0.did })).prefix(20).compactMap { did in
        allResults.first { $0.did == did }
      }

      return Array(uniqueResults)

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
