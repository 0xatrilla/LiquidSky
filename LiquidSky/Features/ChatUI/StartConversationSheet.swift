// TODO: Re-enable StartConversationSheet when chat functionality is ready
/*
import ATProtoKit
import Client
import Models
import SwiftUI

public struct StartConversationSheet: View {
  @Environment(BSkyClient.self) private var client
  @Environment(\.dismiss) private var dismiss
  @State private var query: String = ""
  @State private var results: [SearchUser] = []
  @State private var isSearching = false

  public struct SearchUser: Identifiable, Sendable {
    public let id: String
    public let did: String
    public let handle: String
    public let displayName: String?

    public var displayNameOrHandle: String {
      if let displayName = displayName, !displayName.isEmpty {
        return displayName
      }
      return handle
    }
  }

  let onSelected: (SearchUser) -> Void

  public init(onSelected: @escaping (SearchUser) -> Void) {
    self.onSelected = onSelected
  }

  public var body: some View {
    NavigationStack {
      VStack {
        HStack {
          TextField("Search users", text: $query)
            .textFieldStyle(.roundedBorder)
          if isSearching { ProgressView().scaleEffect(0.8) }
        }
        .padding()

        List(results, id: \.id) { user in
          Button {
            onSelected(user)
            dismiss()
          } label: {
            HStack {
              Text(user.displayNameOrHandle)
              Spacer()
              Text("@\(user.handle)").foregroundStyle(.secondary)
            }
          }
        }
        .listStyle(.plain)
      }
      .navigationTitle("New Message")
      .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
      .task(id: query) {
        await search()
      }
    }
  }

  private func search() async {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      results = []
      return
    }
    isSearching = true
    defer { isSearching = false }
    do {
      let actors = try await client.protoClient.searchActors(matching: trimmed, limit: 20)
      // Map search results to our SearchUser struct
      results = actors.actors.map { actor in
        SearchUser(
          id: actor.actorDID,
          did: actor.actorDID,
          handle: actor.actorHandle,
          displayName: actor.displayName
        )
      }
    } catch {
      results = []
    }
  }
}
*/

// Temporary placeholder StartConversationSheet for compilation
import SwiftUI

public struct StartConversationSheet: View {
  let onSelected: (SearchUser) -> Void

  public init(onSelected: @escaping (SearchUser) -> Void) {
    self.onSelected = onSelected
  }

  public var body: some View {
    Text("Messages feature coming soon!")
      .font(.headline)
      .foregroundStyle(.secondary)
  }
}

public struct SearchUser: Identifiable, Sendable {
  public let id: String
  public let did: String
  public let handle: String
  public let displayName: String?

  public init(id: String = "", did: String = "", handle: String = "", displayName: String? = nil) {
    self.id = id
    self.did = did
    self.handle = handle
    self.displayName = displayName
  }

  public var displayNameOrHandle: String {
    displayName ?? handle
  }
}
