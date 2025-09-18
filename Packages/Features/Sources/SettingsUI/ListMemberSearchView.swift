import Client
import Models
import SwiftUI
import User

public struct ListMemberSearchView: View {
  let list: UserList
  @Binding var members: [ListMember]

  @State private var searchText = ""
  @State private var selectedFilter: MemberFilter = .all
  @State private var showingBulkActions = false
  @State private var selectedMembers: Set<String> = []

  public init(list: UserList, members: Binding<[ListMember]>) {
    self.list = list
    self._members = members
  }

  public var body: some View {
    VStack(spacing: 0) {
      // Search and Filter Bar
      VStack(spacing: 12) {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)

          TextField("Search members...", text: $searchText)
            .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)

        // Filter Picker
        Picker("Filter", selection: $selectedFilter) {
          Text("All").tag(MemberFilter.all)
          Text("Following").tag(MemberFilter.following)
          Text("Muted").tag(MemberFilter.muted)
          Text("Blocked").tag(MemberFilter.blocked)
        }
        .pickerStyle(.segmented)
      }
      .padding(.horizontal)
      .padding(.vertical, 8)
      .background(Color(.systemBackground))

      // Bulk Actions Bar
      if !selectedMembers.isEmpty {
        HStack {
          Text("\(selectedMembers.count) selected")
            .font(.subheadline)
            .foregroundColor(.secondary)

          Spacer()

          Button("Follow All") {
            Task {
              await performBulkAction(.follow)
            }
          }
          .buttonStyle(.bordered)

          Button("Mute All") {
            Task {
              await performBulkAction(.mute)
            }
          }
          .buttonStyle(.bordered)

          Button("Clear") {
            selectedMembers.removeAll()
          }
          .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
      }

      // Members List
      List(filteredMembers) { member in
        ListMemberRowWithSelection(
          member: member,
          isSelected: selectedMembers.contains(member.id),
          onSelectionChange: { isSelected in
            if isSelected {
              selectedMembers.insert(member.id)
            } else {
              selectedMembers.remove(member.id)
            }
          },
          onAction: { action in
            Task {
              await performAction(action, for: member)
            }
          }
        )
      }
      .listStyle(.plain)
    }
    .navigationTitle("\(list.name) Members")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(selectedMembers.isEmpty ? "Select" : "Done") {
          if selectedMembers.isEmpty {
            showingBulkActions = true
          } else {
            selectedMembers.removeAll()
          }
        }
      }
    }
  }

  private var filteredMembers: [ListMember] {
    var filtered = members

    // Apply search filter
    if !searchText.isEmpty {
      filtered = filtered.filter { member in
        member.handle.localizedCaseInsensitiveContains(searchText)
          || (member.displayName?.localizedCaseInsensitiveContains(searchText) ?? false)
          || (member.description?.localizedCaseInsensitiveContains(searchText) ?? false)
      }
    }

    // Apply status filter
    switch selectedFilter {
    case .all:
      break
    case .following:
      filtered = filtered.filter { $0.isFollowing }
    case .muted:
      filtered = filtered.filter { $0.isMuted }
    case .blocked:
      filtered = filtered.filter { $0.isBlocked }
    }

    return filtered
  }

  private func performAction(_ action: ListMemberAction, for member: ListMember) async {
    // TODO: Implement individual member actions
    #if DEBUG
    print("Would perform \(action) for \(member.handle)")
    #endif
  }

  private func performBulkAction(_ action: ListMemberAction) async {
    // TODO: Implement bulk actions
    #if DEBUG
    print("Would perform bulk \(action) for \(selectedMembers.count) members")
    #endif

    // Clear selection after bulk action
    selectedMembers.removeAll()
  }
}

// MARK: - Supporting Views and Types
private struct ListMemberRowWithSelection: View {
  let member: ListMember
  let isSelected: Bool
  let onSelectionChange: (Bool) -> Void
  let onAction: (ListMemberAction) -> Void

  var body: some View {
    HStack(spacing: 12) {
      // Selection Checkbox
      Button(action: {
        onSelectionChange(!isSelected)
      }) {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .foregroundColor(isSelected ? .blue : .secondary)
          .font(.title3)
      }
      .buttonStyle(.plain)

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

      // Status indicators
      HStack(spacing: 4) {
        if member.isFollowing {
          Image(systemName: "person.badge.plus")
            .foregroundColor(.green)
            .font(.caption)
        }
        if member.isMuted {
          Image(systemName: "speaker.slash")
            .foregroundColor(.orange)
            .font(.caption)
        }
        if member.isBlocked {
          Image(systemName: "person.slash")
            .foregroundColor(.red)
            .font(.caption)
        }
      }

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

public enum MemberFilter: CaseIterable {
  case all
  case following
  case muted
  case blocked
}
