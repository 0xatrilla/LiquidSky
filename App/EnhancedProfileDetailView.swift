import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
struct EnhancedProfileDetailView: View {
  let profileId: String
  @Environment(\.detailColumnManager) var detailManager
  @Environment(\.glassEffectManager) var glassEffectManager
  @State private var showingFollowSheet = false
  @State private var showingActionSheet = false
  @Namespace private var profileNamespace

  var body: some View {
    GlassEffectContainer(spacing: 16.0) {
      if detailManager.profileDetailState.isLoading {
        profileLoadingView
      } else if let profile = detailManager.profileDetailState.profile {
        ScrollView {
          LazyVStack(spacing: 20) {
            // Profile header with banner
            profileHeaderView(profile)

            // Profile info section
            profileInfoSection(profile)

            // Profile tabs
            profileTabsView

            // Content based on selected tab
            profileContentView
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
      } else {
        profileNotFoundView
      }
    }
    .navigationTitle("Profile")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        profileToolbarButtons
      }
    }
    .sheet(isPresented: $showingFollowSheet) {
      ProfileFollowSheet(profile: detailManager.profileDetailState.profile)
    }
    .sheet(isPresented: $showingActionSheet) {
      ProfileActionSheet(profile: detailManager.profileDetailState.profile)
    }
    .onAppear {
      Task {
        let detailItem = DetailItem(id: profileId, type: .profile, title: "Profile")
        await detailManager.loadDetailContent(for: detailItem)
      }
    }
  }

  // MARK: - Profile Header

  @ViewBuilder
  private func profileHeaderView(_ profile: ProfileDetailData) -> some View {
    GestureAwareGlassCard(
      cornerRadius: 20,
      isInteractive: true
    ) {
      VStack(spacing: 0) {
        // Banner image
        AsyncImage(url: profile.bannerUrl) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        }
        .frame(height: 120)
        .clipShape(
          UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 20
          )
        )
        .overlay(alignment: .bottomLeading) {
          // Profile avatar overlapping banner
          AsyncImage(url: profile.avatarUrl) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            Circle()
              .fill(.quaternary)
              .overlay {
                Image(systemName: "person.fill")
                  .font(.title)
                  .foregroundStyle(.secondary)
              }
          }
          .frame(width: 80, height: 80)
          .clipShape(Circle())
          .background(
            Circle()
              .fill(.ultraThickMaterial)
              .frame(width: 88, height: 88)
          )
          .glassEffect(.regular, in: .circle)
          .offset(x: 20, y: 40)
        }

        // Profile info
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text(profile.displayName)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

              Text(profile.handle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Follow/Following button
            profileActionButton(profile)
          }
          .padding(.top, 50)  // Account for overlapping avatar

          // Bio
          if !profile.bio.isEmpty {
            Text(profile.bio)
              .font(.body)
              .foregroundStyle(.primary)
              .lineLimit(nil)
          }

