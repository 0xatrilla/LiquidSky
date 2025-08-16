import ATProtoKit
import Client
import Foundation
import Models

@MainActor
public class UserSearchService: ObservableObject {
  @Published var searchResults: [Profile] = []
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
        let users = try await searchUsers(query: query)

        if !Task.isCancelled {
          searchResults = users
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

  private func searchUsers(query: String) async throws -> [Profile] {
    do {
      let results = try await client.protoClient.searchActors(matching: query, limit: 20)
      return results.actors.map { actor in
        Profile(
          did: actor.actorDID,
          handle: actor.actorHandle,
          displayName: actor.displayName,
          avatarImageURL: actor.avatarImageURL,
          description: actor.description,
          followersCount: 0,  // Will be updated when full profile is fetched
          followingCount: 0,  // Will be updated when full profile is fetched
          postsCount: 0,  // Will be updated when full profile is fetched
          isFollowing: actor.viewer?.followingURI != nil,
          isFollowedBy: actor.viewer?.followedByURI != nil,
          isBlocked: actor.viewer?.isBlocked == true,
          isBlocking: actor.viewer?.blockingURI != nil,
          isMuted: actor.viewer?.isMuted == true
        )
      }
    } catch {
      print("Error searching users: \(error)")
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
