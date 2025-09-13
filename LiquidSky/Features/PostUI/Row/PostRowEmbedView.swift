import ATProtoKit
import AppRouter
import DesignSystem
import Models
import NukeUI
import SwiftUI

public struct PostRowEmbedView: View {
  @Environment(\.isQuote) var isQuote

  let post: PostItem

  public init(post: PostItem) {
    self.post = post
  }

  public var body: some View {
    if !isQuote {
      if let embed = post.embed {
        switch embed {
        case .images(let imagesEmbed):
          PostRowImagesView(images: imagesEmbed)
        case .videos(let videoEmbed):
          PostRowVideosView(videos: videoEmbed)
        case .external(let externalEmbed):
          PostRowEmbedExternalView(externalView: externalEmbed)
        case .quotedPost(let quotedPostData):
          QuotedPostContentView(quotedPostData: quotedPostData) {
            // This closure will be handled by the parent view
          }
        case .none:
          EmptyView()
        }
      } else {
        EmptyView()
      }
    } else {
      EmptyView()
    }
  }

}

// MARK: - Quoted Post Content View
struct QuotedPostContentView: View {
  let quotedPostData: QuotedPostData
  let onTap: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Quoted post header
      HStack(spacing: 8) {
        Image(systemName: "quote.bubble")
          .font(.caption)
          .foregroundColor(.secondary)
        Text("Quoted post")
          .font(.caption)
          .foregroundColor(.secondary)
        Spacer()
      }

      // Quoted post content area - now using the extracted data directly
      VStack(alignment: .leading, spacing: 8) {
        // Display author information
        HStack(spacing: 8) {
          if let avatarURL = quotedPostData.author.avatarImageURL {
            AsyncImage(url: avatarURL) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              Image(systemName: "person.circle.fill")
                .foregroundColor(.secondary)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
          } else {
            Image(systemName: "person.circle.fill")
              .foregroundColor(.secondary)
              .frame(width: 32, height: 32)
          }

          VStack(alignment: .leading, spacing: 2) {
            Text(quotedPostData.author.displayName ?? quotedPostData.author.handle)
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(.primary)

            Text("@\(quotedPostData.author.handle)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()
        }

        // Display actual quoted post content
        Text(quotedPostData.content)
          .font(.subheadline)
          .foregroundStyle(.primary)
          .lineLimit(3)
          .multilineTextAlignment(.leading)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    )
    .padding(.horizontal, 12)
    .onTapGesture {
      onTap()
    }
  }
}
