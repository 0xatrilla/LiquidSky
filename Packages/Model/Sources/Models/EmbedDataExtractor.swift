import ATProtoKit
import Foundation

/// Helper class to extract embed data from ATProtoKit post structures
public struct EmbedDataExtractor {

  /// Extract embed data from a FeedViewPostDefinition
  public static func extractEmbed(from postData: Any?) -> EmbedData? {
    guard let postData = postData else { return nil }

    #if DEBUG
      print("EmbedDataExtractor: Starting extraction from type: \(type(of: postData))")
      print("EmbedDataExtractor: PostData value: \(String(describing: postData))")
    #endif

    // Try to extract embed from FeedViewPostDefinition
    if let feedPost = postData as? AppBskyLexicon.Feed.FeedViewPostDefinition {
      #if DEBUG
        print("EmbedDataExtractor: Processing FeedViewPostDefinition")
        print("EmbedDataExtractor: FeedPost embed: \(String(describing: feedPost.post.embed))")
        print("EmbedDataExtractor: FeedPost embed type: \(type(of: feedPost.post.embed))")
      #endif
      // The embed is in the post property
      return convertToEmbedData(feedPost.post.embed)
    }

    // Try to extract embed from PostViewDefinition
    if let postView = postData as? AppBskyLexicon.Feed.PostViewDefinition {
      #if DEBUG
        print("EmbedDataExtractor: Processing PostViewDefinition")
        print("EmbedDataExtractor: PostView embed: \(String(describing: postView.embed))")
        print("EmbedDataExtractor: PostView embed type: \(type(of: postView.embed))")
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
      print("EmbedDataExtractor: Embed value: \(String(describing: embed))")
    #endif

    // Handle the embed union type by checking for specific embed types
    // The embed might be a union that contains different embed types
    
    // Use reflection to examine the embed structure
    let mirror = Mirror(reflecting: embed)
    #if DEBUG
      print("EmbedDataExtractor: Embed mirror children:")
      for child in mirror.children {
        print("EmbedDataExtractor: - \(child.label ?? "nil"): \(child.value)")
      }
    #endif

    // Try to convert directly to our EmbedData types
    if let imagesEmbed = embed as? AppBskyLexicon.Embed.ImagesDefinition.View {
      #if DEBUG
        print("EmbedDataExtractor: Successfully converted to ImagesDefinition.View")
        print("EmbedDataExtractor: Images count: \(imagesEmbed.images.count)")
      #endif
      return .images(imagesEmbed)
    } else if let videoEmbed = embed as? AppBskyLexicon.Embed.VideoDefinition.View {
      #if DEBUG
        print("EmbedDataExtractor: Successfully converted to VideoDefinition.View")
        print("EmbedDataExtractor: Video CID: \(videoEmbed.cid)")
        print("EmbedDataExtractor: Video playlist URI: \(videoEmbed.playlistURI)")
      #endif
      return .videos(videoEmbed)
    } else if let externalEmbed = embed as? AppBskyLexicon.Embed.ExternalDefinition.View {
      #if DEBUG
        print("EmbedDataExtractor: Successfully converted to ExternalDefinition.View")
        print("EmbedDataExtractor: External URI: \(externalEmbed.external.uri)")
        print("EmbedDataExtractor: External title: \(externalEmbed.external.title)")
      #endif
      return .external(externalEmbed)
    } else if let recordEmbed = embed as? AppBskyLexicon.Embed.RecordDefinition.View {
      #if DEBUG
        print("EmbedDataExtractor: Successfully converted to RecordDefinition.View")
        print("EmbedDataExtractor: Record type: \(type(of: recordEmbed.record))")
      #endif
      return .quotedPost(recordEmbed)
    }

    // If direct casting fails, try to extract from union types
    // ATProtoKit uses union types where the actual embed data is nested
    for child in mirror.children {
      if let label = child.label {
        #if DEBUG
          print("EmbedDataExtractor: Examining child: \(label) = \(child.value)")
        #endif
        
        // Check for common union field names
        if label == "images" || label == "imagesEmbed" {
          if let imagesEmbed = child.value as? AppBskyLexicon.Embed.ImagesDefinition.View {
            #if DEBUG
              print("EmbedDataExtractor: Found images embed in union field: \(label)")
            #endif
            return .images(imagesEmbed)
          }
        } else if label == "video" || label == "videoEmbed" {
          if let videoEmbed = child.value as? AppBskyLexicon.Embed.VideoDefinition.View {
            #if DEBUG
              print("EmbedDataExtractor: Found video embed in union field: \(label)")
            #endif
            return .videos(videoEmbed)
          }
        } else if label == "external" || label == "externalEmbed" {
          if let externalEmbed = child.value as? AppBskyLexicon.Embed.ExternalDefinition.View {
            #if DEBUG
              print("EmbedDataExtractor: Found external embed in union field: \(label)")
            #endif
            return .external(externalEmbed)
          }
        } else if label == "record" || label == "recordEmbed" {
          if let recordEmbed = child.value as? AppBskyLexicon.Embed.RecordDefinition.View {
            #if DEBUG
              print("EmbedDataExtractor: Found record embed in union field: \(label)")
            #endif
            return .quotedPost(recordEmbed)
          }
        }
      }
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

    if embedData is AppBskyLexicon.Embed.VideoDefinition.View {
      // VideoDefinition.View is the video itself, not a collection
      return true
    }

    return false
  }

  /// Check if the embed data contains external links
  public static func hasExternalLink(in embedData: Any?) -> Bool {
    guard let embedData = embedData else { return false }

    if embedData is AppBskyLexicon.Embed.ExternalDefinition.View {
      // external is not optional, so it always exists
      return true
    }

    return false
  }

  /// Check if the embed data contains quoted posts
  public static func hasQuotedPost(in embedData: Any?) -> Bool {
    guard let embedData = embedData else { return false }

    if embedData is AppBskyLexicon.Embed.RecordDefinition.View {
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
