import Foundation
import SwiftUI

// ProfileTab enum is defined in EnhancedProfileView.swift

@available(iOS 18.0, *)
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
          .background(.ultraThinMaterial, in: Circle())
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
    .id("profile-header-\(profile.id)")
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
        .background(.ultraThinMaterial, in: Capsule())
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
        .background(.blue.opacity(0.1), in: Capsule())
        .overlay(Capsule().stroke(.blue.opacity(0.3), lineWidth: 1))
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
      .background(.ultraThinMaterial, in: Circle())
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
            title: "Followers",
            count: profile.followersCount,
            color: .primary
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
            title: "Following",
            count: profile.followingCount,
            color: .primary
          )
        }
        .buttonStyle(.plain)

        Divider()
          .frame(height: 40)

        // Posts
        ProfileStatView(
          title: "Posts",
          count: profile.postsCount,
          color: .primary
        )
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
    }
    .id("profile-stats-\(profile.id)")
  }

  // MARK: - Profile Tabs

  @ViewBuilder
  private var profileTabsView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(DetailProfileTab.allCases, id: \.self) { tab in
          Button(action: {
            withAnimation(.smooth(duration: 0.2)) {
              detailManager.profileDetailState.selectedTab = tab
            }
          }) {
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
                .fill(
                  detailManager.profileDetailState.selectedTab == tab
                    ? Color.blue.opacity(0.2) : .clear)
            )
            .overlay {
              if detailManager.profileDetailState.selectedTab == tab {
                Capsule()
                  .stroke(Color.blue, lineWidth: 1)
              }
            }
          }
          .buttonStyle(.plain)
          .foregroundStyle(detailManager.profileDetailState.selectedTab == tab ? .blue : .secondary)
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
        ForEach(posts, id: \.id) { post in
          VStack(alignment: .leading, spacing: 8) {
            Text(post.content)
              .font(.body)
              .lineLimit(3)

            if !post.mediaItems.isEmpty {
              Text("\(post.mediaItems.count) media items")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding()
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
          .id("profile-post-\(post.id)")
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
              .id("profile-media-\(mediaItem.id)")
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
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
  }

  @ViewBuilder
  private var profileNotFoundView: some View {
    ContentUnavailableView(
      "Profile not found",
      systemImage: "person.slash",
      description: Text("This profile may have been deleted or is no longer available")
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
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
    .background(.ultraThinMaterial)

    Button {
      showingActionSheet = true
    } label: {
      Image(systemName: "ellipsis.circle")
        .font(.subheadline)
    }
    .background(.ultraThinMaterial)
  }
}

// ProfileStatView is defined in EnhancedProfileView.swift

// ProfileTabChip is defined in EnhancedProfileView.swift

// MARK: - Profile Post Card

@available(iOS 18.0, *)
// ProfilePostCard is defined in EnhancedProfileView.swift
// ProfilePostCard is defined in EnhancedProfileView.swift

// MARK: - Profile Media Card

@available(iOS 18.0, *)
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
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
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

@available(iOS 18.0, *)
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
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
  }
}

// MARK: - Profile Action Sheet

@available(iOS 18.0, *)
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
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.blue.opacity(0.3), lineWidth: 1))

        Button("Mute User") {
          // Handle mute
          dismiss()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.orange.opacity(0.3), lineWidth: 1))

        Button("Block User") {
          // Handle block
          dismiss()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red.opacity(0.3), lineWidth: 1))

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
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
  }
}
