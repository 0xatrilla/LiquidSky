import Client
import Foundation
import SwiftUI
import ATProtoKit
import Models
import Destinations
import AppRouter
import FeedUI

@available(iOS 18.0, *)
struct EnhancedSearchView: View {
  let client: BSkyClient
  @Environment(\.contentColumnManager) var contentManager
  @Environment(\.glassEffectManager) var glassEffectManager
  @Environment(AppRouter.self) private var router
  @State private var searchText = ""
  @State private var searchResults: [SearchResultData] = []
  @State private var isSearching = false
  @State private var trendingTopics: [TrendingTopic] = []
  @State private var suggestedUsers: [SuggestedUser] = []
  @State private var trendingContentService: TrendingContentService
  @Namespace private var searchNamespace

  init(client: BSkyClient) {
    self.client = client
    self._trendingContentService = State(initialValue: TrendingContentService(client: client))
  }

  var body: some View {
    GlassEffectContainer(spacing: 16.0) {
      // Search results
      searchResultsView
    }
    .onAppear {
      loadTrendingContent()
      startDynamicUpdates()
      setupNotificationObservers()
    }
    .searchable(text: $searchText, prompt: "Search posts, users, and more...")
    .onChange(of: searchText) { _, newValue in
      if !newValue.isEmpty {
        Task {
          await performSearch(query: newValue)
        }
      } else {
        loadTrendingContent()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
      // Focus search bar
    }
  }


  // MARK: - Search Results View

  @ViewBuilder
  private var searchResultsView: some View {
    if isSearching {
      searchLoadingView
    } else if searchResults.isEmpty && !searchText.isEmpty {
      searchEmptyView
    } else if searchText.isEmpty {
      // Show trending topics and suggested users when not searching
      trendingAndSuggestedView
    } else {
      // Show search results when searching
      List {
        ForEach(searchResults) { result in
          SearchResultCard(result: result)
            .glassEffectID(result.id, in: searchNamespace)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
      }
      .listStyle(.insetGrouped)
    }
  }

  @ViewBuilder
  private var searchLoadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)

      Text("Searching...")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
      if #available(iOS 26.0, *) {
        Rectangle()
          .glassEffect(.regular, in: .rect(cornerRadius: 16))
      }
    }
  }

  @ViewBuilder
  private var searchEmptyView: some View {
    ContentUnavailableView(
      "No results found",
      systemImage: "magnifyingglass",
      description: Text("Try adjusting your search terms or filters")
    )
    .background {
      if #available(iOS 26.0, *) {
        Rectangle()
          .glassEffect(.regular, in: .rect(cornerRadius: 16))
      }
    }
  }

  @ViewBuilder
  private var trendingAndSuggestedView: some View {
    ScrollView {
      LazyVStack(spacing: 24) {
        // Trending Topics Section
        trendingTopicsSection
        
        // Suggested Users Section
        suggestedUsersSection
      }
      .padding(.horizontal, 16)
      .padding(.top, 8)
    }
  }

  @ViewBuilder
  private var trendingTopicsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Trending Topics")
          .font(.title2)
          .fontWeight(.bold)
        
        Spacer()
        
        Button("See All") {
          // TODO: Navigate to full trending topics
        }
        .font(.caption)
        .foregroundColor(.blue)
      }
      
      LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
      ], spacing: 8) {
        ForEach(trendingTopics, id: \.self) { topic in
          TrendingTopicCard(topic: topic, router: router)
        }
      }
    }
  }

  @ViewBuilder
  private var suggestedUsersSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Suggested Users")
          .font(.title2)
          .fontWeight(.bold)
        
        Spacer()
        
        HStack(spacing: 12) {
          Button(action: {
            Task {
              await loadTrendingContent()
            }
          }) {
            Image(systemName: "arrow.clockwise")
              .font(.caption)
              .foregroundColor(.blue)
          }
          .disabled(trendingContentService.isLoading)
          
          Button("See All") {
            // TODO: Navigate to full suggested users
          }
          .font(.caption)
          .foregroundColor(.blue)
        }
      }
      
      if trendingContentService.isLoading {
        HStack {
          ProgressView()
            .scaleEffect(0.8)
          Text("Loading suggested users...")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
      } else if suggestedUsers.isEmpty {
        Text("No suggested users available")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
          .padding()
      } else {
        LazyVStack(spacing: 8) {
          ForEach(suggestedUsers, id: \.handle) { user in
            SuggestedUserCard(user: user, router: router)
          }
        }
      }
    }
  }

  // MARK: - Grid Configuration (removed - now using List)


  // MARK: - Search Methods

  private func performSearch(query: String) async {
    guard !query.isEmpty else { return }

    isSearching = true

    do {
      // Search for users and posts using AT Protocol
      let userResults = try await searchUsers(query: query)
      let postResults = try await searchPosts(query: query)
      
      let allResults = userResults + postResults
      
      withAnimation(.smooth(duration: 0.3)) {
        searchResults = allResults
      }
    } catch {
      // Fallback to mock results if search fails
      withAnimation(.smooth(duration: 0.3)) {
        searchResults = generateMockSearchResults(for: query)
      }
    }

    isSearching = false
  }

  private func loadTrendingContent() {
    Task {
      await trendingContentService.fetchTrendingContent()
      
      // Convert Profile objects to SuggestedUser objects
      await MainActor.run {
        withAnimation(.smooth(duration: 0.3)) {
          suggestedUsers = trendingContentService.suggestedUsers.map { profile in
            SuggestedUser(
              did: profile.did,
              handle: profile.handle,
              displayName: profile.displayName ?? profile.handle,
              avatar: profile.avatarImageURL?.absoluteString,
              followersCount: profile.followersCount,
              isFollowing: profile.isFollowing,
              reason: generateSuggestionReason(for: profile)
            )
          }
          trendingTopics = generateTrendingTopics() // Keep trending topics as mock for now
        }
      }
    }
  }

  private func generateMockSearchResults(for query: String) -> [SearchResultData] {
    var results: [SearchResultData] = []

    // Generate mock posts
    for i in 1...10 {
      results.append(
        SearchResultData(
          id: "post-\(i)",
          type: .post,
          title: "Post containing '\(query)' - \(i)",
          subtitle:
            "This is a sample post that contains the search term '\(query)' in its content.",
          authorName: "User \(i)",
          authorHandle: "@user\(i)",
          authorAvatar: nil,
          timestamp: Date().addingTimeInterval(-Double(i * 3600)),
          engagement: SearchEngagement(
            likes: Int.random(in: 0...100),
            reposts: Int.random(in: 0...50),
            replies: Int.random(in: 0...25)
          ),
          hasMedia: i % 3 == 0,
          mediaUrl: i % 3 == 0 ? "https://picsum.photos/300/200" : nil,
          relevanceScore: Double.random(in: 0.5...1.0)
        ))
    }

    // Generate mock users
    for i in 1...5 {
      results.append(
        SearchResultData(
          id: "user-\(i)",
          type: .user,
          title: "User \(i) (\(query.lowercased())user\(i))",
          subtitle: "Bio containing information about \(query)",
          authorName: "User \(i)",
          authorHandle: "@\(query.lowercased())user\(i)",
          authorAvatar: nil,
          timestamp: Date(),
          engagement: SearchEngagement(
            likes: 0,
            reposts: 0,
            replies: 0
          ),
          hasMedia: false,
          mediaUrl: nil,
          relevanceScore: Double.random(in: 0.3...0.8),
          followerCount: Int.random(in: 100...10000),
          isFollowing: Bool.random()
        ))
    }

    return results.sorted { result1, result2 in
      // Sort by relevance score (most relevant first)
      return result1.relevanceScore > result2.relevanceScore
    }
  }

  private func generateTrendingContent() -> [SearchResultData] {
    let trendingTopics = ["Technology", "Design", "SwiftUI", "iPad", "AI", "Photography"]

    return trendingTopics.enumerated().map { index, topic in
      SearchResultData(
        id: "trending-\(index)",
        type: .post,
        title: "Trending: \(topic)",
        subtitle: "Popular posts about \(topic) today",
        authorName: "Trending",
        authorHandle: "@trending",
        authorAvatar: nil,
        timestamp: Date(),
        engagement: SearchEngagement(
          likes: Int.random(in: 50...500),
          reposts: Int.random(in: 20...200),
          replies: Int.random(in: 10...100)
        ),
        hasMedia: index % 2 == 0,
        mediaUrl: index % 2 == 0 ? "https://picsum.photos/300/200" : nil,
        relevanceScore: 1.0
      )
    }
  }

  private func generateTrendingTopics() -> [TrendingTopic] {
    let topics = [
      ("Technology", 1247, 15.2),
      ("Design", 892, 8.7),
      ("SwiftUI", 654, 23.1),
      ("iPad", 432, 12.4),
      ("AI", 2156, 45.8),
      ("Photography", 743, 6.3),
      ("iOS", 1089, 18.9),
      ("macOS", 567, 9.2),
      ("Web Development", 445, 7.1),
      ("Mobile Apps", 678, 11.6)
    ]
    
    return topics.map { name, postCount, growth in
      TrendingTopic(
        name: name,
        postCount: postCount,
        growth: growth
      )
    }
  }

  private func generateSuggestionReason(for profile: Profile) -> String {
    // Generate contextual reasons based on profile characteristics
    if profile.followersCount > 10000 {
      return "Popular account"
    } else if profile.handle.contains("dev") || profile.handle.contains("tech") {
      return "Tech community"
    } else if profile.handle.contains("art") || profile.handle.contains("design") {
      return "Creative community"
    } else if profile.followersCount > 1000 {
      return "Active user"
    } else {
      return "Similar interests"
    }
  }

  private func startDynamicUpdates() {
    // Update trending topics every 30 seconds
    Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
      Task { @MainActor in
        withAnimation(.smooth(duration: 0.5)) {
          trendingTopics = generateTrendingTopics()
        }
      }
    }
    
    // Update suggested users every 2 minutes to get fresh suggestions
    Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { _ in
      Task { @MainActor in
        await loadTrendingContent()
      }
    }
  }
  
  private func setupNotificationObservers() {
    // Refresh suggestions when user follows/unfollows someone
    NotificationCenter.default.addObserver(
      forName: .userDidFollow,
      object: nil,
      queue: .main
    ) { _ in
      Task {
        await loadTrendingContent()
      }
    }
    
    NotificationCenter.default.addObserver(
      forName: .userDidUnfollow,
      object: nil,
      queue: .main
    ) { _ in
      Task {
        await loadTrendingContent()
      }
    }
  }

  private func extractMediaUrl(from embedData: EmbedData?) -> String? {
    guard let embedData = embedData else { return nil }
    
    switch embedData {
    case .images(let imagesEmbed):
      return imagesEmbed.images.first?.fullSizeImageURL.absoluteString
    case .videos(let videoEmbed):
      return videoEmbed.thumbnailImageURL
    case .external(let externalEmbed):
      return externalEmbed.external.uri
    case .quotedPost, .none:
      return nil
    }
  }

  private func searchUsers(query: String) async throws -> [SearchResultData] {
    // Use AT Protocol search for users
    let searchResponse = try await client.protoClient.searchActors(matching: query, limit: 20)
    
    return searchResponse.actors.map { actor in
      SearchResultData(
        id: "user-\(actor.actorDID)",
        type: .user,
        title: actor.displayName ?? actor.actorHandle,
        subtitle: "@\(actor.actorHandle)",
        authorName: actor.displayName ?? actor.actorHandle,
        authorHandle: "@\(actor.actorHandle)",
        authorAvatar: actor.avatarImageURL,
        timestamp: Date(),
        engagement: SearchEngagement(
          likes: 0,
          reposts: 0,
          replies: 0
        ),
        hasMedia: false,
        mediaUrl: nil,
        relevanceScore: 1.0
      )
    }
  }

  private func searchPosts(query: String) async throws -> [SearchResultData] {
    // Use AT Protocol search for posts
    let searchResponse = try await client.protoClient.searchPosts(matching: query, limit: 20)
    
    return searchResponse.posts.map { post in
      let author = post.author
      let record = post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)
      let embedData = EmbedDataExtractor.extractEmbed(from: post)
      
      return SearchResultData(
        id: "post-\(post.uri)",
        type: .post,
        title: record?.text ?? "",
        subtitle: "@\(author.actorHandle)",
        authorName: author.displayName ?? author.actorHandle,
        authorHandle: "@\(author.actorHandle)",
        authorAvatar: author.avatarImageURL,
        timestamp: post.indexedAt,
        engagement: SearchEngagement(
          likes: post.likeCount ?? 0,
          reposts: post.repostCount ?? 0,
          replies: post.replyCount ?? 0
        ),
        hasMedia: embedData != nil,
        mediaUrl: extractMediaUrl(from: embedData),
        relevanceScore: 1.0
      )
    }
  }
}

