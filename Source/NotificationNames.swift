import Foundation

// MARK: - Notification Names
// Centralized definition of all notification names used in the app

extension Notification.Name {
  // Navigation notifications
  static let navigateToFeed = Notification.Name("navigateToFeed")
  static let navigateToSearch = Notification.Name("navigateToSearch")
  static let navigateToProfile = Notification.Name("navigateToProfile")
  static let navigateToNotifications = Notification.Name("navigateToNotifications")
  static let navigateToSettings = Notification.Name("navigateToSettings")

  // Action notifications
  static let focusSearch = Notification.Name("focusSearch")
  static let refresh = Notification.Name("refresh")
  static let toggleSidebar = Notification.Name("toggleSidebar")
  static let newPost = Notification.Name("newPost")
  
  // User interaction notifications
  static let userDidFollow = Notification.Name("userDidFollow")
  static let userDidUnfollow = Notification.Name("userDidUnfollow")

  // App-specific notifications (defined in their respective files)
  // generateSummary - defined in SidebarNavigationView.swift
  // showKeyboardShortcuts - defined in SidebarNavigationView.swift
  // toggleGlassEffects - defined in ShortcutsIntegration.swift
  // shareCompleted - defined in SharingIntegration.swift
}
