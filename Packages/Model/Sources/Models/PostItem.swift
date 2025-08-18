import ATProtoKit
import Foundation

public struct PostItem: Hashable, Identifiable, Equatable, Sendable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(uri)
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
  public let embed: ATUnion.EmbedViewUnion?
  public let replyRef: AppBskyLexicon.Feed.PostRecord.ReplyReference?
  // If this post is a reply, this is the handle of the user being replied to (best-effort)
  public let inReplyToHandle: String?

  // Repost information
  public let repostedBy: Profile?
  public let isReposted: Bool

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
    embed: ATUnion.EmbedViewUnion?,
    replyRef: AppBskyLexicon.Feed.PostRecord.ReplyReference?,
    inReplyToHandle: String? = nil,
    repostedBy: Profile? = nil
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
    self.embed = embed
    self.indexAtFormatted = indexedAt.relativeFormatted
    self.replyRef = replyRef
    self.inReplyToHandle = inReplyToHandle
    self.repostedBy = repostedBy
    self.isReposted = repostedBy != nil
    self.hasReply = replyCount > 0
    self.isReplyTo = replyRef != nil
  }
}

extension AppBskyLexicon.Feed.FeedViewPostDefinition {
  public var postItem: PostItem {
    // Extract repost information if this post was reposted
    var repostedByProfile: Profile? = nil

    if let reason = reason {
      // Check if this is a repost
      print("PostsListView: Repost detected, investigating structure...")
      print("PostsListView: Reason type: \(type(of: reason))")
      print("PostsListView: Reason description: \(reason)")

      // Try to extract repost information from ATProtoKit
      // Since we don't know the exact type, let's use reflection to find the structure
      let mirror = Mirror(reflecting: reason)
      print("PostsListView: Reason mirror children:")
      for child in mirror.children {
        print("PostsListView: - \(child.label ?? "nil"): \(child.value)")
      }

      // Try to extract the repost author from the reason field
      // Based on ATProtoKit structure, the reason should contain author information
      if let repostAuthor = extractRepostAuthor(from: reason) {
        repostedByProfile = repostAuthor
        print(
          "PostsListView: Successfully extracted repost author: \(repostedByProfile?.displayName ?? repostedByProfile?.handle ?? "unknown")"
        )
        print(
          "PostsListView: Repost author details - DID: \(repostedByProfile?.did ?? "nil"), Handle: \(repostedByProfile?.handle ?? "nil")"
        )
      } else {
        print("PostsListView: Failed to extract repost author, using placeholder")
        // Fallback to placeholder if we can't extract the real author
        repostedByProfile = Profile(
          did: "did:placeholder:repost",
          handle: "reposter",
          displayName: "Someone You Follow",
          avatarImageURL: nil
        )
      }
    }

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
      embed: post.embed,
      replyRef: post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.reply,
      inReplyToHandle: extractReplyTargetHandle(
        from: post.record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.reply),
      repostedBy: repostedByProfile
    )

    // Debug reply detection
    if postItem.hasReply {
      print(
        "PostsListView: Reply detected for post \(postItem.uri) - hasReply: \(postItem.hasReply)")
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
    PostItem(
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
      embed: embed,
      replyRef: record.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.reply
    )
  }
}

extension AppBskyLexicon.Feed.ThreadViewPostDefinition {

}

extension AppBskyLexicon.Embed.RecordDefinition.ViewRecord {
  public var postItem: PostItem {
    PostItem(
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
      embed: embeds?.first,
      replyRef: value.getRecord(ofType: AppBskyLexicon.Feed.PostRecord.self)?.reply
    )
  }
}

