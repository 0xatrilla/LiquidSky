import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI

extension EnvironmentValues {
  @Entry public var hideMoreActions = false
}

public struct PostRowActionsView: View {
  @Environment(\.hideMoreActions) var hideMoreActions
  @Environment(PostContext.self) var dataController
  @Environment(AppRouter.self) var router
  @Environment(PostFilterService.self) var postFilterService

  let post: PostItem

  public init(post: PostItem) {
    self.post = post
  }

  public var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 16) {
      // Reply Button
      if postFilterService.canReplyToPost(post) {
        Button(action: {
          router.presentedSheet = .composer(mode: .reply(post))
        }) {
          Label("\(post.replyCount)", systemImage: "bubble")
        }
        .buttonStyle(.plain)
        .foregroundColor(.themePrimary)
      }

      // Repost Button
      if postFilterService.canQuotePost(post) {
        Button(action: {
          Task {
            await dataController.toggleRepost()
          }
        }) {
          Label("\(dataController.repostCount)", systemImage: "quote.bubble")
            .contentTransition(.numericText(value: Double(dataController.repostCount)))
            .monospacedDigit()
            .lineLimit(1)
            .animation(.smooth, value: dataController.repostCount)
        }
        .buttonStyle(.plain)
        .symbolVariant(dataController.isReposted ? .fill : .none)
        .foregroundColor(.themeSecondary)
      }

      // Like Button
      Button(action: {
        Task {
          await dataController.toggleLike()
        }
      }) {
        Label("\(dataController.likeCount)", systemImage: "heart")
          .lineLimit(1)
      }
      .buttonStyle(.plain)
      .symbolVariant(dataController.isLiked ? .fill : .none)
      .symbolEffect(.bounce, value: dataController.isLiked)
      .contentTransition(.numericText(value: Double(dataController.likeCount)))
      .monospacedDigit()
      .animation(.smooth, value: dataController.likeCount)
      .foregroundColor(.themeAccent)

      Spacer()

      if !hideMoreActions {
        Menu {
          // Share post
          Button(action: {
            sharePost()
          }) {
            Label("Share Post", systemImage: "square.and.arrow.up")
          }

          // Copy post text
          Button(action: {
            copyPostText()
          }) {
            Label("Copy Text", systemImage: "doc.on.doc")
          }

          // Copy post link
          Button(action: {
            copyPostLink()
          }) {
            Label("Copy Link", systemImage: "link")
          }

          // Bookmark post (placeholder for future implementation)
          Button(action: {
            bookmarkPost()
          }) {
            Label("Bookmark", systemImage: "bookmark")
          }

          Divider()

          // Translate post (placeholder for future implementation)
          Button(action: {
            translatePost()
          }) {
            Label("Translate", systemImage: "character.bubble")
          }

          // Report post
          Button(action: {
            reportPost()
          }) {
            Label("Report Post", systemImage: "exclamationmark.triangle")
          }

          // Block user
          Button(action: {
            blockUser()
          }) {
            Label("Block @\(post.author.handle)", systemImage: "person.slash")
          }

          // Mute user
          Button(action: {
            muteUser()
          }) {
            Label("Mute @\(post.author.handle)", systemImage: "speaker.slash")
          }

          Divider()

          // View profile
          Button(action: {
            viewProfile()
          }) {
            Label("View Profile", systemImage: "person.circle")
          }

          // View in thread
          if post.isReplyTo || post.hasReply {
            Button(action: {
              viewInThread()
            }) {
              Label("View Thread", systemImage: "bubble.left.and.bubble.right")
            }
          }

          // Conditional actions based on post state
          if dataController.isLiked {
            Button(action: {
              Task {
                await dataController.toggleLike()
              }
            }) {
              Label("Unlike", systemImage: "heart.slash")
            }
          }

          if dataController.isReposted {
            Button(action: {
              Task {
                await dataController.toggleRepost()
              }
            }) {
              Label("Remove Repost", systemImage: "arrow.2.squarepath.slash")
            }
          }
        } label: {
          Image(systemName: "ellipsis")
        }
        .buttonStyle(.plain)
        .foregroundColor(.themePrimary)
      }
    }
    .buttonStyle(.plain)
    .labelStyle(.customSpacing(4))
    .font(.callout)
    .padding(.top, 8)
    .padding(.bottom, 16)
  }

  // MARK: - Action Methods

  private func sharePost() {
    let postText = post.content
    let postLink =
      "https://bsky.app/profile/\(post.author.handle)/post/\(post.uri.components(separatedBy: "/").last ?? "")"

    let activityVC = UIActivityViewController(
      activityItems: [postText, postLink],
      applicationActivities: nil
    )

    // Present the share sheet
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first
    {
      window.rootViewController?.present(activityVC, animated: true)
    }
  }

  private func copyPostText() {
    UIPasteboard.general.string = post.content
    showToast(message: "Text copied to clipboard")
  }

  private func copyPostLink() {
    let postLink =
      "https://bsky.app/profile/\(post.author.handle)/post/\(post.uri.components(separatedBy: "/").last ?? "")"
    UIPasteboard.general.string = postLink
    showToast(message: "Link copied to clipboard")
  }

  private func bookmarkPost() {
    // Placeholder for future bookmark implementation
    // This could save posts to a local database or sync with Bluesky bookmarks
    showToast(message: "Post bookmarked")
  }

  private func translatePost() {
    // Placeholder for future translation implementation
    // This could integrate with a translation service like Google Translate
    showToast(message: "Translation feature coming soon")
  }

  private func reportPost() {
    // Placeholder for future report implementation
    print("Report post: \(post.uri)")
  }

  private func blockUser() {
    // Placeholder for future block implementation
    print("Block user: \(post.author.handle)")
  }

  private func muteUser() {
    // Placeholder for future mute implementation
    print("Mute user: \(post.author.handle)")
  }

  private func viewProfile() {
    router.navigateTo(.profile(post.author))
  }

  private func viewInThread() {
    router.navigateTo(.post(post))
  }

  private func showToast(message: String) {
    // Simple toast notification using UIKit
    let toastLabel = UILabel()
    toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    toastLabel.textColor = UIColor.white
    toastLabel.textAlignment = .center
    toastLabel.font = UIFont.systemFont(ofSize: 14)
    toastLabel.text = message
    toastLabel.alpha = 1.0
    toastLabel.layer.cornerRadius = 10
    toastLabel.clipsToBounds = true

    // Get the window to present the toast
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first
    {
      let windowSize = window.frame.size
      let toastSize = CGSize(width: 200, height: 35)
      let toastX = (windowSize.width - toastSize.width) / 2
      let toastY = windowSize.height - 100

      toastLabel.frame = CGRect(
        x: toastX, y: toastY, width: toastSize.width, height: toastSize.height)
      window.addSubview(toastLabel)

      // Animate the toast
      UIView.animate(
        withDuration: 2.0, delay: 0.1, options: .curveEaseOut,
        animations: {
          toastLabel.alpha = 0.0
        },
        completion: { _ in
          toastLabel.removeFromSuperview()
        })
    }
  }
}
