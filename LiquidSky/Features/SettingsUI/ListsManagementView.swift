import Client
import Models
import SwiftUI
import User

public struct ListsManagementView: View {
  @Environment(BSkyClient.self) private var client
  @Environment(CurrentUser.self) private var currentUser

  @State private var isLoading = false
  @State private var error: Error?
  @State private var lists: [UserList] = []
  @State private var selectedList: UserList?
  @State private var showingCreateList = false
  @State private var showingEditList: UserList?

  public init() {}

  public var body: some View {
    NavigationView {
      Group {
        if isLoading {
          ProgressView("Loading lists…")
        } else if let error {
          VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
              .font(.largeTitle)
              .foregroundStyle(.secondary)
            Text("Failed to load lists")
              .font(.headline)
            Text(error.localizedDescription)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          .padding()
        } else if lists.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "list.bullet")
              .font(.largeTitle)
              .foregroundStyle(.secondary)
            Text("No lists yet")
              .font(.headline)
            Text(
              "Create and manage lists in the official app for now. We'll add full editing soon."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
          }
          .padding()
        } else {
          List(lists) { list in
            Button(action: {
              selectedList = list
            }) {
              HStack(spacing: 12) {
                Image(systemName: icon(for: list.purpose))
                  .foregroundStyle(color(for: list.purpose))
                VStack(alignment: .leading, spacing: 2) {
                  Text(list.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                  if let desc = list.description, !desc.isEmpty {
                    Text(desc)
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                      .lineLimit(2)
                  }
                }
                Spacer()
                Text("\(list.memberCount)")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            .buttonStyle(.plain)
            .contextMenu {
              Button("Edit List") {
                showingEditList = list
              }

              Button("Delete List", role: .destructive) {
                Task {
                  await deleteList(list)
                }
              }
            }
          }
          .listStyle(.insetGrouped)
          .refreshable { await loadLists() }
        }
      }
      .navigationTitle("Lists")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: {
            showingCreateList = true
          }) {
            Image(systemName: "plus")
          }
        }
      }
      .task { await loadLists() }
      .sheet(item: $selectedList) { list in
        ListDetailView(list: list)
      }
      .sheet(isPresented: $showingCreateList) {
        CreateEditListView()
      }
      .sheet(item: $showingEditList) { list in
        CreateEditListView(list: list)
      }
    }
  }

  private func loadLists() async {
    guard !isLoading else { return }
    isLoading = true
    defer { isLoading = false }
    error = nil

    guard let actor = currentUser.profile?.actorHandle ?? currentUser.profile?.actorDID,
      !actor.isEmpty
    else {
      self.lists = []
      return
    }

    do {
      let urlStr =
        "https://public.api.bsky.app/xrpc/app.bsky.graph.getLists?actor=\(actor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? actor)&limit=50"
      guard let url = URL(string: urlStr) else {
        self.lists = []
        return
      }

      let (data, response) = try await URLSession.shared.data(from: url)
      if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
        throw URLError(.badServerResponse)
      }

      let decoded = try JSONDecoder().decode(GetListsResponse.self, from: data)
      var userLists = decoded.lists.map { $0.toUserList() }

      // Fetch member counts for each list
      for i in 0..<userLists.count {
        do {
          let memberCount = try await fetchMemberCount(for: userLists[i].id)
          userLists[i] = UserList(
            id: userLists[i].id,
            name: userLists[i].name,
            description: userLists[i].description,
            purpose: userLists[i].purpose,
            memberCount: memberCount
          )
        } catch {
          // Keep member count as 0 if fetch fails
        }
      }

      self.lists = userLists
    } catch {
      self.error = error
      self.lists = []
    }
  }

  private func fetchMemberCount(for listUri: String) async throws -> Int {
    let urlStr =
      "https://public.api.bsky.app/xrpc/app.bsky.graph.getList?list=\(listUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? listUri)&limit=1"

    guard let url = URL(string: urlStr) else {
      throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)
    if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
      throw URLError(.badServerResponse)
    }

    let decoded = try JSONDecoder().decode(ListMembersResponse.self, from: data)
    return decoded.items.count
  }

  private func deleteList(_ list: UserList) async {
    // TODO: Implement actual list deletion using ATProtoKit
    print("Would delete list: \(list.id)")

    // For now, just remove from local array
    lists.removeAll { $0.id == list.id }
  }

  private struct GetListsResponse: Decodable {
    let lists: [ListView]
  }

  private struct ListMembersResponse: Decodable {
    let items: [ListMemberItem]
    let cursor: String?
  }

  private struct ListMemberItem: Decodable {
    let subject: Subject

    struct Subject: Decodable {
      let did: String
      let handle: String
      let displayName: String?
      let description: String?
      let avatar: String?
    }
  }

  private struct ListView: Decodable {
    let uri: String
    let name: String
    let description: String?
    let purpose: String
    let viewer: Viewer?

    struct Viewer: Decodable {
      let blocked: Bool?
      let muted: Bool?
    }

    func toUserList() -> UserList {
      let purposeType: UserList.Purpose
      if purpose.contains("modlist") {
        purposeType = .moderation
      } else {
        purposeType = .curation
      }
      return UserList(
        id: uri,
        name: name,
        description: description,
        purpose: purposeType,
        memberCount: 0  // Will be updated when we fetch member count
      )
    }
  }

  private func icon(for purpose: UserList.Purpose) -> String {
    switch purpose {
    case .curation: return "star"
    case .moderation: return "hand.raised"
    case .mute: return "speaker.slash"
    case .block: return "person.slash"
    }
  }

  private func color(for purpose: UserList.Purpose) -> Color {
    switch purpose {
    case .curation: return .yellow
    case .moderation: return .orange
    case .mute: return .gray
    case .block: return .red
    }
  }
}

// Minimal local model to render lists; replace with Models types if present
public struct UserList: Identifiable {
  public enum Purpose { case curation, moderation, mute, block }
  public let id: String
  public let name: String
  public let description: String?
  public let purpose: Purpose
  public let memberCount: Int

  // Stub converter for when API becomes available
  public static func fromAPI(_ any: Any) -> UserList {
    UserList(
      id: UUID().uuidString, name: "List", description: nil, purpose: .curation, memberCount: 0)
  }
}