          // Join date
          HStack(spacing: 4) {
            Image(systemName: "calendar")
              .font(.caption)
              .foregroundStyle(.secondary)

            Text("Joined \(profile.joinDate, style: .date)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(20)
      }
    }
    .glassEffectID("profile-header-\(profile.id)", in: profileNamespace)
  }

  @ViewBuilder
  private func profileActionButton(_ profile: ProfileDetailData) -> some View {
    HStack(spacing: 12) {
      if profile.isFollowing {
        Button {
          // Handle unfollow
        } label: {
          Text("Following")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.quaternary, in: Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
      } else {
        Button {
          // Handle follow
        } label: {
          Text("Follow")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.blue, in: Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(.blue).interactive(), in: .capsule)
      }

      Button {
        showingActionSheet = true
      } label: {
        Image(systemName: "ellipsis")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(8)
          .background(.quaternary, in: Circle())
      }
      .buttonStyle(.plain)
      .glassEffect(.regular.interactive(), in: .circle)
    }
  }

  // MARK: - Profile Info Section

  @ViewBuilder
  private func profileInfoSection(_ profile: ProfileDetailData) -> some View {
    GestureAwareGlassCard(
      cornerRadius: 16,
      isInteractive: true
    ) {
      HStack(spacing: 0) {
        // Followers
        Button {
          showingFollowSheet = true
        } label: {
          ProfileStatView(
            count: profile.followersCount,
            label: "Followers"
          )
        }
        .buttonStyle(.plain)

        Divider()
          .frame(height: 40)

        // Following
        Button {
          showingFollowSheet = true
        } label: {
          ProfileStatView(
            count: profile.followingCount,
            label: "Following"
          )
        }
        .buttonStyle(.plain)

        Divider()
          .frame(height: 40)

        // Posts
        ProfileStatView(
          count: profile.postsCount,
          label: "Posts"
        )
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
    }
    .glassEffectID("profile-stats-\(profile.id)", in: profileNamespace)
  }

  // MARK: - Profile Tabs

  @ViewBuilder
  private var profileTabsView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(ProfileTab.allCases, id: \.self) { tab in
          ProfileTabChip(
            tab: tab,
            isSelected: detailManager.profileDetailState.selectedTab == tab
          ) {
            withAnimation(.smooth(duration: 0.2)) {
              detailManager.profileDetailState.selectedTab = tab
            }
          }
        }
      }
      .padding(.horizontal, 16)
    }
  }

  // MARK: - Profile Content

  @ViewBuilder
  private var profileContentView: some View {
    switch detailManager.profileDetailState.selectedTab {
    case .posts:
      profilePostsGrid
    case .replies:
      profileRepliesGrid
    case .media:
      profileMediaGrid
    case .likes:
      profileLikesGrid
    }
  }

  @ViewBuilder
  private var profilePostsGrid: some View {
    let posts = detailManager.profileDetailState.posts

    if posts.isEmpty {
      emptyContentView(
        title: "No posts yet",
        subtitle: "Posts will appear here when they're shared",
        icon: "doc.text"
      )
    } else {
      LazyVGrid(
        columns: [
          GridItem(.flexible(), spacing: 12),
          GridItem(.flexible(), spacing: 12),
        ], spacing: 12
      ) {
        ForEach(posts) { post in
          ProfilePostCard(post: post)
            .glassEffectID("profile-post-\(post.id)", in: profileNamespace)
        }
      }
    }
  }

  @ViewBuilder
  private var profileRepliesGrid: some View {
    emptyContentView(
      title: "No replies yet",
      subtitle: "Replies to other posts will appear here",
      icon: "bubble.left"
    )
  }

  @ViewBuilder
  private var profileMediaGrid: some View {
    let mediaPosts = detailManager.profileDetailState.posts.filter { !$0.mediaItems.isEmpty }

    if mediaPosts.isEmpty {
      emptyContentView(
        title: "No media yet",
        subtitle: "Photos and videos will appear here",
        icon: "photo"
      )
    } else {
      LazyVGrid(
        columns: [
          GridItem(.flexible(), spacing: 8),
          GridItem(.flexible(), spacing: 8),
          GridItem(.flexible(), spacing: 8),
        ], spacing: 8
      ) {
        ForEach(mediaPosts) { post in
          if let mediaItem = post.mediaItems.first {
            ProfileMediaCard(mediaItem: mediaItem, post: post)
              .glassEffectID("profile-media-\(mediaItem.id)", in: profileNamespace)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var profileLikesGrid: some View {
    emptyContentView(
      title: "No likes yet",
      subtitle: "Liked posts will appear here",
      icon: "heart"
    )
  }

  @ViewBuilder
  private func emptyContentView(title: String, subtitle: String, icon: String) -> some View {
    ContentUnavailableView(
      title,
      systemImage: icon,
      description: Text(subtitle)
    )
    .frame(minHeight: 200)
    .glassEffect(.regular, in: .rect(cornerRadius: 16))
  }

  // MARK: - Loading and Error States

  @ViewBuilder
  private var profileLoadingView: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)

      Text("Loading profile...")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .glassEffect(.regular, in: .rect(cornerRadius: 20))
  }

  @ViewBuilder
  private var profileNotFoundView: some View {
    ContentUnavailableView(
      "Profile not found",
      systemImage: "person.slash",
      description: Text("This profile may have been deleted or is no longer available")
    )
    .glassEffect(.regular, in: .rect(cornerRadius: 20))
  }

  // MARK: - Toolbar

  @ViewBuilder
  private var profileToolbarButtons: some View {
    Button {
      // Handle share profile
    } label: {
      Image(systemName: "square.and.arrow.up")
        .font(.subheadline)
    }
    .glassEffect(.regular.interactive())

    Button {
      showingActionSheet = true
    } label: {
      Image(systemName: "ellipsis.circle")
        .font(.subheadline)
    }
    .glassEffect(.regular.interactive())
  }
}

// MARK: - Profile Stat View

@available(iPadOS 26.0, *)
struct ProfileStatView: View {
  let count: Int
  let label: String

  var body: some View {
    VStack(spacing: 4) {
      Text(formatCount(count))
        .font(.title3.weight(.bold))
        .foregroundStyle(.primary)

      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }

  private func formatCount(_ count: Int) -> String {
    if count >= 1_000_000 {
      return String(format: "%.1fM", Double(count) / 1_000_000)
    } else if count >= 1_000 {
      return String(format: "%.1fK", Double(count) / 1_000)
    } else {
      return "\(count)"
    }
  }
}

// MARK: - Profile Tab Chip

@available(iPadOS 26.0, *)
struct ProfileTabChip: View {
  let tab: ProfileTab
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 6) {
        Image(systemName: tab.icon)
          .font(.caption)

        Text(tab.title)
          .font(.caption.weight(.medium))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .background(
        Capsule()
          .fill(isSelected ? Color.blue.opacity(0.2) : .clear)
      )
      .overlay {
        if isSelected {
          Capsule()
            .stroke(.blue, lineWidth: 1)
        }
      }
    }
    .buttonStyle(.plain)
    .foregroundStyle(isSelected ? .blue : .secondary)
    .glassEffect(
      isSelected ? .regular.tint(.blue).interactive() : .regular.interactive(),
      in: .capsule
    )
  }
}

// MARK: - Profile Post Card

@available(iPadOS 26.0, *)
struct ProfilePostCard: View {
  let post: PostDetailData
  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0

  private let cardId = UUID().uuidString

  var body: some View {
    Button {
      // Navigate to post detail
    } label: {
      GestureAwareGlassCard(
        cornerRadius: 12,
        isInteractive: true
      ) {
        VStack(alignment: .leading, spacing: 8) {
          Text(post.content)
            .font(.body)
            .foregroundStyle(.primary)
            .lineLimit(4)
            .multilineTextAlignment(.leading)

          Spacer()

          HStack {
            Text(post.timestamp, style: .relative)
              .font(.caption)
              .foregroundStyle(.tertiary)

            Spacer()

            HStack(spacing: 12) {
              HStack(spacing: 2) {
                Image(systemName: "heart")
                  .font(.caption2)
                Text("\(post.likesCount)")
                  .font(.caption2)
              }
              .foregroundStyle(.secondary)

              HStack(spacing: 2) {
                Image(systemName: "bubble.left")
                  .font(.caption2)
                Text("\(post.repliesCount)")
                  .font(.caption2)
              }
              .foregroundStyle(.secondary)
            }
          }
        }
        .padding(12)
        .frame(minHeight: 120)
      }
    }
    .buttonStyle(.plain)
    .scaleEffect(scaleEffect)
    .brightness(hoverIntensity * 0.05)
    .applePencilHover(id: cardId) { hovering, location, intensity in
      withAnimation(.smooth(duration: 0.2)) {
        isPencilHovering = hovering
        hoverIntensity = intensity
      }
    }
    .onHover { hovering in
      withAnimation(.smooth(duration: 0.2)) {
        isHovering = hovering && !isPencilHovering
      }
    }
  }

  private var scaleEffect: CGFloat {
    if isPencilHovering {
      return 1.02
    } else if isHovering {
      return 1.01
    } else {
      return 1.0
    }
  }
}

// MARK: - Profile Media Card

@available(iPadOS 26.0, *)
struct ProfileMediaCard: View {
  let mediaItem: MediaDetailData
  let post: PostDetailData
  @State private var isHovering = false

  var body: some View {
    Button {
      // Navigate to media detail
    } label: {
      AsyncImage(url: URL(string: mediaItem.url)) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Rectangle()
          .fill(.quaternary)
          .overlay {
            ProgressView()
          }
      }
      .frame(height: 120)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 8))
    }
    .buttonStyle(.plain)
    .scaleEffect(isHovering ? 1.05 : 1.0)
    .onHover { hovering in
      withAnimation(.smooth(duration: 0.2)) {
        isHovering = hovering
      }
    }
  }
}

