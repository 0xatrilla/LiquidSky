import Client
import Foundation
import SwiftUI

@available(iOS 18.0, *)
struct EnhancedSearchView: View {
  let client: BSkyClient
  @Environment(\.contentColumnManager) var contentManager
  @Environment(\.glassEffectManager) var glassEffectManager
  @State private var searchText = ""
  @State private var searchResults: [SearchResultData] = []
  @State private var isSearching = false
  @State private var selectedFilter: SearchContentType = .all
  @State private var selectedSort: SearchSortOrder = .relevance
  @State private var showingFilters = false
  @Namespace private var searchNamespace

  var body: some View {
    GlassEffectContainer(spacing: 16.0) {
      VStack(spacing: 0) {
        // Search header
        searchHeader

        // Search results
        searchResultsView
      }
    }
    .onAppear {
      loadTrendingContent()
    }
    .onChange(of: searchText) { _, newValue in
      if !newValue.isEmpty {
        Task {
          await performSearch(query: newValue)
        }
      } else {
        loadTrendingContent()
      }
    }
    .onChange(of: selectedFilter) { _, _ in
      if !searchText.isEmpty {
        Task {
          await performSearch(query: searchText)
        }
      }
    }
    .onChange(of: selectedSort) { _, _ in
      if !searchText.isEmpty {
        Task {
          await performSearch(query: searchText)
        }
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
      // Focus search bar
    }
  }

  // MARK: - Search Header

  @ViewBuilder
  private var searchHeader: some View {
    VStack(spacing: 12) {
      // Search bar
      GestureAwareSearchBar(
        text: $searchText,
        placeholder: "Search posts, users, and more..."
      )
      .padding(.horizontal, 16)

      // Filter and sort controls
      HStack {
        // Content type filter
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(SearchContentType.allCases, id: \.self) { filter in
              SearchFilterChip(
                filter: filter,
                isSelected: selectedFilter == filter
              ) {
                withAnimation(.smooth(duration: 0.2)) {
                  selectedFilter = filter
                }
              }
            }
          }
          .padding(.horizontal, 16)
        }

        Spacer()

        // Sort menu
        Menu {
          ForEach(SearchSortOrder.allCases, id: \.self) { sort in
            Button {
              selectedSort = sort
            } label: {
              HStack {
                Text(sort.title)
                if selectedSort == sort {
                  Image(systemName: "checkmark")
                }
              }
            }
          }
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "arrow.up.arrow.down")
              .font(.caption)
            Text(selectedSort.title)
              .font(.caption.weight(.medium))
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(.ultraThinMaterial, in: Capsule())
          .background {
            if #available(iOS 26.0, *) {
              Capsule()
                .glassEffect(.regular.interactive(), in: .capsule)
            }
          }
        }
        .padding(.trailing, 16)
      }
    }
    .padding(.vertical, 8)
  }

  // MARK: - Search Results View

  @ViewBuilder
  private var searchResultsView: some View {
    if isSearching {
      searchLoadingView
    } else if searchResults.isEmpty && !searchText.isEmpty {
      searchEmptyView
    } else {
      GeometryReader { geometry in
        ScrollView {
          LazyVGrid(columns: gridColumns(for: geometry.size), spacing: 16) {
            ForEach(filteredResults) { result in
              SearchResultCard(result: result)
                .glassEffectID(result.id, in: searchNamespace)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
      }
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

  // MARK: - Grid Configuration

  private func gridColumns(for size: CGSize) -> [GridItem] {
    let columnCount = contentManager.searchState.columnCount
    let spacing: CGFloat = 16
    let totalSpacing = spacing * CGFloat(columnCount - 1)
    let availableWidth = size.width - 32 - totalSpacing
    let columnWidth = availableWidth / CGFloat(columnCount)

    return Array(repeating: GridItem(.fixed(columnWidth), spacing: spacing), count: columnCount)
  }

  // MARK: - Computed Properties

  private var filteredResults: [SearchResultData] {
    switch selectedFilter {
    case .all:
      return searchResults
    case .posts:
      return searchResults.filter { $0.type == .post }
    case .users:
      return searchResults.filter { $0.type == .user }
    case .media:
      return searchResults.filter { $0.type == .post && $0.hasMedia }
    }
  }

  // MARK: - Search Methods

  private func performSearch(query: String) async {
    guard !query.isEmpty else { return }

    isSearching = true

    // Simulate search delay
    try? await Task.sleep(nanoseconds: 500_000_000)  // 500ms

    withAnimation(.smooth(duration: 0.3)) {
      searchResults = generateMockSearchResults(for: query)
    }

    isSearching = false
  }

  private func loadTrendingContent() {
    withAnimation(.smooth(duration: 0.3)) {
      searchResults = generateTrendingContent()
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
      switch selectedSort {
      case .relevance:
        return result1.relevanceScore > result2.relevanceScore
      case .recent:
        return result1.timestamp > result2.timestamp
      case .popular:
        return result1.engagement.totalEngagement > result2.engagement.totalEngagement
      }
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
  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0

  private let cardId = UUID().uuidString

  var body: some View {
    GestureAwareGlassCard(
      cornerRadius: 16,
      isInteractive: true
    ) {
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
            .background {
              if #available(iOS 26.0, *) {
                Circle()
                  .glassEffect(.regular.tint(result.type.color))
              }
            }

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
    .contextMenu {
      searchResultContextMenu
    }
  }

  // MARK: - Components

  @ViewBuilder
  private var searchResultContextMenu: some View {
    if result.type == .post {
      Button("View Post") {
        // Handle view post
      }

      Button("Share") {
        // Handle share
      }

      Divider()

      Button("Save") {
        // Handle save
      }
    } else if result.type == .user {
      Button("View Profile") {
        // Handle view profile
      }

      Button("Message") {
        // Handle message
      }

      Divider()

      Button("Mute") {
        // Handle mute
      }
    }
  }

  // MARK: - Computed Properties

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
