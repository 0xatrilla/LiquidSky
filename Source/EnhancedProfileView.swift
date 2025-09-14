import Foundation
import SwiftUI

@available(iOS 18.0, *)
enum ProfileTab: Int, CaseIterable {
  case posts = 0
  case replies = 1
  case media = 2
  case likes = 3

  var title: String {
    switch self {
    case .posts: return "Posts"
    case .replies: return "Replies"
    case .media: return "Media"
    case .likes: return "Likes"
    }
  }
}

@available(iOS 18.0, *)
struct EnhancedProfileView: View {
  @Environment(\.contentColumnManager) var contentManager
  @Environment(\.glassEffectManager) var glassEffectManager
  @State private var profileData: ProfileData?
  @State private var isLoading = true
  @State private var selectedTab: ProfileTab = .posts
  @State private var posts: [ProfilePostData] = []
  @State private var isRefreshing = false
  @Namespace private var profileNamespace

  var body: some View {
    GeometryReader { geometry in
      GlassEffectContainer(spacing: 0) {
        ScrollView {
          LazyVStack(spacing: 0) {
            // Profile header with cover image
            profileHeader(geometry: geometry)

            // Profile info section
            profileInfoSection(geometry: geometry)

            // Tab selector
            profileTabSelector

            // Content based on selected tab
            profileContent(geometry: geometry)
          }
        }
        .refreshable {
          await refreshProfile()
        }
      }
    }
    .onAppear {
      loadProfileData()
    }
    .onChange(of: selectedTab) { _, newTab in
      loadTabContent(for: newTab)
    }
    .onReceive(NotificationCenter.default.publisher(for: .refresh)) { _ in
      Task {
        await refreshProfile()
      }
    }
  }

  // MARK: - Profile Header

