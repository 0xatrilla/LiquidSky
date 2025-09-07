import Client
import Foundation
import Models

@MainActor
public class ListMemberActionsService: ObservableObject {
  private let client: BSkyClient

  public init(client: BSkyClient) {
    self.client = client
  }

  public func followUser(did: String) async throws -> String {
    // TODO: Implement actual follow using ATProtoKit
    // The follow API needs to be implemented in ATProtoKit
    print("Would follow user: \(did)")

    // Simulate success for now
    try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 second delay
    return "placeholder://follow/\(did)"
  }

  public func unfollowUser(followUri: String) async throws {
    // TODO: Implement actual unfollow using ATProtoKit
    print("Would unfollow user, record URI: \(followUri)")

    // Simulate success for now
    try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 second delay
  }

  public func muteUser(did: String) async throws -> String {
    try await client.protoClient.muteActor(did)
    return "mute://\(did)"
  }

  public func unmuteUser(muteUri: String) async throws {
    let did = muteUri.replacingOccurrences(of: "mute://", with: "")
    try await client.protoClient.unmuteActor(did)
  }

  public func blockUser(did: String) async throws -> String {
    let result = try await client.blueskyClient.createBlockRecord(
      ofType: .actorBlock(actorDID: did))
    return result.recordURI
  }

  public func unblockUser(blockUri: String) async throws {
    try await client.blueskyClient.deleteRecord(.recordURI(atURI: blockUri))
  }
}

public enum ListMemberActionError: LocalizedError {
  case invalidURI
  case networkError
  case unknownError

  public var errorDescription: String? {
    switch self {
    case .invalidURI:
      return "Invalid record URI"
    case .networkError:
      return "Network error occurred"
    case .unknownError:
      return "An unknown error occurred"
    }
  }
}
