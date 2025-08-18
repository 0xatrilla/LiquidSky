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
        Button(action: {}) {
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
}
