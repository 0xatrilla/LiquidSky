import ATProtoKit
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
    #if DEBUG
      let _ = debugLog()
    #endif

    if !isQuote {
      if let embed = post.embed {
        switch embed {
        case .images(let imagesEmbed):
          PostRowImagesView(images: imagesEmbed)
        case .videos(let videoEmbed):
          PostRowVideosView(videos: videoEmbed)
        case .external(let externalEmbed):
          PostRowEmbedExternalView(externalView: externalEmbed)
        case .quotedPost(let recordEmbed):
          QuotedPostContentView(postView: recordEmbed)
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

  #if DEBUG
    private func debugLog() {
      if let embed = post.embed {
        print("PostRowEmbedView: Found embed data for post \(post.uri)")
        print("PostRowEmbedView: Embed type: \(embed)")
      } else {
        print("PostRowEmbedView: No embed data for post \(post.uri)")
      }
    }
  #endif
}

// MARK: - Quoted Post Content View
struct QuotedPostContentView: View {
  let postView: AppBskyLexicon.Embed.RecordDefinition.View

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

      // Simple quoted post content area
      VStack(alignment: .leading, spacing: 8) {
        // Placeholder content - will be improved later
        Text("Quoted post content")
          .font(.body)
          .foregroundColor(.primary)
          .lineLimit(2)
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
  }
}
