import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import PostUI
import SwiftUI

public struct ProfileView: View {
  @Environment(AppRouter.self) var router

  public let profile: Profile
  public let showBack: Bool
  public let isCurrentUser: Bool

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
        if let description = profile.description, !description.isEmpty {
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
    .background(Color(uiColor: .systemBackground))
    .navigationBarBackButtonHidden()
    .toolbar(.hidden, for: .navigationBar)
  }

  // MARK: - Profile Header
  private var profileHeader: some View {
    HStack(alignment: .top, spacing: 16) {
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

      VStack(alignment: .leading, spacing: 8) {
        // Name and Handle
        VStack(alignment: .leading, spacing: 4) {
          Text(profile.displayName ?? profile.handle)
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.primary)

          Text("@\(profile.handle)")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        // Follow/Unfollow Button
        if !isCurrentUser {  // Don't show for own profile
          Button(action: {
            // TODO: Implement follow/unfollow
          }) {
            Text(profile.isFollowing ? "Following" : "Follow")
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundColor(profile.isFollowing ? .primary : .white)
              .padding(.horizontal, 20)
              .padding(.vertical, 8)
              .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(profile.isFollowing ? Color.gray.opacity(0.2) : Color.blue)
              )
          }
        }
      }

      Spacer()
    }
  }

  // MARK: - Profile Stats
  private var profileStats: some View {
    HStack(spacing: 32) {
      StatItem(count: profile.postsCount, label: "Posts")
      StatItem(count: profile.followingCount, label: "Following")
      StatItem(count: profile.followersCount, label: "Followers")
    }
  }

  // MARK: - Bio Section
  private func bioSection(description: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Bio")
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      Text(description)
        .font(.body)
        .foregroundColor(.primary)
        .multilineTextAlignment(.leading)
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

    if let displayName = profile.displayName {
      shareText += "\(displayName)"
    }

    shareText += " (@\(profile.handle))"

    if let description = profile.description, !description.isEmpty {
      shareText += "\n\n\(description)"
    }

    shareText += "\n\nProfile: https://bsky.app/profile/\(profile.handle)"

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
            title: "Posts", icon: "bubble.fill", color: .blue, count: profile.postsCount)
        }

        NavigationLink(
          value: RouterDestination.profilePosts(profile: profile, filter: .postsWithReplies)
        ) {
          makeTabButton(
            title: "Replies", icon: "arrowshape.turn.up.left.fill", color: .teal,
            count: profile.postsCount > 0 ? profile.postsCount : nil)
        }

        NavigationLink(
          value: RouterDestination.profilePosts(profile: profile, filter: .postsWithMedia)
        ) {
          makeTabButton(
            title: "Media", icon: "photo.fill", color: .purple,
            count: profile.postsCount > 0 ? profile.postsCount : nil)
        }

        NavigationLink(
          value: RouterDestination.profilePosts(profile: profile, filter: .postAndAuthorThreads)
        ) {
          makeTabButton(
            title: "Threads", icon: "bubble.left.and.bubble.right.fill", color: .green,
            count: profile.postsCount > 0 ? profile.postsCount : nil)
        }

        NavigationLink(value: RouterDestination.profileLikes(profile)) {
          makeTabButton(title: "Likes", icon: "heart.fill", color: .red, count: nil)
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
        if profile.isFollowing {
          Label("Following", systemImage: "checkmark.circle.fill")
            .font(.subheadline)
            .foregroundColor(.green)
        }

        if profile.isFollowedBy {
          Label("Follows you", systemImage: "person.circle.fill")
            .font(.subheadline)
            .foregroundColor(.blue)
        }

        if profile.isBlocked {
          Label("Blocked", systemImage: "slash.circle.fill")
            .font(.subheadline)
            .foregroundColor(.red)
        }

        if profile.isBlocking {
          Label("Blocking", systemImage: "slash.circle.fill")
            .font(.subheadline)
            .foregroundColor(.orange)
        }

        if profile.isMuted {
          Label("Muted", systemImage: "speaker.slash.fill")
            .font(.subheadline)
            .foregroundColor(.gray)
        }
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
        .fill(Color(uiColor: .secondarySystemBackground))
    )
  }
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
