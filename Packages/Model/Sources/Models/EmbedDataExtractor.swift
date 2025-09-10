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

    do {
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
    } catch {
      #if DEBUG
        print("EmbedDataExtractor: Error extracting embed data: \(error)")
      #endif
      return nil
    }
  }

  /// Convert ATProtoKit embed types to our EmbedData union type
  private static func convertToEmbedData(_ embed: Any?) -> EmbedData? {
    guard let embed = embed else { return nil }

    do {
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
        if let quotedPostData = extractQuotedPostData(from: recordEmbed) {
          return .quotedPost(quotedPostData)
        } else {
          return .quotedPost(
            QuotedPostData(
              uri: "unknown",
              cid: "unknown",
              author: Profile(
                did: "unknown", handle: "unknown", displayName: nil, avatarImageURL: nil),
              content: "Unable to load quoted post",
              indexedAt: Date()
            ))
        }
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
              if let quotedPostData = extractQuotedPostData(from: recordEmbed) {
                return .quotedPost(quotedPostData)
              } else {
                return .quotedPost(
                  QuotedPostData(
                    uri: "unknown",
                    cid: "unknown",
                    author: Profile(
                      did: "unknown", handle: "unknown", displayName: nil, avatarImageURL: nil),
                    content: "Unable to load quoted post",
                    indexedAt: Date()
                  ))
              }
            }
          }
        }
      }

      // Special handling for EmbedUnion type - this is the key fix!
      if String(describing: type(of: embed)).contains("EmbedUnion") {
        #if DEBUG
          print("EmbedDataExtractor: Detected EmbedUnion type, using advanced extraction")
          print("EmbedDataExtractor: EmbedUnion children count: \(mirror.children.count)")
          for (index, child) in mirror.children.enumerated() {
            print("EmbedDataExtractor: Child \(index): \(child.label ?? "nil") = \(child.value)")
          }
        #endif

        // For EmbedUnion, we need to check all possible union cases
        // Try to extract the actual embed data from the union
        for child in mirror.children {
          if let label = child.label {
            #if DEBUG
              print("EmbedDataExtractor: Examining EmbedUnion child: \(label) = \(child.value)")
            #endif

            // The child.value might be another union or container
            // Let's try to extract from it directly
            if let imagesEmbed = child.value as? AppBskyLexicon.Embed.ImagesDefinition.View {
              #if DEBUG
                print("EmbedDataExtractor: Successfully extracted images from EmbedUnion child")
              #endif
              return .images(imagesEmbed)
            } else if let videoEmbed = child.value as? AppBskyLexicon.Embed.VideoDefinition.View {
              #if DEBUG
                print("EmbedDataExtractor: Successfully extracted video from EmbedUnion child")
              #endif
              return .videos(videoEmbed)
            } else if let externalEmbed = child.value
              as? AppBskyLexicon.Embed.ExternalDefinition.View
            {
              #if DEBUG
                print("EmbedDataExtractor: Successfully extracted external from EmbedUnion child")
              #endif
              return .external(externalEmbed)
            } else if let recordEmbed = child.value as? AppBskyLexicon.Embed.RecordDefinition.View {
              #if DEBUG
                print("EmbedDataExtractor: Successfully extracted record from EmbedUnion child")
              #endif
              if let quotedPostData = extractQuotedPostData(from: recordEmbed) {
                return .quotedPost(quotedPostData)
              } else {
                return .quotedPost(
                  QuotedPostData(
                    uri: "unknown",
                    cid: "unknown",
                    author: Profile(
                      did: "unknown", handle: "unknown", displayName: nil, avatarImageURL: nil),
                    content: "Unable to load quoted post",
                    indexedAt: Date()
                  ))
              }
            } else {
              // If direct casting fails, check if this is a type indicator and look for the data field
              let childMirror = Mirror(reflecting: child.value)
              #if DEBUG
                print(
                  "EmbedDataExtractor: Child \(label) has \(childMirror.children.count) sub-children"
                )
                for (subIndex, subChild) in childMirror.children.enumerated() {
                  print(
                    "EmbedDataExtractor: Sub-child \(subIndex): \(subChild.label ?? "nil") = \(subChild.value)"
                  )
                }
              #endif

              // If this child has a "type" field indicating the embed type, look for the corresponding data field
              var embedType: String? = nil
              var embedData: Any? = nil

              for subChild in childMirror.children {
                if subChild.label == "type", let typeString = subChild.value as? String {
                  embedType = typeString
                  #if DEBUG
                    print("EmbedDataExtractor: Found embed type: \(typeString)")
                  #endif
                } else if subChild.label == "images" || subChild.label == "video"
                  || subChild.label == "external" || subChild.label == "record"
                {
                  embedData = subChild.value
                  #if DEBUG
                    print("EmbedDataExtractor: Found embed data field: \(subChild.label ?? "nil")")
                  #endif
                }
              }

              // Now try to match the type with the data
              if let embedType = embedType, let embedData = embedData {
                if embedType.contains("images") {
                  if let imagesEmbed = embedData as? AppBskyLexicon.Embed.ImagesDefinition.View {
                    #if DEBUG
                      print("EmbedDataExtractor: Successfully extracted images by type matching")
                    #endif
                    return .images(imagesEmbed)
                  }
                } else if embedType.contains("video") {
                  if let videoEmbed = embedData as? AppBskyLexicon.Embed.VideoDefinition.View {
                    #if DEBUG
                      print("EmbedDataExtractor: Successfully extracted video by type matching")
                    #endif
                    return .videos(videoEmbed)
                  }
                } else if embedType.contains("external") {
                  if let externalEmbed = embedData as? AppBskyLexicon.Embed.ExternalDefinition.View
                  {
                    #if DEBUG
                      print("EmbedDataExtractor: Successfully extracted external by type matching")
                    #endif
                    return .external(externalEmbed)
                  }
                } else if embedType.contains("record") {
                  if let recordEmbed = embedData as? AppBskyLexicon.Embed.RecordDefinition.View {
                    #if DEBUG
                      print("EmbedDataExtractor: Successfully extracted record by type matching")
                    #endif
                    if let quotedPostData = extractQuotedPostData(from: recordEmbed) {
                      return .quotedPost(quotedPostData)
                    } else {
                      return .quotedPost(
                        QuotedPostData(
                          uri: "unknown",
                          cid: "unknown",
                          author: Profile(
                            did: "unknown", handle: "unknown", displayName: nil, avatarImageURL: nil
                          ),
                          content: "Unable to load quoted post",
                          indexedAt: Date()
                        ))
                    }
                  }
                }
              }

              // Fallback: try to extract from all sub-children directly
              for subChild in childMirror.children {
                if let imagesEmbed = subChild.value as? AppBskyLexicon.Embed.ImagesDefinition.View {
                  #if DEBUG
                    print(
                      "EmbedDataExtractor: Successfully extracted images from EmbedUnion sub-child")
                  #endif
                  return .images(imagesEmbed)
                } else if let videoEmbed = subChild.value
                  as? AppBskyLexicon.Embed.VideoDefinition.View
                {
                  #if DEBUG
                    print(
                      "EmbedDataExtractor: Successfully extracted video from EmbedUnion sub-child")
                  #endif
                  return .videos(videoEmbed)
                } else if let externalEmbed = subChild.value
                  as? AppBskyLexicon.Embed.ExternalDefinition.View
                {
                  #if DEBUG
                    print(
                      "EmbedDataExtractor: Successfully extracted external from EmbedUnion sub-child"
                    )
                  #endif
                  return .external(externalEmbed)
                } else if let recordEmbed = subChild.value
                  as? AppBskyLexicon.Embed.RecordDefinition.View
                {
                  #if DEBUG
                    print(
                      "EmbedDataExtractor: Successfully extracted record from EmbedUnion sub-child")
                  #endif
                  if let quotedPostData = extractQuotedPostData(from: recordEmbed) {
                    return .quotedPost(quotedPostData)
                  } else {
                    return .quotedPost(
                      QuotedPostData(
                        uri: "unknown",
                        cid: "unknown",
                        author: Profile(
                          did: "unknown", handle: "unknown", displayName: nil, avatarImageURL: nil),
                        content: "Unable to load quoted post",
                        indexedAt: Date()
                      ))
                  }
                }
              }
            }
          }
        }
      }

      #if DEBUG
        print("EmbedDataExtractor: Failed to convert embed type: \(type(of: embed))")
      #endif

      return nil
    } catch {
      #if DEBUG
        print("EmbedDataExtractor: Error converting embed data: \(error)")
      #endif
      return nil
    }
  }

  /// Extract quoted post data from a RecordDefinition.View
  private static func extractQuotedPostData(
    from recordEmbed: AppBskyLexicon.Embed.RecordDefinition.View
  ) -> QuotedPostData? {
    #if DEBUG
      print("EmbedDataExtractor: Starting extraction of quoted post data")
    #endif

    // Use reflection to extract the quoted post data
    let mirror = Mirror(reflecting: recordEmbed)

    var uri: String?
    var cid: String?
    var author: Profile?
    var content: String?
    var indexedAt: Date?

    #if DEBUG
      print(
        "EmbedDataExtractor: Found mirror children: \(mirror.children.map { $0.label ?? "nil" })")
    #endif

    // First, try to find content using the alternative method since we know it works
    if let alternativeContent = extractContentAlternative(from: recordEmbed) {
      content = alternativeContent
      #if DEBUG
        print("EmbedDataExtractor: Found content via alternative method: \(alternativeContent)")
      #endif
    }

    // Now look for other properties
    for child in mirror.children {
      if let label = child.label {
        #if DEBUG
          print("EmbedDataExtractor: Processing child with label: \(label)")
        #endif

        switch label {
        case "record":
          // The record should contain the actual post data
          let recordMirror = Mirror(reflecting: child.value)
          #if DEBUG
            print(
              "EmbedDataExtractor: Record mirror children: \(recordMirror.children.map { $0.label ?? "nil" })"
            )
          #endif

          for recordChild in recordMirror.children {
            if let recordLabel = recordChild.label {
              #if DEBUG
                print("EmbedDataExtractor: Processing record child: \(recordLabel)")
              #endif

              switch recordLabel {
              case "viewRecord":
                // This is where the actual post data is stored
                let viewRecordMirror = Mirror(reflecting: recordChild.value)
                #if DEBUG
                  print(
                    "EmbedDataExtractor: ViewRecord mirror children: \(viewRecordMirror.children.map { $0.label ?? "nil" })"
                  )
                #endif

                for viewRecordChild in viewRecordMirror.children {
                  if let viewRecordLabel = viewRecordChild.label {
                    #if DEBUG
                      print("EmbedDataExtractor: Processing viewRecord child: \(viewRecordLabel)")
                    #endif

                    switch viewRecordLabel {
                    case "uri":
                      if let uriString = viewRecordChild.value as? String {
                        uri = uriString
                        #if DEBUG
                          print("EmbedDataExtractor: Found URI: \(uriString)")
                        #endif
                      }
                    case "cid":
                      if let cidString = viewRecordChild.value as? String {
                        cid = cidString
                        #if DEBUG
                          print("EmbedDataExtractor: Found CID: \(cidString)")
                        #endif
                      }
                    case "indexedAt":
                      if let dateString = viewRecordChild.value as? String {
                        indexedAt = ISO8601DateFormatter().date(from: dateString)
                        #if DEBUG
                          print("EmbedDataExtractor: Found indexedAt: \(dateString)")
                        #endif
                      }
                    case "author":
                      // Extract author information from the viewRecord
                      if let authorData = extractAuthorFromValue(viewRecordChild.value) {
                        author = authorData
                        #if DEBUG
                          print(
                            "EmbedDataExtractor: Found author in viewRecord: \(authorData.handle)")
                        #endif
                      }
                    default:
                      break
                    }
                  }
                }
              case "uri":
                if let uriString = recordChild.value as? String {
                  uri = uriString
                  #if DEBUG
                    print("EmbedDataExtractor: Found URI: \(uriString)")
                  #endif
                }
              case "cid":
                if let cidString = recordChild.value as? String {
                  cid = cidString
                  #if DEBUG
                    print("EmbedDataExtractor: Found CID: \(cidString)")
                  #endif
                }
              case "indexedAt":
                if let dateString = recordChild.value as? String {
                  indexedAt = ISO8601DateFormatter().date(from: dateString)
                  #if DEBUG
                    print("EmbedDataExtractor: Found indexedAt: \(dateString)")
                  #endif
                }
              default:
                break
              }
            }
          }
        case "author":
          // Extract author information
          if let authorData = extractAuthorFromValue(child.value) {
            author = authorData
            #if DEBUG
              print("EmbedDataExtractor: Found author: \(authorData.handle)")
            #endif
          }
        case "actor", "creator", "postedBy":
          // Try alternative author property names
          if let authorData = extractAuthorFromValue(child.value) {
            author = authorData
            #if DEBUG
              print(
                "EmbedDataExtractor: Found author via alternative property \(label): \(authorData.handle)"
              )
            #endif
          }
        default:
          break
        }
      }
    }

    #if DEBUG
      print(
        "EmbedDataExtractor: Extraction results - URI: \(uri ?? "nil"), CID: \(cid ?? "nil"), Author: \(author?.handle ?? "nil"), Content: \(content ?? "nil"), IndexedAt: \(indexedAt?.description ?? "nil")"
      )
    #endif

    // If we have content, create QuotedPostData
    if let content = content, !content.isEmpty {
      // Create QuotedPostData with available information, using defaults for missing fields
      return QuotedPostData(
        uri: uri ?? "unknown",
        cid: cid ?? "unknown",
        author: author
          ?? Profile(did: "unknown", handle: "unknown", displayName: nil, avatarImageURL: nil),
        content: content,
        indexedAt: indexedAt ?? Date()
      )
    }

    return nil
  }

  /// Alternative method to extract content from RecordDefinition.View
  private static func extractContentAlternative(
    from recordEmbed: AppBskyLexicon.Embed.RecordDefinition.View
  ) -> String? {
    #if DEBUG
      print("EmbedDataExtractor: Trying alternative content extraction")
    #endif

    let mirror = Mirror(reflecting: recordEmbed)

    // Try to find any text content in the structure
    for child in mirror.children {
      if let label = child.label {
        #if DEBUG
          print("EmbedDataExtractor: Alternative - checking child: \(label)")
        #endif

        // Look for text content in various possible locations
        if let text = extractTextFromValue(child.value) {
          #if DEBUG
            print("EmbedDataExtractor: Alternative - found text: \(text)")
          #endif
          return text
        }

        // Special handling for the record property which should contain the actual post data
        if label == "record" {
          #if DEBUG
            print(
              "EmbedDataExtractor: Alternative - found record property, examining it more closely")
          #endif

          let recordMirror = Mirror(reflecting: child.value)
          for recordChild in recordMirror.children {
            if let recordLabel = recordChild.label {
              #if DEBUG
                print("EmbedDataExtractor: Alternative - checking record child: \(recordLabel)")
              #endif

              // Look specifically in viewRecord for the actual post content
              if recordLabel == "viewRecord" {
                if let text = extractTextFromValue(recordChild.value) {
                  #if DEBUG
                    print("EmbedDataExtractor: Alternative - found text in viewRecord: \(text)")
                  #endif
                  return text
                }
              }
            }
          }
        }
      }
    }

    return nil
  }

  /// Extract text content from any value using reflection
  private static func extractTextFromValue(_ value: Any) -> String? {
    let mirror = Mirror(reflecting: value)

    #if DEBUG
      print(
        "EmbedDataExtractor: extractTextFromValue - checking children: \(mirror.children.map { $0.label ?? "nil" })"
      )
    #endif

    for child in mirror.children {
      if let label = child.label {
        #if DEBUG
          print("EmbedDataExtractor: extractTextFromValue - checking property: \(label)")
        #endif

        switch label {
        case "text", "content", "value":
          if let text = child.value as? String, !text.isEmpty {
            #if DEBUG
              print("EmbedDataExtractor: extractTextFromValue - found text in \(label): \(text)")
            #endif
            return text
          }
        case "record", "post", "feed":
          // These might contain the actual post data
          if let childText = extractTextFromValue(child.value) {
            return childText
          }
        default:
          break
        }
      }

      // Recursively check child values
      if let childText = extractTextFromValue(child.value) {
        return childText
      }
    }

    return nil
  }

  /// Extract author information from a value
  private static func extractAuthorFromValue(_ value: Any) -> Profile? {
    let mirror = Mirror(reflecting: value)

    var did: String?
    var handle: String?
    var displayName: String?
    var avatarURL: URL?

    #if DEBUG
      print(
        "EmbedDataExtractor: Extracting author from value with children: \(mirror.children.map { $0.label ?? "nil" })"
      )
    #endif

    for child in mirror.children {
      if let label = child.label {
        #if DEBUG
          print("EmbedDataExtractor: Checking author property: \(label)")
        #endif

        switch label {
        case "did", "actorDID", "actorDid":
          if let didString = child.value as? String {
            did = didString
            #if DEBUG
              print("EmbedDataExtractor: Found DID: \(didString)")
            #endif
          }
        case "handle", "actorHandle", "actorHandle":
          if let handleString = child.value as? String {
            handle = handleString
            #if DEBUG
              print("EmbedDataExtractor: Found handle: \(handleString)")
            #endif
          }
        case "displayName", "displayName", "actorDisplayName":
          if let displayNameString = child.value as? String {
            displayName = displayNameString
            #if DEBUG
              print("EmbedDataExtractor: Found displayName: \(displayNameString)")
            #endif
          }
        case "avatarImageURL", "avatar", "actorAvatar":
          if let url = child.value as? URL {
            avatarURL = url
            #if DEBUG
              print("EmbedDataExtractor: Found avatar URL: \(url)")
            #endif
          } else if let urlString = child.value as? String, let url = URL(string: urlString) {
            avatarURL = url
            #if DEBUG
              print("EmbedDataExtractor: Found avatar URL string: \(urlString)")
            #endif
          }
        default:
          // Try to recursively search for author information in nested structures
          if let nestedAuthor = extractAuthorFromValue(child.value) {
            return nestedAuthor
          }
          break
        }
      }
    }

    // If we found the essential author information, create a Profile
    if let did = did, let handle = handle {
      #if DEBUG
        print("EmbedDataExtractor: Successfully created Profile for author: \(handle)")
      #endif
      return Profile(
        did: did,
        handle: handle,
        displayName: displayName,
        avatarImageURL: avatarURL
      )
    }

    #if DEBUG
      print("EmbedDataExtractor: Failed to extract author information - missing DID or handle")
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

/// Struct containing extracted quoted post data for easy display
public struct QuotedPostData: Sendable {
  public let uri: String
  public let cid: String
  public let author: Profile
  public let content: String
  public let indexedAt: Date

  public init(
    uri: String,
    cid: String,
    author: Profile,
    content: String,
    indexedAt: Date
  ) {
    self.uri = uri
    self.cid = cid
    self.author = author
    self.content = content
    self.indexedAt = indexedAt
  }
}

/// Union type for embed data that conforms to Sendable
public enum EmbedData: Sendable {
  case images(AppBskyLexicon.Embed.ImagesDefinition.View)
  case videos(AppBskyLexicon.Embed.VideoDefinition.View)
  case external(AppBskyLexicon.Embed.ExternalDefinition.View)
  case quotedPost(QuotedPostData)
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
