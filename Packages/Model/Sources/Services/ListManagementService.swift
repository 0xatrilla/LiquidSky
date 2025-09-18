import ATProtoKit
import Foundation

@Observable
public final class ListManagementService: Sendable {
  private let client: BSkyClient
  
  public init(client: BSkyClient) {
    self.client = client
  }
  
  // MARK: - List Operations
  
  /// Create a new list
  public func createList(name: String, description: String?, purpose: UserList.Purpose) async throws -> String {
    do {
      // Get the current user's session
      guard let session = try await client.protoClient.getUserSession() else {
        throw ListManagementError.noSession
      }
      
      // Map purpose to Bluesky's internal purpose
      let blueskyPurpose = mapPurposeToBluesky(purpose)
      
      // Create the list record
      let listRecord = AppBskyLexicon.Graph.ListDefinition(
        name: name,
        purpose: blueskyPurpose,
        description: description,
        createdAt: Date()
      )
      
      // Create the list using XRPC
      let response = try await client.protoClient.createRecord(
        repositoryDID: session.sessionDID,
        collection: "app.bsky.graph.list",
        record: listRecord
      )
      
      #if DEBUG
      print("ListManagementService: Successfully created list '\(name)' with URI: \(response.recordURI)")
      #endif
      
      return response.recordURI
      
    } catch {
      #if DEBUG
      print("ListManagementService: Failed to create list: \(error)")
      #endif
      throw ListManagementError.failedToCreate(error.localizedDescription)
    }
  }
  
  /// Update an existing list
  public func updateList(listURI: String, name: String, description: String?, purpose: UserList.Purpose) async throws {
    do {
      // Get the current user's session
      guard let session = try await client.protoClient.getUserSession() else {
        throw ListManagementError.noSession
      }
      
      // Map purpose to Bluesky's internal purpose
      let blueskyPurpose = mapPurposeToBluesky(purpose)
      
      // Create the updated list record
      let listRecord = AppBskyLexicon.Graph.ListDefinition(
        name: name,
        purpose: blueskyPurpose,
        description: description,
        createdAt: Date()
      )
      
      // Update the list using XRPC
      try await client.protoClient.updateRecord(
        repositoryDID: session.sessionDID,
        collection: "app.bsky.graph.list",
        recordKey: listURI,
        record: listRecord
      )
      
      #if DEBUG
      print("ListManagementService: Successfully updated list '\(name)'")
      #endif
      
    } catch {
      #if DEBUG
      print("ListManagementService: Failed to update list: \(error)")
      #endif
      throw ListManagementError.failedToUpdate(error.localizedDescription)
    }
  }
  
  /// Delete a list
  public func deleteList(listURI: String) async throws {
    do {
      // Delete the list using XRPC
      try await client.blueskyClient.deleteRecord(.recordURI(atURI: listURI))
      
      #if DEBUG
      print("ListManagementService: Successfully deleted list")
      #endif
      
    } catch {
      #if DEBUG
      print("ListManagementService: Failed to delete list: \(error)")
      #endif
      throw ListManagementError.failedToDelete(error.localizedDescription)
    }
  }
  
  // MARK: - Helper Methods
  
  private func mapPurposeToBluesky(_ purpose: UserList.Purpose) -> String {
    switch purpose {
    case .curation:
      return "app.bsky.graph.defs#curatelist"
    case .moderation:
      return "app.bsky.graph.defs#modlist"
    case .mute:
      return "app.bsky.graph.defs#mutelist"
    case .block:
      return "app.bsky.graph.defs#blocklist"
    }
  }
}

// MARK: - Error Types

public enum ListManagementError: Error, LocalizedError {
  case noSession
  case failedToCreate(String)
  case failedToUpdate(String)
  case failedToDelete(String)
  
  public var errorDescription: String? {
    switch self {
    case .noSession:
      return "No valid session found"
    case .failedToCreate(let message):
      return "Failed to create list: \(message)"
    case .failedToUpdate(let message):
      return "Failed to update list: \(message)"
    case .failedToDelete(let message):
      return "Failed to delete list: \(message)"
    }
  }
}
