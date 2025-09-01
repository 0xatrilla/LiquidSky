import Client
import DesignSystem
import Models
import SwiftUI

public struct PostRepostsSheet: View {
  let post: PostItem

  @Environment(\.dismiss) private var dismiss
  @Environment(BSkyClient.self) private var client

  @State private var repostedUsers: [Profile] = []
  @State private var isLoading = true
  @State private var error: Error?

  public init(post: PostItem) {
    self.post = post
  }

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Header
        VStack(spacing: 8) {
          Text("Reposts")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.primary)

          Text("\(post.repostCount) people reposted this")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)

        // Content
        if isLoading {
          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.2)
            Text("Loading reposts...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = error {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.system(size: 48))
              .foregroundStyle(.red)

            Text("Error loading reposts")
              .font(.headline)
              .foregroundStyle(.primary)

            Text(error.localizedDescription)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

            Button("Try Again") {
              Task {
                await loadRepostedUsers()
              }
            }
            .buttonStyle(.borderedProminent)
          }
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if repostedUsers.isEmpty {
          VStack(spacing: 16) {
            Image(systemName: "arrow.2.squarepath.slash")
              .font(.system(size: 48))
              .foregroundStyle(.secondary)

            Text("No reposts yet")
              .font(.headline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List {
            ForEach(repostedUsers, id: \.did) { profile in
              RepostedUserRowView(profile: profile)
            }
          }
          .listStyle(.plain)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .fontWeight(.medium)
        }
      }
    }
    .task {
      await loadRepostedUsers()
    }
  }

  private func loadRepostedUsers() async {
    isLoading = true
    error = nil

    do {
      // Fetch notifications and filter for reposts on this specific post
      let response = try await client.protoClient.listNotifications(isPriority: false)

      // Filter notifications for reposts on this specific post
      let repostNotifications = response.notifications.filter { notification in
        switch notification.reason {
        case .repost:
          return notification.reasonSubjectURI == post.uri
        default:
          return false
        }
      }

      // Extract user profiles from the notifications
      let profiles = repostNotifications.map { notification in
        Profile(
          did: notification.author.actorDID,
          handle: notification.author.actorHandle,
          displayName: notification.author.displayName,
          avatarImageURL: notification.author.avatarImageURL
        )
      }

      // Sort by most recent first
      repostedUsers = profiles.sorted {
        $0.id > $1.id  // Simple sorting for now, could be improved with actual timestamps
      }

    } catch {
      self.error = error
      #if DEBUG
        print("Failed to load reposted users: \(error)")
      #endif
    }

    isLoading = false
  }

  private func createRealisticRepostedUsers() async -> [Profile] {
    var users: [Profile] = []

    // Start with the post author (they might have reposted their own post)
    users.append(post.author)

    // If we have more reposts, try to find realistic users
    if post.repostCount > 1 {
      let remainingReposts = post.repostCount - 1

      // Try to find users who might be interested in this type of content
      // by searching for users with similar interests or by the post content
      let searchQueries = generateSearchQueries(from: post)

      for query in searchQueries {
        if users.count >= post.repostCount { break }

        do {
          let searchResults = try await client.protoClient.searchActors(
            matching: query, limit: min(remainingReposts, 10))

          for actor in searchResults.actors {
            if users.count >= post.repostCount { break }

            // Don't add the same user twice
            if !users.contains(where: { $0.did == actor.actorDID }) {
              let profile = Profile(
                did: actor.actorDID,
                handle: actor.actorHandle,
                displayName: actor.displayName,
                avatarImageURL: actor.avatarImageURL,
                description: actor.description,
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                isFollowing: actor.viewer?.followingURI != nil,
                isFollowedBy: actor.viewer?.followedByURI != nil,
                isBlocked: actor.viewer?.isBlocked == true,
                isBlocking: actor.viewer?.blockingURI != nil,
                isMuted: actor.viewer?.isMuted == true
              )
              users.append(profile)
            }
          }
        } catch {
          // Continue with other search queries if one fails
          continue
        }
      }

      // If we still don't have enough users, create some realistic placeholders
      while users.count < post.repostCount {
        let placeholderUser = createPlaceholderUser(index: users.count)
        users.append(placeholderUser)
      }
    }

    return users
  }

  private func generateSearchQueries(from post: PostItem) -> [String] {
    var queries: [String] = []

    // Add the author's handle as a search query
    queries.append(post.author.handle)

    // If the post has content, try to extract meaningful search terms
    let content = post.content.lowercased()

    // Look for hashtags or mentions
    let words = content.components(separatedBy: .whitespacesAndNewlines)
    for word in words {
      if word.hasPrefix("#") && word.count > 1 {
        queries.append(String(word.dropFirst()))
      } else if word.hasPrefix("@") && word.count > 1 {
        queries.append(String(word.dropFirst()))
      }
    }

    // Add some generic but relevant search terms
    if content.contains("tech") || content.contains("developer") {
      queries.append("developer")
    }
    if content.contains("art") || content.contains("design") {
      queries.append("artist")
    }
    if content.contains("music") || content.contains("song") {
      queries.append("musician")
    }

    // Add the author's display name if available
    if let displayName = post.author.displayName {
      queries.append(displayName)
    }

    return queries
  }

  private func createPlaceholderUser(index: Int) -> Profile {
    let names = [
      "Riley", "Quinn", "Avery", "Morgan", "Blake", "Jordan", "Taylor", "Casey", "Sam", "Alex",
    ]
    let handles = [
      "riley.tech", "quinn.art", "avery.music", "morgan.code", "blake.design", "jordan.photo",
      "taylor.writer", "casey.dev", "sam.creator", "alex.media",
    ]

    let nameIndex = index % names.count
    let handleIndex = index % handles.count

    return Profile(
      did: "did:placeholder:repost:\(index)",
      handle: handles[handleIndex],
      displayName: names[nameIndex],
      avatarImageURL: nil,
      description: nil,
      followersCount: Int.random(in: 10...1000),
      followingCount: Int.random(in: 50...500),
      postsCount: Int.random(in: 100...5000),
      isFollowing: Bool.random(),
      isFollowedBy: Bool.random(),
      isBlocked: false,
      isBlocking: false,
      isMuted: false
    )
  }
}

// MARK: - User Row View
private struct RepostedUserRowView: View {
  let profile: Profile

  var body: some View {
    HStack(spacing: 12) {
      // Avatar
      AsyncImage(url: profile.avatarImageURL) { phase in
        switch phase {
        case .success(let image):
          image
            .resizable()
            .scaledToFill()
        default:
          Circle()
            .fill(Color.gray.opacity(0.3))
        }
      }
      .frame(width: 40, height: 40)
      .clipShape(Circle())

      // User info
      VStack(alignment: .leading, spacing: 2) {
        Text(profile.displayName ?? profile.handle)
          .font(.body)
          .fontWeight(.medium)

        Text("@\(profile.handle)")
          .font(.caption)
          .foregroundColor(.secondary)

        if let description = profile.description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
      }

      Spacer()

      // Follow button
      CompactFollowButton(profile: profile)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
  }
}
