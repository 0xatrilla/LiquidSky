import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import NukeUI
import SwiftUI

public struct FollowingListView: View {
  let profile: Profile

  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @Environment(\.dismiss) private var dismiss
  @State private var followingProfiles: [Profile] = []
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
          Text("Following")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.primary)

          Text("People \(profile.displayName ?? profile.handle) follows")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)

        // Following list
        if isLoading {
          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.2)
            Text("Loading following...")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = error {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.system(size: 48))
              .foregroundStyle(.red)

            Text("Error loading following")
              .font(.headline)
              .foregroundStyle(.primary)

            Text(error.localizedDescription)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

            Button("Try Again") {
              Task {
                await loadFollowingProfiles()
              }
            }
            .buttonStyle(.borderedProminent)
          }
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if followingProfiles.isEmpty {
          VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
              .font(.system(size: 48))
              .foregroundStyle(.secondary)

            Text("Not following anyone")
              .font(.headline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          List {
            ForEach(followingProfiles, id: \.did) { profile in
              FollowingRowView(profile: profile)
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
      await loadFollowingProfiles()
    }
  }

  private func loadFollowingProfiles() async {
    isLoading = true
    error = nil

    do {
      let followingData = try await client.protoClient.getFollows(from: profile.did)
      let profiles = followingData.follows.map { follow in
        Profile(
          did: follow.actorDID,
          handle: follow.actorHandle,
          displayName: follow.displayName,
          avatarImageURL: follow.avatarImageURL
        )
      }

      await MainActor.run {
        self.followingProfiles = profiles
        self.isLoading = false
      }
    } catch {
      await MainActor.run {
        self.error = error
        self.isLoading = false
      }
      #if DEBUG
        print("Error loading following for \(profile.did): \(error)")
      #endif
    }
  }
}

private struct FollowingRowView: View {
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
  FollowingListView(
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
