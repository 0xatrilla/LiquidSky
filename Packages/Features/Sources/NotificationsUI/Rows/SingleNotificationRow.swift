import ATProtoKit
import AppRouter
import Client
import Destinations
import Models
import PostUI
import SwiftUI

public struct SingleNotificationRow: View {
  let notification: AppBskyLexicon.Notification.Notification
  let postItem: PostItem?

  @Namespace private var namespace
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @Environment(PostContextProvider.self) var postDataControllerProvider
  let actionText: String

  public init(
    notification: AppBskyLexicon.Notification.Notification, postItem: PostItem?, actionText: String
  ) {
    self.notification = notification
    self.postItem = postItem
    self.actionText = actionText
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header with avatar, name, action, and timestamp - IceCubesApp style
      HStack(alignment: .top, spacing: 12) {
        // Avatar with clean styling - IceCubesApp style
        AsyncImage(url: notification.author.avatarImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(Color(uiColor: .systemGray5))
            .overlay(
              Image(systemName: "person.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            )
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(
          Circle()
            .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
        .onTapGesture {
          router.navigateTo(.profile(notification.author.profile))
        }

        VStack(alignment: .leading, spacing: 6) {
          // Name and action - IceCubesApp style
          HStack(spacing: 4) {
            Text(notification.author.displayName ?? notification.author.actorHandle)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)

            Text(actionText)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }

          // Handle and timestamp - IceCubesApp style
          HStack(spacing: 8) {
            Text("@\(notification.author.actorHandle)")
              .font(.caption)
              .foregroundStyle(.secondary)

            Text(notification.indexedAt.formatted(.relative(presentation: .named)))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        Spacer()
      }

      // Post content if available - IceCubesApp style
      if let postItem {
        VStack(alignment: .leading, spacing: 8) {
          // Post text content
          if !postItem.content.isEmpty {
            Text(postItem.content)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .lineLimit(3)
              .padding(12)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color(uiColor: .systemGray6))
              )
          }

          // Media content if available - extract from embed
          if let embed = postItem.embed {
            switch embed {
            case .embedImagesView(let images):
              // Display images in a grid
              LazyVGrid(
                columns: [
                  GridItem(.flexible()),
                  GridItem(.flexible()),
                  GridItem(.flexible()),
                ], spacing: 4
              ) {
                ForEach(Array(images.images.prefix(3).enumerated()), id: \.offset) { index, image in
                  AsyncImage(url: image.thumbnailImageURL ?? image.fullSizeImageURL) { phase in
                    switch phase {
                    case .success(let img):
                      img
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                      RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .systemGray5))
                        .overlay(
                          Image(systemName: "photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        )
                    @unknown default:
                      EmptyView()
                    }
                  }
                  .frame(height: 80)
                  .clipShape(RoundedRectangle(cornerRadius: 4))
                }
              }
              .frame(height: 80)

            case .embedVideoView(let video):
              // Display video thumbnail
              AsyncImage(url: URL(string: video.thumbnailImageURL ?? "")) { phase in
                switch phase {
                case .success(let img):
                  img
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                  RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .overlay(
                      VStack(spacing: 4) {
                        Image(systemName: "video")
                          .font(.caption)
                        Text("Video")
                          .font(.caption2)
                      }
                      .foregroundStyle(.secondary)
                    )
                @unknown default:
                  EmptyView()
                }
              }
              .frame(height: 80)
              .clipShape(RoundedRectangle(cornerRadius: 4))
              .overlay(
                Image(systemName: "play.circle.fill")
                  .font(.title2)
                  .foregroundStyle(.white)
                  .background(Circle().fill(.black.opacity(0.7)))
              )

            default:
              EmptyView()
            }
          }
        }
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(uiColor: .systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
    )
    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    .onTapGesture {
      if let postItem {
        router.navigateTo(.post(postItem))
      }
    }
  }
}