// MARK: - Search Filter Chip

@available(iOS 18.0, *)
struct SearchFilterChip: View {
  let filter: SearchContentType
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 6) {
        Image(systemName: filter.icon)
          .font(.caption)

        Text(filter.title)
          .font(.caption.weight(.medium))
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
      )
      .overlay {
        if isSelected {
          Capsule()
            .stroke(Color.blue, lineWidth: 1)
        }
      }
    }
    .buttonStyle(.plain)
    .foregroundStyle(isSelected ? Color.blue : .secondary)
    .background {
      if #available(iOS 26.0, *) {
        Capsule()
          .glassEffect(
            isSelected ? .regular.tint(Color.blue).interactive() : .regular.interactive(),
            in: .capsule
          )
      }
    }
  }
}

// MARK: - Search Result Card

@available(iOS 18.0, *)
struct SearchResultCard: View {
  let result: SearchResultData

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack(spacing: 12) {
        // Type icon
        Image(systemName: result.type.icon)
          .font(.subheadline)
          .foregroundStyle(result.type.color)
          .frame(width: 20, height: 20)
          .background(
            Circle()
              .fill(result.type.color.opacity(0.1))
          )

        // Author info
        VStack(alignment: .leading, spacing: 2) {
          Text(result.authorName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)

          Text(result.authorHandle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        // Timestamp
        Text(result.timestamp, style: .relative)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }

        // Content
        VStack(alignment: .leading, spacing: 8) {
          Text(result.title)
            .font(.body.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(2)

          Text(result.subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }

        // Media preview
        if let mediaUrl = result.mediaUrl {
          AsyncImage(url: URL(string: mediaUrl)) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.gray.opacity(0.1))
              .overlay {
                ProgressView()
              }
          }
          .frame(height: 120)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .background {
            if #available(iOS 26.0, *) {
              RoundedRectangle(cornerRadius: 8)
                .glassEffect(.regular, in: .rect(cornerRadius: 8))
            }
          }
        }

        // Footer
        HStack {
          if result.type == .post {
            // Engagement metrics
            HStack(spacing: 16) {
              MetricView(
                icon: "heart",
                count: result.engagement.likes,
                color: Color.red
              )

              MetricView(
                icon: "arrow.2.squarepath",
                count: result.engagement.reposts,
                color: Color.green
              )

              MetricView(
                icon: "bubble.left",
                count: result.engagement.replies,
                color: Color.blue
              )
            }
          } else if result.type == .user {
            // User metrics
            HStack(spacing: 16) {
              if let followerCount = result.followerCount {
                Text("\(followerCount) followers")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              Spacer()

              Button {
                // Handle follow/unfollow
              } label: {
                Text(result.isFollowing == true ? "Following" : "Follow")
                  .font(.caption.weight(.medium))
                  .foregroundStyle(result.isFollowing == true ? .secondary : Color.blue)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 4)
                  .background(
                    Capsule()
                      .fill(result.isFollowing == true ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                  )
                  .overlay {
                    if result.isFollowing != true {
                      Capsule()
                        .stroke(Color.blue, lineWidth: 1)
                    }
                  }
              }
              .buttonStyle(.plain)
              .background {
                if #available(iOS 26.0, *) {
                  Capsule()
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
              }
            }
          }

          Spacer()

          // Relevance indicator
          HStack(spacing: 4) {
            ForEach(0..<5) { index in
              Circle()
                .fill(index < Int(result.relevanceScore * 5) ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 4, height: 4)
            }
          }
        }
      }
      .padding(16)
      .background(Color(.systemBackground))
      .cornerRadius(12)
      .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
  }

// MARK: - Metric View

@available(iOS 18.0, *)
struct MetricView: View {
  let icon: String
  let count: Int
  let color: Color

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
        .font(.caption2)
        .foregroundStyle(color)

