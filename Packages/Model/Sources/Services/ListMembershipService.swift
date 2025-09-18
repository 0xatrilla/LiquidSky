import ATProtoKit
import Foundation

@Observable
public final class ListMembershipService: Sendable {
  private let client: BSkyClient
  
  public init(client: BSkyClient) {
    self.client = client
  }
  
  // MARK: - List Membership Operations
  
  /// Add a user to a list
  public func addUserToList(userDID: String, listURI: String) async throws {
    do {
      // Get the current user's session
      guard let session = try await client.protoClient.getUserSession() else {
        throw ListMembershipError.noSession
      }
      
      // Create the list item record
      let listItemRecord = AppBskyLexicon.Graph.ListitemDefinition(
        subject: userDID,
        list: listURI,
        createdAt: Date()
      )
      
      // Add the user to the list using XRPC
      let response = try await client.protoClient.createRecord(
        repositoryDID: session.sessionDID,
        collection: "app.bsky.graph.listitem",
        record: listItemRecord
      )
      
      #if DEBUG
      print("ListMembershipService: Successfully added user \(userDID) to list \(listURI)")
      print("ListMembershipService: Response: \(response)")
      #endif
      
    } catch {
      #if DEBUG
      print("ListMembershipService: Failed to add user to list: \(error)")
      #endif
      throw ListMembershipError.failedToAdd(error.localizedDescription)
    }
  }
  
  /// Remove a user from a list
  public func removeUserFromList(listItemURI: String) async throws {
    do {
      // Remove the user from the list using XRPC
      try await client.blueskyClient.deleteRecord(.recordURI(atURI: listItemURI))
      
      #if DEBUG
      print("ListMembershipService: Successfully removed user from list")
      #endif
      
    } catch {
      #if DEBUG
      print("ListMembershipService: Failed to remove user from list: \(error)")
      #endif
      throw ListMembershipError.failedToRemove(error.localizedDescription)
    }
  }
  
  /// Get lists that a user is a member of
  public func getUserLists(userDID: String) async throws -> [UserList] {
    do {
      // This would require implementing a proper API call to get user's lists
      // For now, return an empty array as this is a complex operation
      return []
    } catch {
      #if DEBUG
      print("ListMembershipService: Failed to get user lists: \(error)")
      #endif
      throw ListMembershipError.failedToFetch(error.localizedDescription)
    }
  }
}

// MARK: - Error Types

public enum ListMembershipError: Error, LocalizedError {
  case noSession
  case failedToAdd(String)
  case failedToRemove(String)
  case failedToFetch(String)
  
  public var errorDescription: String? {
    switch self {
    case .noSession:
      return "No valid session found"
    case .failedToAdd(let message):
      return "Failed to add user to list: \(message)"
    case .failedToRemove(let message):
      return "Failed to remove user from list: \(message)"
    case .failedToFetch(let message):
      return "Failed to fetch lists: \(message)"
    }
  }
}