  @ViewBuilder
  private func profileHeader(geometry: GeometryProxy) -> some View {
    ZStack(alignment: .bottomLeading) {
      // Cover image
      AsyncImage(url: profileData?.coverImageUrl) { image in
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
      .frame(height: 200)
      .clipShape(RoundedRectangle(cornerRadius: 0))
      .background {
        if #available(iOS 26.0, *) {
          Rectangle()
            .glassEffect(.regular, in: .rect(cornerRadius: 0))
        }
      }

      // Glass overlay for better text readability
      Rectangle()
        .fill(.ultraThinMaterial)
        .frame(height: 80)
        .background {
          if #available(iOS 26.0, *) {
            Rectangle()
              .glassEffect(.regular, in: .rect(cornerRadius: 0))
          }
        }

      // Profile avatar and basic info
      HStack(spacing: 16) {
        // Avatar
        AsyncImage(url: profileData?.avatarUrl) { image in
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
        .overlay {
          Circle()
            .stroke(.white, lineWidth: 3)
        }
        .background {
          if #available(iOS 26.0, *) {
            Circle()
              .glassEffect(.regular, in: .circle)
          }
        }

        // Name and handle
        VStack(alignment: .leading, spacing: 4) {
          Text(profileData?.displayName ?? "Loading...")
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)

          Text(profileData?.handle ?? "@loading")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 16)
    }
  }

  // MARK: - Profile Info Section

  @ViewBuilder
  private func profileInfoSection(geometry: GeometryProxy) -> some View {
    let isWideLayout = geometry.size.width > 800

    if isWideLayout {
      // Two-column layout for wide screens
      HStack(alignment: .top, spacing: 24) {
        // Left column - Bio and details
        VStack(alignment: .leading, spacing: 16) {
          profileBioSection
          profileDetailsSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // Right column - Stats and actions
        VStack(alignment: .trailing, spacing: 16) {
          profileStatsSection
          profileActionsSection
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
    } else {
      // Single column layout for narrow screens
      VStack(alignment: .leading, spacing: 16) {
        profileBioSection
        profileStatsSection
        profileDetailsSection
        profileActionsSection
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
    }
  }

  @ViewBuilder
  private var profileBioSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let bio = profileData?.bio, !bio.isEmpty {
        Text(bio)
          .font(.body)
          .foregroundStyle(.primary)
          .lineLimit(nil)
      }

      if let website = profileData?.website {
        Link(destination: website) {
          HStack(spacing: 4) {
            Image(systemName: "link")
              .font(.caption)
            Text(website.absoluteString)
              .font(.caption)
          }
          .foregroundStyle(.blue)
        }
        .background {
          if #available(iOS 26.0, *) {
            Rectangle()
              .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 0))
          }
        }
      }

      if let joinDate = profileData?.joinDate {
        HStack(spacing: 4) {
          Image(systemName: "calendar")
            .font(.caption)
          Text("Joined \(joinDate, style: .date)")
            .font(.caption)
        }
        .foregroundStyle(.secondary)
      }
    }
  }

  @ViewBuilder
  private var profileStatsSection: some View {
    GestureAwareGlassCard(cornerRadius: 12, isInteractive: true) {
      HStack(spacing: 24) {
        ProfileStatView(
          title: "Posts",
          count: profileData?.postsCount ?? 0,
          color: .blue
        )

        ProfileStatView(
          title: "Following",
          count: profileData?.followingCount ?? 0,
          color: .green
        )

        ProfileStatView(
          title: "Followers",
          count: profileData?.followersCount ?? 0,
          color: .purple
        )

        ProfileStatView(
          title: "Likes",
          count: profileData?.likesCount ?? 0,
          color: .red
        )
      }
      .padding(16)
    }
  }

  @ViewBuilder
  private var profileDetailsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let location = profileData?.location {
        HStack(spacing: 8) {
          Image(systemName: "location")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(location)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      if let verified = profileData?.isVerified, verified {
        HStack(spacing: 8) {
          Image(systemName: "checkmark.seal.fill")
            .font(.caption)
            .foregroundStyle(.blue)
          Text("Verified Account")
            .font(.caption)
            .foregroundStyle(.blue)
        }
      }
    }
  }

  @ViewBuilder
  private var profileActionsSection: some View {
    HStack(spacing: 12) {
      // Follow/Unfollow button
      Button {
        // Handle follow/unfollow
      } label: {
        Text(profileData?.isFollowing == true ? "Following" : "Follow")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(profileData?.isFollowing == true ? .secondary : Color.white)
          .padding(.horizontal, 20)
          .padding(.vertical, 8)
          .background(
            Capsule()
              .fill(profileData?.isFollowing == true ? Color.gray.opacity(0.2) : Color.blue)
          )
      }
      .buttonStyle(.plain)
      .background {
          if #available(iOS 26.0, *) {
            Capsule()
              .glassEffect(.regular.interactive(), in: .capsule)
          }
        }

      // Message button
      Button {
        // Handle message
      } label: {
        Image(systemName: "message")
          .font(.subheadline)
          .foregroundStyle(.blue)
          .padding(8)
          .background(Circle().fill(.blue.opacity(0.1)))
          .overlay {
            Circle().stroke(.blue, lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
      .background {
          if #available(iOS 26.0, *) {
            Circle()
              .glassEffect(.regular.interactive(), in: .circle)
          }
        }

      // More actions button
      Menu {
        Button("Share Profile") {
          // Handle share
        }

        Button("Copy Link") {
          // Handle copy link
        }

        Divider()

        Button("Mute") {
          // Handle mute
        }

        Button("Block", role: .destructive) {
          // Handle block
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(8)
          .background(Circle().fill(.quaternary))
      }
      .buttonStyle(.plain)
      .background {
          if #available(iOS 26.0, *) {
            Circle()
              .glassEffect(.regular.interactive(), in: .circle)
          }
        }
    }
  }

  // MARK: - Profile Tab Selector

  @ViewBuilder
  private var profileTabSelector: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(ProfileTab.allCases, id: \.self) { tab in
          ProfileTabChip(
            tab: tab,
            isSelected: selectedTab == tab,
            count: getTabCount(for: tab)
          ) {
            withAnimation(.smooth(duration: 0.2)) {
              selectedTab = tab
            }
          }
        }
      }
      .padding(.horizontal, 20)
    }
    .padding(.vertical, 12)
    .background(.ultraThinMaterial)
    .background {
          if #available(iOS 26.0, *) {
            Rectangle()
              .glassEffect(.regular, in: .rect(cornerRadius: 0))
          }
        }
  }

  // MARK: - Profile Content

  @ViewBuilder
  private func profileContent(geometry: GeometryProxy) -> some View {
    LazyVStack(spacing: 16) {
      switch selectedTab {
      case .posts:
        profilePostsGrid(geometry: geometry)
      case .replies:
        profileRepliesGrid(geometry: geometry)
      case .media:
        profileMediaGrid(geometry: geometry)
      case .likes:
        profileLikesGrid(geometry: geometry)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
  }

  @ViewBuilder
  private func profilePostsGrid(geometry: GeometryProxy) -> some View {
    let columns = gridColumns(for: geometry.size)

    LazyVGrid(columns: columns, spacing: 16) {
      ForEach(posts.filter { $0.type == .post }) { post in
        ProfilePostCard(post: post)
          .glassEffectID(post.id, in: profileNamespace)
      }
    }
  }

  @ViewBuilder
  private func profileRepliesGrid(geometry: GeometryProxy) -> some View {
    let columns = gridColumns(for: geometry.size)

    LazyVGrid(columns: columns, spacing: 16) {
      ForEach(posts.filter { $0.type == .reply }) { post in
        ProfilePostCard(post: post)
          .glassEffectID(post.id, in: profileNamespace)
      }
    }
  }

  @ViewBuilder
  private func profileMediaGrid(geometry: GeometryProxy) -> some View {
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(posts.filter { $0.hasMedia }) { post in
        if let mediaUrl = post.mediaUrl {
          AsyncImage(url: URL(string: mediaUrl)) { image in
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
          .background {
            if #available(iOS 26.0, *) {
              RoundedRectangle(cornerRadius: 8)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 8))
            }
          }
          .onTapGesture {
            // Handle media tap
          }
        }
      }
    }
  }

  @ViewBuilder
  private func profileLikesGrid(geometry: GeometryProxy) -> some View {
    let columns = gridColumns(for: geometry.size)

    LazyVGrid(columns: columns, spacing: 16) {
      ForEach(posts.filter { $0.isLiked }) { post in
        ProfilePostCard(post: post)
          .glassEffectID(post.id, in: profileNamespace)
      }
    }
  }

  // MARK: - Helper Methods

  private func gridColumns(for size: CGSize) -> [GridItem] {
    let columnCount = size.width > 800 ? 2 : 1
    let spacing: CGFloat = 16
    let totalSpacing = spacing * CGFloat(columnCount - 1)
    let availableWidth = size.width - 40 - totalSpacing  // 40 for horizontal padding
    let columnWidth = availableWidth / CGFloat(columnCount)

    return Array(repeating: GridItem(.fixed(columnWidth), spacing: spacing), count: columnCount)
  }

  private func getTabCount(for tab: ProfileTab) -> Int {
    switch tab {
    case .posts:
      return posts.filter { $0.type == .post }.count
    case .replies:
      return posts.filter { $0.type == .reply }.count
    case .media:
      return posts.filter { $0.hasMedia }.count
    case .likes:
      return posts.filter { $0.isLiked }.count
    }
  }

  private func loadProfileData() {
    // Simulate loading
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      withAnimation(.smooth(duration: 0.3)) {
        profileData = generateMockProfileData()
        posts = generateMockPosts()
        isLoading = false
      }
    }
  }

  private func loadTabContent(for tab: ProfileTab) {
    // Simulate loading tab-specific content
    // In a real app, this would fetch different data based on the tab
  }

  private func refreshProfile() async {
    isRefreshing = true

    // Simulate network request
    try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

    withAnimation(.smooth(duration: 0.3)) {
      profileData = generateMockProfileData()
      posts = generateMockPosts()
    }

    isRefreshing = false
  }

  private func generateMockProfileData() -> ProfileData {
    ProfileData(
      id: "user-123",
      displayName: "John Doe",
      handle: "@johndoe",
      bio:
        "iOS Developer passionate about SwiftUI and creating beautiful user experiences. Building the future of mobile apps.",
      avatarUrl: URL(string: "https://picsum.photos/200/200"),
      coverImageUrl: URL(string: "https://picsum.photos/800/400"),
      website: URL(string: "https://johndoe.dev"),
      location: "San Francisco, CA",
      joinDate: Date().addingTimeInterval(-365 * 24 * 3600),  // 1 year ago
      postsCount: 1234,
      followingCount: 567,
      followersCount: 8901,
      likesCount: 2345,
      isVerified: true,
      isFollowing: false
    )
  }

  private func generateMockPosts() -> [ProfilePostData] {
    return (1...20).map { index in
      ProfilePostData(
        id: "post-\(index)",
        content:
          "This is a sample post \(index) from the user's profile. It demonstrates the enhanced profile layout with glass effects.",
        timestamp: Date().addingTimeInterval(-Double(index * 3600)),
        likesCount: Int.random(in: 0...100),
        repostsCount: Int.random(in: 0...50),
        repliesCount: Int.random(in: 0...25),
        isLiked: Bool.random(),
        hasMedia: index % 3 == 0,
        mediaUrl: index % 3 == 0 ? "https://picsum.photos/400/300" : nil,
        type: index % 4 == 0 ? .reply : .post
      )
    }
  }
}

