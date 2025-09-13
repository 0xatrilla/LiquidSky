// Temporary placeholders for compilation
import Client
import Foundation

// TODO: Re-enable ChatService when chat functionality is ready
/*
@MainActor
public final class ChatService: ObservableObject {
  let client: BSkyClient

  public init(client: BSkyClient) {
    self.client = client
  }

  // MARK: - Conversations

  public struct Conversation: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let lastMessagePreview: String
    public let updatedAt: Date
    public let unreadCount: Int
  }

  public struct Message: Identifiable, Sendable {
    public let id: String
    public let text: String
    public let sentAt: Date
    public let isMine: Bool
    public let isRead: Bool
  }

  public func listConversations(cursor: String? = nil, limit: Int = 30) async throws -> (
    items: [Conversation], cursor: String?
  ) {
    var params: [String: Any] = ["limit": limit]
    if let cursor { params["cursor"] = cursor }

    struct Response: Decodable {
      struct Convo: Decodable {
        let id: String
        let rev: String?
        let members: [Member]?
        let lastMessage: LastMessage?
        let unreadCount: Int?
        struct Member: Decodable {
          let did: String
          let handle: String?
          let displayName: String?
        }
        struct LastMessage: Decodable {
          let text: String?
          let sentAt: String?
        }
      }
      let convos: [Convo]
      let cursor: String?
    }

    let resp: Response = try await performXrpcCall("chat.bsky.convo.listConvos", parameters: params)
    let mapped = resp.convos.map { c in
      Conversation(
        id: c.id,
        title: (c.members?.first?.displayName) ?? (c.members?.first?.handle) ?? "Conversation",
        lastMessagePreview: c.lastMessage?.text ?? "",
        updatedAt: ISO8601DateFormatter().date(from: c.lastMessage?.sentAt ?? "") ?? Date(),
        unreadCount: c.unreadCount ?? 0
      )
    }
    return (mapped, resp.cursor)
  }

  public func getMessages(conversationID: String, cursor: String? = nil, limit: Int = 50)
    async throws -> (items: [Message], cursor: String?)
  {
    var params: [String: Any] = [
      "convoId": conversationID,
      "limit": limit,
    ]
    if let cursor { params["cursor"] = cursor }

    struct Response: Decodable {
      struct Item: Decodable {
        let id: String
        let text: String?
        let sentAt: String
        let isMine: Bool?
        let isRead: Bool?
      }
      let messages: [Item]
      let cursor: String?
    }
    let resp: Response = try await performXrpcCall(
      "chat.bsky.convo.getMessages", parameters: params)
    let fmt = ISO8601DateFormatter()
    let mapped = resp.messages.map { m in
      Message(
        id: m.id,
        text: m.text ?? "",
        sentAt: fmt.date(from: m.sentAt) ?? Date(),
        isMine: m.isMine ?? false,
        isRead: m.isRead ?? true
      )
    }
    return (mapped, resp.cursor)
  }

  public func getOrCreateConversation(withMembers memberDIDs: [String]) async throws -> Conversation
  {
    let params: [String: Any] = ["members": memberDIDs]

    struct Resp: Decodable {
      let id: String
      let members: [Member]
      struct Member: Decodable {
        let did: String
        let handle: String?
        let displayName: String?
      }
    }
    let resp: Resp = try await performXrpcCall(
      "chat.bsky.convo.getConvoForMembers", method: "POST", parameters: params)
    return Conversation(
      id: resp.id,
      title: resp.members.first?.displayName ?? resp.members.first?.handle ?? "Conversation",
      lastMessagePreview: "",
      updatedAt: Date(),
      unreadCount: 0
    )
  }

  public func sendMessage(conversationID: String, text: String) async throws -> Message {
    let params: [String: Any] = [
      "convoId": conversationID,
      "message": ["text": text],
    ]

    struct Resp: Decodable {
      let id: String
      let text: String
      let sentAt: String
      let isRead: Bool?
    }
    let resp: Resp = try await performXrpcCall(
      "chat.bsky.convo.sendMessage", method: "POST", parameters: params)
    let fmt = ISO8601DateFormatter()
    return Message(
      id: resp.id, text: resp.text, sentAt: fmt.date(from: resp.sentAt) ?? Date(), isMine: true,
      isRead: resp.isRead ?? true)
  }

  public func markAsRead(conversationID: String) async throws {
    let params: [String: Any] = ["convoId": conversationID]
    _ =
      try await performXrpcCall("chat.bsky.convo.markAsRead", method: "POST", parameters: params)
      as EmptyResponse
  }
}

public enum ChatError: LocalizedError {
  case networkError(Error)
  case invalidResponse
  case conversationNotFound
  case messageNotFound

  public var errorDescription: String? {
    switch self {
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .invalidResponse:
      return "Invalid response from server"
    case .conversationNotFound:
      return "Conversation not found"
    case .messageNotFound:
      return "Message not found"
    }
  }
}
*/

@MainActor
public final class ChatService: ObservableObject {
  let client: BSkyClient

  public init(client: BSkyClient) {
    self.client = client
  }

  public func listConversations(cursor: String? = nil, limit: Int = 30) async throws -> (
    items: [Conversation], cursor: String?
  ) {
    throw ChatError.invalidResponse
  }

  public func getMessages(conversationID: String, cursor: String? = nil, limit: Int = 50)
    async throws -> (items: [Message], cursor: String?)
  {
    throw ChatError.invalidResponse
  }

  public func getOrCreateConversation(withMembers memberDIDs: [String]) async throws -> Conversation
  {
    throw ChatError.invalidResponse
  }

  public func sendMessage(conversationID: String, text: String) async throws -> Message {
    throw ChatError.invalidResponse
  }

  public func markAsRead(conversationID: String) async throws {
    throw ChatError.invalidResponse
  }

  public struct Conversation: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let lastMessagePreview: String
    public let updatedAt: Date
    public let unreadCount: Int
  }

  public struct Message: Identifiable, Sendable {
    public let id: String
    public let text: String
    public let sentAt: Date
    public let isMine: Bool
    public let isRead: Bool
  }
}

public enum ChatError: LocalizedError {
  case networkError(Error)
  case invalidResponse
  case conversationNotFound
  case messageNotFound

  public var errorDescription: String? {
    switch self {
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .invalidResponse:
      return "Invalid response from server"
    case .conversationNotFound:
      return "Conversation not found"
    case .messageNotFound:
      return "Message not found"
    }
  }
}
