import Client
import Models
import SwiftUI
import User

public struct ListDetailView: View {
  let list: UserList

  @Environment(BSkyClient.self) private var client
  @Environment(CurrentUser.self) private var currentUser
  @Environment(\.dismiss) private var dismiss

  @State private var members: [ListMember] = []
  @State private var isLoading = false
  @State private var error: Error?
  @State private var cursor: String?
  @State private var hasMore = true
  @State private var actionsService: ListMemberActionsService?

  public init(list: UserList) {
    self.list = list
  }

  public var body: some View {
    NavigationView {
      Group {
        if isLoading && members.isEmpty {
          ProgressView("Loading members...")
        } else if let error = error {
          VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
              .font(.largeTitle)
              .foregroundStyle(.secondary)
            Text("Failed to load members")
              .font(.headline)
            Text(error.localizedDescription)
              .font(.footnote)
              .foregroundStyle(.secondary)
            Button("Try Again") {
              Task { await loadMembers() }
            }
            .buttonStyle(.bordered)
          }
          .padding()
        } else if members.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "person.2")
              .font(.largeTitle)
              .foregroundStyle(.secondary)
            Text("No members")
              .font(.headline)
            Text("This list doesn't have any members yet.")
              .font(.footnote)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          .padding()
        } else {
          List {
            ForEach(members) { member in
              ListMemberRow(member: member) { action in
                Task {
                  await performAction(action, for: member)
                }
              }
            }

            if hasMore {
              HStack {
                Spacer()
                if isLoading {
                  ProgressView()
                    .scaleEffect(0.8)
                } else {
                  Button("Load More") {
                    Task { await loadMoreMembers() }
                  }
                  .buttonStyle(.bordered)
                }
                Spacer()
              }
              .listRowSeparator(.hidden)
            }
          }
          .listStyle(.insetGrouped)
          .refreshable { await loadMembers() }
        }
      }
      .navigationTitle(list.name)
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Search") {
            // TODO: Navigate to search view
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
      .task {
        actionsService = ListMemberActionsService(client: client)
        await loadMembers()
      }
    }
  }

  private func loadMembers() async {
    guard !isLoading else { return }
    isLoading = true
    error = nil
    cursor = nil
    hasMore = true

    do {
      let response = try await fetchListMembers(listUri: list.id, cursor: nil)
      self.members = response.members
      self.cursor = response.cursor
      self.hasMore = response.cursor != nil
    } catch {
      self.error = error
      self.members = []
    }

    isLoading = false
  }

  private func loadMoreMembers() async {
    guard !isLoading, hasMore, let cursor = cursor else { return }
    isLoading = true

    do {
      let response = try await fetchListMembers(listUri: list.id, cursor: cursor)
      self.members.append(contentsOf: response.members)
      self.cursor = response.cursor
      self.hasMore = response.cursor != nil
    } catch {
      self.error = error
    }

    isLoading = false
  }

  private func fetchListMembers(listUri: String, cursor: String?) async throws
    -> ListMembersResponse
  {
    let urlStr =
      "https://public.api.bsky.app/xrpc/app.bsky.graph.getList?list=\(listUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? listUri)&limit=50\(cursor != nil ? "&cursor=\(cursor!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cursor!)" : "")"

    guard let url = URL(string: urlStr) else {
      throw URLError(.badURL)
    }

    let (data, response) = try await URLSession.shared.data(from: url)
    if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
      throw URLError(.badServerResponse)
    }

    let decoded = try JSONDecoder().decode(ListMembersResponse.self, from: data)
    return decoded
  }

  private func performAction(_ action: ListMemberAction, for member: ListMember) async {
    guard let service = actionsService else { return }

    do {
      switch action {
      case .follow:
        let followUri = try await service.followUser(did: member.did)
        // Store the follow URI for future unfollow operations
        if let index = members.firstIndex(where: { $0.id == member.id }) {
          var updatedMember = members[index]
          updatedMember = ListMember(
            id: updatedMember.id,
            did: updatedMember.did,
            handle: updatedMember.handle,
            displayName: updatedMember.displayName,
            description: updatedMember.description,
            avatarURL: updatedMember.avatarURL,
            isFollowing: true,
            isMuted: updatedMember.isMuted,
            isBlocked: updatedMember.isBlocked,
            followUri: followUri,
            muteUri: updatedMember.muteUri,
            blockUri: updatedMember.blockUri
          )
          members[index] = updatedMember
        }
        return
      case .unfollow:
        guard let followUri = member.followUri else { return }
        try await service.unfollowUser(followUri: followUri)
      case .mute:
        let muteUri = try await service.muteUser(did: member.did)
        // Store the mute URI for future unmute operations
        if let index = members.firstIndex(where: { $0.id == member.id }) {
          var updatedMember = members[index]
          updatedMember = ListMember(
            id: updatedMember.id,
            did: updatedMember.did,
            handle: updatedMember.handle,
            displayName: updatedMember.displayName,
            description: updatedMember.description,
            avatarURL: updatedMember.avatarURL,
            isFollowing: updatedMember.isFollowing,
            isMuted: true,
            isBlocked: updatedMember.isBlocked,
            followUri: updatedMember.followUri,
            muteUri: muteUri,
            blockUri: updatedMember.blockUri
          )
          members[index] = updatedMember
        }
        return
      case .unmute:
        guard let muteUri = member.muteUri else { return }
        try await service.unmuteUser(muteUri: muteUri)
      case .block:
        let blockUri = try await service.blockUser(did: member.did)
        // Store the block URI for future unblock operations
        if let index = members.firstIndex(where: { $0.id == member.id }) {
          var updatedMember = members[index]
          updatedMember = ListMember(
            id: updatedMember.id,
            did: updatedMember.did,
            handle: updatedMember.handle,
            displayName: updatedMember.displayName,
            description: updatedMember.description,
            avatarURL: updatedMember.avatarURL,
            isFollowing: updatedMember.isFollowing,
            isMuted: updatedMember.isMuted,
            isBlocked: true,
            followUri: updatedMember.followUri,
            muteUri: updatedMember.muteUri,
            blockUri: blockUri
          )
          members[index] = updatedMember
        }
        return
      case .unblock:
        guard let blockUri = member.blockUri else { return }
        try await service.unblockUser(blockUri: blockUri)
      }

      // Update the member's state in the UI for unfollow/unmute/unblock actions
      if let index = members.firstIndex(where: { $0.id == member.id }) {
        var updatedMember = members[index]
        switch action {
        case .unfollow:
          updatedMember = ListMember(
            id: updatedMember.id,
            did: updatedMember.did,
            handle: updatedMember.handle,
            displayName: updatedMember.displayName,
            description: updatedMember.description,
            avatarURL: updatedMember.avatarURL,
            isFollowing: false,
            isMuted: updatedMember.isMuted,
            isBlocked: updatedMember.isBlocked,
            followUri: nil,
            muteUri: updatedMember.muteUri,
            blockUri: updatedMember.blockUri
          )
        case .unmute:
          updatedMember = ListMember(
            id: updatedMember.id,
            did: updatedMember.did,
            handle: updatedMember.handle,
            displayName: updatedMember.displayName,
            description: updatedMember.description,
            avatarURL: updatedMember.avatarURL,
            isFollowing: updatedMember.isFollowing,
            isMuted: false,
            isBlocked: updatedMember.isBlocked,
            followUri: updatedMember.followUri,
            muteUri: nil,
            blockUri: updatedMember.blockUri
          )
        case .unblock:
          updatedMember = ListMember(
            id: updatedMember.id,
            did: updatedMember.did,
            handle: updatedMember.handle,
            displayName: updatedMember.displayName,
            description: updatedMember.description,
            avatarURL: updatedMember.avatarURL,
            isFollowing: updatedMember.isFollowing,
            isMuted: updatedMember.isMuted,
            isBlocked: false,
            followUri: updatedMember.followUri,
            muteUri: updatedMember.muteUri,
            blockUri: nil
          )
        default:
          break  // Follow/mute/block actions are handled above
        }
        members[index] = updatedMember
      }
    } catch {
      print("Failed to perform \(action) for \(member.handle): \(error)")
      // TODO: Show error to user
    }
  }
}

