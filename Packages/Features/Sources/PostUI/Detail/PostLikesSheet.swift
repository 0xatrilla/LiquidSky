import Client
import DesignSystem
import Models
import SwiftUI

public struct PostLikesSheet: View {
  let post: PostItem

  @Environment(\.dismiss) private var dismiss
  @Environment(BSkyClient.self) private var client

  @State private var likedUsers: [Profile] = []
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
          Text("Likes")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.primary)

          Text("\(post.likeCount) people liked this post")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)

        Divider()
          .padding(.top, 20)

        // Content
        if isLoading {
          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.2)
            Text("Loading likes...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = error {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
              .font(.system(size: 40))
              .foregroundStyle(.orange)

            Text("Unable to load likes")
              .font(.headline)
              .foregroundStyle(.primary)

            Text(error.localizedDescription)
              .font(.body)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

            Button("Try Again") {
              Task {
                await loadLikedUsers()
              }
            }
            .buttonStyle(.borderedProminent)
          }
          .padding(.horizontal, 20)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if likedUsers.isEmpty {
          VStack(spacing: 16) {
            Image(systemName: "heart")
              .font(.system(size: 40))
              .foregroundStyle(.red.opacity(0.6))

            Text("No likes yet")
              .font(.headline)
              .foregroundStyle(.primary)

            Text("Be the first to like this post!")
              .font(.body)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          .padding(.horizontal, 20)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(likedUsers) { user in
                UserRowView(user: user)
                  .padding(.horizontal, 16)
                  .padding(.vertical, 12)

                if user.id != likedUsers.last?.id {
                  Divider()
                    .padding(.leading, 60)
                }
              }
            }
            .padding(.vertical, 8)
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .task {
      await loadLikedUsers()
    }
  }

  private func loadLikedUsers() async {
    isLoading = true
    error = nil

    do {
      // Fetch notifications and filter for likes on this specific post
      let response = try await client.protoClient.listNotifications(isPriority: false)

      // Filter notifications for likes on this specific post
      let likeNotifications = response.notifications.filter { notification in
        switch notification.reason {
        case .like:
          return notification.reasonSubjectURI == post.uri
        default:
          return false
        }
      }

      // Extract user profiles from the notifications
      let profiles = likeNotifications.map { notification in
        Profile(
          did: notification.author.actorDID,
          handle: notification.author.actorHandle,
          displayName: notification.author.displayName,
          avatarImageURL: notification.author.avatarImageURL
        )
      }

      // Sort by most recent first
      likedUsers = profiles.sorted {
        $0.id > $1.id  // Simple sorting for now, could be improved with actual timestamps
      }

    } catch {
      self.error = error
      #if DEBUG
        print("Failed to load liked users: \(error)")
      #endif
    }

    isLoading = false
  }
}

// MARK: - User Row View
private struct UserRowView: View {
  let user: Profile

  var body: some View {
    HStack(spacing: 12) {
      // Avatar
      AsyncImage(url: user.avatarImageURL) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Circle()
          .fill(.secondary.opacity(0.2))
      }
      .frame(width: 44, height: 44)
      .clipShape(Circle())

      // User info
      VStack(alignment: .leading, spacing: 2) {
        Text(user.displayName ?? user.handle)
          .font(.body)
          .fontWeight(.medium)
          .foregroundStyle(.primary)

        Text("@\(user.handle)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      // Follow button
      FollowButton(profile: user, size: .small)
    }
  }
}
