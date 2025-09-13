import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
extension View {
  /// Adds detail navigation capability to content views
  func withDetailNavigation() -> some View {
    self.modifier(DetailNavigationModifier())
  }
}

@available(iPadOS 26.0, *)
struct DetailNavigationModifier: ViewModifier {
  @Environment(\.detailColumnManager) var detailManager

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: .showPostDetail)) { notification in
        if let userInfo = notification.userInfo,
          let postId = userInfo["postId"] as? String,
          let title = userInfo["title"] as? String
        {
          detailManager.showPostDetail(postId: postId, title: title)
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .showProfileDetail)) { notification in
        if let userInfo = notification.userInfo,
          let profileId = userInfo["profileId"] as? String,
          let title = userInfo["title"] as? String
        {
          detailManager.showProfileDetail(profileId: profileId, title: title)
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .showMediaDetail)) { notification in
        if let userInfo = notification.userInfo,
          let mediaId = userInfo["mediaId"] as? String,
          let title = userInfo["title"] as? String
        {
          detailManager.showMediaDetail(mediaId: mediaId, title: title)
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .showThreadDetail)) { notification in
        if let userInfo = notification.userInfo,
          let threadId = userInfo["threadId"] as? String,
          let title = userInfo["title"] as? String
        {
          detailManager.showThreadDetail(threadId: threadId, title: title)
        }
      }
  }
}

// MARK: - Detail Navigation Helpers

@available(iPadOS 26.0, *)
struct DetailNavigationHelper {
  static func showPostDetail(postId: String, title: String = "Post") {
    NotificationCenter.default.post(
      name: .showPostDetail,
      object: nil,
      userInfo: ["postId": postId, "title": title]
    )
  }

  static func showProfileDetail(profileId: String, title: String = "Profile") {
    NotificationCenter.default.post(
      name: .showProfileDetail,
      object: nil,
      userInfo: ["profileId": profileId, "title": title]
    )
  }

  static func showMediaDetail(mediaId: String, title: String = "Media") {
    NotificationCenter.default.post(
      name: .showMediaDetail,
      object: nil,
      userInfo: ["mediaId": mediaId, "title": title]
    )
  }

  static func showThreadDetail(threadId: String, title: String = "Thread") {
    NotificationCenter.default.post(
      name: .showThreadDetail,
      object: nil,
      userInfo: ["threadId": threadId, "title": title]
    )
  }
}

// MARK: - Enhanced Detail Column Manager Extensions

// MARK: - Content View Integration Extensions

@available(iPadOS 26.0, *)
extension EnhancedFeedCard {
  /// Adds tap gesture to show post detail
  func withPostDetailNavigation() -> some View {
    self.onTapGesture {
      DetailNavigationHelper.showPostDetail(postId: item.id, title: "Post by \(item.authorName)")
    }
  }
}

@available(iPadOS 26.0, *)
extension EnhancedNotificationRow {
  /// Adds tap gesture to show appropriate detail based on notification type
  func withNotificationDetailNavigation() -> some View {
    self.onTapGesture {
      switch notification.type {
      case .like, .repost, .reply:
        if let postContent = notification.postContent {
          DetailNavigationHelper.showPostDetail(
            postId: "post-from-notification-\(notification.id)",
            title: "Post"
          )
        }
      case .follow, .mention:
        DetailNavigationHelper.showProfileDetail(
          profileId: notification.id,
          title: notification.actorName
        )
      }
    }
  }
}

@available(iPadOS 26.0, *)
extension SearchResultCard {
  /// Adds tap gesture to show appropriate detail based on result type
  func withSearchResultDetailNavigation() -> some View {
    self.onTapGesture {
      switch result.type {
      case .post:
        DetailNavigationHelper.showPostDetail(postId: result.id, title: result.title)
      case .user:
        DetailNavigationHelper.showProfileDetail(profileId: result.id, title: result.authorName)
      }
    }
  }
}

// MARK: - Picture-in-Picture Support

@available(iPadOS 26.0, *)
@Observable
class PictureInPictureManager {
  var isActive = false
  var currentMediaItem: MediaDetailData?
  var pipFrame: CGRect = CGRect(x: 20, y: 100, width: 200, height: 150)
  var isDragging = false

  func startPictureInPicture(mediaItem: MediaDetailData) {
    withAnimation(.smooth(duration: 0.3)) {
      currentMediaItem = mediaItem
      isActive = true
    }
  }

  func stopPictureInPicture() {
    withAnimation(.smooth(duration: 0.3)) {
      isActive = false
      currentMediaItem = nil
    }
  }

  func updatePipFrame(_ frame: CGRect) {
    pipFrame = frame
  }
}

@available(iPadOS 26.0, *)
struct PictureInPictureView: View {
  @Environment(\.pictureInPictureManager) var pipManager
  @Environment(\.detailColumnManager) var detailManager
  @State private var dragOffset: CGSize = .zero

  var body: some View {
    if pipManager.isActive, let mediaItem = pipManager.currentMediaItem {
      VStack {
        Spacer()

        HStack {
          Spacer()

          // PiP window
          VStack(spacing: 0) {
            // Media content
            AsyncImage(url: URL(string: mediaItem.url)) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              Rectangle()
                .fill(.quaternary)
                .overlay {
                  ProgressView()
                    .scaleEffect(0.8)
                }
            }
            .frame(width: 200, height: 150)
            .clipShape(
              UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 12
              )
            )

            // Controls
            HStack {
              Button {
                // Expand to full detail
                detailManager.showMediaDetail(mediaId: mediaItem.id, title: "Media")
                pipManager.stopPictureInPicture()
              } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                  .font(.caption)
                  .foregroundStyle(.white)
              }
              .buttonStyle(.plain)

              Spacer()

              Button {
                pipManager.stopPictureInPicture()
              } label: {
                Image(systemName: "xmark")
                  .font(.caption)
                  .foregroundStyle(.white)
              }
              .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.black.opacity(0.8))
            .clipShape(
              UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 12,
                topTrailingRadius: 0
              )
            )
          }
          .offset(dragOffset)
          .gesture(
            DragGesture()
              .onChanged { value in
                dragOffset = value.translation
              }
              .onEnded { value in
                // Snap to edges
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height

                let currentX = dragOffset.width
                let currentY = dragOffset.height
                let targetX = currentX > screenWidth / 2 ? screenWidth - 220 : 20
                let targetY = max(100, min(currentY, screenHeight - 200))

                withAnimation(.smooth(duration: 0.3)) {
                  dragOffset = CGSize(width: targetX, height: targetY)
                }
              }
          )
          .onTapGesture {
            // Expand to full detail
            detailManager.showMediaDetail(mediaId: mediaItem.id, title: "Media")
            pipManager.stopPictureInPicture()
          }

          Spacer()
        }

        Spacer()
      }
    } else {
      EmptyView()
    }
  }
}

// MARK: - Environment Keys

@available(iPadOS 26.0, *)
struct PictureInPictureManagerKey: EnvironmentKey {
  static let defaultValue = PictureInPictureManager()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var pictureInPictureManager: PictureInPictureManager {
    get { self[PictureInPictureManagerKey.self] }
    set { self[PictureInPictureManagerKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let showPostDetail = Notification.Name("showPostDetail")
  static let showProfileDetail = Notification.Name("showProfileDetail")
  static let showMediaDetail = Notification.Name("showMediaDetail")
  static let showThreadDetail = Notification.Name("showThreadDetail")
}
