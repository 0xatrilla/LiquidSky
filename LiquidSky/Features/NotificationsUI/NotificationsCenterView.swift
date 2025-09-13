import Client
import Models
import SwiftUI
import UserNotifications

public struct NotificationsCenterView: View {
  @State private var preferences = NotificationPreferences.shared
  @Environment(BSkyClient.self) private var client

  public init() {}

  public var body: some View {
    NavigationView {
      List {
        Section("Bluesky Notifications") {
          Toggle(
            "Notify when Bluesky notifications arrive",
            isOn: Binding(
              get: { preferences.notifyOnBlueskyNotifications },
              set: { preferences.notifyOnBlueskyNotifications = $0 }
            )
          )
        }
        Section("App Notifications") {
          Button("Request Permission") {
            UNUserNotificationCenter.current().requestAuthorization(options: [
              .alert, .sound, .badge,
            ]) { _, _ in }
          }
          Button("Send Test Notification") {
            let content = UNMutableNotificationContent()
            content.title = "Horizon"
            content.body = "Test notification from Notifications Center"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let req = UNNotificationRequest(
              identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
          }
        }

        Section("Subscribed Accounts") {
          let dids = preferences.allSubscribedDIDs()
          if dids.isEmpty {
            Text("No account notifications enabled.")
              .foregroundStyle(.secondary)
          } else {
            ForEach(dids, id: \.self) { did in
              SubscribedAccountRow(did: did, client: client) {
                preferences.toggleSubscription(for: did)
              }
            }
          }
        }

        Section("List Notifications") {
          Text("Configure list notifications from Settings → List Notifications.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        Section("Info") {
          Text(
            "You will receive a notification when a subscribed account posts. This is a local prototype; server push can be wired later."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
        }
      }
      .navigationTitle("Notifications")
    }
  }
}

// MARK: - Subscribed Account Row
private struct SubscribedAccountRow: View {
  let did: String
  let client: BSkyClient
  let onRemove: () -> Void

  @State private var profile: Profile?
  @State private var isLoading = true

  var body: some View {
    HStack(spacing: 12) {
      // Avatar
      AsyncImage(url: profile?.avatarImageURL) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Circle()
          .fill(Color.gray.opacity(0.3))
          .overlay(
            Image(systemName: "person.fill")
              .foregroundColor(.gray)
          )
      }
      .frame(width: 40, height: 40)
      .clipShape(Circle())

      // Profile info
      VStack(alignment: .leading, spacing: 2) {
        if let profile = profile {
          Text(profile.displayName ?? profile.handle)
            .font(.body)
            .fontWeight(.medium)

          Text("@\(profile.handle)")
            .font(.caption)
            .foregroundColor(.secondary)
        } else if isLoading {
          HStack(spacing: 8) {
            ProgressView()
              .scaleEffect(0.8)
            Text("Loading...")
              .font(.body)
              .foregroundColor(.secondary)
          }
        } else {
          Text(did)
            .font(.body)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      // Remove button
      Button("Remove") {
        onRemove()
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
    }
    .task {
      await loadProfile()
    }
  }

  private func loadProfile() async {
    do {
      let response = try await client.protoClient.getProfile(for: did)
      await MainActor.run {
        self.profile = response.profile
        self.isLoading = false
      }
    } catch {
      await MainActor.run {
        self.isLoading = false
      }
    }
  }
}
