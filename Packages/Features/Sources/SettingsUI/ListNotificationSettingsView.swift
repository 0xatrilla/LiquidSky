import Client
import SwiftUI
@preconcurrency import UserNotifications

public struct ListNotificationSettingsView: View {
  @Environment(BSkyClient.self) private var client
  @Environment(\.dismiss) private var dismiss

  @State private var isEnabled = false
  @State private var newMemberNotifications = true
  @State private var listUpdateNotifications = true

  public init() {}

  public var body: some View {
    NavigationView {
      Form {
        Section {
          Toggle("Enable List Notifications", isOn: $isEnabled)
        } header: {
          Text("General")
        } footer: {
          Text("Receive notifications when your lists are updated or new members are added.")
        }

        if isEnabled {
          Section {
            Toggle("New Member Notifications", isOn: $newMemberNotifications)
            Toggle("List Update Notifications", isOn: $listUpdateNotifications)
          } header: {
            Text("Notification Types")
          } footer: {
            Text("Choose which types of list changes you want to be notified about.")
          }

          Section {
            Button("Test Notification") {
              let center = UNUserNotificationCenter.current()
              center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                guard granted else { return }
                let content = UNMutableNotificationContent()
                content.title = "List Notifications"
                content.body = "This is a test notification for your list settings."
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(
                  identifier: UUID().uuidString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
              }
            }
            .foregroundColor(.blue)
          } header: {
            Text("Testing")
          } footer: {
            Text("Send a test notification to verify your settings are working correctly.")
          }
        }

        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("About List Notifications")
              .font(.headline)

            Text(
              "List notifications help you stay informed about changes to your curated lists. You'll receive notifications when:"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
              HStack {
                Image(systemName: "person.badge.plus")
                  .foregroundColor(.green)
                Text("New members are added to your lists")
              }
              .font(.caption)

              HStack {
                Image(systemName: "pencil")
                  .foregroundColor(.blue)
                Text("Lists are renamed or descriptions are updated")
              }
              .font(.caption)

              HStack {
                Image(systemName: "trash")
                  .foregroundColor(.red)
                Text("Lists are deleted")
              }
              .font(.caption)
            }
            .padding(.leading, 8)
          }
          .padding(.vertical, 8)
        } header: {
          Text("Information")
        }
      }
      .navigationTitle("List Notifications")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
      .onAppear {
        loadSettings()
      }
      .onDisappear {
        saveSettings()
      }
    }
  }

  private func loadSettings() {
    isEnabled = UserDefaults.standard.bool(forKey: "listNotificationsEnabled")
    newMemberNotifications = UserDefaults.standard.bool(forKey: "newMemberNotifications")
    listUpdateNotifications = UserDefaults.standard.bool(forKey: "listUpdateNotifications")
  }

  private func saveSettings() {
    UserDefaults.standard.set(isEnabled, forKey: "listNotificationsEnabled")
    UserDefaults.standard.set(newMemberNotifications, forKey: "newMemberNotifications")
    UserDefaults.standard.set(listUpdateNotifications, forKey: "listUpdateNotifications")
  }
}

#Preview {
  ListNotificationSettingsView()
}
