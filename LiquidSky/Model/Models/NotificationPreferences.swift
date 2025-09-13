import Foundation

@MainActor

@Observable
public final class NotificationPreferences {
  public static let shared = NotificationPreferences()

  private let storeKey = "postNotificationDIDs"
  private let blueskyNotifKey = "notifyOnBlueskyNotifications"
  private var subscribedDIDs: Set<String> = []
  public var notifyOnBlueskyNotifications: Bool {
    didSet { UserDefaults.standard.set(notifyOnBlueskyNotifications, forKey: blueskyNotifKey) }
  }

  private init() {
    if let saved = UserDefaults.standard.array(forKey: storeKey) as? [String] {
      subscribedDIDs = Set(saved)
    }
    notifyOnBlueskyNotifications = UserDefaults.standard.bool(forKey: blueskyNotifKey)
  }

  public func isSubscribed(to did: String) -> Bool {
    subscribedDIDs.contains(did)
  }

  public func toggleSubscription(for did: String) {
    if subscribedDIDs.contains(did) {
      subscribedDIDs.remove(did)
    } else {
      subscribedDIDs.insert(did)
    }
    persist()
  }

  public func allSubscribedDIDs() -> [String] {
    Array(subscribedDIDs)
  }

  private func persist() {
    UserDefaults.standard.set(Array(subscribedDIDs), forKey: storeKey)
  }
}
