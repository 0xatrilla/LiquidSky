import Foundation
import UserNotifications

public final class PostNotificationManager {
  public static let shared = PostNotificationManager()

  private let center = UNUserNotificationCenter.current()
  private let seenKey = "notified.post.uris"
  private var seenURIs: Set<String>

  private init() {
    if let arr = UserDefaults.standard.array(forKey: seenKey) as? [String] {
      seenURIs = Set(arr)
    } else {
      seenURIs = []
    }
  }

  public func process(posts: [PostItem]) {
    let prefs = NotificationPreferences.shared
    guard !posts.isEmpty else { return }

    for post in posts {
      guard !seenURIs.contains(post.uri) else { continue }
      guard prefs.isSubscribed(to: post.author.did) else { continue }

      let title = post.author.displayName ?? "@\(post.author.handle)"
      let body = truncate(post.content, to: 140)

      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default

      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      let request = UNNotificationRequest(
        identifier: post.uri,
        content: content,
        trigger: trigger
      )
      center.add(request)

      seenURIs.insert(post.uri)
    }

    UserDefaults.standard.set(Array(seenURIs), forKey: seenKey)
  }

  private func truncate(_ text: String, to max: Int) -> String {
    guard text.count > max else { return text }
    let idx = text.index(text.startIndex, offsetBy: max)
    let prefix = text[..<idx]
    if let lastSpace = prefix.lastIndex(of: " ") {
      return String(prefix[..<lastSpace]) + "…"
    }
    return String(prefix) + "…"
  }
}


