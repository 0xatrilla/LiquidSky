import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import NukeUI
import SwiftUI

public struct FollowersListView: View {
  let profile: Profile

  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @Environment(\.dismiss) private var dismiss
  @State private var followerProfiles: [Profile] = []
  @State private var isLoading = true
  @State private var error: Error?

  public init(profile: Profile) {
    self.profile = profile
  }

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Header
        VStack(spacing: 8) {
          Text("Followers")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.primary)

          Text("People following \(profile.displayName ?? profile.handle)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)

        // Followers list
        if isLoading {
          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.2)
            Text("Loading followers...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = error {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.system(size: 48))
              .foregroundStyle(.red)

            Text("Error loading followers")
              .font(.headline)
              .foregroundStyle(.primary)

            Text(error.localizedDescription)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

            Button("Try Again") {
              Task {
                await loadFollowerProfiles()
              }
            }
            .buttonStyle(.borderedProminent)
          }
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if followerProfiles.isEmpty {
          VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
              .font(.system(size: 48))
              .foregroundStyle(.secondary)

            Text("No followers")
              .font(.headline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List {
            ForEach(followerProfiles, id: \.did) { profile in
              FollowerRowView(profile: profile)
                .onTapGesture {
                  dismiss()
                  router.navigateTo(.profile(profile))
                }
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
      await loadFollowerProfiles()
    }
  }

  private func loadFollowerProfiles() async {
    isLoading = true
    error = nil

    do {
      let followersData = try await client.protoClient.getFollowers(by: profile.did)

      // Check if current user is following each profile
      let profiles = await withTaskGroup(of: Profile.self) { group in
        for follower in followersData.followers {
          group.addTask {
            // Check if current user is following this profile
            let isFollowing = await self.checkIfCurrentUserIsFollowing(follower.actorDID)

            return Profile(
              did: follower.actorDID,
              handle: follower.actorHandle,
              displayName: follower.displayName,
              avatarImageURL: follower.avatarImageURL,
              description: nil,
              followersCount: 0,
              followingCount: 0,
              postsCount: 0,
              isFollowing: isFollowing
            )
          }
        }

        var results: [Profile] = []
        for await profile in group {
          results.append(profile)
        }
        return results.sorted { $0.handle < $1.handle }
      }

      await MainActor.run {
        self.followerProfiles = profiles
        self.isLoading = false
      }
    } catch {
      await MainActor.run {
        self.error = error
        self.isLoading = false
      }
      #if DEBUG
        print("Error loading followers for \(profile.did): \(error)")
      #endif
    }
  }

  private func checkIfCurrentUserIsFollowing(_ targetDID: String) async -> Bool {
    do {
      let currentUserProfile = try await client.protoClient.getProfile(for: targetDID)
      return currentUserProfile.viewer?.followingURI != nil
    } catch {
      #if DEBUG
        print("Error checking follow status for \(targetDID): \(error)")
      #endif
      return false
    }
  }
}

private struct FollowerRowView: View {
  let profile: Profile

  var body: some View {
    HStack(spacing: 12) {
      // Avatar
      if let avatarURL = profile.avatarImageURL {
        LazyImage(url: avatarURL) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            Image(systemName: "person.circle.fill")
              .foregroundStyle(.secondary)
          }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
        .overlay(
          Circle()
            .stroke(LinearGradient.avatarBorder, lineWidth: 1)
        )
      } else {
        Image(systemName: "person.circle.fill")
          .font(.system(size: 48))
          .foregroundStyle(.secondary)
      }

      // User info
      VStack(alignment: .leading, spacing: 4) {
        Text(profile.displayName ?? profile.handle)
          .font(.headline)
          .foregroundStyle(.primary)

        Text("@\(profile.handle)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      // Follow button
      FollowButton(profile: profile, size: .small)
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  FollowersListView(
    profile: Profile(
      did: "did:example:123",
      handle: "testuser",
      displayName: "Test User",
      avatarImageURL: nil,
      description: "Test user",
      followersCount: 42,
      followingCount: 15,
      postsCount: 128,
      isFollowing: false
    )
  )
  .environment(AppRouter(initialTab: .feed))
}
