import ATProtoKit
import Foundation

public struct Profile: Codable, Hashable, Equatable, Sendable, Identifiable {
  public var id: String { did }
  public let did: String
  public let handle: String
  public let displayName: String?
  public let avatarImageURL: URL?
  public let description: String?
  public let followersCount: Int
  public let followingCount: Int
  public let postsCount: Int
  public let isFollowing: Bool
  public let isFollowedBy: Bool
  public let isBlocked: Bool
  public let isBlocking: Bool
  public let isMuted: Bool

  public init(
    did: String,
    handle: String,
    displayName: String?,
    avatarImageURL: URL?,
    description: String? = nil,
    followersCount: Int = 0,
    followingCount: Int = 0,
    postsCount: Int = 0,
    isFollowing: Bool = false,
    isFollowedBy: Bool = false,
    isBlocked: Bool = false,
    isBlocking: Bool = false,
    isMuted: Bool = false
  ) {
    self.did = did
    self.handle = handle
    self.displayName = displayName
    self.avatarImageURL = avatarImageURL
    self.description = description
    self.followersCount = followersCount
    self.followingCount = followingCount
    self.postsCount = postsCount
    self.isFollowing = isFollowing
    self.isFollowedBy = isFollowedBy
    self.isBlocked = isBlocked
    self.isBlocking = isBlocking
    self.isMuted = isMuted
  }

  // Convenience initializer for basic profile creation
  public init(
    did: String,
    handle: String,
    displayName: String?,
    avatarImageURL: URL?
  ) {
    self.did = did
    self.handle = handle
    self.displayName = displayName
    self.avatarImageURL = avatarImageURL
    self.description = nil
    self.followersCount = 0
    self.followingCount = 0
    self.postsCount = 0
    self.isFollowing = false
    self.isFollowedBy = false
    self.isBlocked = false
    self.isBlocking = false
    self.isMuted = false
  }
}

extension AppBskyLexicon.Actor.ProfileViewDetailedDefinition {
  public var profile: Profile {
    Profile(
      did: actorDID,
      handle: actorHandle,
      displayName: displayName,
      avatarImageURL: avatarImageURL,
      description: description,
      followersCount: followerCount ?? 0,
      followingCount: followCount ?? 0,
      postsCount: postCount ?? 0,
      isFollowing: viewer?.followingURI != nil,
      isFollowedBy: viewer?.followedByURI != nil,
      isBlocked: viewer?.isBlocked == true,
      isBlocking: viewer?.blockingURI != nil,
      isMuted: viewer?.isMuted == true
    )
  }
}

// Enhanced Profile creation with better error handling
extension AppBskyLexicon.Actor.ProfileViewBasicDefinition {
  public var profile: Profile {
    Profile(
      did: actorDID,
      handle: actorHandle,
      displayName: displayName,
      avatarImageURL: avatarImageURL
    )
  }
}
