import Foundation

public struct UserList: Identifiable, Codable, Hashable {
  public let id: String
  public let name: String
  public let description: String?
  public let purpose: Purpose
  public let uri: String
  public let cid: String
  public let createdAt: Date
  public let creator: Profile
  public let memberCount: Int
  public let isSubscribed: Bool
  
  public init(
    id: String,
    name: String,
    description: String?,
    purpose: Purpose,
    uri: String,
    cid: String,
    createdAt: Date,
    creator: Profile,
    memberCount: Int,
    isSubscribed: Bool
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.purpose = purpose
    self.uri = uri
    self.cid = cid
    self.createdAt = createdAt
    self.creator = creator
    self.memberCount = memberCount
    self.isSubscribed = isSubscribed
  }
  
  public enum Purpose: String, Codable, CaseIterable {
    case moderation = "app.bsky.graph.defs#modlist"
    case curation = "app.bsky.graph.defs#curatelist"
    case custom = "app.bsky.graph.defs#custom"
    case mute = "app.bsky.graph.defs#mutelist"
    case block = "app.bsky.graph.defs#blocklist"
    
    public var displayName: String {
      switch self {
      case .moderation:
        return "Moderation"
      case .curation:
        return "Curation"
      case .custom:
        return "Custom"
      case .mute:
        return "Mute"
      case .block:
        return "Block"
      }
    }
    
    public var description: String {
      switch self {
      case .moderation:
        return "For moderating content and users"
      case .curation:
        return "For curating interesting content"
      case .custom:
        return "Custom purpose list"
      case .mute:
        return "For muting users"
      case .block:
        return "For blocking users"
      }
    }
  }
}