// MARK: - Profile Stat View

@available(iOS 18.0, *)
struct ProfileStatView: View {
  let title: String
  let count: Int
  let color: Color

  var body: some View {
    VStack(spacing: 4) {
      Text("\(count)")
        .font(.title3.weight(.bold))
        .foregroundStyle(color)

      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - Profile Tab Chip

@available(iOS 18.0, *)
struct ProfileTabChip: View {
  let tab: ProfileTab
  let isSelected: Bool
  let count: Int
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 6) {
        Image(systemName: tab.icon)
          .font(.caption)

        Text(tab.title)
          .font(.caption.weight(.medium))

        if count > 0 {
          Text("\(count)")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(tab.color, in: Capsule())
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(isSelected ? tab.color.opacity(0.2) : .clear)
      )
      .overlay {
        if isSelected {
          Capsule()
            .stroke(tab.color, lineWidth: 1)
        }
      }
    }
    .buttonStyle(.plain)
    .foregroundStyle(isSelected ? tab.color : .secondary)
    .background {
      if #available(iOS 26.0, *) {
        Capsule()
          .glassEffect(
            isSelected ? .regular.tint(tab.color).interactive() : .regular.interactive(),
            in: .capsule
          )
      }
    }
  }
}

// MARK: - Profile Post Card