// MARK: - List Member Row
private struct ListMemberRow: View {
  let member: ListMember
  let onAction: (ListMemberAction) -> Void

  @State private var showingActions = false

  var body: some View {
    HStack(spacing: 12) {
      // Avatar
      AsyncImage(url: member.avatarURL) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Image(systemName: "person.circle.fill")
          .foregroundColor(.secondary)
      }
      .frame(width: 44, height: 44)
      .clipShape(Circle())

      // Member info
      VStack(alignment: .leading, spacing: 2) {
        Text(member.displayName ?? member.handle)
          .font(.headline)
          .lineLimit(1)

        Text("@\(member.handle)")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .lineLimit(1)

        if let description = member.description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
      }

      Spacer()

      // Action button
      Menu {
        if member.isFollowing {
          Button("Unfollow") {
            onAction(.unfollow)
          }
        } else {
          Button("Follow") {
            onAction(.follow)
          }
        }

        if member.isMuted {
          Button("Unmute") {
            onAction(.unmute)
          }
        } else {
          Button("Mute") {
            onAction(.mute)
          }
        }

        if member.isBlocked {
          Button("Unblock") {
            onAction(.unblock)
          }
        } else {
          Button("Block", role: .destructive) {
            onAction(.block)
          }
        }
      } label: {
        Image(systemName: "ellipsis")
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Data Models
public struct ListMember: Identifiable {
  public let id: String
  public let did: String
  public let handle: String
  public let displayName: String?
  public let description: String?
  public let avatarURL: URL?
  public let isFollowing: Bool
  public let isMuted: Bool
  public let isBlocked: Bool
  public let followUri: String?
  public let muteUri: String?
  public let blockUri: String?
}

public enum ListMemberAction {
  case follow
  case unfollow
  case mute
  case unmute
  case block
  case unblock
}

private struct ListMembersResponse: Decodable {
  let items: [ListMemberItem]
  let cursor: String?

  var members: [ListMember] {
    items.map { $0.toListMember() }
  }
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

  func toListMember() -> ListMember {
    return ListMember(
      id: subject.did,
      did: subject.did,
      handle: subject.handle,
      displayName: subject.displayName,
      description: subject.description,
      avatarURL: subject.avatar.flatMap(URL.init),
      isFollowing: false,  // TODO: Get from viewer data
      isMuted: false,  // TODO: Get from viewer data
      isBlocked: false,  // TODO: Get from viewer data
      followUri: nil,  // TODO: Get from viewer data
      muteUri: nil,  // TODO: Get from viewer data
      blockUri: nil  // TODO: Get from viewer data
    )
  }
}
