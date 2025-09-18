import ATProtoKit
import Foundation

public struct PostItem: Hashable, Identifiable, Sendable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(uri)
  }

  public static func == (lhs: PostItem, rhs: PostItem) -> Bool {
    return lhs.uri == rhs.uri && lhs.cid == rhs.cid
  }

  public var id: String { uri + uuid.uuidString }
  private let uuid = UUID()
  public let uri: String
  public let cid: String
  public let indexedAt: Date
  public let indexAtFormatted: String
  public let author: Profile
  public let content: String
  public let replyCount: Int
  public let repostCount: Int
  public let likeCount: Int
  public let likeURI: String?
  public let repostURI: String?

  public let replyRef: AppBskyLexicon.Feed.PostRecord.ReplyReference?
  // If this post is a reply, this is the handle of the user being replied to (best-effort)
  public let inReplyToHandle: String?

  // Repost information
  public let repostedBy: Profile?
  public let isReposted: Bool

  // Embed data for media, links, and quoted posts
  public let embed: EmbedData?

  // Content warnings and labels
  public let isSensitive: Bool
  public let contentWarning: String?

  public var hasReply: Bool = false
  public var isReplyTo: Bool = false

  public init(
    uri: String,
    cid: String,
    indexedAt: Date,
    author: Profile,
    content: String,
    replyCount: Int,
    repostCount: Int,
    likeCount: Int,
    likeURI: String?,
    repostURI: String?,
    replyRef: AppBskyLexicon.Feed.PostRecord.ReplyReference?,
    inReplyToHandle: String? = nil,
    repostedBy: Profile? = nil,
    embed: EmbedData? = nil,
    isSensitive: Bool = false,
    contentWarning: String? = nil
  ) {
    self.uri = uri
    self.cid = cid
    self.indexedAt = indexedAt
    self.author = author
    self.content = content
    self.replyCount = replyCount
    self.repostCount = repostCount
    self.likeCount = likeCount
    self.likeURI = likeURI
    self.repostURI = repostURI
    self.indexAtFormatted = indexedAt.relativeFormatted
    self.replyRef = replyRef
    self.inReplyToHandle = inReplyToHandle
    self.repostedBy = repostedBy
    self.embed = embed
    self.isSensitive = isSensitive
    self.contentWarning = contentWarning
    self.isReposted = repostedBy != nil
    self.hasReply = replyCount > 0
    self.isReplyTo = replyRef != nil
  }
}

// MARK: - Sensitive Content Detection
private func detectSensitiveContent(from post: AppBskyLexicon.Feed.PostViewDefinition) -> (isSensitive: Bool, contentWarning: String?) {
  // Check for labels in the post record
  if let record = post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self) {
    // Check for content warnings in the text
    let text = record.text.lowercased()
    let sensitiveKeywords = ["nsfw", "sensitive", "adult", "explicit", "trigger warning", "tw:", "cw:"]
    
    for keyword in sensitiveKeywords {
      if text.contains(keyword) {
        return (true, "Content Warning")
      }
    }
    
    // Check for labels array if available
    if let labels = record.labels {
      for label in labels {
        let labelValue = label.val.lowercased()
        if labelValue.contains("nsfw") || labelValue.contains("sensitive") || labelValue.contains("adult") {
          return (true, labelValue.capitalized)
        }
      }
    }
  }
  
  // Check for labels in the post itself
  if let labels = post.labels {
    for label in labels {
      let labelValue = label.val.lowercased()
      if labelValue.contains("nsfw") || labelValue.contains("sensitive") || labelValue.contains("adult") {
        return (true, labelValue.capitalized)
      }
    }
  }
  
  return (false, nil)
}

private func detectSensitiveContent(from viewRecord: AppBskyLexicon.Embed.RecordDefinition.ViewRecord) -> (isSensitive: Bool, contentWarning: String?) {
  // Check for labels in the post record
  if let record = viewRecord.value.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self) {
    // Check for content warnings in the text
    let text = record.text.lowercased()
    let sensitiveKeywords = ["nsfw", "sensitive", "adult", "explicit", "trigger warning", "tw:", "cw:"]
    
    for keyword in sensitiveKeywords {
      if text.contains(keyword) {
        return (true, "Content Warning")
      }
    }
    
    // Check for labels array if available
    if let labels = record.labels {
      for label in labels {
        let labelValue = label.val.lowercased()
        if labelValue.contains("nsfw") || labelValue.contains("sensitive") || labelValue.contains("adult") {
          return (true, labelValue.capitalized)
        }
      }
    }
  }
  
  // Check for labels in the view record itself
  if let labels = viewRecord.labels {
    for label in labels {
      let labelValue = label.val.lowercased()
      if labelValue.contains("nsfw") || labelValue.contains("sensitive") || labelValue.contains("adult") {
        return (true, labelValue.capitalized)
      }
    }
  }
  
  return (false, nil)
}

