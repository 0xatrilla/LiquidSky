import ATProtoKit
import Foundation

@Observable
public final class BookmarkService: Sendable {
  private let client: BSkyClient
  
  public init(client: BSkyClient) {
    self.client = client
  }
  
  // MARK: - Bookmark Operations
  
  /// Create a bookmark for a post
  public func createBookmark(for post: PostItem) async throws {
    do {
      // Create a bookmark record using ATProtoKit
      let bookmarkRecord = AppBskyLexicon.Graph.StarterpackBookmarkDefinition(
        subject: AppBskyLexicon.Graph.StarterpackBookmarkDefinition.Subject(
          uri: post.uri,
          cid: post.cid
        ),
        createdAt: Date()
      )
      
      // Create the bookmark using the ATProtoKit client
      let response = try await client.protoClient.createRecord(
        repo: client.configuration.handle,
        collection: "app.bsky.graph.starterpack.bookmark",
        record: bookmarkRecord
      )
      
      #if DEBUG
      print("BookmarkService: Created bookmark for post \(post.uri)")
      print("BookmarkService: Response: \(response)")
      #endif
      
    } catch {
      #if DEBUG
      print("BookmarkService: Failed to create bookmark: \(error)")
      #endif
      throw BookmarkError.failedToCreate(error.localizedDescription)
    }
  }
  
  /// Remove a bookmark for a post
  public func removeBookmark(for post: PostItem) async throws {
    do {
      // First, we need to find the bookmark record URI
      let bookmarks = try await getBookmarks()
      
      guard let bookmark = bookmarks.first(where: { $0.postUri == post.uri }) else {
        throw BookmarkError.bookmarkNotFound
      }
      
      // Delete the bookmark record
      try await client.protoClient.deleteRecord(
        repo: client.configuration.handle,
        collection: "app.bsky.graph.starterpack.bookmark",
        recordKey: bookmark.recordKey
      )
      
      #if DEBUG
      print("BookmarkService: Removed bookmark for post \(post.uri)")
      #endif
      
    } catch {
      #if DEBUG
      print("BookmarkService: Failed to remove bookmark: \(error)")
      #endif
      throw BookmarkError.failedToRemove(error.localizedDescription)
    }
  }
  
  /// Check if a post is bookmarked
  public func isBookmarked(_ post: PostItem) async throws -> Bool {
    let bookmarks = try await getBookmarks()
    return bookmarks.contains { $0.postUri == post.uri }
  }
  
  /// Get all bookmarks for the current user
  public func getBookmarks() async throws -> [BookmarkItem] {
    do {
      let response = try await client.protoClient.listRecords(
        repo: client.configuration.handle,
        collection: "app.bsky.graph.starterpack.bookmark",
        limit: 100
      )
      
      let bookmarks = response.records.compactMap { record -> BookmarkItem? in
        guard let bookmarkRecord = record.value as? AppBskyLexicon.Graph.StarterpackBookmarkDefinition else {
          return nil
        }
        
        return BookmarkItem(
          recordKey: record.uri,
          postUri: bookmarkRecord.subject.uri,
          postCid: bookmarkRecord.subject.cid,
          createdAt: bookmarkRecord.createdAt
        )
      }
      
      #if DEBUG
      print("BookmarkService: Retrieved \(bookmarks.count) bookmarks")
      #endif
      
      return bookmarks
      
    } catch {
      #if DEBUG
      print("BookmarkService: Failed to get bookmarks: \(error)")
      #endif
      throw BookmarkError.failedToFetch(error.localizedDescription)
    }
  }
  
  /// Get bookmarked posts with full post data
  public func getBookmarkedPosts() async throws -> [PostItem] {
    let bookmarks = try await getBookmarks()
    var posts: [PostItem] = []
    
    for bookmark in bookmarks {
      do {
        // Fetch the full post data for each bookmark
        let thread = try await client.protoClient.getPostThread(from: bookmark.postUri)
        
        switch thread.thread {
        case .threadViewPost(let threadViewPost):
          posts.append(threadViewPost.post.postItem)
        default:
          // Skip if we can't get the post data
          continue
        }
      } catch {
        #if DEBUG
        print("BookmarkService: Failed to fetch post data for bookmark \(bookmark.postUri): \(error)")
        #endif
        // Continue with other bookmarks even if one fails
        continue
      }
    }
    
    return posts
  }
}

// MARK: - Bookmark Models

public struct BookmarkItem: Identifiable, Hashable, Sendable {
  public let id: String
  public let recordKey: String
  public let postUri: String
  public let postCid: String
  public let createdAt: Date
  
  public init(recordKey: String, postUri: String, postCid: String, createdAt: Date) {
    self.id = recordKey
    self.recordKey = recordKey
    self.postUri = postUri
    self.postCid = postCid
    self.createdAt = createdAt
  }
}

// MARK: - Bookmark Errors

public enum BookmarkError: LocalizedError {
  case failedToCreate(String)
  case failedToRemove(String)
  case failedToFetch(String)
  case bookmarkNotFound
  
  public var errorDescription: String? {
    switch self {
    case .failedToCreate(let message):
      return "Failed to create bookmark: \(message)"
    case .failedToRemove(let message):
      return "Failed to remove bookmark: \(message)"
    case .failedToFetch(let message):
      return "Failed to fetch bookmarks: \(message)"
    case .bookmarkNotFound:
      return "Bookmark not found"
    }
  }
}
