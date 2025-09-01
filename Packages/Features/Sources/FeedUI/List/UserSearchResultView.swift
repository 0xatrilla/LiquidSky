import AppRouter
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct UserSearchResultView: View {
  let profile: Profile
  @Environment(AppRouter.self) var router

  public init(profile: Profile) {
    self.profile = profile
  }

  public var body: some View {
    HStack(spacing: 12) {
      // Avatar
      if let avatarURL = profile.avatarImageURL {
        AsyncImage(url: avatarURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
              Image(systemName: "person.fill")
                .font(.title2)
                .foregroundColor(.gray)
            )
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
        .onTapGesture {
          // Force navigation within the current tab (search/compose)
          router[.compose].append(.profile(profile))
        }
      } else {
        Circle()
          .fill(Color.gray.opacity(0.3))
          .frame(width: 50, height: 50)
          .overlay(
            Image(systemName: "person.fill")
              .font(.title2)
              .foregroundColor(.gray)
          )
      }

      // User Info
      VStack(alignment: .leading, spacing: 4) {
        Text(profile.displayName ?? "")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        Text("@\(profile.handle)")
          .font(.body)
          .foregroundColor(.secondary)

        if let description = profile.description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundColor(.primary)
            .lineLimit(2)
        }

        HStack(spacing: 16) {
          Text("\(profile.followersCount) followers")
            .font(.caption)
            .foregroundColor(.secondary)

          Text("\(profile.postsCount) posts")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()
    }
    .padding(.vertical, 8)
    .contentShape(Rectangle())
    .onTapGesture {
      // Force navigation within the current tab (search/compose)
      router[.compose].append(.profile(profile))
    }
  }
}

#Preview {
  List {
    UserSearchResultView(
      profile: Profile(
        did: "did:example:123",
        handle: "testuser",
        displayName: "Test User",
        avatarImageURL: nil,
        description: "This is a test user with a bio",
        followersCount: 42,
        followingCount: 15,
        postsCount: 128,
        isFollowing: false
      )
    )

    UserSearchResultView(
      profile: Profile(
        did: "did:example:456",
        handle: "testuser2",
        displayName: "Another Test User",
        avatarImageURL: nil,
        description: "Another test user with a different bio",
        followersCount: 156,
        followingCount: 89,
        postsCount: 256,
        isFollowing: true
      )
    )
  }
  .listStyle(.plain)
  .environment(AppRouter(initialTab: .feed))
}
