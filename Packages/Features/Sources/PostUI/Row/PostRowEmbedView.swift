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

      // Quoted post content area - extract actual content using reflection
      VStack(alignment: .leading, spacing: 8) {
        // Use reflection to extract the quoted post data
        let quotedPostData = extractQuotedPostData(from: postView)

        if let author = quotedPostData.author {
          HStack(spacing: 8) {
            if let avatarURL = quotedPostData.avatarURL {
              AsyncImage(url: avatarURL) { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
              } placeholder: {
                Image(systemName: "person.circle.fill")
                  .foregroundColor(.secondary)
              }
              .frame(width: 24, height: 24)
              .clipShape(Circle())
            } else {
              Image(systemName: "person.circle.fill")
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
              Text(author.displayName ?? author.handle)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

              Text("@\(author.handle)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()
          }
        }

        if let content = quotedPostData.content, !content.isEmpty {
          Text(content)
            .font(.caption)
            .foregroundStyle(.primary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
        } else {
          HStack(spacing: 8) {
            Image(systemName: "doc.text")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("Quoted post content")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
        }
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

  // Helper function to extract quoted post data using reflection
  private func extractQuotedPostData(from postView: AppBskyLexicon.Embed.RecordDefinition.View) -> (
    author: Profile?, content: String?, avatarURL: URL?
  ) {
    let mirror = Mirror(reflecting: postView)

    var author: Profile? = nil
    var content: String? = nil
    var avatarURL: URL? = nil

    // Look for author and content information in the View structure
    for child in mirror.children {
      if let label = child.label {
        switch label {
        case "author":
          // Try to extract author information
          if let authorData = extractAuthor(from: child.value) {
            author = authorData
          }
        case "record":
          // Try to extract content from the record
          if let recordContent = extractContent(from: child.value) {
            content = recordContent
          }
        case "avatarImageURL":
          // Try to extract avatar URL
          if let urlString = child.value as? String, let url = URL(string: urlString) {
            avatarURL = url
          }
        default:
          break
        }
      }
    }

    // If we didn't find author in the expected location, try to find it elsewhere
    if author == nil {
      for child in mirror.children {
        if let authorData = extractAuthor(from: child.value) {
          author = authorData
          break
        }
      }
    }

    // If we didn't find content in the expected location, try to find it elsewhere
    if content == nil {
      for child in mirror.children {
        if let recordContent = extractContent(from: child.value) {
          content = recordContent
          break
        }
      }
    }

    return (author: author, content: content, avatarURL: avatarURL)
  }

  // Helper function to extract author information
  private func extractAuthor(from value: Any) -> Profile? {
    let mirror = Mirror(reflecting: value)

    var did: String? = nil
    var handle: String? = nil
    var displayName: String? = nil
    var avatarURL: URL? = nil

    for child in mirror.children {
      if let label = child.label {
        switch label {
        case "did", "actorDID":
          if let didString = child.value as? String {
            did = didString
          }
        case "handle", "actorHandle":
          if let handleString = child.value as? String {
            handle = handleString
          }
        case "displayName":
          if let displayNameString = child.value as? String {
            displayName = displayNameString
          }
        case "avatarImageURL":
          if let urlString = child.value as? String, let url = URL(string: urlString) {
            avatarURL = url
          }
        default:
          break
        }
      }
    }

    // If we found the essential author information, create a Profile
    if let did = did, let handle = handle {
      return Profile(
        did: did,
        handle: handle,
        displayName: displayName,
        avatarImageURL: avatarURL
      )
    }

    return nil
  }

  // Helper function to extract content from record
  private func extractContent(from value: Any) -> String? {
    let mirror = Mirror(reflecting: value)

    // Look for text content in the record
    for child in mirror.children {
      if let label = child.label {
        switch label {
        case "text":
          if let text = child.value as? String {
            return text
          }
        case "value":
          // The value might contain the actual record data
          if let recordContent = extractContent(from: child.value) {
            return recordContent
          }
        default:
          break
        }
      }
    }

    // Try to use getRecord if available
    if let record = value as? AppBskyLexicon.Feed.PostRecord {
      return record.text
    }

    return nil
  }
}