      Text("\(count)")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - Data Models

@available(iOS 18.0, *)
struct SearchResultData: Identifiable, Hashable {
  let id: String
  let type: SearchResultType
  let title: String
  let subtitle: String
  let authorName: String
  let authorHandle: String
  let authorAvatar: URL?
  let timestamp: Date
  let engagement: SearchEngagement
  let hasMedia: Bool
  let mediaUrl: String?
  let relevanceScore: Double
  let followerCount: Int?
  let isFollowing: Bool?

  init(
    id: String, type: SearchResultType, title: String, subtitle: String, authorName: String,
    authorHandle: String, authorAvatar: URL?, timestamp: Date, engagement: SearchEngagement,
    hasMedia: Bool, mediaUrl: String?, relevanceScore: Double, followerCount: Int? = nil,
    isFollowing: Bool? = nil
  ) {
    self.id = id
    self.type = type
    self.title = title
    self.subtitle = subtitle
    self.authorName = authorName
    self.authorHandle = authorHandle
    self.authorAvatar = authorAvatar
    self.timestamp = timestamp
    self.engagement = engagement
    self.hasMedia = hasMedia
    self.mediaUrl = mediaUrl
    self.relevanceScore = relevanceScore
    self.followerCount = followerCount
    self.isFollowing = isFollowing
  }

