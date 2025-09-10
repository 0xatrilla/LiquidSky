// TODO: Re-enable ConversationsView when chat functionality is ready
/*
import Client
import Models
import SwiftUI

public struct ConversationsView: View {
  @Environment(BSkyClient.self) private var client
  @State private var isLoading = false
  @State private var error: Error?
  @State private var conversations: [ConversationSummary] = []
  @State private var selectedConversation: ConversationSummary?
  @State private var showStartConversation = false
  @State private var prefillUser: (did: String, handle: String, display: String)?
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
            Text("Messages Unavailable")
              .font(.headline)
            Text(error.localizedDescription)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
            Button("Try Again") {
              Task { await reloadAll() }
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
          }
          .padding()
        } else if conversations.isEmpty {
          VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
              .font(.largeTitle)
              .foregroundStyle(.secondary)
            Text("Messages")
              .font(.title2)
              .fontWeight(.semibold)
            Text(
              "Chat functionality is currently being implemented. We're working on integrating with Bluesky's messaging system."
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            if let error {
              Text("Last error: \(error.localizedDescription)")
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            Button("Test Connection") {
              Task { await reloadAll() }
            }
            .buttonStyle(.bordered)
          }
          .padding()
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
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showStartConversation = true
          } label: {
            Image(systemName: "square.and.pencil")
          }
        }
      }
      .sheet(item: $selectedConversation) { convo in
        MessagesView(conversation: convo)
      }
      .sheet(isPresented: $showStartConversation) {
        StartConversationSheet(onSelected: { user in
          Task {
            guard let chatService else { return }
            do {
              let convo = try await chatService.getOrCreateConversation(withMembers: [user.did])
              await MainActor.run {
                self.selectedConversation = ConversationSummary(
                  id: convo.id,
                  title: user.displayName ?? user.handle,
                  lastMessagePreview: "",
                  updatedAt: Date(),
                  unreadCount: 0)
              }
            } catch {
              // ignore for now
            }
          }
        })
        .environment(client)
      }
      .onReceive(NotificationCenter.default.publisher(for: .init("startConversationWithDID"))) {
        note in
        if let ui = note.userInfo,
          let did = ui["did"] as? String,
          let handle = ui["handle"] as? String,
          let display = ui["displayName"] as? String
        {
          prefillUser = (did, handle, display)
          showStartConversation = true
        }
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
      print("📱 Loading conversations...")
      let result = try await chatService.listConversations(cursor: nil)
      print("✅ Loaded \(result.items.count) conversations")
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
      print("❌ Failed to load conversations: \(error)")
      print("Error type: \(type(of: error))")

      // Provide better error messages for common chat issues
      if let chatError = error as? ChatError {
        print("Chat error: \(chatError)")
        switch chatError {
        case .conversationNotFound:
          // This likely means chat is not available for this user
          let chatUnavailableError = NSError(
            domain: "ChatService",
            code: -1,
            userInfo: [
              NSLocalizedDescriptionKey:
                "Chat functionality is not available for your account. This feature may not be enabled yet or requires special permissions."
            ]
          )
          self.error = chatUnavailableError
        default:
          self.error = error
        }
      } else if let nsError = error as NSError? {
        print("NSError details: domain=\(nsError.domain), code=\(nsError.code)")
        if let userInfo = nsError.userInfo["NSLocalizedDescription"] as? String {
          print("Error description: \(userInfo)")
        }

        // Handle network errors specifically
        if nsError.domain == "NSURLErrorDomain" {
          let networkError = NSError(
            domain: "ChatService",
            code: -2,
            userInfo: [
              NSLocalizedDescriptionKey:
                "Network connection issue. Please check your internet connection and try again."
            ]
          )
          self.error = networkError
        } else {
          self.error = error
        }
      } else {
        self.error = error
      }

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
*/

// Temporary placeholders for compilation
import Foundation
import SwiftUI

public struct ConversationSummary: Identifiable {
  public let id: String
  public let title: String
  public let lastMessagePreview: String
  public let updatedAt: Date
  public let unreadCount: Int

  public init(
    id: String = "", title: String = "", lastMessagePreview: String = "", updatedAt: Date = Date(),
    unreadCount: Int = 0
  ) {
    self.id = id
    self.title = title
    self.lastMessagePreview = lastMessagePreview
    self.updatedAt = updatedAt
    self.unreadCount = unreadCount
  }
}

public struct ConversationsView: View {
  public init() {}

  public var body: some View {
    Text("Messages feature coming soon!")
      .font(.headline)
      .foregroundStyle(.secondary)
  }
}
