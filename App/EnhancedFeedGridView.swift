import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
struct EnhancedFeedGridView: View {
  @Environment(\.contentColumnManager) var contentManager
  @Environment(\.glassEffectManager) var glassEffectManager
  @Environment(\.gestureCoordinator) var gestureCoordinator
  @State private var refreshTrigger = false
  @State private var isRefreshing = false
  @State private var scrollPosition: CGPoint = .zero
  @Namespace private var feedNamespace

  // Mock data for demonstration
  @State private var feedItems: [FeedItemData] = []

  var body: some View {
    GeometryReader { geometry in
      GlassEffectContainer(spacing: 16.0) {
        ScrollView {
          LazyVGrid(columns: gridColumns(for: geometry.size), spacing: 16) {
            ForEach(feedItems) { item in
              EnhancedFeedCard(item: item)
                .glassEffectID(item.id, in: feedNamespace)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
        .refreshable {
          await refreshFeed()
        }
        .overlay(alignment: .top) {
          if isRefreshing {
            GlassRefreshIndicator()
              .transition(.move(edge: .top).combined(with: .opacity))
          }
        }
      }
    }
    .onAppear {
      loadInitialData()
    }
    .onChange(of: contentManager.feedState.columnCount) { _, newCount in
      // Animate layout change
      withAnimation(.smooth(duration: 0.3)) {
        // Grid will automatically update with new column count
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .refresh)) { _ in
      Task {
        await refreshFeed()
      }
    }
  }

  // MARK: - Grid Configuration

  private func gridColumns(for size: CGSize) -> [GridItem] {
    let columnCount = contentManager.feedState.columnCount
    let spacing: CGFloat = 16
    let totalSpacing = spacing * CGFloat(columnCount - 1)
    let availableWidth = size.width - 32 - totalSpacing  // 32 for horizontal padding
    let columnWidth = availableWidth / CGFloat(columnCount)

    return Array(repeating: GridItem(.fixed(columnWidth), spacing: spacing), count: columnCount)
  }

  // MARK: - Data Loading

  private func loadInitialData() {
    // Mock data generation
    feedItems = generateMockFeedItems()
  }

  private func refreshFeed() async {
    isRefreshing = true

    // Simulate network request
    try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

    // Update with new mock data
    withAnimation(.smooth(duration: 0.5)) {
      feedItems = generateMockFeedItems()
    }

    isRefreshing = false
  }

  private func generateMockFeedItems() -> [FeedItemData] {
    return (1...20).map { index in
      FeedItemData(
        id: "feed-\(index)-\(UUID().uuidString)",
        authorName: "User \(index)",
        authorHandle: "@user\(index)",
        authorAvatar: nil,
        content:
          "This is a sample post content for item \(index). It demonstrates the enhanced feed grid layout with glass effects and adaptive columns.",
        timestamp: Date().addingTimeInterval(-Double(index * 3600)),
        likesCount: Int.random(in: 0...100),
        repostsCount: Int.random(in: 0...50),
        repliesCount: Int.random(in: 0...25),
        isLiked: Bool.random(),
        isReposted: Bool.random(),
        mediaItems: index % 3 == 0 ? generateMockMedia() : [],
        type: .post
      )
    }
  }

  private func generateMockMedia() -> [MediaItem] {
    return [
      MediaItem(
        id: UUID().uuidString,
        type: .image,
        url: "https://picsum.photos/400/300",
        thumbnailUrl: "https://picsum.photos/200/150",
        altText: "Sample image"
      )
    ]
  }
}

// MARK: - Enhanced Feed Card

@available(iPadOS 26.0, *)
struct EnhancedFeedCard: View {
  let item: FeedItemData
  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0
  @State private var isPressed = false

  private let cardId = UUID().uuidString

  var body: some View {
    GestureAwareGlassCard(
      cornerRadius: 16,
      isInteractive: true
    ) {
      VStack(alignment: .leading, spacing: 12) {
        // Author header
        authorHeader

        // Content
        contentSection

        // Media (if present)
        if !item.mediaItems.isEmpty {
          mediaSection
        }

        // Interaction buttons
        interactionButtons
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
    .onLongPressGesture(minimumDuration: 0) { pressing in
      withAnimation(.smooth(duration: 0.1)) {
        isPressed = pressing
      }
    } perform: {
    }
    .contextMenu {
      feedCardContextMenu
    }
  }

  // MARK: - Card Components

  @ViewBuilder
  private var authorHeader: some View {
    HStack(spacing: 12) {
      // Avatar
      AsyncImage(url: item.authorAvatar) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Circle()
          .fill(.quaternary)
          .overlay {
            Image(systemName: "person.fill")
              .foregroundStyle(.secondary)
          }
      }
      .frame(width: 40, height: 40)
      .clipShape(Circle())
      .background(.ultraThinMaterial, in: Circle())

      // Author info
      VStack(alignment: .leading, spacing: 2) {
        Text(item.authorName)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)

        Text(item.authorHandle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      // Timestamp
      Text(item.timestamp, style: .relative)
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
  }

  @ViewBuilder
  private var contentSection: some View {
    Text(item.content)
      .font(.body)
      .foregroundStyle(.primary)
      .lineLimit(nil)
      .multilineTextAlignment(.leading)
  }

  @ViewBuilder
  private var mediaSection: some View {
    if let mediaItem = item.mediaItems.first {
      AsyncImage(url: URL(string: mediaItem.url)) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        RoundedRectangle(cornerRadius: 12)
          .fill(.quaternary)
          .overlay {
            ProgressView()
          }
      }
      .frame(height: 200)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
  }

  @ViewBuilder
  private var interactionButtons: some View {
    HStack(spacing: 24) {
      // Reply button
      InteractionButton(
        systemImage: "bubble.left",
        count: item.repliesCount,
        isActive: false,
        color: .blue
      ) {
        // Handle reply
      }

      // Repost button
      InteractionButton(
        systemImage: "arrow.2.squarepath",
        count: item.repostsCount,
        isActive: item.isReposted,
        color: .green
      ) {
        // Handle repost
      }

      // Like button
      InteractionButton(
        systemImage: item.isLiked ? "heart.fill" : "heart",
        count: item.likesCount,
        isActive: item.isLiked,
        color: .red
      ) {
        // Handle like
      }

      Spacer()

      // Share button
      Button {
        // Handle share
      } label: {
        Image(systemName: "square.and.arrow.up")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private var feedCardContextMenu: some View {
    Button("Copy Link") {
      // Handle copy link
    }

    Button("Share Post") {
      // Handle share
    }

    Divider()

    Button("Mute User") {
      // Handle mute
    }

    Button("Report Post", role: .destructive) {
      // Handle report
    }
  }

  // MARK: - Computed Properties

  private var scaleEffect: CGFloat {
    if isPressed {
      return 0.98
    } else if isPencilHovering {
      return 1.02
    } else if isHovering {
      return 1.01
    } else {
      return 1.0
    }
  }
}

// MARK: - Interaction Button

@available(iPadOS 26.0, *)
struct InteractionButton: View {
  let systemImage: String
  let count: Int
  let isActive: Bool
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        Image(systemName: systemImage)
          .font(.subheadline)
          .foregroundStyle(isActive ? color : .secondary)

        if count > 0 {
          Text("\(count)")
            .font(.caption)
            .foregroundStyle(isActive ? color : .secondary)
        }
      }
    }
    .buttonStyle(.plain)
    .background(
      isActive ? color.opacity(0.1) : .clear,
      in: RoundedRectangle(cornerRadius: 6)
    )
    .scaleEffect(isActive ? 1.05 : 1.0)
    .animation(.smooth(duration: 0.2), value: isActive)
  }
}

// MARK: - Glass Refresh Indicator

@available(iPadOS 26.0, *)
struct GlassRefreshIndicator: View {
  @State private var rotation: Double = 0

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "arrow.clockwise")
        .font(.subheadline)
        .foregroundStyle(.blue)
        .rotationEffect(.degrees(rotation))
        .onAppear {
          withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            rotation = 360
          }
        }

      Text("Refreshing...")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.primary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(.ultraThinMaterial, in: Capsule())
  }
}

// MARK: - Feed Item Data Model

@available(iPadOS 26.0, *)
struct FeedItemData: Identifiable, Hashable {
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
  let mediaItems: [MediaItem]
  let type: FeedItemType

  static func == (lhs: FeedItemData, rhs: FeedItemData) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

@available(iPadOS 26.0, *)
struct MediaItem: Identifiable, Hashable {
  let id: String
  let type: MediaType
  let url: String
  let thumbnailUrl: String?
  let altText: String?

  enum MediaType {
    case image, video, gif
  }
}

@available(iPadOS 26.0, *)
enum FeedItemType {
  case post, repost, reply
}