extension AppBskyLexicon.Feed.FeedViewPostDefinition {
  public var postItem: PostItem {
    // Extract repost information if this post was reposted
    var repostedByProfile: Profile? = nil

    if let reason = reason {
      // Check if this is a repost
      // Try to extract repost information from ATProtoKit
      // Since we don't know the exact type, let's use reflection to find the structure
      let _ = Mirror(reflecting: reason)

      // Try to extract the repost author from the reason field
      // Based on ATProtoKit structure, the reason should contain author information
      if let repostAuthor = extractRepostAuthor(from: reason) {
        repostedByProfile = repostAuthor
      } else {
        // Fallback to placeholder if we can't extract the real author
        repostedByProfile = Profile(
          did: "did:placeholder:repost",
          handle: "reposter",
          displayName: "Someone You Follow",
          avatarImageURL: nil
        )
      }
    }

    let embedData = EmbedDataExtractor.extractEmbed(from: post)
    let sensitiveContent = detectSensitiveContent(from: post)
    
    let postItem = PostItem(
      uri: post.postItem.uri,
      cid: post.postItem.cid,
      indexedAt: post.indexedAt,
      author: post.author.profile,
      content: post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.text ?? "",
      replyCount: post.replyCount ?? 0,
      repostCount: post.repostCount ?? 0,
      likeCount: post.likeCount ?? 0,
      likeURI: post.viewer?.likeURI,
      repostURI: post.viewer?.repostURI,
      replyRef: post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.reply,
      inReplyToHandle: extractReplyTargetHandle(
        from: post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.reply),
      repostedBy: repostedByProfile,
      embed: embedData,
      isSensitive: sensitiveContent.isSensitive,
      contentWarning: sensitiveContent.contentWarning
    )

    // Debug reply detection
    if postItem.hasReply {
      // Reply detected
    }

    return postItem
  }
}
// Best-effort: attempt to pull the handle of the author of the parent/root of a reply reference
private func extractReplyTargetHandle(from reply: AppBskyLexicon.Feed.PostRecord.ReplyReference?)
  -> String?
{
  guard let reply else { return nil }
  // We do not have full author objects here, so try common fields via reflection
  let mirror = Mirror(reflecting: reply)
  for child in mirror.children {
    if child.label == "parent" || child.label == "root" {
      let subMirror = Mirror(reflecting: child.value)
      for subChild in subMirror.children {
        if let label = subChild.label, label.lowercased().contains("handle"),
          let handle = subChild.value as? String
        {
          return handle
        }
      }
    }
  }
  return nil
}

extension AppBskyLexicon.Feed.PostViewDefinition {
  public var postItem: PostItem {
    let embedData = EmbedDataExtractor.extractEmbed(from: self)
    let sensitiveContent = detectSensitiveContent(from: self)
    #if DEBUG
    print("PostViewDefinition: Creating PostItem for \(uri)")
    print("PostViewDefinition: Embed data extracted: \(String(describing: embedData))")
    #endif
    
    return PostItem(
      uri: uri,
      cid: cid,
      indexedAt: indexedAt,
      author: author.profile,
      content: record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.text ?? "",
      replyCount: replyCount ?? 0,
      repostCount: repostCount ?? 0,
      likeCount: likeCount ?? 0,
      likeURI: viewer?.likeURI,
      repostURI: viewer?.repostURI,
      replyRef: record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.reply,
      embed: embedData,
      isSensitive: sensitiveContent.isSensitive,
      contentWarning: sensitiveContent.contentWarning
    )
  }
}

extension AppBskyLexicon.Feed.ThreadViewPostDefinition {

}

extension AppBskyLexicon.Embed.RecordDefinition.ViewRecord {
  public var postItem: PostItem {
    let embedData = EmbedDataExtractor.extractEmbed(from: self)
    let sensitiveContent = detectSensitiveContent(from: self)
    #if DEBUG
    print("ViewRecord: Creating PostItem for \(uri)")
    print("ViewRecord: Embed data extracted: \(String(describing: embedData))")
    #endif
    
    return PostItem(
      uri: uri,
      cid: cid,
      indexedAt: indexedAt,
      author: author.profile,
      content: value.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.text ?? "",
      replyCount: replyCount ?? 0,
      repostCount: repostCount ?? 0,
      likeCount: likeCount ?? 0,
      likeURI: nil,
      repostURI: nil,
      replyRef: value.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.reply,
      embed: embedData,
      isSensitive: sensitiveContent.isSensitive,
      contentWarning: sensitiveContent.contentWarning
    )
  }
}

extension PostItem {
  public static let placeholders: [PostItem] = Array(
    repeating: (), count: 10
  ).map { _ in
          PostItem(
        uri: UUID().uuidString,
        cid: UUID().uuidString,
        indexedAt: Date(),
        author: Profile(
          did: "placeholder",
          handle: "placeholder@bsky",
          displayName: "Placeholder Name",
          avatarImageURL: nil),
        content:
          "Some content some content some content\nSome content some content some content\nsomecontent",
        replyCount: 0,
        repostCount: 0,
        likeCount: 0,
        likeURI: nil,
        repostURI: nil,
        replyRef: nil,
        embed: nil,
        isSensitive: false,
        contentWarning: nil)
  }

}

