import ATProtoKit
import DesignSystem
import Models
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
      // Simple quoted post indicator
      HStack {
        Image(systemName: "quote.bubble")
          .font(.caption)
          .foregroundColor(.secondary)
        Text("Quoted post")
          .font(.caption)
          .foregroundColor(.secondary)
        Spacer()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.gray.opacity(0.1))
      .cornerRadius(8)
      .padding(.horizontal, 12)
    }
  }
}
