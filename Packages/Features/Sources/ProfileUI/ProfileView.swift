import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import PostUI
import SwiftUI

public struct ProfileView: View {
  let profile: Profile
  let showBack: Bool
  let isCurrentUser: Bool

  @Namespace private var namespace
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client

  @State private var fullProfile: Profile?
  @State private var isLoadingProfile = false
  @State private var profileError: Error?

  public init(profile: Profile, showBack: Bool = true, isCurrentUser: Bool = false) {
    self.profile = profile
    self.showBack = showBack
    self.isCurrentUser = isCurrentUser
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        // Profile Header
        profileHeader
          .padding(.horizontal)
          .padding(.top)

        // Profile Stats
        profileStats
          .padding(.horizontal)
          .padding(.vertical, 16)

        // Bio Section
        if let description = (fullProfile ?? profile).description, !description.isEmpty {
          bioSection(description: description)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }

        // Relationship Status (for other users)
        if !isCurrentUser {
          relationshipStatusSection
            .padding(.horizontal)
            .padding(.bottom, 16)
        }

        // Action Buttons
        actionButtons
          .padding(.horizontal)
          .padding(.bottom, 24)

        // Content Tabs
        contentTabs
          .padding(.horizontal)
      }
    }
    .background(.background)
    .navigationBarBackButtonHidden()
    .task {
      await fetchFullProfile()
    }
  }

  // MARK: - Profile Header
  private var profileHeader: some View {
    HStack(alignment: .top, spacing: 16) {
      // Avatar
      if let avatarURL = (fullProfile ?? profile).avatarImageURL {
        AsyncImage(url: avatarURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
              Image(systemName: "person.fill")
                .font(.title)
                .foregroundColor(.gray)
            )
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(
          Circle()
            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
        .onTapGesture {
          router.presentedSheet = SheetDestination.fullScreenProfilePicture(
            imageURL: avatarURL,
            namespace: namespace
          )
        }
      } else {
        Circle()
          .fill(Color.gray.opacity(0.3))
          .frame(width: 80, height: 80)
          .overlay(
            Image(systemName: "person.fill")
              .font(.title)
              .foregroundColor(.gray)
          )
      }

      // User Info
      VStack(alignment: .leading, spacing: 4) {
        Text((fullProfile ?? profile).displayName ?? "")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)

        Text("@\((fullProfile ?? profile).handle)")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      Spacer()
    }
  }

  // MARK: - Profile Stats
  private var profileStats: some View {
    HStack(spacing: 32) {
      VStack(spacing: 4) {
        Text("\((fullProfile ?? profile).postsCount)")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
        Text("Posts")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      VStack(spacing: 4) {
        Text("\((fullProfile ?? profile).followingCount)")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
        Text("Following")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      VStack(spacing: 4) {
        Text("\((fullProfile ?? profile).followersCount)")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
        Text("Followers")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Bio Section
  private func bioSection(description: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Bio")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      Text((fullProfile ?? profile).description ?? "")
        .font(.body)
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Action Buttons
  private var actionButtons: some View {
    HStack(spacing: 12) {
      ShareLink(
        item: createProfileShareText(),
        subject: Text("Check out this profile"),
        message: Text("I found this interesting profile on Bluesky")
      ) {
        Label("Share", systemImage: "square.and.arrow.up")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.primary)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 20)
              .fill(Color.gray.opacity(0.1))
          )
      }

      Button(action: {
        // TODO: Implement more options
      }) {
        Image(systemName: "ellipsis")
          .font(.subheadline)
          .foregroundColor(.primary)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 20)
              .fill(Color.gray.opacity(0.1))
          )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Share Helper
  private func createProfileShareText() -> String {
    var shareText = ""

    if let displayName = (fullProfile ?? profile).displayName {
      shareText += "\(displayName)"
    }

    shareText += " (@\((fullProfile ?? profile).handle))"

    if let description = (fullProfile ?? profile).description, !description.isEmpty {
      shareText += "\n\n\(description)"
    }

    shareText += "\n\nProfile: https://bsky.app/profile/\((fullProfile ?? profile).handle)"

    return shareText
  }

  // MARK: - Content Tabs
  private var contentTabs: some View {
    VStack(spacing: 16) {
      // Section Header
      HStack {
        Text("Content")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
        Spacer()
      }

      // Tab Buttons
      VStack(spacing: 12) {
        NavigationLink(
          value: RouterDestination.profilePosts(profile: profile, filter: .postsWithNoReplies)
        ) {
          makeTabButton(
            title: "Posts", icon: "bubble.fill", color: .blueskyPrimary,
            count: (fullProfile ?? profile).postsCount)
        }

        NavigationLink(
          value: RouterDestination.profilePosts(profile: profile, filter: .userReplies)
        ) {
          makeTabButton(
            title: "Replies", icon: "arrowshape.turn.up.left.fill", color: .blueskySecondary,
            count: nil)
        }

        NavigationLink(
          value: RouterDestination.profilePosts(profile: profile, filter: .postsWithMedia)
        ) {
          makeTabButton(
            title: "Media", icon: "photo.fill", color: .blueskyAccent,
            count: (fullProfile ?? profile).postsCount > 0
              ? (fullProfile ?? profile).postsCount : nil)
        }

        NavigationLink(value: RouterDestination.profileLikes(profile)) {
          makeTabButton(title: "Likes", icon: "heart.fill", color: .blueskyPrimary, count: nil)
        }
      }
    }
  }

  // MARK: - Relationship Status Section
  private var relationshipStatusSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Relationship")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      HStack(spacing: 16) {
        // Follow/Unfollow Button
        FollowButton(profile: fullProfile ?? profile, size: .medium)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func makeTabButton(title: String, icon: String, color: Color, count: Int?) -> some View {
    HStack {
      Image(systemName: icon)
        .foregroundColor(.white)
        .shadow(color: .white, radius: 3)
        .padding(12)
        .background(
          LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
        )
        .frame(width: 40, height: 40)
        .glowingRoundedRectangle()

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        if let count = count {
          Text("\(count)")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(LinearGradient.blueskySubtle)
    )
  }

  // MARK: - Fetch Full Profile
  private func fetchFullProfile() async {
    isLoadingProfile = true
    profileError = nil

    do {
      let profileData = try await client.protoClient.getProfile(for: profile.did)

      // Store the followingURI for follow/unfollow operations
      // followingURI = profileData.viewer?.followingURI // This line is removed

      fullProfile = Profile(
        did: profileData.actorDID,
        handle: profileData.actorHandle,
        displayName: profileData.displayName,
        avatarImageURL: profileData.avatarImageURL,
        description: profileData.description,
        followersCount: profileData.followerCount ?? 0,
        followingCount: profileData.followCount ?? 0,
        postsCount: profileData.postCount ?? 0,
        isFollowing: profileData.viewer?.followingURI != nil,
        isFollowedBy: profileData.viewer?.followedByURI != nil,
        isBlocked: profileData.viewer?.isBlocked == true,
        isBlocking: profileData.viewer?.blockingURI != nil,
        isMuted: profileData.viewer?.isMuted == true
      )
    } catch {
      profileError = error
      print("Error fetching full profile: \(error)")
    }

    isLoadingProfile = false
  }

  // The toggleFollow method and its related state variables are removed as per the edit hint.
}

// MARK: - Stat Item
struct StatItem: View {
  let count: Int
  let label: String

  var body: some View {
    VStack(spacing: 4) {
      Text("\(count)")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.primary)

      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
}
