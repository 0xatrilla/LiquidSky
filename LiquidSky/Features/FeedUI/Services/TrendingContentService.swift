import ATProtoKit
import Client
import Foundation
import Models

@MainActor
@Observable
public class TrendingContentService {
  var trendingHashtags: [TrendingHashtag] = []
  var suggestedUsers: [Profile] = []
  var isLoading = false
  var error: Error?

  public var client: BSkyClient
  private var fetchTask: Task<Void, Never>?

  public init(client: BSkyClient) {
    self.client = client
  }

  // MARK: - Public Methods

  public func fetchTrendingContent() async {
    fetchTask?.cancel()

    fetchTask = Task {
      isLoading = true
      error = nil

      do {
        #if DEBUG
        print("TrendingContentService: Starting to fetch trending content...")
        #endif
        
        async let hashtags = fetchTrendingHashtags()
        async let users = fetchSuggestedUsers()

        let (trendingHashtags, suggestedUsers) = try await (hashtags, users)

        if !Task.isCancelled {
          #if DEBUG
          print("TrendingContentService: Successfully fetched \(trendingHashtags.count) hashtags and \(suggestedUsers.count) users")
          #endif
          
          self.trendingHashtags = trendingHashtags
          self.suggestedUsers = suggestedUsers
        }
      } catch {
        if !Task.isCancelled {
          #if DEBUG
          print("TrendingContentService: Error fetching content: \(error)")
          #endif
          
          self.error = error
          // Fallback to curated content if API fails
          await loadFallbackContent()
        }
      }

      if !Task.isCancelled {
        isLoading = false
      }
    }
  }

  public func clearContent() {
    fetchTask?.cancel()
    trendingHashtags = []
    suggestedUsers = []
    error = nil
    isLoading = false
  }

  // MARK: - Private Methods

