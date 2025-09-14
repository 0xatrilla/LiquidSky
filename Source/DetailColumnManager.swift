import Foundation
import SwiftUI

@available(iOS 18.0, *)
@Observable
class DetailColumnManager {
  var currentDetailType: DetailType?
  var detailStack: [DetailItem] = []
  var isLoading = false
  var error: DetailError?

  // Navigation state
  var canGoBack: Bool { detailStack.count > 1 }
  var currentBreadcrumb: [BreadcrumbItem] { generateBreadcrumb() }

  // Content-specific states
  var postDetailState = PostDetailState()
  var profileDetailState = ProfileDetailState()
  var mediaDetailState = MediaDetailState()

  init() {
    setupInitialState()
  }

  private func setupInitialState() {
    // Start with empty state
    currentDetailType = nil
  }

  // MARK: - Navigation Methods

  func showDetail(_ item: DetailItem) {
    withAnimation(.smooth(duration: 0.3)) {
      detailStack.append(item)
      currentDetailType = item.type
      updateStateForDetailType(item.type)
    }
  }

  func pushDetail(_ item: DetailItem) {
    withAnimation(.smooth(duration: 0.3)) {
      detailStack.append(item)
      currentDetailType = item.type
      updateStateForDetailType(item.type)
    }
  }

  func popDetail() {
    guard canGoBack else { return }

    withAnimation(.smooth(duration: 0.3)) {
      detailStack.removeLast()

      if let lastItem = detailStack.last {
        currentDetailType = lastItem.type
        updateStateForDetailType(lastItem.type)
      } else {
        currentDetailType = nil
      }
    }
  }

  func popToRoot() {
    withAnimation(.smooth(duration: 0.3)) {
      detailStack.removeAll()
      currentDetailType = nil
    }
  }

  func clearDetail() {
    withAnimation(.smooth(duration: 0.3)) {
      detailStack.removeAll()
      currentDetailType = nil
    }
  }

  // MARK: - Content Loading

  func loadDetailContent(for item: DetailItem) async {
    isLoading = true
    error = nil

    do {
      switch item.type {
      case .post:
        await loadPostDetail(item)
      case .profile:
        await loadProfileDetail(item)
      case .media:
        await loadMediaDetail(item)
      case .thread:
        await loadThreadDetail(item)
      case .list:
        await loadListDetail(item)
      }
    } catch {
      self.error = DetailError.loadingFailed
    }

    isLoading = false
  }

  private func loadPostDetail(_ item: DetailItem) async {
    postDetailState.isLoading = true

    // Simulate loading
    try? await Task.sleep(nanoseconds: 500_000_000)  // 500ms

    // Mock data loading
    postDetailState.post = generateMockPostDetail(for: item.id)
    postDetailState.replies = generateMockReplies(for: item.id)
    postDetailState.isLoading = false
  }

  private func loadProfileDetail(_ item: DetailItem) async {
    profileDetailState.isLoading = true

    // Simulate loading
    try? await Task.sleep(nanoseconds: 600_000_000)  // 600ms

    // Mock data loading
    profileDetailState.profile = generateMockProfile(for: item.id)
    profileDetailState.posts = generateMockProfilePosts(for: item.id)
    profileDetailState.isLoading = false
  }

  private func loadMediaDetail(_ item: DetailItem) async {
    mediaDetailState.isLoading = true

    // Simulate loading
    try? await Task.sleep(nanoseconds: 300_000_000)  // 300ms

    // Mock data loading
    mediaDetailState.mediaItem = generateMockMediaItem(for: item.id)
    mediaDetailState.isLoading = false
  }

  private func loadThreadDetail(_ item: DetailItem) async {
    postDetailState.isLoading = true

    // Simulate loading
    try? await Task.sleep(nanoseconds: 700_000_000)  // 700ms

    // Mock thread data
    postDetailState.post = generateMockPostDetail(for: item.id)
    postDetailState.replies = generateMockThreadReplies(for: item.id)
    postDetailState.isLoading = false
  }

  private func loadListDetail(_ item: DetailItem) async {
    // Handle list detail loading
    try? await Task.sleep(nanoseconds: 400_000_000)  // 400ms
  }

  // MARK: - State Management

  private func updateStateForDetailType(_ type: DetailType) {
    // Reset states when switching detail types
    switch type {
    case .post, .thread:
      profileDetailState.reset()
      mediaDetailState.reset()
    case .profile:
      postDetailState.reset()
      mediaDetailState.reset()
    case .media:
      postDetailState.reset()
      profileDetailState.reset()
    case .list:
      // Keep other states as they might be relevant
      break
    }
  }

