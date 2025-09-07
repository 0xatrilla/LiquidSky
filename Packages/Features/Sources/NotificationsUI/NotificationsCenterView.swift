import Models
import SettingsUI
import SwiftUI
import UserNotifications

public struct NotificationsCenterView: View {
  @State private var preferences = NotificationPreferences.shared

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
              HStack {
                Text(did)
                Spacer()
                Button("Remove") {
                  preferences.toggleSubscription(for: did)
                }
                .buttonStyle(.bordered)
              }
            }
          }
        }

        Section("List Notifications") {
          NavigationLink("Open List Notification Settings") {
            ListNotificationSettingsView()
          }
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