extension PostItem {
  public static let placeholders: [PostItem] = Array(
    repeating: (), count: 10
  ).map {
    .init(
      uri: UUID().uuidString,
      cid: UUID().uuidString,
      indexedAt: Date(),
      author: .init(
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
      embed: nil,
      replyRef: nil)
  }

}

// Helper function to extract repost author from the reason field
private func extractRepostAuthor(from reason: Any) -> Profile? {
  print("PostsListView: Starting repost author extraction...")

  // Use reflection to find the author information in the reason field
  let mirror = Mirror(reflecting: reason)
  print("PostsListView: Reason object type: \(type(of: reason))")
  print("PostsListView: Reason object description: \(reason)")

  // Look for common patterns in ATProtoKit repost structures
  for child in mirror.children {
    if let label = child.label {
      print("PostsListView: Examining child: \(label) = \(child.value)")

      // Check if this child contains the author information
      if label == "by" || label == "author" || label == "reposter" || label == "actor" {
        print("PostsListView: Found potential author field: \(label)")
        // This should contain the author profile
        if let authorProfile = extractProfileFromValue(child.value) {
          print("PostsListView: Successfully extracted profile from \(label)")
          return authorProfile
        } else {
          print("PostsListView: Failed to extract profile from \(label)")
        }
      }

      // Handle the nested ReasonRepostUnion structure
      if label == "reasonRepost" {
        print("PostsListView: Found reasonRepost field, extracting author from nested structure")
        if let repostReason = child.value as? AppBskyLexicon.Feed.ReasonRepostDefinition {
          // Extract the author from the nested by field
          let repostAuthor = repostReason.by
          let profile = Profile(
            did: repostAuthor.actorDID,
            handle: repostAuthor.actorHandle,
            displayName: repostAuthor.displayName,
            avatarImageURL: repostAuthor.avatarImageURL
          )
          print(
            "PostsListView: Successfully extracted profile from reasonRepost.by: \(profile.displayName ?? profile.handle)"
          )
          return profile
        } else {
          print("PostsListView: Failed to cast reasonRepost to ReasonRepostDefinition")
        }
      }
    }
  }

  print(
    "PostsListView: No direct author field found, trying to extract from entire reason structure")
  // If we can't find the author directly, try to extract from the entire reason structure
  if let authorProfile = extractProfileFromValue(reason) {
    print("PostsListView: Successfully extracted profile from entire reason structure")
    return authorProfile
  }

  print("PostsListView: Failed to extract profile from entire reason structure")
  return nil
}

// Helper function to extract Profile from various ATProtoKit types
private func extractProfileFromValue(_ value: Any) -> Profile? {
  print("PostsListView: Extracting profile from value type: \(type(of: value))")

  let mirror = Mirror(reflecting: value)

  var did: String?
  var handle: String?
  var displayName: String?
  var avatarImageURL: URL?

  for child in mirror.children {
    if let label = child.label {
      print("PostsListView: Profile field: \(label) = \(child.value)")

      switch label {
      case "did", "actorDID", "actorDid":
        if let stringValue = child.value as? String {
          did = stringValue
          print("PostsListView: Found DID: \(stringValue)")
        }
      case "handle", "actorHandle", "actorHandle":
        if let stringValue = child.value as? String {
          handle = stringValue
          print("PostsListView: Found handle: \(stringValue)")
        }
      case "displayName", "display_name":
        if let stringValue = child.value as? String {
          displayName = stringValue
          print("PostsListView: Found displayName: \(stringValue)")
        }
      case "avatar", "avatarImageURL", "avatarURL":
        if let urlValue = child.value as? URL {
          avatarImageURL = urlValue
          print("PostsListView: Found avatar: \(urlValue)")
        }
      default:
        print("PostsListView: Unhandled field: \(label)")
        break
      }
    }
  }

  print(
    "PostsListView: Profile extraction result - DID: \(did ?? "nil"), Handle: \(handle ?? "nil"), DisplayName: \(displayName ?? "nil")"
  )

  // Only return a profile if we have the essential fields
  if let did = did, let handle = handle {
    let profile = Profile(
      did: did,
      handle: handle,
      displayName: displayName,
      avatarImageURL: avatarImageURL
    )
    print(
      "PostsListView: Successfully created profile for: \(profile.displayName ?? profile.handle)")
    return profile
  }

  print("PostsListView: Failed to create profile - missing essential fields")
  return nil
}
