import ATProtoKit
import AppRouter
import DesignSystem
import Destinations
import Models
import PostUI
import SwiftUI

public struct GroupedNotificationRow: View {
  let group: NotificationsGroup

  @Namespace private var namespace
  @Environment(AppRouter.self) var router
  let actionText: (Int) -> String  // Closure to generate action text based on count

  public init(group: NotificationsGroup, actionText: @escaping (Int) -> String) {
    self.group = group
    self.actionText = actionText
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header with avatars, action text, and timestamp
      HStack(alignment: .top, spacing: 12) {
        // Avatar stack with enhanced glass styling
        ZStack(alignment: .bottomTrailing) {
          avatarsView

          // Notification type icon with glass effect
          NotificationIconView(
            icon: group.type.iconName,
            color: group.type.color
          )
          .background(
            Circle()
              .fill(.ultraThinMaterial)
              .blur(radius: 8)
          )
        }

        VStack(alignment: .leading, spacing: 6) {
          // Action text with improved typography
          Text(actionText(group.notifications.count))
            .font(.subheadline)
            .foregroundStyle(.secondary)

          // Timestamp with better contrast
          if let firstNotification = group.notifications.first {
            Text(firstNotification.indexedAt.formatted(.relative(presentation: .named)))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        Spacer()
      }

      // Post content if available with glass effects
      if let post = group.postItem {
        VStack(alignment: .leading, spacing: 8) {
          // Post text content with glass background and improved text handling
          if !post.content.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
              // Improved text display with better typography
              Text(post.content)
                .font(.system(size: 15, weight: .regular, design: .default))
                .foregroundStyle(.secondary)
                .lineLimit(nil)  // Remove line limit to show full text
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)  // Allow text to expand vertically
                .lineSpacing(2)  // Add line spacing for better readability
                .textSelection(.enabled)  // Allow text selection

              // Add a subtle divider if there's media content below
              if post.embed != nil {
                Divider()
                  .background(.white.opacity(0.1))
              }
            }
            .padding(16)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)  // Add subtle shadow for depth
          }

          // Media content if available - extract from embed
          if let embed = post.embed {
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
          // Header with avatars, action text, and timestamp
          HStack(alignment: .top, spacing: 12) {
            // Avatar stack with enhanced glass styling
            ZStack(alignment: .bottomTrailing) {
              avatarsView

              // Notification type icon with glass effect
              NotificationIconView(
                icon: group.type.iconName,
                color: group.type.color
              )
              .background(
                Circle()
                  .fill(.ultraThinMaterial)
                  .blur(radius: 8)
              )
            }

            VStack(alignment: .leading, spacing: 6) {
              // Action text with improved typography
              Text(actionText(group.notifications.count))
                .font(.subheadline)
                .foregroundStyle(.secondary)

              // Timestamp with better contrast
              if let firstNotification = group.notifications.first {
                Text(firstNotification.indexedAt.formatted(.relative(presentation: .named)))
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }

            Spacer()
          }

          // Post content if available with glass effects
          if let post = group.postItem {
            VStack(alignment: .leading, spacing: 8) {
              // Post text content with glass background and improved text handling
              if !post.content.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                  // Improved text display with better typography
                  Text(post.content)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)  // Remove line limit to show full text
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)  // Allow text to expand vertically
                    .lineSpacing(2)  // Add line spacing for better readability
                    .textSelection(.enabled)  // Allow text selection

                  // Add a subtle divider if there's media content below
                  if post.embed != nil {
                    Divider()
                      .background(.white.opacity(0.1))
                  }
                }
                .padding(16)
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                      RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)  // Add subtle shadow for depth
              }

              // Media content if available - extract from embed
              if let embed = post.embed {
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
      if let post = group.postItem {
        router.navigateTo(.post(post))
      }
    }
  }

  @ViewBuilder
  private var avatarsView: some View {
    let maxAvatars = 3
    let avatarCount = min(group.notifications.count, maxAvatars)

    HStack(spacing: -8) {
      ForEach(Array(group.notifications.prefix(avatarCount).enumerated()), id: \.offset) {
        index, notification in
        AsyncImage(url: notification.author.avatarImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(.ultraThinMaterial)
            .overlay(
              Image(systemName: "person.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            )
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
        .overlay(
          Circle()
            .stroke(.ultraThinMaterial, lineWidth: 2)
        )
        .background(
          Circle()
            .fill(.ultraThinMaterial)
            .blur(radius: 6)
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
      }
    }
  }

  @ViewBuilder
  private var postView: some View {
    if let post = group.postItem {
      VStack(alignment: .leading, spacing: 8) {
        // Post text content
        if !post.content.isEmpty {
          Text(post.content)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .padding(12)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
            )
        }

        // Media content if available - extract from embed
        if let embed = post.embed {
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
}
