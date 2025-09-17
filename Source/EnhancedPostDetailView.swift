import Foundation
import SwiftUI
import Models

@available(iOS 18.0, *)
struct EnhancedPostDetailView: View {
  let postId: String
  @Environment(\.detailColumnManager) var detailManager
  @Environment(\.glassEffectManager) var glassEffectManager
  @State private var showingReplyComposer = false
  @State private var replyText = ""
  @Namespace private var postDetailNamespace

  var body: some View {
    GlassEffectContainer(spacing: 16.0) {
      if detailManager.postDetailState.isLoading {
        postLoadingView
      } else if let post = detailManager.postDetailState.post {
        ScrollView {
          LazyVStack(spacing: 16) {
            // Main post
            mainPostView(post)

            // Reply composer
            replyComposerView

            // Replies thread
            repliesThreadView
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
      } else {
        postNotFoundView
      }
    }
    .navigationTitle("Post")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        postToolbarButtons
      }
    }
    .onAppear {
      Task {
        let detailItem = DetailItem(post: PostItem(
          uri: postId,
          cid: "placeholder",
          indexedAt: Date(),
          author: Profile(
            did: "placeholder",
            handle: "placeholder",
            displayName: "Loading...",
            avatarImageURL: nil
          ),
          content: "Loading post...",
          replyCount: 0,
          repostCount: 0,
          likeCount: 0,
          likeURI: nil,
          repostURI: nil,
          replyRef: nil
        ))
        await detailManager.loadDetailContent(for: detailItem)
      }
    }
  }

  // MARK: - Main Post View

  @ViewBuilder
  private func mainPostView(_ post: PostDetailData) -> some View {
    GestureAwareGlassCard(
      cornerRadius: 20,
      isInteractive: true
    ) {
      VStack(alignment: .leading, spacing: 16) {
        // Author header
        postAuthorHeader(post)

        // Post content
        postContentSection(post)

        // Media gallery
        if !post.mediaItems.isEmpty {
          postMediaGallery(post.mediaItems)
        }

        // Engagement metrics
        postEngagementMetrics(post)

        // Interaction buttons
        postInteractionButtons(post)
      }
      .padding(20)
    }
    .id("main-post-\(post.id)")
  }