  static func == (lhs: SearchResultData, rhs: SearchResultData) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

@available(iOS 18.0, *)
struct SearchEngagement {
  let likes: Int
  let reposts: Int
  let replies: Int

  var totalEngagement: Int {
    likes + reposts + replies
  }
}

@available(iOS 18.0, *)
enum SearchResultType {
  case post, user

  var icon: String {
    switch self {
    case .post: return "doc.text"
    case .user: return "person"
    }
  }

  var color: Color {
    switch self {
    case .post: return Color.blue
    case .user: return Color.green
    }
  }
}

// MARK: - Extensions

@available(iOS 18.0, *)
extension SearchContentType {
  static var allCases: [SearchContentType] {
    [.all, .posts, .users, .media]
  }

  var icon: String {
    switch self {
    case .all: return "square.grid.2x2"
    case .posts: return "doc.text"
    case .users: return "person"
    case .media: return "photo"
    }
  }

  var title: String {
    switch self {
    case .all: return "All"
    case .posts: return "Posts"
    case .users: return "Users"
    case .media: return "Media"
    }
  }
}

@available(iOS 18.0, *)
extension SearchSortOrder {
  static var allCases: [SearchSortOrder] {
    [.relevance, .recent, .popular]
  }

  var title: String {
    switch self {
    case .relevance: return "Relevance"
    case .recent: return "Recent"
    case .popular: return "Popular"
    }
  }
}

// MARK: - Data Models

@available(iOS 18.0, *)
struct TrendingTopic: Identifiable, Hashable {
  let id = UUID()
  let name: String
  let postCount: Int
  let growth: Double // Percentage growth
  