  private func generateBreadcrumb() -> [BreadcrumbItem] {
    return detailStack.enumerated().map { index, item in
      BreadcrumbItem(
        id: item.id,
        title: item.title,
        isLast: index == detailStack.count - 1
      )
    }
  }

  // MARK: - Mock Data Generation

  private func generateMockPostDetail(for id: String) -> PostDetailData {
    PostDetailData(
      id: id,
      authorName: "Sample Author",
      authorHandle: "@sampleauthor",
      authorAvatar: nil,
      content:
        "This is a detailed view of a post with rich content and interactions. It demonstrates the enhanced post detail view with glass effects.",
      timestamp: Date().addingTimeInterval(-3600),
      likesCount: 42,
      repostsCount: 12,
      repliesCount: 8,
      isLiked: false,
      isReposted: false,
      mediaItems: [],
      replyToPost: nil
    )
  }

  private func generateMockReplies(for postId: String) -> [PostDetailData] {
    return (1...5).map { index in
      PostDetailData(
        id: "reply-\(index)",
        authorName: "Replier \(index)",
        authorHandle: "@replier\(index)",
        authorAvatar: nil,
        content: "This is a reply to the main post. Reply number \(index).",
        timestamp: Date().addingTimeInterval(-Double(index * 1800)),
        likesCount: Int.random(in: 0...20),
        repostsCount: Int.random(in: 0...5),
        repliesCount: Int.random(in: 0...3),
        isLiked: Bool.random(),
        isReposted: false,
        mediaItems: [],
        replyToPost: postId
      )
    }
  }

  private func generateMockThreadReplies(for postId: String) -> [PostDetailData] {
    return (1...10).map { index in
      PostDetailData(
        id: "thread-reply-\(index)",
        authorName: "Thread User \(index)",
        authorHandle: "@threaduser\(index)",
        authorAvatar: nil,
        content: "This is part of a conversation thread. Message \(index) in the discussion.",
        timestamp: Date().addingTimeInterval(-Double(index * 900)),
        likesCount: Int.random(in: 0...15),
        repostsCount: Int.random(in: 0...3),
        repliesCount: Int.random(in: 0...2),
        isLiked: Bool.random(),
        isReposted: false,
        mediaItems: [],
        replyToPost: index > 1 ? "thread-reply-\(index - 1)" : postId
      )
    }
  }

  private func generateMockProfile(for id: String) -> ProfileDetailData {
    ProfileDetailData(
      id: id,
      displayName: "Sample User",
      handle: "@sampleuser",
      bio:
        "This is a sample user profile with a bio that demonstrates the enhanced profile detail view.",
      avatarUrl: nil,
      bannerUrl: nil,
      followersCount: 1234,
      followingCount: 567,
      postsCount: 89,
      isFollowing: false,
      isFollowedBy: false,
      joinDate: Date().addingTimeInterval(-86400 * 365)  // 1 year ago
    )
  }

  private func generateMockProfilePosts(for profileId: String) -> [PostDetailData] {
    return (1...12).map { index in
      PostDetailData(
        id: "profile-post-\(index)",
        authorName: "Sample User",
        authorHandle: "@sampleuser",
        authorAvatar: nil,
        content: "This is post number \(index) from this user's profile.",
        timestamp: Date().addingTimeInterval(-Double(index * 7200)),
        likesCount: Int.random(in: 0...50),
        repostsCount: Int.random(in: 0...20),
        repliesCount: Int.random(in: 0...10),
        isLiked: Bool.random(),
        isReposted: Bool.random(),
        mediaItems: index % 3 == 0 ? [generateMockMediaItem(for: "media-\(index)")] : [],
        replyToPost: nil
      )
    }
  }

  private func generateMockMediaItem(for id: String) -> MediaDetailData {
    MediaDetailData(
      id: id,
      type: .image,
      url: "https://picsum.photos/800/600",
      thumbnailUrl: "https://picsum.photos/200/150",
      altText: "Sample image",
      width: 800,
      height: 600,
      aspectRatio: 4 / 3
    )
  }
}

// MARK: - Detail Types and Models

@available(iOS 18.0, *)
enum DetailType {
  case post, profile, media, thread, list

  var title: String {
    switch self {
    case .post: return "Post"
    case .profile: return "Profile"
    case .media: return "Media"
    case .thread: return "Thread"
    case .list: return "List"
    }
  }
}

