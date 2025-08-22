import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct FollowersListView: View {
  let followers: [AppBskyLexicon.Actor.ProfileViewDefinition]

  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @Environment(\.dismiss) private var dismiss
  @State private var followerProfiles: [Profile] = []

  public init(followers: [AppBskyLexicon.Actor.ProfileViewDefinition]) {
    self.followers = followers
  }

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Header
        VStack(spacing: 8) {
          Text("New Followers")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.primary)

          Text("\(followers.count) people followed you")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)

        // Followers list
        if followers.isEmpty {
          VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
              .font(.system(size: 48))
              .foregroundStyle(.secondary)

            Text("No followers to show")
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
    var profiles: [Profile] = []

    for follower in followers {
      do {
        // Get the full profile with following status
        let profileData = try await client.protoClient.getProfile(for: follower.actorDID)

        // Use the existing extension to convert to our Profile model
        let profileModel = profileData.profile

        profiles.append(profileModel)
      } catch {
        #if DEBUG
        print("Error loading profile for \(follower.actorDID): \(error)")
        #endif

        // Fallback to basic profile if we can't get the full one
        let fallbackProfile = Profile(
          did: follower.actorDID,
          handle: follower.actorHandle,
          displayName: follower.displayName,
          avatarImageURL: follower.avatarImageURL,
          isFollowing: false,  // Default to not following
          isFollowedBy: true  // They are following the current user
        )

        profiles.append(fallbackProfile)
      }
    }

    await MainActor.run {
      self.followerProfiles = profiles
    }
  }
}

private struct FollowerRowView: View {
  let profile: Profile

  var body: some View {
    HStack(spacing: 12) {
      // Avatar
      if let avatarURL = profile.avatarImageURL {
        AsyncImage(url: avatarURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Image(systemName: "person.circle.fill")
            .foregroundStyle(.secondary)
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

      // Follow button - now uses the actual following status
      FollowButton(profile: profile, size: .small)
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  FollowersListView(followers: [])
    .environment(AppRouter(initialTab: .feed))
}