  @ViewBuilder
  private func postAuthorHeader(_ post: PostDetailData) -> some View {
    HStack(spacing: 16) {
      // Avatar
      AsyncImage(url: post.authorAvatar) { image in
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
      .frame(width: 50, height: 50)
      .clipShape(Circle())

      // Author info
      VStack(alignment: .leading, spacing: 4) {
        Text(post.authorName)
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        Text(post.authorHandle)
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(post.timestamp, style: .date)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }

      Spacer()

      // Follow button (if not own post)
      Button {
        // Handle follow action
      } label: {
        Text("Follow")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.blue)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(.blue.opacity(0.1), in: Capsule())
          .overlay {
            Capsule()
              .stroke(.blue, lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private func postContentSection(_ post: PostDetailData) -> some View {
    Text(post.content)
      .font(.body)
      .foregroundStyle(.primary)
      .lineLimit(nil)
      .multilineTextAlignment(.leading)
      .textSelection(.enabled)
  }

  @ViewBuilder
  private func postMediaGallery(_ mediaItems: [MediaDetailData]) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(mediaItems) { mediaItem in
          Button {
            // Show media detail
            let detailItem = DetailItem(media: mediaItem)
            detailManager.pushDetail(detailItem)
          } label: {
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
            .frame(width: 200, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 4)
    }
  }

  @ViewBuilder
  private func postEngagementMetrics(_ post: PostDetailData) -> some View {
    HStack(spacing: 24) {
      EngagementMetric(
        icon: "heart.fill",
        count: post.likesCount,
        color: .red,
        label: "likes"
      )

      EngagementMetric(
        icon: "arrow.2.squarepath",
        count: post.repostsCount,
        color: .green,
        label: "reposts"
      )

      EngagementMetric(
        icon: "bubble.left.fill",
        count: post.repliesCount,
        color: .blue,
        label: "replies"
      )

      Spacer()
    }
    .padding(.vertical, 8)
  }

  @ViewBuilder
  private func postInteractionButtons(_ post: PostDetailData) -> some View {
    HStack(spacing: 32) {
      // Reply button
      PostInteractionButton(
        systemImage: "bubble.left",
        isActive: false,
        color: .blue,
        size: .large
      ) {
        showingReplyComposer = true
      }

      // Repost button
      PostInteractionButton(
        systemImage: "arrow.2.squarepath",
        isActive: post.isReposted,
        color: .green,
        size: .large
      ) {
        // Handle repost
      }

      // Like button
      PostInteractionButton(
        systemImage: post.isLiked ? "heart.fill" : "heart",
        isActive: post.isLiked,
        color: .red,
        size: .large
      ) {
        // Handle like
      }

      Spacer()

      // Share button
      Button {
        // Handle share
      } label: {
        Image(systemName: "square.and.arrow.up")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Reply Composer

  @ViewBuilder
  private var replyComposerView: some View {
    if showingReplyComposer {
      GestureAwareGlassCard(
        cornerRadius: 16,
        isInteractive: true
      ) {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Reply")
              .font(.headline.weight(.semibold))
              .foregroundStyle(.primary)

            Spacer()

            Button("Cancel") {
              withAnimation(.smooth(duration: 0.3)) {
                showingReplyComposer = false
                replyText = ""
              }
            }
            .foregroundStyle(.secondary)
          }

          TextField("Write a reply...", text: $replyText, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.body)
            .lineLimit(3...6)
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

          HStack {
            Spacer()

            Button("Post Reply") {
              // Handle post reply
              withAnimation(.smooth(duration: 0.3)) {
                showingReplyComposer = false
                replyText = ""
              }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.blue, in: Capsule())
            .disabled(replyText.isEmpty)
          }
        }
        .padding(16)
      }
      .transition(.move(edge: .top).combined(with: .opacity))
    }
  }

  // MARK: - Replies Thread

  @ViewBuilder
  private var repliesThreadView: some View {
    if !detailManager.postDetailState.replies.isEmpty {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Replies")
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)

          Spacer()

          Text("\(detailManager.postDetailState.replies.count)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)

        LazyVStack(spacing: 8) {
          ForEach(detailManager.postDetailState.replies) { reply in
            ReplyRowView(reply: reply)
              .id("reply-\(reply.id)")
          }
        }
      }
    }
  }

  // MARK: - Loading and Error States

  @ViewBuilder
  private var postLoadingView: some View {
    if #available(iOS 26.0, *) {
      VStack(spacing: 20) {
        ProgressView()
          .scaleEffect(1.5)

        Text("Loading post...")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    } else {
      // Fallback on earlier versions
    }

    if #available(iOS 26.0, *) {
      VStack(spacing: 20) {
        ProgressView()
          .scaleEffect(1.5)

        Text("Loading post...")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    } else {
      // Fallback on earlier versions
    }

    if #available(iOS 26.0, *) {
      VStack(spacing: 20) {
        ProgressView()
          .scaleEffect(1.5)

        Text("Loading post...")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    } else {
      // Fallback on earlier versions
    }

    if #available(iOS 26.0, *) {
      VStack(spacing: 20) {
        ProgressView()
          .scaleEffect(1.5)

        Text("Loading post...")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    } else {
      // Fallback on earlier versions
    }
  }

  @ViewBuilder
  private var postNotFoundView: some View {
    ContentUnavailableView(
      "Post not found",
      systemImage: "doc.text",
      description: Text("This post may have been deleted or is no longer available")
    )
  }

  // MARK: - Toolbar

  @ViewBuilder
  private var postToolbarButtons: some View {
    Button {
      // Handle bookmark
    } label: {
      Image(systemName: "bookmark")
        .font(.subheadline)
    }

    Button {
      // Handle more options
    } label: {
      Image(systemName: "ellipsis.circle")
        .font(.subheadline)
    }
  }
}

// MARK: - Reply Row View

@available(iOS 18.0, *)
struct ReplyRowView: View {
  let reply: PostDetailData
  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0

  private let rowId = UUID().uuidString

  var body: some View {
    GestureAwareGlassCard(
      cornerRadius: 12,
      isInteractive: true
    ) {
      VStack(alignment: .leading, spacing: 12) {
        // Reply header
        HStack(spacing: 12) {
          // Avatar
          AsyncImage(url: reply.authorAvatar) { image in
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
          .frame(width: 32, height: 32)
          .clipShape(Circle())

          // Author info
          VStack(alignment: .leading, spacing: 2) {
            Text(reply.authorName)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.primary)

            Text(reply.authorHandle)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Text(reply.timestamp, style: .relative)
            .font(.caption)
            .foregroundStyle(.tertiary)
        }

        // Reply content
        Text(reply.content)
          .font(.body)
          .foregroundStyle(.primary)
          .lineLimit(nil)

        // Reply interactions
        HStack(spacing: 20) {
          PostInteractionButton(
            systemImage: "bubble.left",
            isActive: false,
            color: .blue,
            size: .small
          ) {
            // Handle reply to reply
          }

          PostInteractionButton(
            systemImage: reply.isLiked ? "heart.fill" : "heart",
            isActive: reply.isLiked,
            color: .red,
            size: .small
          ) {
            // Handle like reply
          }

          if reply.likesCount > 0 {
            Text("\(reply.likesCount)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()
        }
      }
      .padding(12)
    }
    .scaleEffect(scaleEffect)
    .brightness(hoverIntensity * 0.05)
    .applePencilHover(id: rowId) { hovering, location, intensity in
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
      replyContextMenu
    }
  }

  @ViewBuilder
  private var replyContextMenu: some View {
    Button("Reply") {
      // Handle reply
    }

    Button("Copy Text") {
      // Handle copy
    }

    Divider()

    Button("Mute User") {
      // Handle mute
    }

    Button("Report", role: .destructive) {
      // Handle report
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

// MARK: - Engagement Metric

@available(iOS 18.0, *)
struct EngagementMetric: View {
  let icon: String
  let count: Int
  let color: Color
  let label: String

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: icon)
        .font(.subheadline)
        .foregroundStyle(color)

      VStack(alignment: .leading, spacing: 2) {
        Text("\(count)")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)

        Text(label)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }
}

// MARK: - Interaction Button

@available(iOS 18.0, *)
struct PostInteractionButton: View {
  let systemImage: String
  let isActive: Bool
  let color: Color
  let size: ButtonSize
  let action: () -> Void

  enum ButtonSize {
    case small, large

    var iconSize: Font {
      switch self {
      case .small: return .subheadline
      case .large: return .title3
      }
    }

    var padding: CGFloat {
      switch self {
      case .small: return 8
      case .large: return 12
      }
    }
  }

  var body: some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .font(size.iconSize)
        .foregroundStyle(isActive ? color : .secondary)
        .padding(size.padding)
        .background(
          Circle()
            .fill(isActive ? color.opacity(0.1) : .clear)
        )
    }
    .buttonStyle(.plain)
    .scaleEffect(isActive ? 1.1 : 1.0)
    .animation(.smooth(duration: 0.2), value: isActive)
  }
}
