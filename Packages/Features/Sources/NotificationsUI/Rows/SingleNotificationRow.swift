import ATProtoKit
import AppRouter
import Client
import DesignSystem
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
      // Header with avatar, name, action, and timestamp
      HStack(alignment: .top, spacing: 12) {
        // Avatar with enhanced glass styling
        AsyncImage(url: notification.author.avatarImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(.ultraThinMaterial)
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
            .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .background(
          Circle()
            .fill(.ultraThinMaterial)
            .blur(radius: 10)
        )
        .onTapGesture {
          let profile = Profile(
            did: notification.author.actorDID,
            handle: notification.author.actorHandle,
            displayName: notification.author.displayName,
            avatarImageURL: notification.author.avatarImageURL
          )
          router.navigateTo(.profile(profile))
        }

        VStack(alignment: .leading, spacing: 6) {
          // Name and action with improved typography
          HStack(spacing: 4) {
            Text(notification.author.displayName ?? notification.author.actorHandle)
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)

            Text(actionText)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }

          // Handle and timestamp with better contrast
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

      // Post content if available with glass effects
      if let postItem {
        VStack(alignment: .leading, spacing: 8) {
          // Post text content with glass background
          if !postItem.content.isEmpty {
            Text(postItem.content)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .lineLimit(3)
              .padding(16)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(.ultraThinMaterial)
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(.white.opacity(0.1), lineWidth: 0.5)
                  )
              )
          }

          // Media content if available - extract from embed
          if let embed = postItem.embed {
            switch embed {
            case .embedImagesView(let images):
              // Display images in a grid with glass effects
              LazyVGrid(
                columns: [
                  GridItem(.flexible()),
                  GridItem(.flexible()),
                  GridItem(.flexible()),
                ], spacing: 6
              ) {
                ForEach(Array(images.images.prefix(3).enumerated()), id: \.offset) { index, image in
                  AsyncImage(url: image.thumbnailImageURL ?? image.fullSizeImageURL) { phase in
                    switch phase {
                    case .success(let img):
                      img
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                      RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
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
                  .clipShape(RoundedRectangle(cornerRadius: 8))
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(.white.opacity(0.1), lineWidth: 0.5)
                  )
                }
              }
              .frame(height: 80)

            case .embedVideoView(let video):
              // Display video thumbnail with glass effects
              AsyncImage(url: URL(string: video.thumbnailImageURL ?? "")) { phase in
                switch phase {
                case .success(let img):
                  img
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                  RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
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
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(.white.opacity(0.1), lineWidth: 0.5)
              )
              .overlay(
                Image(systemName: "play.circle.fill")
                  .font(.title2)
                  .foregroundStyle(.white)
                  .background(
                    Circle()
                      .fill(.black.opacity(0.7))
                      .blur(radius: 2)
                  )
              )

            default:
              EmptyView()
            }
          }
        }
      }
    }
    .padding(20)
    .background(
      NotificationGlassCard(
        backgroundColor: .white.opacity(0.05),
        borderColor: .white.opacity(0.15),
        shadowColor: .black.opacity(0.06),
        shadowRadius: 16,
        shadowOffset: CGSize(width: 0, height: 6)
      ) {
        VStack(alignment: .leading, spacing: 16) {
          // Header with avatar, name, action, and timestamp
          HStack(alignment: .top, spacing: 12) {
            // Avatar with enhanced glass styling
            AsyncImage(url: notification.author.avatarImageURL) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              Circle()
                .fill(.ultraThinMaterial)
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
                .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .background(
              Circle()
                .fill(.ultraThinMaterial)
                .blur(radius: 10)
            )
            .onTapGesture {
              let profile = Profile(
                did: notification.author.actorDID,
                handle: notification.author.actorHandle,
                displayName: notification.author.displayName,
                avatarImageURL: notification.author.avatarImageURL
              )
              router.navigateTo(.profile(profile))
            }

            VStack(alignment: .leading, spacing: 6) {
              // Name and action with improved typography
              HStack(spacing: 4) {
                Text(notification.author.displayName ?? notification.author.actorHandle)
                  .font(.subheadline)
                  .fontWeight(.semibold)
                  .foregroundStyle(.primary)

                Text(actionText)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }

              // Handle and timestamp with better contrast
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

          // Post content if available with glass effects
          if let postItem {
            VStack(alignment: .leading, spacing: 8) {
              // Post text content with glass background
              if !postItem.content.isEmpty {
                Text(postItem.content)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
                  .lineLimit(3)
                  .padding(16)
                  .background(
                    RoundedRectangle(cornerRadius: 12)
                      .fill(.ultraThinMaterial)
                      .overlay(
                        RoundedRectangle(cornerRadius: 12)
                          .stroke(.white.opacity(0.1), lineWidth: 0.5)
                      )
                  )
              }

              // Media content if available - extract from embed
              if let embed = postItem.embed {
                switch embed {
                case .embedImagesView(let images):
                  // Display images in a grid with glass effects
                  LazyVGrid(
                    columns: [
                      GridItem(.flexible()),
                      GridItem(.flexible()),
                      GridItem(.flexible()),
                    ], spacing: 6
                  ) {
                    ForEach(Array(images.images.prefix(3).enumerated()), id: \.offset) {
                      index, image in
                      AsyncImage(url: image.thumbnailImageURL ?? image.fullSizeImageURL) { phase in
                        switch phase {
                        case .success(let img):
                          img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                          RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
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
                      .clipShape(RoundedRectangle(cornerRadius: 8))
                      .overlay(
                        RoundedRectangle(cornerRadius: 8)
                          .stroke(.white.opacity(0.1), lineWidth: 0.5)
                      )
                    }
                  }
                  .frame(height: 80)

                case .embedVideoView(let video):
                  // Display video thumbnail with glass effects
                  AsyncImage(url: URL(string: video.thumbnailImageURL ?? "")) { phase in
                    switch phase {
                    case .success(let img):
                      img
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                      RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
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
                  .clipShape(RoundedRectangle(cornerRadius: 8))
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(.white.opacity(0.1), lineWidth: 0.5)
                  )
                  .overlay(
                    Image(systemName: "play.circle.fill")
                      .font(.title2)
                      .foregroundStyle(.white)
                      .background(
                        Circle()
                          .fill(.black.opacity(0.7))
                          .blur(radius: 2)
                      )
                  )

                default:
                  EmptyView()
                }
              }
            }
          }
        }
        .padding(20)
      }
    )
    .onTapGesture {
      if let postItem {
        router.navigateTo(.post(postItem))
      }
    }
  }
}
