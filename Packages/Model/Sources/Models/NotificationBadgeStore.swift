import Foundation

@Observable
public final class NotificationBadgeStore {
  public nonisolated(unsafe) static let shared = NotificationBadgeStore()

  private let lastSeenKey = "notifications.lastSeen"
  private let badgeCountKey = "notifications.badge.count"

  public var unreadCount: Int {
    didSet {
      UserDefaults.standard.set(unreadCount, forKey: badgeCountKey)
    }
  }
  public var lastSeenDate: Date {
    didSet { UserDefaults.standard.set(lastSeenDate.timeIntervalSince1970, forKey: lastSeenKey) }
  }

  private init() {
    let ts = UserDefaults.standard.double(forKey: lastSeenKey)
    lastSeenDate = ts > 0 ? Date(timeIntervalSince1970: ts) : .distantPast
    unreadCount = UserDefaults.standard.integer(forKey: badgeCountKey)
  }

  public func markSeenNow() {
    lastSeenDate = Date()
    unreadCount = 0
  }

  public func incrementBadge() {
    unreadCount += 1
  }
}
