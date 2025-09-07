import Foundation

@MainActor

@Observable
public final class NotificationPreferences {
  public static let shared = NotificationPreferences()

  private let storeKey = "postNotificationDIDs"
  private var subscribedDIDs: Set<String> = []

  private init() {
    if let saved = UserDefaults.standard.array(forKey: storeKey) as? [String] {
      subscribedDIDs = Set(saved)
    }
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
