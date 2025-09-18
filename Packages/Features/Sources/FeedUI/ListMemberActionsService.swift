import Foundation
import Models
import ATProtoKit
import Client

public class ListMemberActionsService: ObservableObject {
  private let client: BSkyClient
  
  public init(client: BSkyClient) {
    self.client = client
  }
  
  public func followUser(did: String) async throws -> String {
    let response = try await client.blueskyClient.createFollowRecord(
      actorDID: did,
      createdAt: Date()
    )
    
    return response.recordURI
  }
  
  public func unfollowUser(followingURI: String) async throws {
    try await client.blueskyClient.deleteRecord(.recordURI(atURI: followingURI))
  }
}

public enum ListMemberActionError: Error {
  case unknownError
  case userNotFound
  case networkError
}
