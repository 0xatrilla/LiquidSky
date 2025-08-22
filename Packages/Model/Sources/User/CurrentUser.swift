@preconcurrency import ATProtoKit
import Client
import SwiftUI

@Observable
public final class CurrentUser: @unchecked Sendable {
  public let client: BSkyClient

  public private(set) var profile: AppBskyLexicon.Actor.ProfileViewDetailedDefinition?
  public private(set) var savedFeeds: [AppBskyLexicon.Actor.SavedFeed] = []

  public init(client: BSkyClient) async throws {
    self.client = client
    try await refresh()
  }

  public func refresh() async throws {
    #if DEBUG
    print("CurrentUser: Refreshing user data...")
    #endif
    async let profile: AppBskyLexicon.Actor.ProfileViewDetailedDefinition? = fetchProfile()
    async let savedFeeds = fetchPreferences()
    (self.profile, self.savedFeeds) = try await (profile, savedFeeds)
    #if DEBUG
    print(
      "CurrentUser: Refresh complete. Profile: \(self.profile?.displayName ?? "nil"), Saved feeds: \(self.savedFeeds.count)"
    )
    #endif
  }

  public func fetchProfile() async throws -> AppBskyLexicon.Actor.ProfileViewDetailedDefinition? {
    if let DID = try await client.protoClient.getUserSession()?.sessionDID {
      #if DEBUG
      print("CurrentUser: Fetching profile for DID: \(DID)")
      #endif
      return try await client.protoClient.getProfile(for: DID)
    }
    #if DEBUG
    print("CurrentUser: No session DID found")
    #endif
    return nil
  }

  public func fetchPreferences() async throws -> [AppBskyLexicon.Actor.SavedFeed] {
    #if DEBUG
    print("CurrentUser: Fetching preferences...")
    #endif
    let preferences = try await client.protoClient.getPreferences().preferences
    #if DEBUG
    print("CurrentUser: Raw preferences: \(preferences)")
    #endif

    for preference in preferences {
      switch preference {
      case .savedFeedsVersion2(let feeds):
        #if DEBUG
        print("CurrentUser: Found saved feeds v2: \(feeds)")
        #endif
        var feeds = feeds.items
        feeds.removeAll(where: { $0.value == "following" })
        #if DEBUG
        print("CurrentUser: Processed saved feeds: \(feeds.count)")
        #endif
        return feeds
      default:
        #if DEBUG
        print("CurrentUser: Preference type: \(type(of: preference))")
        #endif
        continue
      }
    }
    #if DEBUG
    print("CurrentUser: No saved feeds found in preferences")
    #endif
    return []
  }
}
