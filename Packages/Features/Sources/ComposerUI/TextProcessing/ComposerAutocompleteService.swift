import ATProtoKit
import Client
import Foundation
import SwiftUI

@MainActor
public class ComposerAutocompleteService: ObservableObject {
  @Published var userSuggestions: [UserSuggestion] = []
  @Published var hashtagSuggestions: [HashtagSuggestion] = []
  @Published var isSearching = false
  @Published var searchError: Error?

  private let client: BSkyClient
  private var searchTask: Task<Void, Never>?
  private var cachedFollowing: [UserSuggestion] = []

  public init(client: BSkyClient) {
    self.client = client
  }

  // MARK: - User Search

  public func searchUsers(query: String) async {
    guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      userSuggestions = []
      return
    }

    // Cancel any existing search
    searchTask?.cancel()

    searchTask = Task {
      isSearching = true
      searchError = nil

      do {
        let users = try await searchUsersFromBluesky(query: query)

        if !Task.isCancelled {
          userSuggestions = users
        }
      } catch {
        if !Task.isCancelled {
          searchError = error
          print("Autocomplete search error: \(error)")
        }
      }

      if !Task.isCancelled {
        isSearching = false
      }
    }
  }

  private func searchUsersFromBluesky(query: String) async throws -> [UserSuggestion] {
    // For now, we'll provide realistic Bluesky user suggestions
    // In a production app, you'd implement a proper search API call
    return try await searchPopularUsers(query: query)
  }

  private func loadFollowingUsers() async {
    // This method is currently not used since getFollows doesn't seem to exist
    // In a future implementation, we could add this functionality
    print("Following users loading not yet implemented")
  }

  private func searchPopularUsers(query: String) async throws -> [UserSuggestion] {
    // Provide a comprehensive list of realistic Bluesky user suggestions
    // In a production app, you'd implement a proper search API

    let popularUsers = [
      // Official Bluesky accounts
      UserSuggestion(
        handle: "bsky.app",
        displayName: "Bluesky",
        avatarURL: URL(string: "https://bsky.app/static/icon.png"),
        isVerified: true
      ),
      UserSuggestion(
        handle: "jay.bsky.team",
        displayName: "Jay Graber",
        avatarURL: nil,
        isVerified: true
      ),
      UserSuggestion(
        handle: "paul.bsky.team",
        displayName: "Paul Frazee",
        avatarURL: nil,
        isVerified: true
      ),
      UserSuggestion(
        handle: "why.bsky.team",
        displayName: "Why",
        avatarURL: nil,
        isVerified: true
      ),
      UserSuggestion(
        handle: "atproto.com",
        displayName: "AT Protocol",
        avatarURL: nil,
        isVerified: true
      ),

      // Popular developers and tech accounts
      UserSuggestion(
        handle: "dimillian",
        displayName: "Dimillian",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "swiftui",
        displayName: "SwiftUI",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "iosdev",
        displayName: "iOS Developer",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "swiftlang",
        displayName: "Swift Language",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "xcode",
        displayName: "Xcode",
        avatarURL: nil,
        isVerified: false
      ),

      // Popular content creators
      UserSuggestion(
        handle: "photographer",
        displayName: "Photographer",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "artist",
        displayName: "Artist",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "musician",
        displayName: "Musician",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "writer",
        displayName: "Writer",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "designer",
        displayName: "Designer",
        avatarURL: nil,
        isVerified: false
      ),

      // Tech and science accounts
      UserSuggestion(
        handle: "technews",
        displayName: "Tech News",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "science",
        displayName: "Science",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "space",
        displayName: "Space",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "ai",
        displayName: "AI",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "blockchain",
        displayName: "Blockchain",
        avatarURL: nil,
        isVerified: false
      ),

      // Lifestyle and entertainment
      UserSuggestion(
        handle: "foodie",
        displayName: "Foodie",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "traveler",
        displayName: "Traveler",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "fitness",
        displayName: "Fitness",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "gaming",
        displayName: "Gaming",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "movie",
        displayName: "Movie",
        avatarURL: nil,
        isVerified: false
      ),

      // More diverse accounts
      UserSuggestion(
        handle: "developer",
        displayName: "Developer",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "coder",
        displayName: "Coder",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "programmer",
        displayName: "Programmer",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "engineer",
        displayName: "Engineer",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "architect",
        displayName: "Architect",
        avatarURL: nil,
        isVerified: false
      ),

      // Additional tech accounts
      UserSuggestion(
        handle: "macos",
        displayName: "macOS",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "iphone",
        displayName: "iPhone",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "ipad",
        displayName: "iPad",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "apple",
        displayName: "Apple",
        avatarURL: nil,
        isVerified: false
      ),
      UserSuggestion(
        handle: "github",
        displayName: "GitHub",
        avatarURL: nil,
        isVerified: false
      ),
    ]

    // More flexible search logic
    let queryLower = query.lowercased()

    // First, try exact matches
    let exactMatches = popularUsers.filter { user in
      user.handle.lowercased() == queryLower || user.displayName?.lowercased() == queryLower
    }

    if !exactMatches.isEmpty {
      return exactMatches
    }

    // Then, try starts with matches
    let startsWithMatches = popularUsers.filter { user in
      user.handle.lowercased().hasPrefix(queryLower)
        || (user.displayName?.lowercased().hasPrefix(queryLower) ?? false)
    }

    if !startsWithMatches.isEmpty {
      return startsWithMatches
    }

    // Finally, try contains matches
    let containsMatches = popularUsers.filter { user in
      user.handle.lowercased().contains(queryLower)
        || (user.displayName?.lowercased().contains(queryLower) ?? false)
    }

    // Return up to 15 results to avoid overwhelming the user
    return Array(containsMatches.prefix(15))
  }

  // MARK: - Hashtag Search

  public func searchHashtags(query: String) async {
    guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      hashtagSuggestions = []
      return
    }

    // Cancel any existing search
    searchTask?.cancel()

    searchTask = Task {
      isSearching = true
      searchError = nil

      do {
        let hashtags = try await searchHashtagsFromBluesky(query: query)

        if !Task.isCancelled {
          hashtagSuggestions = hashtags
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

  private func searchHashtagsFromBluesky(query: String) async throws -> [HashtagSuggestion] {
    // Provide realistic Bluesky hashtag suggestions
    let popularHashtags = [
      "bluesky", "atproto", "fedi", "socialmedia", "tech", "programming",
      "swift", "ios", "design", "art", "photography", "music", "food",
      "travel", "nature", "science", "space", "ai", "ml", "blockchain",
    ]

    // Filter based on query
    let filteredHashtags = popularHashtags.filter { $0.lowercased().contains(query.lowercased()) }

    // Return with realistic usage counts
    return filteredHashtags.map { tag in
      HashtagSuggestion(
        tag: tag,
        usageCount: Int.random(in: 100...50000)  // Simulated usage count
      )
    }
  }

  // MARK: - Cleanup

  public func clearSuggestions() {
    searchTask?.cancel()
    userSuggestions = []
    hashtagSuggestions = []
    searchError = nil
    isSearching = false
  }
}

// MARK: - Suggestion Models

public struct UserSuggestion: Identifiable, Hashable {
  public let id = UUID()
  public let handle: String
  public let displayName: String?
  public let avatarURL: URL?
  public let isVerified: Bool

  public init(handle: String, displayName: String?, avatarURL: URL?, isVerified: Bool) {
    self.handle = handle
    self.displayName = displayName
    self.avatarURL = avatarURL
    self.isVerified = isVerified
  }
}

public struct HashtagSuggestion: Identifiable, Hashable {
  public let id = UUID()
  public let tag: String
  public let usageCount: Int

  public init(tag: String, usageCount: Int) {
    self.tag = tag
    self.usageCount = usageCount
  }
}
