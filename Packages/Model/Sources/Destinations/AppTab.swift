import AppRouter
import SwiftUI

extension EnvironmentValues {
  @Entry public var currentTab: AppTab = .feed
}

public enum AppTab: String, TabType, CaseIterable {
  case feed, notification, profile, settings, compose, bookmarks
  // TODO: Re-enable messages case when chat functionality is ready
  // case messages

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .feed: return "Home"
    // TODO: Re-enable messages case when chat functionality is ready
    // case .messages: return "Messages"
    case .notification: return "Notifications"
    case .profile: return "Profile"
    case .settings: return "Settings"
    case .compose: return "Search"
    case .bookmarks: return "Bookmarks"
    }
  }

  public var icon: String {
    switch self {
    case .feed: return "house"
    // TODO: Re-enable messages case when chat functionality is ready
    // case .messages: return "bubble.left.and.bubble.right"
    case .notification: return "bell"
    case .profile: return "person"
    case .settings: return "gearshape"
    case .compose: return "magnifyingglass"
    case .bookmarks: return "bookmark"
    }
  }
}
