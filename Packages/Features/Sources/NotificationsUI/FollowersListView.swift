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
            ForEach(followers, id: \.actorDID) { follower in
              FollowerRowView(follower: follower)
                .onTapGesture {
                  let profile = Profile(
                    did: follower.actorDID,
                    handle: follower.actorHandle,
                    displayName: follower.displayName,
                    avatarImageURL: follower.avatarImageURL
                  )
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
  }
}

private struct FollowerRowView: View {
  let follower: AppBskyLexicon.Actor.ProfileViewDefinition

  var body: some View {
    HStack(spacing: 12) {
      // Avatar
      if let avatarURL = follower.avatarImageURL {
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
        Text(follower.displayName ?? follower.actorHandle)
          .font(.headline)
          .foregroundStyle(.primary)

        Text("@\(follower.actorHandle)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      // Follow button - convert to Profile model and use proper FollowButton
      let profile = Profile(
        did: follower.actorDID,
        handle: follower.actorHandle,
        displayName: follower.displayName,
        avatarImageURL: follower.avatarImageURL,
        isFollowing: false,  // New followers are typically not being followed by the current user
        isFollowedBy: true  // They are following the current user
      )

      FollowButton(profile: profile, size: .small)
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  FollowersListView(followers: [])
    .environment(AppRouter(initialTab: .feed))
}