// MARK: - Profile Follow Sheet

@available(iPadOS 26.0, *)
struct ProfileFollowSheet: View {
  let profile: ProfileDetailData?
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationView {
      VStack {
        Text("Follow functionality would be implemented here")
          .font(.body)
          .foregroundStyle(.secondary)
          .padding()

        Spacer()
      }
      .navigationTitle("Followers")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .glassEffect(.regular, in: .rect(cornerRadius: 16))
  }
}

// MARK: - Profile Action Sheet

@available(iPadOS 26.0, *)
struct ProfileActionSheet: View {
  let profile: ProfileDetailData?
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationView {
      VStack(spacing: 16) {
        Button("Share Profile") {
          // Handle share
          dismiss()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .glassEffect(.regular.tint(.blue).interactive(), in: .rect(cornerRadius: 12))

        Button("Mute User") {
          // Handle mute
          dismiss()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .glassEffect(.regular.tint(.orange).interactive(), in: .rect(cornerRadius: 12))

        Button("Block User") {
          // Handle block
          dismiss()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .glassEffect(.regular.tint(.red).interactive(), in: .rect(cornerRadius: 12))

        Spacer()
      }
      .padding()
      .navigationTitle("Profile Actions")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
    .glassEffect(.regular, in: .rect(cornerRadius: 16))
  }
}
