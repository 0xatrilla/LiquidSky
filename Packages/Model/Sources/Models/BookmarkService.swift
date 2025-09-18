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
    // Use blueskyClient to create bookmark record
    // This follows the same pattern as likes and reposts
    let response = try await client.blueskyClient.createBookmarkRecord(
      .init(recordURI: post.uri, cidHash: post.cid)
    // Create bookmark record using the generic record creation approach
    // This follows the same pattern as other record operations
    let bookmarkRecord = BookmarkRecord(
      subject: BookmarkSubject(uri: post.uri, cid: post.cid),
      createdAt: Date()
    )

    let recordData = try ATProtoKitJSONEncoder().encode(bookmarkRecord)
    let recordDict = try JSONSerialization.jsonObject(with: recordData) as! [String: Any]

recordDict    )

    #if DEBUG
    print("BookmarkService: Created bookmark for post \(post.uri) with URI \(response.recordURI)")
    #endif
  }

  /// Remove a bookmark for a post
  public func removeBookmark(for post: PostItem) async throws {
    // First, find the bookmark record for this post
    let bookmarks = try await getBookmarkRecords()

    for bookmark in bookmarks {
      if let subject = bookmark.value.subject,
         subject.uri == post.uri {

        // Delete the bookmark record
        try await client.blueskyClient.deleteRecord(.recordURI(atURI: bookmark.uri))

        #if DEBUG
        print("BookmarkService: Removed bookmark for post \(post.uri)")
        #endif
        return
      }
    }

    throw BookmarkError.bookmarkNotFound
  }

  /// Get all bookmarks for the current user
  public func getBookmarks() async throws -> [PostItem] {
    // Get all bookmark records
    let bookmarkRecords = try await getBookmarkRecords()

    // Convert bookmark records to PostItems
    var posts: [PostItem] = []

    for bookmark in bookmarkRecords {
      guard let subject = bookmark.value.subject else { continue }

      // Fetch the original post from the bookmark subject
      do {
        let postResponse = try await client.protoClient.getPostThread(from: subject.uri)

        if let threadPost = postResponse.thread.post {
          let postItem = PostItem(
            uri: threadPost.uri,
            cid: threadPost.cid,
            author: threadPost.author,
            content: threadPost.record.text,
            indexedAt: threadPost.indexedAt,
            likeCount: threadPost.likeCount ?? 0,
            repostCount: threadPost.repostCount ?? 0,
            replyCount: threadPost.replyCount ?? 0,
            likeURI: threadPost.viewer?.like,
            repostURI: threadPost.viewer?.repost,
            isReplyTo: threadPost.reply != nil,
            hasReply: threadPost.replyCount ?? 0 > 0
          )
          posts.append(postItem)
        }
      } catch {
        print("BookmarkService: Failed to fetch post for bookmark \(subject.uri): \(error)")
      }
    }

    #if DEBUG
    print("BookmarkService: Retrieved \(posts.count) bookmarks")
    #endif

    return posts
  }

  /// Check if a post is bookmarked
  public func isBookmarked(_ post: PostItem) async throws -> Bool {
    // Get all bookmark records and check if this post exists
    let bookmarks = try await getBookmarkRecords()

    for bookmark in bookmarks {
      if let subject = bookmark.value.subject,
         subject.uri == post.uri {
        return true
      }
    }

    return false
  }

  // MARK: - Helper Methods

  /// Get all bookmark records for the current user
  private func getBookmarkRecords() async throws -> [ATProtoKit.Record] {
    // Use the ATProtoKit to list bookmarks from the user's repository
    let session = try await client.protoClient.session

    guard let userDID = session.did else {
      throw BookmarkError.noSession
    }

    // Get bookmarks from the user's repository
    let response = try await client.protoClient.findRecords(
      collection: "app.bsky.graph.bookmark",
      repo: userDID
    )

    return response.records
  }
}

// MARK: - Supporting Types

private struct BookmarkRecord: Codable {
  let subject: BookmarkSubject
  let createdAt: String

  init(subject: BookmarkSubject, createdAt: Date) {
    self.subject = subject
    self.createdAt = ISO8601DateFormatter().string(from: createdAt)
  }
}

private struct BookmarkSubject: Codable {
  let uri: String
  let cid: String
}

private class ATProtoKitJSONEncoder: JSONEncoder {
  init() {
    super.init()
    self.dateEncodingStrategy = .iso8601
    self.keyEncodingStrategy = .convertToSnakeCase
  }
}

// MARK: - Error Types

public enum BookmarkError: Error, LocalizedError {
  case noSession
  case bookmarkFailed(Error)
  case retrievalFailed(Error)
  case bookmarkNotFound

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
    }
  }
}
