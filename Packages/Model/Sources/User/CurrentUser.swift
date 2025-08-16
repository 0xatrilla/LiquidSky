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
    print("CurrentUser: Refreshing user data...")
    async let profile: AppBskyLexicon.Actor.ProfileViewDetailedDefinition? = fetchProfile()
    async let savedFeeds = fetchPreferences()
    (self.profile, self.savedFeeds) = try await (profile, savedFeeds)
    print("CurrentUser: Refresh complete. Profile: \(self.profile?.displayName ?? "nil"), Saved feeds: \(self.savedFeeds.count)")
  }

  public func fetchProfile() async throws -> AppBskyLexicon.Actor.ProfileViewDetailedDefinition? {
    if let DID = try await client.protoClient.getUserSession()?.sessionDID {
      print("CurrentUser: Fetching profile for DID: \(DID)")
      return try await client.protoClient.getProfile(for: DID)
    }
    print("CurrentUser: No session DID found")
    return nil
  }

  public func fetchPreferences() async throws -> [AppBskyLexicon.Actor.SavedFeed] {
    print("CurrentUser: Fetching preferences...")
    let preferences = try await client.protoClient.getPreferences().preferences
    print("CurrentUser: Raw preferences: \(preferences)")
    
    for preference in preferences {
      switch preference {
      case .savedFeedsVersion2(let feeds):
        print("CurrentUser: Found saved feeds v2: \(feeds)")
        var feeds = feeds.items
        feeds.removeAll(where: { $0.value == "following" })
        print("CurrentUser: Processed saved feeds: \(feeds.count)")
        return feeds
      default:
        print("CurrentUser: Preference type: \(type(of: preference))")
        continue
      }
    }
    print("CurrentUser: No saved feeds found in preferences")
    return []
  }
}
