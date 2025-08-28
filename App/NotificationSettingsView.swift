import SwiftUI
import WidgetKit
import InAppPurchase

struct NotificationSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(PushNotificationService.self) private var pushNotificationService
  @Environment(CloudKitSyncService.self) private var cloudKitSyncService
  @Environment private var purchaseService: InAppPurchaseService

  @State private var pushNotificationsEnabled = false
  @State private var iCloudSyncEnabled = false
  @State private var showTestNotification = false
  @State private var showTippingView = false

  var body: some View {
    NavigationView {
      Form {
        // Push Notifications Section
        Section("Push Notifications") {
          HStack {
            Image(systemName: "bell.badge")
              .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
              Text("Push Notifications")
                .font(.headline)
              Text("Receive real-time updates from Bluesky")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $pushNotificationsEnabled)
              .onChange(of: pushNotificationsEnabled) { _, newValue in
                if newValue {
                  Task {
                    await requestPushNotificationPermission()
                  }
                } else {
                  pushNotificationService.unregisterForRemoteNotifications()
                }
              }
          }

          if pushNotificationService.authorizationStatus == .authorized {
            HStack {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
              Text("Notifications enabled")
                .foregroundColor(.green)
            }

            Button("Send Test Notification") {
              pushNotificationService.sendTestNotification()
              showTestNotification = true
            }
            .buttonStyle(.bordered)
          } else if pushNotificationService.authorizationStatus == .denied {
            HStack {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
              Text("Notifications disabled")
                .foregroundColor(.red)
            }

            Text("Enable in Settings > Notifications > LiquidSky")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        // iCloud Sync Section
        Section("iCloud Sync") {
          HStack {
            Image(systemName: "icloud")
              .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
              Text("iCloud Sync")
                .font(.headline)
              Text("Sync preferences across devices")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $iCloudSyncEnabled)
              .onChange(of: iCloudSyncEnabled) { _, newValue in
                if newValue {
                  Task {
                    await cloudKitSyncService.performFullSync()
                  }
                }
              }
          }

          if cloudKitSyncService.isSignedInToiCloud {
            HStack {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
              Text("iCloud available")
                .foregroundColor(.green)
            }

            if let lastSync = cloudKitSyncService.lastSyncDate {
              HStack {
                Image(systemName: "clock")
                  .foregroundColor(.secondary)
                Text("Last synced: \(lastSync, style: .relative)")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }

            switch cloudKitSyncService.syncStatus {
            case .syncing:
              HStack {
                ProgressView()
                  .scaleEffect(0.8)
                Text("Syncing...")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            case .completed:
              HStack {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.green)
                Text("Sync completed")
                  .font(.caption)
                  .foregroundColor(.green)
              }
            case .failed:
              HStack {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.red)
                Text("Sync failed")
                  .font(.caption)
                  .foregroundColor(.red)
              }

              if let errorMessage = cloudKitSyncService.errorMessage {
                Text(errorMessage)
                  .font(.caption)
                  .foregroundColor(.red)
              }
            case .idle:
              EmptyView()
            }

            Button("Sync Now") {
              Task {
                await cloudKitSyncService.performFullSync()
              }
            }
            .buttonStyle(.bordered)
            .disabled(cloudKitSyncService.syncStatus == .syncing)
          } else {
            HStack {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
              Text("iCloud not available")
                .foregroundColor(.red)
            }

            Text("Sign in to iCloud in Settings to enable sync")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        // Widget Section
        Section("Widgets") {
          HStack {
            Image(systemName: "rectangle.3.group")
              .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
              Text("Home Screen Widgets")
                .font(.headline)
              Text("Add widgets to your home screen")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Button("Add Widget") {
              // This will open the widget gallery
              if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
              }
            }
            .buttonStyle(.bordered)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Available Widgets:")
              .font(.subheadline)
              .fontWeight(.medium)

            VStack(alignment: .leading, spacing: 4) {
              HStack {
                Image(systemName: "person.3.fill")
                  .foregroundColor(.blue)
                Text("Follower Count")
                Spacer()
                Text("Small, Medium")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              HStack {
                Image(systemName: "bell.fill")
                  .foregroundColor(.orange)
                Text("Recent Notification")
                Spacer()
                Text("Small, Medium")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              HStack {
                Image(systemName: "list.bullet.circle.fill")
                  .foregroundColor(.green)
                Text("Feed Updates")
                Spacer()
                Text("Medium, Large")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
            .font(.caption)
          }
        }

        // Tipping Section
        Section("Support Horizon") {
          HStack {
            Image(systemName: "heart.fill")
              .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 4) {
              Text("Send a Tip")
                .font(.headline)
              Text("Support continued development")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Button("Tip Now") {
              showTippingView = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
          }

          // Quick tip stats
          if !purchaseService.getPurchaseHistory().isEmpty {
            VStack(spacing: 8) {
              HStack {
                Text("Total Tips Sent")
                Spacer()
                Text("\(purchaseService.getPurchaseHistory().count)")
                  .fontWeight(.semibold)
              }

              HStack {
                Text("Total Amount")
                Spacer()
                Text(formatCurrency(purchaseService.getTotalTipsAmount()))
                  .fontWeight(.semibold)
                  .foregroundColor(.blue)
              }

              if let lastDate = purchaseService.getLastTipDate() {
                HStack {
                  Text("Last Tip")
                  Spacer()
                  Text(lastDate, style: .date)
                    .fontWeight(.semibold)
                }
              }
            }
            .font(.caption)
            .padding(.top, 4)
          }

          Text(
            "Tips help cover development costs and motivate continued improvements to Horizon."
          )
          .font(.caption2)
          .foregroundColor(.secondary)
          .padding(.top, 4)
        }
      }
      .navigationTitle("Notifications & Sync")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .onAppear {
      // Check current status
      pushNotificationsEnabled = pushNotificationService.authorizationStatus == .authorized
      iCloudSyncEnabled = cloudKitSyncService.isSignedInToiCloud
    }
    .alert("Test Notification", isPresented: $showTestNotification) {
      Button("OK") {}
    } message: {
      Text("A test notification has been sent. Check your notification center!")
    }
    // .sheet(isPresented: $showTippingView) {
    //   TippingView()
    //     .environment(purchaseService)
    // }
  }

  private func requestPushNotificationPermission() async {
    let granted = await pushNotificationService.requestPermission()
    await MainActor.run {
      pushNotificationsEnabled = granted
    }
  }

  private func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
  }
}

// #Preview {
//   NotificationSettingsView()
//     .environment(PushNotificationService.shared)
//     .environment(CloudKitSyncService.shared)
//     .environment(InAppPurchaseService.shared)
// }
