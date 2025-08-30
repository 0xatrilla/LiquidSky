import ATProtoKit
import Foundation

/// Helper class to extract embed data from ATProtoKit post structures
public struct EmbedDataExtractor {

  /// Extract embed data from a FeedViewPostDefinition
  public static func extractEmbed(from postData: Any?) -> EmbedData? {
    guard let postData = postData else { return nil }

    #if DEBUG
      print("EmbedDataExtractor: Starting extraction from type: \(type(of: postData))")
    #endif

    // Try to extract embed from FeedViewPostDefinition
    if let feedPost = postData as? AppBskyLexicon.Feed.FeedViewPostDefinition {
      #if DEBUG
        print("EmbedDataExtractor: Processing FeedViewPostDefinition")
        print("EmbedDataExtractor: FeedPost embed: \(String(describing: feedPost.post.embed))")
      #endif
      // The embed is in the post property
      return convertToEmbedData(feedPost.post.embed)
    }

    // Try to extract embed from PostViewDefinition
    if let postView = postData as? AppBskyLexicon.Feed.PostViewDefinition {
      #if DEBUG
        print("EmbedDataExtractor: Processing PostViewDefinition")
        print("EmbedDataExtractor: PostView embed: \(String(describing: postView.embed))")
      #endif
      // The embed is directly accessible
      return convertToEmbedData(postView.embed)
    }

    // Try to extract embed from ViewRecord
    if let viewRecord = postData as? AppBskyLexicon.Embed.RecordDefinition.ViewRecord {
      #if DEBUG
        print("EmbedDataExtractor: Processing ViewRecord")
        print("EmbedDataExtractor: ViewRecord embeds: \(String(describing: viewRecord.embeds))")
      #endif
      if let firstEmbed = viewRecord.embeds?.first {
        return convertToEmbedData(firstEmbed)
      }
    }

    #if DEBUG
      print("EmbedDataExtractor: No embed data found")
    #endif
    return nil
  }

  /// Convert ATProtoKit embed types to our EmbedData union type
  private static func convertToEmbedData(_ embed: Any?) -> EmbedData? {
    guard let embed = embed else { return nil }
    
    #if DEBUG
    print("EmbedDataExtractor: Converting embed type: \(type(of: embed))")
    #endif
    
    // Try to convert directly to our EmbedData types
    if let imagesEmbed = embed as? AppBskyLexicon.Embed.ImagesDefinition.View {
      #if DEBUG
      print("EmbedDataExtractor: Successfully converted to ImagesDefinition.View")
      #endif
      return .images(imagesEmbed)
    } else if let videoEmbed = embed as? AppBskyLexicon.Embed.VideoDefinition.View {
      #if DEBUG
      print("EmbedDataExtractor: Successfully converted to VideoDefinition.View")
      #endif
      return .videos(videoEmbed)
    } else if let externalEmbed = embed as? AppBskyLexicon.Embed.ExternalDefinition.View {
      #if DEBUG
      print("EmbedDataExtractor: Successfully converted to ExternalDefinition.View")
      #endif
      return .external(externalEmbed)
    } else if let recordEmbed = embed as? AppBskyLexicon.Embed.RecordDefinition.View {
      #if DEBUG
      print("EmbedDataExtractor: Successfully converted to RecordDefinition.View")
      #endif
      return .quotedPost(recordEmbed)
    }
    
    #if DEBUG
    print("EmbedDataExtractor: Failed to convert embed type: \(type(of: embed))")
    #endif
    
    return nil
  }

  /// Check if the embed data contains images
  public static func hasImages(in embedData: Any?) -> Bool {
    guard let embedData = embedData else { return false }

    if let imagesEmbed = embedData as? AppBskyLexicon.Embed.ImagesDefinition.View {
      return !imagesEmbed.images.isEmpty
    }

    return false
  }

  /// Check if the embed data contains videos
  public static func hasVideos(in embedData: Any?) -> Bool {
    guard let embedData = embedData else { return false }

    if let videoEmbed = embedData as? AppBskyLexicon.Embed.VideoDefinition.View {
      // VideoDefinition.View is the video itself, not a collection
      return true
    }

    return false
  }

  /// Check if the embed data contains external links
  public static func hasExternalLink(in embedData: Any?) -> Bool {
    guard let embedData = embedData else { return false }

    if let externalEmbed = embedData as? AppBskyLexicon.Embed.ExternalDefinition.View {
      // external is not optional, so it always exists
      return true
    }

    return false
  }

  /// Check if the embed data contains quoted posts
  public static func hasQuotedPost(in embedData: Any?) -> Bool {
    guard let embedData = embedData else { return false }

    if let recordEmbed = embedData as? AppBskyLexicon.Embed.RecordDefinition.View {
      // record is not optional, so it always exists
      return true
    }

    return false
  }

  /// Get the embed type for display purposes
  public static func getEmbedType(from embedData: Any?) -> EmbedType {
    guard let embedData = embedData else { return .none }

    if hasImages(in: embedData) { return .images }
    if hasVideos(in: embedData) { return .videos }
    if hasExternalLink(in: embedData) { return .external }
    if hasQuotedPost(in: embedData) { return .quotedPost }

    return .none
  }
}

/// Union type for embed data that conforms to Sendable
public enum EmbedData: Sendable {
  case images(AppBskyLexicon.Embed.ImagesDefinition.View)
  case videos(AppBskyLexicon.Embed.VideoDefinition.View)
  case external(AppBskyLexicon.Embed.ExternalDefinition.View)
  case quotedPost(AppBskyLexicon.Embed.RecordDefinition.View)
  case none
}

/// Enum representing different types of embeds
public enum EmbedType {
  case none
  case images
  case videos
  case external
  case quotedPost
}