@available(iOS 18.0, *)
struct DetailItem: Identifiable, Hashable {
  let id: String
  let type: DetailType
  let title: String
  let data: [String: Any]?

  init(id: String, type: DetailType, title: String, data: [String: Any]? = nil) {
    self.id = id
    self.type = type
    self.title = title
    self.data = data
  }

  static func == (lhs: DetailItem, rhs: DetailItem) -> Bool {
    lhs.id == rhs.id && lhs.type == rhs.type
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(type)
  }
}

@available(iOS 18.0, *)
struct BreadcrumbItem: Identifiable {
  let id: String
  let title: String
  let isLast: Bool
}

// MARK: - Content States

@available(iOS 18.0, *)
@Observable
class PostDetailState {
  var post: PostDetailData?
  var replies: [PostDetailData] = []
  var isLoading = false
  var showingReplyComposer = false
  var replyText = ""

  func reset() {
    post = nil
    replies = []
    isLoading = false
    showingReplyComposer = false
    replyText = ""
  }
}

@available(iOS 18.0, *)
@Observable
class ProfileDetailState {
  var profile: ProfileDetailData?
  var posts: [PostDetailData] = []
  var selectedTab: DetailProfileTab = .posts
  var isLoading = false
  var showingFollowSheet = false

  func reset() {
    profile = nil
    posts = []
    selectedTab = .posts
    isLoading = false
    showingFollowSheet = false
  }
}

@available(iOS 18.0, *)
@Observable
class MediaDetailState {
  var mediaItem: MediaDetailData?
  var isLoading = false
  var zoomScale: CGFloat = 1.0
  var offset: CGSize = .zero
  var showingShareSheet = false

  func reset() {
    mediaItem = nil
    isLoading = false
    zoomScale = 1.0
    offset = .zero
    showingShareSheet = false
  }
}

// MARK: - Data Models

@available(iOS 18.0, *)
struct PostDetailData: Identifiable, Hashable {
  let id: String
  let authorName: String
  let authorHandle: String
  let authorAvatar: URL?
  let content: String
  let timestamp: Date
  let likesCount: Int
  let repostsCount: Int
  let repliesCount: Int
  let isLiked: Bool
  let isReposted: Bool
  let mediaItems: [MediaDetailData]
  let replyToPost: String?

  static func == (lhs: PostDetailData, rhs: PostDetailData) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

@available(iOS 18.0, *)
struct ProfileDetailData: Identifiable, Hashable {
  let id: String
  let displayName: String
  let handle: String
  let bio: String
  let avatarUrl: URL?
  let bannerUrl: URL?
  let followersCount: Int
  let followingCount: Int
  let postsCount: Int
  let isFollowing: Bool
  let isFollowedBy: Bool
  let joinDate: Date

  static func == (lhs: ProfileDetailData, rhs: ProfileDetailData) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

@available(iOS 18.0, *)
struct MediaDetailData: Identifiable, Hashable {
  let id: String
  let type: MediaType
  let url: String
  let thumbnailUrl: String?
  let altText: String?
  let width: Int?
  let height: Int?
  let aspectRatio: Double?

  enum MediaType {
    case image, video, gif
  }

  static func == (lhs: MediaDetailData, rhs: MediaDetailData) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

@available(iOS 18.0, *)
enum DetailProfileTab: CaseIterable {
  case posts, replies, media, likes

  var title: String {
    switch self {
    case .posts: return "Posts"
    case .replies: return "Replies"
    case .media: return "Media"
    case .likes: return "Likes"
    }
  }

  var icon: String {
    switch self {
    case .posts: return "doc.text"
    case .replies: return "bubble.left"
    case .media: return "photo"
    case .likes: return "heart"
    }
  }
}

@available(iOS 18.0, *)
enum DetailError: Error, LocalizedError {
  case loadingFailed
  case notFound
  case networkError
  case unauthorized

  var errorDescription: String? {
    switch self {
    case .loadingFailed:
      return "Failed to load detail content"
    case .notFound:
      return "Content not found"
    case .networkError:
      return "Network connection error"
    case .unauthorized:
      return "Unauthorized access"
    }
  }
}

// MARK: - Environment Key

@available(iOS 18.0, *)
struct DetailColumnManagerKey: EnvironmentKey {
  static let defaultValue = DetailColumnManager()
}

@available(iOS 18.0, *)
extension EnvironmentValues {
  var detailColumnManager: DetailColumnManager {
    get { self[DetailColumnManagerKey.self] }
    set { self[DetailColumnManagerKey.self] = newValue }
  }
}