  static func == (lhs: TrendingTopic, rhs: TrendingTopic) -> Bool {
    lhs.name == rhs.name
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }
}

@available(iOS 18.0, *)
struct SuggestedUser: Identifiable, Hashable {
  let id = UUID()
  let did: String
  let handle: String
  let displayName: String
  let avatar: String?
  let followersCount: Int
  let isFollowing: Bool
  let reason: String // Why this user is suggested
  
  static func == (lhs: SuggestedUser, rhs: SuggestedUser) -> Bool {
    lhs.handle == rhs.handle
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(handle)
  }
}

// MARK: - Card Components

@available(iOS 18.0, *)
struct TrendingTopicCard: View {
  let topic: TrendingTopic
  let router: Router<AppTab, RouterDestination, SheetDestination>
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(topic.name)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
        
        Spacer()
        
        if topic.growth > 0 {
          Image(systemName: "arrow.up")
            .font(.caption2)
            .foregroundColor(.green)
        }
      }
      
      Text("\(topic.postCount) posts")
        .font(.caption2)
        .foregroundColor(.secondary)
      
      if topic.growth > 0 {
        Text("+\(Int(topic.growth))%")
          .font(.caption2)
          .foregroundColor(.green)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(.systemGray6))
    )
    .onTapGesture {
      // Navigate to hashtag feed
      router[.compose].append(.hashtag(topic.name))
    }
  }
}

@available(iOS 18.0, *)
struct SuggestedUserCard: View {
  let user: SuggestedUser
  let router: Router<AppTab, RouterDestination, SheetDestination>
  
  var body: some View {
    HStack(spacing: 12) {
      AsyncImage(url: URL(string: user.avatar ?? "")) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Circle()
          .fill(Color.gray.opacity(0.3))
      }
      .frame(width: 40, height: 40)
      .clipShape(Circle())
      
      VStack(alignment: .leading, spacing: 2) {
        Text(user.displayName)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.primary)
        
        Text("@\(user.handle)")
          .font(.caption)
          .foregroundColor(.secondary)
        
        Text(user.reason)
          .font(.caption2)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }
      
      Spacer()
      
      VStack(alignment: .trailing, spacing: 4) {
        Text("\(user.followersCount)")
          .font(.caption)
          .foregroundColor(.secondary)
        
        Button(user.isFollowing ? "Following" : "Follow") {
          // TODO: Follow/unfollow user
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .fill(user.isFollowing ? Color.gray.opacity(0.2) : Color.blue)
        )
        .foregroundColor(user.isFollowing ? .primary : .white)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(.systemGray6))
    )
    .onTapGesture {
      // Navigate to user profile using the real DID from search results
      let profile = Profile(
        did: user.did, // Use the real DID from search results
        handle: user.handle,
        displayName: user.displayName,
        avatarImageURL: user.avatar.flatMap { URL(string: $0) },
        description: nil,
        followersCount: user.followersCount,
        followingCount: 0,
        postsCount: 0,
        isFollowing: user.isFollowing,
        isFollowedBy: false,
        isBlocked: false,
        isBlocking: false,
        isMuted: false
      )
      router[.compose].append(.profile(profile))
    }
  }
}
