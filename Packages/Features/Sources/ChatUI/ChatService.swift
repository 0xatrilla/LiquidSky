import Client
import Foundation

@MainActor
public final class ChatService: ObservableObject {
  private let client: BSkyClient

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
    // TODO: Implement direct XRPC call to chat.bsky.convo.listConvos
    // For now, return empty list until chat APIs are available
    print("Chat API not yet available - returning empty conversations list")
    return ([], nil)
  }

  public func getMessages(conversationID: String, cursor: String? = nil, limit: Int = 50)
    async throws -> (items: [Message], cursor: String?)
  {
    // TODO: Implement direct XRPC call to chat.bsky.convo.getMessages
    // For now, return empty list until chat APIs are available
    print("Chat API not yet available - returning empty messages list")
    return ([], nil)
  }

  public func getOrCreateConversation(withMembers memberDIDs: [String]) async throws -> Conversation
  {
    // TODO: Implement direct XRPC call to chat.bsky.convo.getConvoForMembers
    // For now, return placeholder until chat APIs are available
    print("Chat API not yet available - returning placeholder conversation")
    return Conversation(
      id: UUID().uuidString,
      title: "Conversation",
      lastMessagePreview: "",
      updatedAt: Date(),
      unreadCount: 0
    )
  }

  public func sendMessage(conversationID: String, text: String) async throws -> Message {
    // TODO: Implement direct XRPC call to chat.bsky.convo.sendMessage
    // For now, return placeholder until chat APIs are available
    print("Chat API not yet available - returning placeholder message")
    return Message(
      id: UUID().uuidString,
      text: text,
      sentAt: Date(),
      isMine: true,
      isRead: false
    )
  }

  public func markAsRead(conversationID: String) async throws {
    // TODO: Implement direct XRPC call to chat.bsky.convo.markAsRead
    // For now, just log until chat APIs are available
    print("Chat API not yet available - would mark conversation \(conversationID) as read")
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
