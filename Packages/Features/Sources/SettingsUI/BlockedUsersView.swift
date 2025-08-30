import DesignSystem
import Models
import SwiftUI

public struct BlockedUsersView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var blockedUsersService = BlockedUsersService.shared
  @State private var selectedTab = 0

  public init() {}

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Tab Picker
        Picker("", selection: $selectedTab) {
          Text("Blocked (\(blockedUsersService.blockedUsers.count))")
            .tag(0)
          Text("Muted (\(blockedUsersService.mutedUsers.count))")
            .tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()

        // Content
        TabView(selection: $selectedTab) {
          blockedUsersTab
            .tag(0)

          mutedUsersTab
            .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      }
      .navigationTitle("Blocked & Muted Users")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }

  private var blockedUsersTab: some View {
    Group {
      if blockedUsersService.blockedUsers.isEmpty {
        emptyStateView(
          title: "No Blocked Users",
          message:
            "Users you block won't appear in your feeds and won't be able to interact with you.",
          icon: "person.slash"
        )
      } else {
        List {
          ForEach(blockedUsersService.blockedUsers) { user in
            BlockedUserRow(
              user: user,
              onUnblock: {
                blockedUsersService.unblockUser(did: user.did)
              }
            )
          }
        }
      }
    }
  }

  private var mutedUsersTab: some View {
    Group {
      if blockedUsersService.mutedUsers.isEmpty {
        emptyStateView(
          title: "No Muted Users",
          message: "Users you mute won't appear in your feeds but can still interact with you.",
          icon: "speaker.slash"
        )
      } else {
        List {
          ForEach(blockedUsersService.mutedUsers) { user in
            MutedUserRow(
              user: user,
              onUnmute: {
                blockedUsersService.unmuteUser(did: user.did)
              }
            )
          }
        }
      }
    }
  }

  private func emptyStateView(title: String, message: String, icon: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: icon)
        .font(.system(size: 48))
        .foregroundColor(.secondary)

      Text(title)
        .font(.title2)
        .fontWeight(.semibold)

      Text(message)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
  }
}

// MARK: - Blocked User Row

private struct BlockedUserRow: View {
  let user: BlockedUser
  let onUnblock: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("@\(user.handle)")
          .font(.body)
          .fontWeight(.medium)

        Text("Blocked \(timeAgoString(from: user.timestamp))")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      Button("Unblock") {
        onUnblock()
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
    }
    .padding(.vertical, 4)
  }

  private func timeAgoString(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
  }
}

// MARK: - Muted User Row

private struct MutedUserRow: View {
  let user: MutedUser
  let onUnmute: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("@\(user.handle)")
          .font(.body)
          .fontWeight(.medium)

        Text("Muted \(timeAgoString(from: user.timestamp))")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      Button("Unmute") {
        onUnmute()
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
    }
    .padding(.vertical, 4)
  }

  private func timeAgoString(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
  }
}

#Preview {
  BlockedUsersView()
}
