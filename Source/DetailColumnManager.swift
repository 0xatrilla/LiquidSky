import SwiftUI
import Destinations
import Models
import ATProtoKit
import Client
import PostUI

@available(iOS 18.0, *)
@Observable
class DetailColumnManager {
  var currentDestination: RouterDestination?
  var isShowingDetail = false
  
  // Client for API calls
  private let client: BSkyClient
  
  // Media detail state
  var mediaDetailState = MediaDetailState()
  
  // Post detail state
  var postDetailState = PostDetailState()
  
  // Profile detail state
  var profileDetailState = ProfileDetailState()
  
  // Detail item state
  var detailItem: DetailItem?
  
  init(client: BSkyClient) {
    self.client = client
  }
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
    self.detailItem = detailItem
    isShowingDetail = true
    
    switch detailItem {
    case .profile(let profile):
      await loadProfileDetail(profile)
    case .post(let post):
      await loadPostDetail(post)
    case .media(let media):
      await loadMediaDetail(media)
    }
  }
  
  private func loadProfileDetail(_ profile: Profile) async {
    profileDetailState.isLoading = true
    profileDetailState.error = nil
    
    do {
      // First, try to get the real profile data using the handle
      let realProfile = try await fetchProfileByHandle(profile.handle)
      
      // Convert to ProfileDetailData
      let profileDetailData = ProfileDetailData(
        id: realProfile.actorDID,
        handle: realProfile.actorHandle,
        displayName: realProfile.displayName,
        description: realProfile.description,
        bio: realProfile.description,
        avatarImageURL: realProfile.avatarImageURL,
        avatarUrl: realProfile.avatarImageURL,
        bannerImageURL: realProfile.bannerImageURL,
        bannerUrl: realProfile.bannerImageURL,
        followersCount: realProfile.followerCount ?? 0,
        followingCount: realProfile.followCount ?? 0,
        postsCount: realProfile.postCount ?? 0,
        isFollowing: realProfile.viewer?.followingURI != nil,
        isFollowedBy: realProfile.viewer?.followedByURI != nil,
        isBlocked: realProfile.viewer?.isBlocked == true,
        isBlocking: realProfile.viewer?.blockingURI != nil,
        isMuted: realProfile.viewer?.isMuted == true,
        joinDate: nil, // This would need to be fetched separately
        posts: [] // Will be loaded separately
      )
      
      profileDetailState.profile = profileDetailData
      
      // Load posts for this profile
      await loadProfilePosts(realProfile.actorDID)
      
    } catch {
      print("DetailColumnManager: Error loading profile: \(error)")
      profileDetailState.error = error
    }
    
    profileDetailState.isLoading = false
  }
  
  private func loadPostDetail(_ post: PostItem) async {
    postDetailState.isLoading = true
    postDetailState.error = nil
    
    // TODO: Implement post detail loading
    postDetailState.isLoading = false
  }
  
  private func loadMediaDetail(_ media: MediaDetailData) async {
    mediaDetailState.isLoading = true
    mediaDetailState.error = nil
    
    // TODO: Implement media detail loading
    mediaDetailState.isLoading = false
  }
  
  private func fetchProfileByHandle(_ handle: String) async throws -> AppBskyLexicon.Actor.ProfileViewDetailedDefinition {
    do {
      // First, search for the actor by handle to get their DID
      let searchResults = try await client.protoClient.searchActors(matching: handle, limit: 1)
      
      guard let firstActor = searchResults.actors.first else {
        throw NSError(domain: "ProfileError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
      }
      
      // Now fetch the detailed profile using the DID
      let detailedProfile = try await client.protoClient.getProfile(for: firstActor.actorDID)
      return detailedProfile
    } catch {
      print("DetailColumnManager: Error fetching profile for handle \(handle): \(error)")
      throw error
    }
  }
  
  private func loadProfilePosts(_ did: String) async {
    do {
      // Fetch the author feed for this profile using the same pattern as PostsProfileView
      let feed = try await client.protoClient.getAuthorFeed(by: did, postFilter: .postsWithReplies)
      
      // Convert feed items to PostItem objects using the same processFeed function
      let posts = await processFeed(feed.feed, client: client.protoClient)
      profileDetailState.posts = posts
      
    } catch {
      print("DetailColumnManager: Error loading profile posts: \(error)")
      profileDetailState.error = error
    }
  }
  
  func pushDetail(_ detailItem: DetailItem) {
    self.detailItem = detailItem
    isShowingDetail = true
  }
}

// MARK: - Environment Key

@available(iOS 18.0, *)
struct DetailColumnManagerKey: EnvironmentKey {
  static let defaultValue: DetailColumnManager = {
    // This will be overridden by the app with a real client
    fatalError("DetailColumnManager must be provided with a real BSkyClient")
  }()
}

@available(iOS 18.0, *)
extension EnvironmentValues {
  var detailColumnManager: DetailColumnManager {
    get { self[DetailColumnManagerKey.self] }
    set { self[DetailColumnManagerKey.self] = newValue }
  }
}