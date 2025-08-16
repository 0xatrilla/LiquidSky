import Foundation
import ATProtoKit
import Models
import Client

@MainActor
public class UnifiedSearchService: ObservableObject {
  @Published var searchResults: [FeedSearchResult] = []
  @Published var isSearching = false
  @Published var searchError: Error?
  
  private let client: BSkyClient
  private var searchTask: Task<Void, Never>?
  
  public init(client: BSkyClient) {
    self.client = client
  }
  
  public func search(query: String) async {
    guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      searchResults = []
      return
    }
    
    // Cancel any existing search
    searchTask?.cancel()
    
    searchTask = Task {
      isSearching = true
      searchError = nil
      
      do {
        let feeds = try await searchFeeds(query: query)
        
        if !Task.isCancelled {
          searchResults = feeds
        }
      } catch {
        if !Task.isCancelled {
          searchError = error
        }
      }
      
      if !Task.isCancelled {
        isSearching = false
      }
    }
  }
  
  private func searchFeeds(query: String) async throws -> [FeedSearchResult] {
    do {
      let results = try await client.protoClient.getPopularFeedGenerators(matching: query)
      return results.feeds.map { feed in
        FeedSearchResult(
          uri: feed.feedURI,
          displayName: feed.displayName,
          description: feed.description,
          avatarURL: feed.avatarImageURL,
          creatorHandle: feed.creator.actorHandle,
          likesCount: feed.likeCount ?? 0,
          isLiked: feed.viewer?.likeURI != nil
        )
      }
    } catch {
      print("Error searching feeds: \(error)")
      return []
    }
  }
  
  public func clearSearch() {
    searchTask?.cancel()
    searchResults = []
    searchError = nil
    isSearching = false
  }
}

// MARK: - Search Result Models

public struct FeedSearchResult: Identifiable, Hashable {
  public var id: String { uri }
  public let uri: String
  public let displayName: String
  public let description: String?
  public let avatarURL: URL?
  public let creatorHandle: String
  public let likesCount: Int
  public let isLiked: Bool
}