// Helper function to extract repost author from the reason field
private func extractRepostAuthor(from reason: Any) -> Profile? {
  #if DEBUG
    print("PostsListView: Starting repost author extraction...")
  #endif

  // Use reflection to find the author information in the reason field
  let mirror = Mirror(reflecting: reason)
  #if DEBUG
    print("PostsListView: Reason object type: \(type(of: reason))")
    print("PostsListView: Reason object description: \(reason)")
  #endif

  // Look for common patterns in ATProtoKit repost structures
  for child in mirror.children {
    if let label = child.label {
      #if DEBUG
        print("PostsListView: Examining child: \(label) = \(child.value)")
      #endif

      // Check if this child contains the author information
      if label == "by" || label == "author" || label == "reposter" || label == "actor" {
        #if DEBUG
          print("PostsListView: Found potential author field: \(label)")
        #endif
        // This should contain the author profile
        if let authorProfile = extractProfileFromValue(child.value) {
          #if DEBUG
            print("PostsListView: Successfully extracted profile from \(label)")
          #endif
          return authorProfile
        } else {
          #if DEBUG
            print("PostsListView: Failed to extract profile from \(label)")
          #endif
        }
      }

      // Handle the nested ReasonRepostUnion structure
      if label == "reasonRepost" {
        #if DEBUG
          print("PostsListView: Found reasonRepost field, extracting author from nested structure")
        #endif
        if let repostReason = child.value as? AppBskyLexicon.Feed.ReasonRepostDefinition {
          // Extract the author from the nested by field
          let repostAuthor = repostReason.by
          let profile = Profile(
            did: repostAuthor.actorDID,
            handle: repostAuthor.actorHandle,
            displayName: repostAuthor.displayName,
            avatarImageURL: repostAuthor.avatarImageURL
          )
          #if DEBUG
            print(
              "PostsListView: Successfully extracted profile from reasonRepost.by: \(profile.displayName ?? profile.handle)"
            )
          #endif
          return profile
        } else {
          #if DEBUG
            print("PostsListView: Failed to cast reasonRepost to ReasonRepostDefinition")
          #endif
        }
      }
    }
  }

  #if DEBUG
    print(
      "PostsListView: No direct author field found, trying to extract from entire reason structure")
  #endif
  // If we can't find the author directly, try to extract from the entire reason structure
  if let authorProfile = extractProfileFromValue(reason) {
    #if DEBUG
      print("PostsListView: Successfully extracted profile from entire reason structure")
    #endif
    return authorProfile
  }

  #if DEBUG
    print("PostsListView: Failed to extract profile from entire reason structure")
  #endif
  return nil
}

// Helper function to extract Profile from various ATProtoKit types
private func extractProfileFromValue(_ value: Any) -> Profile? {
  #if DEBUG
    print("PostsListView: Extracting profile from value type: \(type(of: value))")
  #endif

  let mirror = Mirror(reflecting: value)

  var did: String?
  var handle: String?
  var displayName: String?
  var avatarImageURL: URL?

  for child in mirror.children {
    if let label = child.label {
      #if DEBUG
        print("PostsListView: Profile field: \(label) = \(child.value)")
      #endif

      switch label {
      case "did", "actorDID", "actorDid":
        if let stringValue = child.value as? String {
          did = stringValue
          #if DEBUG
            print("PostsListView: Found DID: \(stringValue)")
          #endif
        }
      case "handle", "actorHandle":
        if let stringValue = child.value as? String {
          handle = stringValue
          #if DEBUG
            print("PostsListView: Found handle: \(stringValue)")
          #endif
        }
      case "displayName", "display_name":
        if let stringValue = child.value as? String {
          displayName = stringValue
          #if DEBUG
            print("PostsListView: Found displayName: \(stringValue)")
          #endif
        }
      case "avatar", "avatarImageURL", "avatarURL":
        if let urlValue = child.value as? URL {
          avatarImageURL = urlValue
          #if DEBUG
            print("PostsListView: Found avatar: \(urlValue)")
          #endif
        }
      default:
        #if DEBUG
          print("PostsListView: Unhandled field: \(label)")
        #endif
        break
      }
    }
  }

  #if DEBUG
    print(
      "PostsListView: Profile extraction result - DID: \(did ?? "nil"), Handle: \(handle ?? "nil"), DisplayName: \(displayName ?? "nil")"
    )
  #endif

  // Only return a profile if we have the essential fields
  if let did = did, let handle = handle {
    let profile = Profile(
      did: did,
      handle: handle,
      displayName: displayName,
      avatarImageURL: avatarImageURL
    )
    #if DEBUG
      print(
        "PostsListView: Successfully created profile for: \(profile.displayName ?? profile.handle)")
    #endif
    return profile
  }

  #if DEBUG
    print("PostsListView: Failed to create profile - missing essential fields")
  #endif
  return nil
}