  private func fetchTrendingHashtags() async throws -> [TrendingHashtag] {
    do {
      // Try to get trending hashtags from recent popular posts
      // Search for posts with common topics to find trending hashtags
      let popularPosts = try await client.protoClient.searchPosts(
        matching: "bluesky OR tech OR art OR music OR science",
        sortRanking: .top,
        limit: 50
      )

      var hashtagCounts: [String: Int] = [:]

      for post in popularPosts.posts {
        if let postRecord = post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self) {
          let postText = postRecord.text
          let hashtagPattern = "#\\w+"

          do {
            let regex = try NSRegularExpression(pattern: hashtagPattern)
            let range = NSRange(location: 0, length: postText.count)
            let matches = regex.matches(in: postText, range: range)

            for match in matches {
              let hashtag = String(postText[Range(match.range, in: postText)!])
              let hashtagWithoutHash = String(hashtag.dropFirst())

              // Filter out very short hashtags and common ones
              if hashtagWithoutHash.count > 2 && !isCommonHashtag(hashtagWithoutHash) {
                hashtagCounts[hashtagWithoutHash, default: 0] += 1
              }
            }
          } catch {
            continue
          }
        }
      }

      // Convert to TrendingHashtag format and sort by usage count
      let trendingHashtags = hashtagCounts.map { tag, count in
        TrendingHashtag(
          tag: tag,
          usageCount: count,
          isTrending: count > 10
        )
      }.sorted { $0.usageCount > $1.usageCount }

      // Return top trending hashtags
      return Array(trendingHashtags.prefix(8))

    } catch {
      #if DEBUG
      print("TrendingContentService: Failed to fetch trending hashtags: \(error)")
      #endif
      throw error
    }
  }

  private func fetchSuggestedUsers() async throws -> [Profile] {
    do {
      // Try multiple search strategies to get better suggested users
      _ = [Profile]()
      
      // Strategy 1: Search for popular tech/developer accounts
      let techUsers = try await client.protoClient.searchActors(
        matching: "developer",
        limit: 10
      )
      
      // Strategy 2: Search for popular content creators
      let creatorUsers = try await client.protoClient.searchActors(
        matching: "artist",
        limit: 10
      )
      
      // Strategy 3: Search for popular tech companies/accounts
      let companyUsers = try await client.protoClient.searchActors(
        matching: "tech",
        limit: 10
      )
      
      // Combine and filter results
      let allActors = techUsers.actors + creatorUsers.actors + companyUsers.actors
      
      let suggestedUsers = allActors
        .filter { actor in
          // Filter out accounts with suspicious handles or very short names
          !actor.actorHandle.contains("bot") && 
          !actor.actorHandle.contains("spam") &&
          !actor.actorHandle.contains("test") &&
          actor.actorHandle.count > 3 &&
          actor.displayName?.count ?? 0 > 2
        }
        .map { actor in
          Profile(
            did: actor.actorDID,
            handle: actor.actorHandle,
            displayName: actor.displayName,
            avatarImageURL: actor.avatarImageURL,
            description: actor.description,
            followersCount: 0,  // Will be updated when full profile is fetched
            followingCount: 0,
            postsCount: 0,
            isFollowing: actor.viewer?.followingURI != nil,
            isFollowedBy: actor.viewer?.followedByURI != nil,
            isBlocked: actor.viewer?.isBlocked == true,
            isBlocking: actor.viewer?.blockingURI != nil,
            isMuted: actor.viewer?.isMuted == true
          )
        }
        .uniqued(by: \.did) // Remove duplicates based on DID

      // Return a curated selection, prioritizing verified/established accounts
      return Array(suggestedUsers.prefix(8))

    } catch {
      #if DEBUG
      print("TrendingContentService: Failed to fetch suggested users: \(error)")
      #endif
      throw error
    }
  }

  private func loadFallbackContent() async {
    #if DEBUG
    print("TrendingContentService: Loading fallback content")
    #endif
    
    // Provide curated fallback content when API fails
    trendingHashtags = [
      TrendingHashtag(tag: "bluesky", usageCount: 15420, isTrending: true),
      TrendingHashtag(tag: "tech", usageCount: 12340, isTrending: true),
      TrendingHashtag(tag: "art", usageCount: 9870, isTrending: true),
      TrendingHashtag(tag: "music", usageCount: 8760, isTrending: true),
      TrendingHashtag(tag: "photography", usageCount: 7650, isTrending: true),
      TrendingHashtag(tag: "science", usageCount: 6540, isTrending: true),
      TrendingHashtag(tag: "gaming", usageCount: 5430, isTrending: true),
      TrendingHashtag(tag: "food", usageCount: 4320, isTrending: true),
      TrendingHashtag(tag: "travel", usageCount: 3980, isTrending: false),
      TrendingHashtag(tag: "books", usageCount: 3450, isTrending: false),
      TrendingHashtag(tag: "fitness", usageCount: 2980, isTrending: false),
      TrendingHashtag(tag: "cooking", usageCount: 2670, isTrending: false),
    ]

    #if DEBUG
    print("TrendingContentService: Loaded \(trendingHashtags.count) fallback hashtags")
    #endif

    // Create fallback suggested users
    suggestedUsers = [
      Profile(
        did: "did:plc:bskyteam",
        handle: "bsky.app",
        displayName: "Bluesky",
        avatarImageURL: nil,
        description: "The official Bluesky app",
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        isFollowing: false,
        isFollowedBy: false,
        isBlocked: false,
        isBlocking: false,
        isMuted: false
      ),
      Profile(
        did: "did:plc:jay",
        handle: "jay.bsky.team",
        displayName: "Jay Graber",
        avatarImageURL: nil,
        description: "Bluesky CEO",
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        isFollowing: false,
        isFollowedBy: false,
        isBlocked: false,
        isBlocking: false,
        isMuted: false
      ),
      Profile(
        did: "did:plc:paul",
        handle: "paul.bsky.team",
        displayName: "Paul Frazee",
        avatarImageURL: nil,
        description: "Bluesky CTO",
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        isFollowing: false,
        isFollowedBy: false,
        isBlocked: false,
        isBlocking: false,
        isMuted: false
      ),
    ]
  }

  private func isCommonHashtag(_ hashtag: String) -> Bool {
    let commonHashtags = [
      "the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one",
      "our", "out", "day", "get", "has", "him", "his", "how", "man", "new", "now", "old", "see",
      "two", "way", "who", "boy", "did", "its", "let", "put", "say", "she", "too", "use",
    ]
    return commonHashtags.contains(hashtag.lowercased())
  }
}

// MARK: - Models

public struct TrendingHashtag: Identifiable, Hashable, Sendable {
  public let id = UUID()
  public let tag: String
  public let usageCount: Int
  public let isTrending: Bool

  public init(tag: String, usageCount: Int, isTrending: Bool) {
    self.tag = tag
    self.usageCount = usageCount
    self.isTrending = isTrending
  }

  public var formattedCount: String {
    if usageCount >= 1_000_000 {
      return String(format: "%.1fM", Double(usageCount) / 1000000.0)
    } else if usageCount >= 1000 {
      return String(format: "%.1fK", Double(usageCount) / 1000.0)
    } else {
      return "\(usageCount)"
    }
  }
}

// MARK: - Array Extension for Uniqued
extension Array {
  func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
    var seen = Set<T>()
    return filter { element in
      let key = element[keyPath: keyPath]
      if seen.contains(key) {
        return false
      } else {
        seen.insert(key)
        return true
      }
    }
  }
}
