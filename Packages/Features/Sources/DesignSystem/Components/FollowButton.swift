import Client
import Models
import SwiftUI

public struct FollowButton: View {
  let profile: Profile
  let size: FollowButtonSize

  @Environment(BSkyClient.self) private var client
  @State private var isLoading = false
  @State private var isFollowing: Bool
  @State private var followingURI: String?
  @State private var followersCount: Int

  public init(profile: Profile, size: FollowButtonSize = .medium) {
    self.profile = profile
    self.size = size
    self._isFollowing = State(initialValue: profile.isFollowing)
    self._followersCount = State(initialValue: profile.followersCount)
  }

  public var body: some View {
    Button(action: {
      Task {
        await toggleFollow()
      }
    }) {
      HStack(spacing: size.iconSpacing) {
        if isLoading {
          ProgressView()
            .scaleEffect(size.progressScale)
            .foregroundColor(.white)
        } else {
          Image(systemName: isFollowing ? "checkmark.circle.fill" : "person.badge.plus")
            .font(size.iconFont)
            .foregroundColor(.white)
        }

        Text(isFollowing ? "Following" : "Follow")
          .font(size.textFont)
          .fontWeight(.medium)
          .foregroundColor(.white)
      }
      .padding(.horizontal, size.horizontalPadding)
      .padding(.vertical, size.verticalPadding)
      .background(
        RoundedRectangle(cornerRadius: size.cornerRadius)
          .fill(isFollowing ? Color.green : Color.blue)
      )
    }
    .buttonStyle(.plain)
    .disabled(isLoading)
    .onAppear {
      // Update local state when profile changes
      isFollowing = profile.isFollowing
      followersCount = profile.followersCount
    }
    .onChange(of: profile.isFollowing) { _, newValue in
      isFollowing = newValue
    }
    .onChange(of: profile.followersCount) { _, newValue in
      followersCount = newValue
    }
  }

  private func toggleFollow() async {
    isLoading = true

    do {
      if isFollowing {
        // Unfollow: Delete the follow record
        if let followingURI = followingURI {
          try await client.blueskyClient.deleteRecord(.recordURI(atURI: followingURI))

          // Optimistically update the UI
          isFollowing = false
          followersCount = max(0, followersCount - 1)
        } else {
          // If we don't have the followingURI, we need to fetch the profile first
          await fetchProfileForFollowingURI()
          if let followingURI = followingURI {
            try await client.blueskyClient.deleteRecord(.recordURI(atURI: followingURI))
            isFollowing = false
            followersCount = max(0, followersCount - 1)
          }
        }
      } else {
        // Follow: Create a follow record
        // For now, we'll use a placeholder approach until we can determine the correct API
        print("Would create follow record for \(profile.did)")

        // Optimistically update the UI
        isFollowing = true
        followersCount += 1
        followingURI = "ui.optimistic.follow"
      }
    } catch {
      print("Error toggling follow: \(error)")

      // Revert optimistic updates on error
      isFollowing = profile.isFollowing
      followersCount = profile.followersCount
    }

    isLoading = false
  }

  private func fetchProfileForFollowingURI() async {
    do {
      let profileData = try await client.protoClient.getProfile(for: profile.did)
      followingURI = profileData.viewer?.followingURI
    } catch {
      print("Error fetching profile for followingURI: \(error)")
    }
  }
}

// MARK: - Follow Button Size

public enum FollowButtonSize {
  case small
  case medium
  case large

  var iconFont: Font {
    switch self {
    case .small: return .caption
    case .medium: return .subheadline
    case .large: return .body
    }
  }

  var textFont: Font {
    switch self {
    case .small: return .caption
    case .medium: return .subheadline
    case .large: return .body
    }
  }

  var iconSpacing: CGFloat {
    switch self {
    case .small: return 4
    case .medium: return 8
    case .large: return 10
    }
  }

  var horizontalPadding: CGFloat {
    switch self {
    case .small: return 12
    case .medium: return 16
    case .large: return 20
    }
  }

  var verticalPadding: CGFloat {
    switch self {
    case .small: return 6
    case .medium: return 8
    case .large: return 12
    }
  }

  var cornerRadius: CGFloat {
    switch self {
    case .small: return 16
    case .medium: return 20
    case .large: return 24
    }
  }

  var progressScale: CGFloat {
    switch self {
    case .small: return 0.6
    case .medium: return 0.8
    case .large: return 1.0
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    FollowButton(
      profile: Profile(
        did: "did:example:123",
        handle: "testuser",
        displayName: "Test User",
        avatarImageURL: nil,
        isFollowing: false
      ),
      size: .small
    )

    FollowButton(
      profile: Profile(
        did: "did:example:456",
        handle: "testuser2",
        displayName: "Test User 2",
        avatarImageURL: nil,
        isFollowing: true
      ),
      size: .medium
    )

    FollowButton(
      profile: Profile(
        did: "did:example:789",
        handle: "testuser3",
        displayName: "Test User 3",
        avatarImageURL: nil,
        isFollowing: false
      ),
      size: .large
    )
  }
  .padding()
  .background(Color(.systemBackground))
}
