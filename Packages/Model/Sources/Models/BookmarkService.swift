import ATProtoKit
import Foundation
import Client

@Observable
public final class BookmarkService: Sendable {
  private let client: BSkyClient

  public init(client: BSkyClient) {
    self.client = client
  }

  // MARK: - Bookmark Operations

  /// Create a bookmark for a post
  public func createBookmark(for post: PostItem) async throws {
    // Get the current user's DID from the session
    guard let session = try await client.protoClient.getUserSession() else {
      throw BookmarkError.noSession
    }

    let repositoryDID = session.sessionDID

    // Create bookmark record using the ATProtoKit API
    let bookmarkData: [String: CodableValue] = [
      "subject": [
        "uri": .string(post.uri),
        "cid": .string(post.cid)
      ],
      "createdAt": .string(ISO8601DateFormatter().string(from: Date()))
    ]

    let record = try await client.protoClient.createRecord(
      repositoryDID: repositoryDID,
      collection: "app.bsky.graph.bookmark",
      record: .unknown(bookmarkData)
    )

    #if DEBUG
    print("BookmarkService: Created bookmark for post \(post.uri) with record \(record)")
    #endif
  }

  /// Remove a bookmark for a post
  public func removeBookmark(for post: PostItem) async throws {
    // For now, this is a simplified implementation
    // In a complete implementation, we would need to track the bookmark URI
    // and use it to delete the specific record
    #if DEBUG
    print("BookmarkService: Remove bookmark not fully implemented")
    #endif
    throw BookmarkError.notImplemented
  }

  /// Get all bookmarks for the current user - simplified implementation
  public func getBookmarks() async throws -> [PostItem] {
    // For now, return empty array until we can properly fetch bookmarks
    // This is a limitation of the current ATProtoKit implementation
    #if DEBUG
    print("BookmarkService: getBookmarks() not fully implemented - returning empty array")
    #endif
    return []
  }

  /// Check if a post is bookmarked - simplified implementation
  public func isBookmarked(_ post: PostItem) async throws -> Bool {
    // For now, return false until we can properly check bookmarks
    // This is a limitation of the current ATProtoKit implementation
    return false
  }
}

// MARK: - Error Types

public enum BookmarkError: Error, LocalizedError {
  case noSession
  case bookmarkFailed(Error)
  case retrievalFailed(Error)
  case bookmarkNotFound
  case notImplemented

  public var errorDescription: String? {
    switch self {
    case .noSession:
      return "No active session found"
    case .bookmarkFailed(let error):
      return "Failed to bookmark post: \(error.localizedDescription)"
    case .retrievalFailed(let error):
      return "Failed to retrieve bookmarks: \(error.localizedDescription)"
    case .bookmarkNotFound:
      return "Bookmark not found"
    case .notImplemented:
      return "This bookmark feature is not yet implemented"
    }
  }
}
