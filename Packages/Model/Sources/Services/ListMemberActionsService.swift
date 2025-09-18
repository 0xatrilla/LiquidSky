import Client
import Foundation
import Models
import ATProtoKit

@MainActor
public class ListMemberActionsService: ObservableObject {
  private let client: BSkyClient

  public init(client: BSkyClient) {
    self.client = client
  }

  public func followUser(did: String) async throws -> String {
    let followRecord: [String: Any] = [
      "subject": did,
      "createdAt": ISO8601DateFormatter().string(from: Date())
    ]
    
    // Get the current user's session
    guard let session = try await client.protoClient.getUserSession() else {
      throw ListMemberActionError.unknownError
    }
    
    let response = try await client.protoClient.createRecord(
      repositoryDID: session.sessionDID,
      collection: "app.bsky.graph.follow",
      record: followRecord
    )
    
    return response.recordURI
  }

  public func unfollowUser(followUri: String) async throws {
    try await client.blueskyClient.deleteRecord(.recordURI(atURI: followUri))
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
