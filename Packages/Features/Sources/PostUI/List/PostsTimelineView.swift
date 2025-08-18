@preconcurrency import ATProtoKit
import Client
import DesignSystem
import Models
import SwiftUI
import User

public struct PostsTimelineView: View {
  @Environment(BSkyClient.self) var client

  public init() {}

  public var body: some View {
    PostListView(datasource: self)
  }
}

// MARK: - Datasource
extension PostsTimelineView: @MainActor PostsListViewDatasource {
  var title: String {
    "Following"
  }

  func loadPosts(with state: PostsListViewState) async -> PostsListViewState {
    do {
      switch state {
      case .uninitialized, .loading, .error:
        let feed = try await client.protoClient.getTimeline()

        // Debug logging to identify the issue
        print("Timeline feed received: \(feed.feed.count) posts")
        if let firstPost = feed.feed.first {
          print("First post structure: \(firstPost)")
          print("First post URI: \(firstPost.post.postItem.uri)")
          print("First post author: \(firstPost.post.author.actorHandle)")
        }

        // Validate feed data before processing
        guard !feed.feed.isEmpty else {
          print("Timeline feed is empty")
          return .error(
            NSError(
              domain: "TimelineError", code: 1,
              userInfo: [NSLocalizedDescriptionKey: "No posts found in timeline"]))
        }

        // Try to process the feed with enhanced error handling
        let posts = await PostListView.processFeed(feed.feed, client: client.protoClient)
        print("Successfully processed \(posts.count) posts from timeline")

        return .loaded(posts: posts, cursor: feed.cursor)
      case .loaded(let posts, let cursor):
        let feed = try await client.protoClient.getTimeline(cursor: cursor)
        let newPosts = await PostListView.processFeed(feed.feed, client: client.protoClient)
        return .loaded(posts: posts + newPosts, cursor: feed.cursor)
      }
    } catch {
      // Enhanced error handling to identify the specific issue
      print("Timeline error: \(error)")
      if let decodingError = error as? DecodingError {
        print("Decoding error details: \(decodingError)")

        // Provide more specific error messages for common issues
        switch decodingError {
        case .dataCorrupted(let context):
          return .error(
            NSError(
              domain: "TimelineError", code: 2,
              userInfo: [
                NSLocalizedDescriptionKey: "Data format error: \(context.debugDescription)"
              ]))
        case .keyNotFound(let key, let context):
          return .error(
            NSError(
              domain: "TimelineError", code: 3,
              userInfo: [
                NSLocalizedDescriptionKey:
                  "Missing data: \(key.stringValue) - \(context.debugDescription)"
              ]))
        case .typeMismatch(let type, let context):
          return .error(
            NSError(
              domain: "TimelineError", code: 4,
              userInfo: [
                NSLocalizedDescriptionKey:
                  "Type mismatch: expected \(type) - \(context.debugDescription)"
              ]))
        case .valueNotFound(let type, let context):
          return .error(
            NSError(
              domain: "TimelineError", code: 5,
              userInfo: [
                NSLocalizedDescriptionKey: "Value not found: \(type) - \(context.debugDescription)"
              ]))
        @unknown default:
          return .error(
            NSError(
              domain: "TimelineError", code: 6,
              userInfo: [NSLocalizedDescriptionKey: "Unknown decoding error: \(decodingError)"]))
        }
      }

      return .error(error)
    }
  }
}
