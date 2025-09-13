import AppIntents
import Foundation
import SwiftUI

// MARK: - Notifications to route from shortcuts
extension Notification.Name {
  static let openComposerNewPostFromShortcut = Notification.Name("openComposerNewPostFromShortcut")
  static let openNotificationsFromShortcut = Notification.Name("openNotificationsFromShortcut")
  static let openSearchFromShortcut = Notification.Name("openSearchFromShortcut")
  static let openProfileFromShortcut = Notification.Name("openProfileFromShortcut")
  static let openFeedFromShortcut = Notification.Name("openFeedFromShortcut")
  static let notificationsUpdated = Notification.Name("notificationsUpdated")
}

// MARK: - Intents
@preconcurrency
struct NewPostIntent: AppIntent {
  nonisolated static var title: LocalizedStringResource { "New Post" }

  nonisolated static var description: IntentDescription {
    IntentDescription("Compose a new Bluesky post")
  }

  // Ensure app opens when the shortcut runs
  nonisolated static var openAppWhenRun: Bool { true }

  func perform() async throws -> some IntentResult {
    // Notify the running app to present the composer when foregrounded
    await MainActor.run {
      NotificationCenter.default.post(name: .openComposerNewPostFromShortcut, object: nil)
    }
    return .result()
  }
}

@preconcurrency
struct CheckNotificationsIntent: AppIntent {
  nonisolated static var title: LocalizedStringResource { "Check Notifications" }

  nonisolated static var description: IntentDescription {
    IntentDescription("View your latest Bluesky notifications")
  }

  nonisolated static var openAppWhenRun: Bool { true }

  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(name: .openNotificationsFromShortcut, object: nil)
    }
    return .result()
  }
}

@preconcurrency
struct SearchUsersIntent: AppIntent {
  nonisolated static var title: LocalizedStringResource { "Search Users" }

  nonisolated static var description: IntentDescription {
    IntentDescription("Search for Bluesky users")
  }

  nonisolated static var openAppWhenRun: Bool { true }

  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(name: .openSearchFromShortcut, object: nil)
    }
    return .result()
  }
}

@preconcurrency
struct ViewProfileIntent: AppIntent {
  nonisolated static var title: LocalizedStringResource { "View Profile" }

  nonisolated static var description: IntentDescription {
    IntentDescription("View your Bluesky profile")
  }

  nonisolated static var openAppWhenRun: Bool { true }

  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(name: .openProfileFromShortcut, object: nil)
    }
    return .result()
  }
}

@preconcurrency
struct CheckFeedIntent: AppIntent {
  nonisolated static var title: LocalizedStringResource { "Check Feed" }

  nonisolated static var description: IntentDescription {
    IntentDescription("View your Bluesky home feed")
  }

  nonisolated static var openAppWhenRun: Bool { true }

  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(name: .openFeedFromShortcut, object: nil)
    }
    return .result()
  }
}

// MARK: - App Shortcuts Provider
@preconcurrency
struct HorizonAppShortcuts: AppShortcutsProvider {
  // Must be a literal per AppIntents validation
  nonisolated static var shortcutTileColor: ShortcutTileColor { .blue }

  @AppShortcutsBuilder
  nonisolated static var appShortcuts: [AppIntents.AppShortcut] {
    AppIntents.AppShortcut(
      intent: SearchIntent(), phrases: ["Search in LiquidSky"], shortTitle: "Search")

    AppIntents.AppShortcut(
      intent: ToggleGlassEffectsIntent(), phrases: ["Toggle glass effects"],
      shortTitle: "Toggle Glass")

    AppIntents.AppShortcut(
      intent: GenerateAISummaryIntent(), phrases: ["Generate AI summary"],
      shortTitle: "AI Summary")
  }

  @AppShortcutsBuilder
  nonisolated static var additionalShortcuts: [AppIntents.AppShortcut] {
    AppIntents.AppShortcut(
      intent: NewPostIntent(),
      phrases: [
        "Compose with ${applicationName}",
        "New post in ${applicationName}",
        "Post using ${applicationName}",
        "Create post in ${applicationName}",
      ],
      shortTitle: "New Post",
      systemImageName: "square.and.pencil"
    )

    AppIntents.AppShortcut(
      intent: CheckNotificationsIntent(),
      phrases: [
        "Check notifications in ${applicationName}",
        "View notifications in ${applicationName}",
        "Show notifications in ${applicationName}",
        "Check ${applicationName} notifications",
      ],
      shortTitle: "Notifications",
      systemImageName: "bell.fill"
    )

    AppIntents.AppShortcut(
      intent: SearchUsersIntent(),
      phrases: [
        "Search users in ${applicationName}",
        "Find users in ${applicationName}",
        "Discover users in ${applicationName}",
        "Search ${applicationName} users",
      ],
      shortTitle: "Search Users",
      systemImageName: "magnifyingglass"
    )

    AppIntents.AppShortcut(
      intent: ViewProfileIntent(),
      phrases: [
        "View profile in ${applicationName}",
        "Show profile in ${applicationName}",
        "Open profile in ${applicationName}",
        "My profile in ${applicationName}",
      ],
      shortTitle: "View Profile",
      systemImageName: "person.circle.fill"
    )

    AppIntents.AppShortcut(
      intent: CheckFeedIntent(),
      phrases: [
        "Check feed in ${applicationName}",
        "View feed in ${applicationName}",
        "Show feed in ${applicationName}",
        "Open feed in ${applicationName}",
      ],
      shortTitle: "Check Feed",
      systemImageName: "house.fill"
    )
  }
}

@preconcurrency
struct SearchIntent: AppIntent {
  nonisolated static var title: LocalizedStringResource { "Search" }

  nonisolated static var description: IntentDescription {
    IntentDescription("Search for posts and users")
  }

  nonisolated static var openAppWhenRun: Bool { true }

  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(name: .focusSearch, object: nil)
    }
    return .result()
  }
}

@preconcurrency
struct ToggleGlassEffectsIntent: AppIntent {
  nonisolated static var title: LocalizedStringResource { "Toggle Glass Effects" }

  nonisolated static var description: IntentDescription {
    IntentDescription("Toggle glass effects on or off")
  }

  nonisolated static var openAppWhenRun: Bool { true }

  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(name: .toggleGlassEffects, object: nil)
    }
    return .result()
  }
}

@preconcurrency
struct GenerateAISummaryIntent: AppIntent {
  nonisolated static var title: LocalizedStringResource { "Generate AI Summary" }

  nonisolated static var description: IntentDescription {
    IntentDescription("Generate an AI summary of your feed")
  }

  nonisolated static var openAppWhenRun: Bool { true }

  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(name: .generateSummary, object: nil)
    }
    return .result()
  }
}
