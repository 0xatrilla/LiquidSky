import Models
import SwiftUI

public struct NotificationsCenterView: View {
  @State private var preferences = NotificationPreferences.shared

  public init() {}

  public var body: some View {
    NavigationView {
      List {
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