@available(iOS 18.0, *)
struct ProfilePostCard: View {
  let post: ProfilePostData
  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0

  private let cardId = UUID().uuidString

  var body: some View {
    GestureAwareGlassCard(
      cornerRadius: 12,
      isInteractive: true
    ) {
      VStack(alignment: .leading, spacing: 12) {
        // Content
        Text(post.content)
          .font(.body)
          .foregroundStyle(.primary)
          .lineLimit(4)
          .multilineTextAlignment(.leading)

        // Media (if present)
        if let mediaUrl = post.mediaUrl {
          AsyncImage(url: URL(string: mediaUrl)) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            RoundedRectangle(cornerRadius: 8)
              .fill(.quaternary)
              .overlay {
                ProgressView()
              }
          }
          .frame(height: 150)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .background {
            if #available(iOS 26.0, *) {
              RoundedRectangle(cornerRadius: 8)
                .glassEffect(.regular, in: .rect(cornerRadius: 8))
            }
          }
        }

        // Footer with timestamp and engagement
        HStack {
          Text(post.timestamp, style: .relative)
            .font(.caption)
            .foregroundStyle(.tertiary)

          Spacer()

          HStack(spacing: 16) {
            HStack(spacing: 4) {
              Image(systemName: "heart")
                .font(.caption2)
              Text("\(post.likesCount)")
                .font(.caption2)
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 4) {
              Image(systemName: "arrow.2.squarepath")
                .font(.caption2)
              Text("\(post.repostsCount)")
                .font(.caption2)
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 4) {
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
    }
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

// MARK: - Data Models

@available(iOS 18.0, *)
struct ProfileData {
  let id: String
  let displayName: String
  let handle: String
  let bio: String
  let avatarUrl: URL?
  let coverImageUrl: URL?
  let website: URL?
  let location: String?
  let joinDate: Date
  let postsCount: Int
  let followingCount: Int
  let followersCount: Int
  let likesCount: Int
  let isVerified: Bool
  let isFollowing: Bool
}

@available(iOS 18.0, *)
struct ProfilePostData: Identifiable, Hashable {
  let id: String
  let content: String
  let timestamp: Date
  let likesCount: Int
  let repostsCount: Int
  let repliesCount: Int
  let isLiked: Bool
  let hasMedia: Bool
  let mediaUrl: String?
  let type: ProfilePostType

  static func == (lhs: ProfilePostData, rhs: ProfilePostData) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

@available(iOS 18.0, *)
enum ProfilePostType {
  case post, reply
}

// MARK: - Extensions

@available(iOS 18.0, *)
extension ProfileTab {
  static var allCases: [ProfileTab] {
    [.posts, .replies, .media, .likes]
  }

  var icon: String {
    switch self {
    case .posts: return "doc.text"
    case .replies: return "bubble.left"
    case .media: return "photo"
    case .likes: return "heart"
    }
  }

  var color: Color {
    switch self {
    case .posts: return .blue
    case .replies: return .green
    case .media: return .orange
    case .likes: return .red
    }
  }
}
