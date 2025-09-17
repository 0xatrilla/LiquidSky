import SwiftUI
import Destinations
import Models

@available(iOS 18.0, *)
@Observable
class DetailColumnManager {
  var currentDestination: RouterDestination?
  var isShowingDetail = false
  
  // Media detail state
  var mediaDetailState = MediaDetailState()
  
  // Post detail state
  var postDetailState = PostDetailState()
  
  // Profile detail state
  var profileDetailState = ProfileDetailState()
  
  // Detail item state
  var detailItem: DetailItem?
}

@available(iOS 18.0, *)
public struct MediaDetailState {
  var isLoading = false
  var mediaItem: MediaDetailData?
  var error: Error?
}

@available(iOS 18.0, *)
public struct PostDetailState {
  var isLoading = false
  var post: PostDetailData?
  var replies: [PostDetailData] = []
  var error: Error?
}

@available(iOS 18.0, *)
public struct ProfileDetailState {
  var isLoading = false
  var profile: ProfileDetailData?
  var selectedTab: DetailProfileTab = .posts
  var posts: [PostItem] = []
  var error: Error?
}

@available(iOS 18.0, *)
public enum DetailItem {
  case media(MediaDetailData)
  case post(PostItem)
  case profile(Profile)
  
  public init(media: MediaDetailData) {
    self = .media(media)
  }
  
  public init(post: PostItem) {
    self = .post(post)
  }
  
  public init(profile: Profile) {
    self = .profile(profile)
  }
}

@available(iOS 18.0, *)
public struct PostDetailData: Identifiable {
  public let id: String
  public let content: String
  public let author: Profile
  public let createdAt: Date
  public let replyCount: Int
  public let repostCount: Int
  public let likeCount: Int
  public let isLiked: Bool
  public let isReposted: Bool
  public let embed: EmbedData?
  public let replies: [PostDetailData]
  
  // Additional properties expected by the views
  public let mediaItems: [MediaDetailData]
  public let authorAvatar: URL?
  public let authorName: String
  public let authorHandle: String
  public let timestamp: Date
  public let likesCount: Int
  public let repostsCount: Int
  public let repliesCount: Int
  
  public init(
    id: String,
    content: String,
    author: Profile,
    createdAt: Date,
    replyCount: Int,
    repostCount: Int,
    likeCount: Int,
    isLiked: Bool,
    isReposted: Bool,
    embed: EmbedData?,
    replies: [PostDetailData],
    mediaItems: [MediaDetailData] = [],
    authorAvatar: URL? = nil,
    authorName: String? = nil,
    authorHandle: String? = nil,
    timestamp: Date? = nil,
    likesCount: Int? = nil,
    repostsCount: Int? = nil,
    repliesCount: Int? = nil
  ) {
    self.id = id
    self.content = content
    self.author = author
    self.createdAt = createdAt
    self.replyCount = replyCount
    self.repostCount = repostCount
    self.likeCount = likeCount
    self.isLiked = isLiked
    self.isReposted = isReposted
    self.embed = embed
    self.replies = replies
    self.mediaItems = mediaItems
    self.authorAvatar = authorAvatar
    self.authorName = authorName ?? author.displayName ?? author.handle
    self.authorHandle = authorHandle ?? author.handle
    self.timestamp = timestamp ?? createdAt
    self.likesCount = likesCount ?? likeCount
    self.repostsCount = repostsCount ?? repostCount
    self.repliesCount = repliesCount ?? replyCount
  }
}

@available(iOS 18.0, *)
public struct ProfileDetailData {
  let id: String
  let handle: String
  let displayName: String?
  let description: String?
  let bio: String?
  let avatarImageURL: URL?
  let avatarUrl: URL?
  let bannerImageURL: URL?
  let bannerUrl: URL?
  let followersCount: Int
  let followingCount: Int
  let postsCount: Int
  let isFollowing: Bool
  let isFollowedBy: Bool
  let isBlocked: Bool
  let isBlocking: Bool
  let isMuted: Bool
  let joinDate: Date?
  let posts: [PostItem]
}

extension DetailColumnManager {
  func displayPostDetail(postId: String, title: String) {
    // This would need to fetch the actual post data
    // For now, we'll create a placeholder
    let placeholderProfile = Profile(
      did: "placeholder",
      handle: "placeholder",
      displayName: "Loading...",
      avatarImageURL: nil
    )
    
    let placeholderPost = PostItem(
      uri: postId,
      cid: "placeholder",
      indexedAt: Date(),
      author: placeholderProfile,
      content: "Loading post...",
      replyCount: 0,
      repostCount: 0,
      likeCount: 0,
      likeURI: nil,
      repostURI: nil,
      replyRef: nil
    )
    
    currentDestination = .post(placeholderPost)
    isShowingDetail = true
  }
  
  func displayProfileDetail(profileId: String, title: String) {
    // This would need to fetch the actual profile data
    // For now, we'll create a placeholder
    let placeholderProfile = Profile(
      did: profileId,
      handle: "placeholder",
      displayName: title,
      avatarImageURL: nil
    )
    
    currentDestination = .profile(placeholderProfile)
    isShowingDetail = true
  }
  
  func displayMediaDetail(mediaId: String, title: String) {
    // Placeholder for media detail
    isShowingDetail = false
  }
  
  func displayThreadDetail(threadId: String, title: String) {
    // Placeholder for thread detail
    isShowingDetail = false
  }
  
  func clearDetail() {
    currentDestination = nil
    isShowingDetail = false
  }
  
  func loadDetailContent(for detailItem: DetailItem) async {
    // This would load the actual content
    // For now, we'll just set the detail item
    self.detailItem = detailItem
    isShowingDetail = true
  }
  
  func pushDetail(_ detailItem: DetailItem) {
    self.detailItem = detailItem
    isShowingDetail = true
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