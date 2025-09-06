import Client
import Models
import SwiftUI

public struct ConversationsView: View {
  @Environment(BSkyClient.self) private var client
  @State private var isLoading = false
  @State private var error: Error?
  @State private var conversations: [ConversationSummary] = []
  @State private var selectedConversation: ConversationSummary?
  @State private var chatService: ChatService?
  @State private var cursor: String?
  @State private var hasMore = true

  public init() {}

  public var body: some View {
    NavigationView {
      Group {
        if isLoading && conversations.isEmpty {
          ProgressView("Loading conversations…")
        } else if let error {
          VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
              .font(.largeTitle)
              .foregroundStyle(.secondary)
            Text("Failed to load conversations")
              .font(.headline)
            Text(error.localizedDescription)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          .padding()
        } else if conversations.isEmpty {
          ContentUnavailableView(
            "No Conversations",
            systemImage: "bubble.left.and.bubble.right",
            description: Text("Start a new conversation from a user's profile.")
          )
        } else {
          List {
            ForEach(conversations) { convo in
              Button {
                selectedConversation = convo
              } label: {
                HStack(spacing: 12) {
                  Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(.blue)
                  VStack(alignment: .leading, spacing: 2) {
                    HStack {
                      Text(convo.title)
                        .font(.headline)
                        .lineLimit(1)
                      if convo.unreadCount > 0 {
                        Text("\(convo.unreadCount)")
                          .font(.caption)
                          .fontWeight(.semibold)
                          .foregroundColor(.white)
                          .padding(.horizontal, 6)
                          .padding(.vertical, 2)
                          .background(Color.blue)
                          .clipShape(Capsule())
                      }
                      Spacer()
                    }
                    Text(convo.lastMessagePreview)
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                      .lineLimit(2)
                  }
                  Spacer()
                  VStack(alignment: .trailing, spacing: 2) {
                    Text(convo.relativeTime)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                    if convo.unreadCount > 0 {
                      Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    }
                  }
                }
              }
              .buttonStyle(.plain)
            }

            if hasMore {
              HStack {
                Spacer()
                if isLoading {
                  ProgressView().scaleEffect(0.8)
                } else {
                  Button("Load More") { Task { await loadMore() } }
                    .buttonStyle(.bordered)
                }
                Spacer()
              }
              .listRowSeparator(.hidden)
            }
          }
          .listStyle(.insetGrouped)
          .refreshable { await reloadAll() }
        }
      }
      .navigationTitle("Messages")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            // TODO: start new message flow
          } label: {
            Image(systemName: "square.and.pencil")
          }
        }
      }
      .sheet(item: $selectedConversation) { convo in
        MessagesView(conversation: convo)
      }
      .task {
        chatService = ChatService(client: client)
        await reloadAll()
      }
    }
  }

  private func reloadAll() async {
    guard !isLoading else { return }
    isLoading = true
    defer { isLoading = false }
    error = nil
    cursor = nil
    hasMore = true

    guard let chatService else {
      self.conversations = []
      return
    }
    do {
      let result = try await chatService.listConversations(cursor: nil)
      self.conversations = result.items.map { convo in
        ConversationSummary(
          id: convo.id,
          title: convo.title.isEmpty ? "Conversation" : convo.title,
          lastMessagePreview: convo.lastMessagePreview,
          updatedAt: convo.updatedAt,
          unreadCount: convo.unreadCount
        )
      }
      self.cursor = result.cursor
      self.hasMore = (result.cursor != nil)
    } catch {
      self.error = error
      self.conversations = []
    }
  }

  private func loadConversations() async { await reloadAll() }

  private func loadMore() async {
    guard !isLoading, hasMore, let cursor else { return }
    isLoading = true
    defer { isLoading = false }
    guard let chatService else { return }
    do {
      let result = try await chatService.listConversations(cursor: cursor)
      let more = result.items.map { convo in
        ConversationSummary(
          id: convo.id,
          title: convo.title.isEmpty ? "Conversation" : convo.title,
          lastMessagePreview: convo.lastMessagePreview,
          updatedAt: convo.updatedAt,
          unreadCount: convo.unreadCount
        )
      }
      self.conversations.append(contentsOf: more)
      self.cursor = result.cursor
      self.hasMore = (result.cursor != nil)
    } catch {
      self.error = error
    }
  }
}

public struct ConversationSummary: Identifiable {
  public let id: String
  public let title: String
  public let lastMessagePreview: String
  public let updatedAt: Date
  public let unreadCount: Int

  public var relativeTime: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: updatedAt, relativeTo: Date())
  }
}
