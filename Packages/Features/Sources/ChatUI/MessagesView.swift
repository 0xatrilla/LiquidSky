import Client
import Models
import SwiftUI

public struct MessagesView: View {
  let conversation: ConversationSummary

  @Environment(BSkyClient.self) private var client
  @Environment(\.dismiss) private var dismiss
  @State private var isLoading = false
  @State private var error: Error?
  @State private var messages: [ChatMessage] = []
  @State private var draft: String = ""
  @State private var chatService: ChatService?
  @State private var cursor: String?
  @State private var hasMore = true

  public init(conversation: ConversationSummary) {
    self.conversation = conversation
  }

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        if isLoading && messages.isEmpty {
          ProgressView("Loading messages…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error {
          VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
              .font(.largeTitle)
              .foregroundStyle(.secondary)
            Text("Failed to load messages")
              .font(.headline)
            Text(error.localizedDescription)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
        } else {
          List {
            if hasMore {
              HStack {
                Spacer()
                if isLoading {
                  ProgressView().scaleEffect(0.8)
                } else {
                  Button("Load earlier messages") { Task { await loadMore() } }
                    .buttonStyle(.bordered)
                }
                Spacer()
              }
              .listRowSeparator(.hidden)
            }

            ForEach(messages) { msg in
              HStack(alignment: .bottom, spacing: 8) {
                if msg.isMine { Spacer(minLength: 32) }
                VStack(alignment: msg.isMine ? .trailing : .leading, spacing: 4) {
                  Text(msg.text)
                    .padding(10)
                    .background(msg.isMine ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                  HStack(spacing: 4) {
                    Text(msg.relativeTime)
                      .font(.caption2)
                      .foregroundStyle(.secondary)
                    if msg.isMine {
                      Image(systemName: msg.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.caption2)
                        .foregroundStyle(msg.isRead ? .blue : .secondary)
                    }
                  }
                }
                if !msg.isMine { Spacer(minLength: 32) }
              }
              .listRowSeparator(.hidden)
            }
          }
          .listStyle(.plain)
        }

        // Composer
        HStack(spacing: 8) {
          TextField("Message", text: $draft, axis: .vertical)
            .textFieldStyle(.roundedBorder)
          Button {
            Task { await sendMessage() }
          } label: {
            Image(systemName: "paperplane.fill")
          }
          .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
      }
      .navigationTitle(conversation.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
      .task {
        chatService = ChatService(client: client)
        await loadMessages()
        await markAsRead()
      }
    }
  }

  private func loadMessages() async {
    guard !isLoading else { return }
    isLoading = true
    defer { isLoading = false }
    error = nil

    guard let chatService else {
      self.messages = []
      return
    }
    do {
      let result = try await chatService.getMessages(conversationID: conversation.id, cursor: nil)
      self.messages = result.items.map { msg in
        ChatMessage(
          id: msg.id, text: msg.text, sentAt: msg.sentAt, isMine: msg.isMine, isRead: msg.isRead)
      }
      self.cursor = result.cursor
      self.hasMore = (result.cursor != nil)
    } catch {
      self.error = error
      self.messages = []
    }
  }

  private func sendMessage() async {
    let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    let temp = ChatMessage(
      id: UUID().uuidString, text: text, sentAt: Date(), isMine: true, isRead: false)
    messages.append(temp)
    draft = ""

    do {
      guard let chatService else { return }
      let sent = try await chatService.sendMessage(conversationID: conversation.id, text: text)
      if let idx = messages.firstIndex(where: { $0.id == temp.id }) {
        messages[idx] = ChatMessage(
          id: sent.id, text: sent.text, sentAt: sent.sentAt, isMine: sent.isMine,
          isRead: sent.isRead)
      }
    } catch {
      // revert optimistic send on error
      messages.removeAll { $0.id == temp.id }
    }
  }

  private func loadMore() async {
    guard !isLoading, hasMore, let cursor else { return }
    isLoading = true
    defer { isLoading = false }
    guard let chatService else { return }
    do {
      let result = try await chatService.getMessages(
        conversationID: conversation.id, cursor: cursor)
      let older = result.items.map {
        ChatMessage(
          id: $0.id, text: $0.text, sentAt: $0.sentAt, isMine: $0.isMine, isRead: $0.isRead)
      }
      self.messages.insert(contentsOf: older, at: 0)
      self.cursor = result.cursor
      self.hasMore = (result.cursor != nil)
    } catch {
      self.error = error
    }
  }

  private func markAsRead() async {
    guard let chatService else { return }
    do {
      try await chatService.markAsRead(conversationID: conversation.id)
    } catch {
      print("Failed to mark conversation as read: \(error)")
    }
  }
}

public struct ChatMessage: Identifiable {
  public let id: String
  public let text: String
  public let sentAt: Date
  public let isMine: Bool
  public let isRead: Bool

  public var relativeTime: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: sentAt, relativeTo: Date())
  }
}
