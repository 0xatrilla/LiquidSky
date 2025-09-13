import Client
import Foundation
import UserNotifications

@MainActor
public class ListNotificationService: ObservableObject {
  private let client: BSkyClient
  private let notificationCenter = UNUserNotificationCenter.current()

  @Published public var isEnabled = false
  @Published public var newMemberNotifications = true
  @Published public var listUpdateNotifications = true

  public init(client: BSkyClient) {
    self.client = client
    loadSettings()
  }

  // MARK: - Settings Management
  private func loadSettings() {
    // Load from UserDefaults
    isEnabled = UserDefaults.standard.bool(forKey: "listNotificationsEnabled")
    newMemberNotifications = UserDefaults.standard.bool(forKey: "newMemberNotifications")
    listUpdateNotifications = UserDefaults.standard.bool(forKey: "listUpdateNotifications")
  }

  public func updateSettings(
    enabled: Bool,
    newMembers: Bool,
    updates: Bool
  ) {
    isEnabled = enabled
    newMemberNotifications = newMembers
    listUpdateNotifications = updates

    // Save to UserDefaults
    UserDefaults.standard.set(enabled, forKey: "listNotificationsEnabled")
    UserDefaults.standard.set(newMembers, forKey: "newMemberNotifications")
    UserDefaults.standard.set(updates, forKey: "listUpdateNotifications")

    if enabled {
      Task {
        await requestNotificationPermission()
      }
    }
  }

  // MARK: - Permission Management
  public func requestNotificationPermission() async {
    do {
      let granted = try await notificationCenter.requestAuthorization(options: [
        .alert, .badge, .sound,
      ])
      if !granted {
        isEnabled = false
        UserDefaults.standard.set(false, forKey: "listNotificationsEnabled")
      }
    } catch {
      print("Failed to request notification permission: \(error)")
    }
  }

  // MARK: - Notification Sending
  public func sendNewMemberNotification(listName: String, memberHandle: String) {
    guard isEnabled && newMemberNotifications else { return }

    let content = UNMutableNotificationContent()
    content.title = "New List Member"
    content.body = "@\(memberHandle) was added to your list \"\(listName)\""
    content.sound = .default
    content.badge = 1

    let request = UNNotificationRequest(
      identifier: "new-member-\(UUID().uuidString)",
      content: content,
      trigger: nil
    )

    notificationCenter.add(request) { error in
      if let error = error {
        print("Failed to send new member notification: \(error)")
      }
    }
  }

  public func sendListUpdateNotification(listName: String, updateType: ListUpdateType) {
    guard isEnabled && listUpdateNotifications else { return }

    let content = UNMutableNotificationContent()
    content.title = "List Updated"
    content.body = "Your list \"\(listName)\" was \(updateType.description)"
    content.sound = .default
    content.badge = 1

    let request = UNNotificationRequest(
      identifier: "list-update-\(UUID().uuidString)",
      content: content,
      trigger: nil
    )

    notificationCenter.add(request) { error in
      if let error = error {
        print("Failed to send list update notification: \(error)")
      }
    }
  }

  // MARK: - Background Monitoring
  public func startMonitoring() {
    guard isEnabled else { return }

    // TODO: Implement background monitoring of list changes
    // This would involve setting up a background task or push notification handling
    print("Starting list change monitoring...")
  }

  public func stopMonitoring() {
    // TODO: Stop background monitoring
    print("Stopping list change monitoring...")
  }
}

public enum ListUpdateType {
  case created
  case updated
  case deleted
  case memberAdded
  case memberRemoved

  var description: String {
    switch self {
    case .created:
      return "created"
    case .updated:
      return "updated"
    case .deleted:
      return "deleted"
    case .memberAdded:
      return "updated with new members"
    case .memberRemoved:
      return "updated with members removed"
    }
  }
}
