import AppIntents
import Foundation
import Intents
import IntentsUI
import SwiftUI

// MARK: - App Intents
// Note: Intent definitions are in AppShortcuts.swift

@available(iOS 18.0, *)
@Observable
class ShortcutsIntegrationManager {
  // Shortcuts state
  var availableShortcuts: [AppShortcut] = []
  var suggestedShortcuts: [AppShortcut] = []
  var userShortcuts: [UserShortcut] = []

  // Siri integration
  var siriEnabled = true
  var voiceShortcuts: [VoiceShortcut] = []

  // Usage tracking for suggestions
  private var actionUsageTracker: [String: ActionUsage] = [:]

  init() {
    setupShortcutsIntegration()
    createDefaultShortcuts()
    setupSiriIntegration()
  }

  private func setupShortcutsIntegration() {
    // Register app intents
    registerAppIntents()

    // Setup usage tracking
    setupUsageTracking()

    // Load user shortcuts
    loadUserShortcuts()
  }

  private func registerAppIntents() {
    // In a real implementation, these would be registered through the Intents framework
    // and defined in Intents.intentdefinition file
  }

  private func createDefaultShortcuts() {
    availableShortcuts = [
      AppShortcut(
        id: "new-post",
        title: "New Post",
        subtitle: "Create a new post with glass effects",
        systemImage: "plus.circle",
        intentType: "newPost",
        category: .content,
        glassEffectEnabled: true
      ),
      AppShortcut(
        id: "search",
        title: "Search",
        subtitle: "Search content with glass interface",
        systemImage: "magnifyingglass",
        intentType: "search",
        category: .navigation,
        glassEffectEnabled: true
      ),
      AppShortcut(
        id: "notifications",
        title: "Check Notifications",
        subtitle: "View notifications with glass effects",
        systemImage: "bell",
        intentType: "checkNotifications",
        category: .navigation,
        glassEffectEnabled: true
      ),
      AppShortcut(
        id: "profile",
        title: "My Profile",
        subtitle: "View your profile with glass interface",
        systemImage: "person.circle",
        intentType: "viewProfile",
        category: .navigation,
        glassEffectEnabled: true
      ),
      AppShortcut(
        id: "toggle-glass",
        title: "Toggle Glass Effects",
        subtitle: "Enable or disable liquid glass effects",
        systemImage: "sparkles",
        intentType: "toggleGlassEffects",
        category: .settings,
        glassEffectEnabled: false
      ),
      AppShortcut(
        id: "ai-summary",
        title: "AI Summary",
        subtitle: "Generate AI summary of your feed",
        systemImage: "brain",
        intentType: "generateAISummary",
        category: .content,
        glassEffectEnabled: true
      ),
    ]
  }

  private func setupSiriIntegration() {
    // Create voice shortcuts for common actions
    voiceShortcuts = [
      VoiceShortcut(
        phrase: "New post in LiquidSky",
        shortcut: availableShortcuts.first { $0.id == "new-post" }!,
        isEnabled: true
      ),
      VoiceShortcut(
        phrase: "Search LiquidSky",
        shortcut: availableShortcuts.first { $0.id == "search" }!,
        isEnabled: true
      ),
      VoiceShortcut(
        phrase: "Check my notifications",
        shortcut: availableShortcuts.first { $0.id == "notifications" }!,
        isEnabled: true
      ),
      VoiceShortcut(
        phrase: "Show my profile",
        shortcut: availableShortcuts.first { $0.id == "profile" }!,
        isEnabled: true
      ),
    ]
  }

  private func setupUsageTracking() {
    NotificationCenter.default.addObserver(
      forName: .shortcutExecuted,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      if let shortcutId = notification.userInfo?["shortcutId"] as? String {
        Task { @MainActor in
          self?.trackShortcutUsage(shortcutId)
        }
      }
    }
  }

  private func loadUserShortcuts() {
    // In a real implementation, this would load from UserDefaults or Core Data
    userShortcuts = []
  }

  // MARK: - Shortcut Execution

  func executeShortcut(_ shortcut: AppShortcut) {
    // Track usage
    trackShortcutUsage(shortcut.id)

    // Execute the intent
    executeIntent(shortcut.intent, with: shortcut)

    // Provide haptic feedback if glass effects are enabled
    if shortcut.glassEffectEnabled {
      provideGlassEffectFeedback()
    }

    // Notify observers
    NotificationCenter.default.post(
      name: .shortcutExecuted,
      object: nil,
      userInfo: [
        "shortcutId": shortcut.id,
        "shortcut": shortcut,
      ]
    )
  }

  private func executeIntent(_ intent: any AppIntent, with shortcut: AppShortcut) {
    switch intent {
    case is NewPostIntent:
      executeNewPostIntent()
    case is SearchIntent:
      executeSearchIntent()
    case is CheckNotificationsIntent:
      executeCheckNotificationsIntent()
    case is ViewProfileIntent:
      executeViewProfileIntent()
    case is ToggleGlassEffectsIntent:
      executeToggleGlassEffectsIntent()
    case is GenerateAISummaryIntent:
      executeGenerateAISummaryIntent()
    default:
      break
    }
  }

  private func executeNewPostIntent() {
    NotificationCenter.default.post(name: .newPost, object: nil)
  }

  private func executeSearchIntent() {
    NotificationCenter.default.post(name: .navigateToSearch, object: nil)
  }

  private func executeCheckNotificationsIntent() {
    NotificationCenter.default.post(name: .navigateToNotifications, object: nil)
  }

  private func executeViewProfileIntent() {
    NotificationCenter.default.post(name: .navigateToProfile, object: nil)
  }

  private func executeToggleGlassEffectsIntent() {
    NotificationCenter.default.post(
      name: .toggleGlassEffects,
      object: nil
    )
  }

  private func executeGenerateAISummaryIntent() {
    NotificationCenter.default.post(name: Notification.Name("generateSummary"), object: nil)
  }

  private func provideGlassEffectFeedback() {
    // Provide enhanced haptic feedback for glass effect shortcuts
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred(intensity: 0.7)

    // Add a subtle secondary feedback
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      let selectionFeedback = UISelectionFeedbackGenerator()
      selectionFeedback.selectionChanged()
    }
  }

  // MARK: - Usage Tracking and Suggestions

  @MainActor
  private func trackShortcutUsage(_ shortcutId: String) {
    let currentUsage = actionUsageTracker[shortcutId] ?? ActionUsage(count: 0, lastUsed: Date())

    actionUsageTracker[shortcutId] = ActionUsage(
      count: currentUsage.count + 1,
      lastUsed: Date()
    )

    // Update suggestions based on usage
    updateSuggestedShortcuts()
  }

  private func updateSuggestedShortcuts() {
    // Sort shortcuts by usage frequency and recency
    let sortedUsage = actionUsageTracker.sorted { first, second in
      let firstScore = calculateUsageScore(first.value)
      let secondScore = calculateUsageScore(second.value)
      return firstScore > secondScore
    }

    // Create suggestions from top used shortcuts
    suggestedShortcuts = sortedUsage.prefix(3).compactMap { usage in
      availableShortcuts.first { $0.id == usage.key }
    }

    // Add contextual suggestions
    addContextualSuggestions()
  }

  private func calculateUsageScore(_ usage: ActionUsage) -> Double {
    let recencyWeight = 0.7
    let frequencyWeight = 0.3

    let daysSinceLastUse = Date().timeIntervalSince(usage.lastUsed) / (24 * 60 * 60)
    let recencyScore = max(0, 1 - (daysSinceLastUse / 7))  // Decay over a week

    let frequencyScore = min(1.0, Double(usage.count) / 10.0)  // Normalize to 10 uses

    return (recencyScore * recencyWeight) + (frequencyScore * frequencyWeight)
  }

  private func addContextualSuggestions() {
    let currentHour = Calendar.current.component(.hour, from: Date())

    // Morning suggestions (6-12)
    if currentHour >= 6 && currentHour < 12 {
      if let notificationsShortcut = availableShortcuts.first(where: { $0.id == "notifications" }),
        !suggestedShortcuts.contains(where: { $0.id == "notifications" })
      {
        suggestedShortcuts.append(notificationsShortcut)
      }
    }

    // Evening suggestions (18-23)
    if currentHour >= 18 && currentHour < 23 {
      if let summaryShortcut = availableShortcuts.first(where: { $0.id == "ai-summary" }),
        !suggestedShortcuts.contains(where: { $0.id == "ai-summary" })
      {
        suggestedShortcuts.append(summaryShortcut)
      }
    }
  }

  // MARK: - Custom Shortcuts

  func createCustomShortcut(
    title: String,
    actions: [ShortcutAction],
    glassEffectEnabled: Bool = true
  ) -> UserShortcut {
    let shortcut = UserShortcut(
      id: UUID().uuidString,
      title: title,
      actions: actions,
      glassEffectEnabled: glassEffectEnabled,
      createdDate: Date()
    )

    userShortcuts.append(shortcut)
    saveUserShortcuts()

    return shortcut
  }

  func deleteCustomShortcut(_ shortcut: UserShortcut) {
    userShortcuts.removeAll { $0.id == shortcut.id }
    saveUserShortcuts()
  }

  private func saveUserShortcuts() {
    // In a real implementation, this would save to UserDefaults or Core Data
  }

  // MARK: - Siri Integration

  func addToSiri(_ shortcut: AppShortcut, phrase: String) {
    let voiceShortcut = VoiceShortcut(
      phrase: phrase,
      shortcut: shortcut,
      isEnabled: true
    )

    voiceShortcuts.append(voiceShortcut)

    // In a real implementation, this would use INVoiceShortcutCenter
    // INVoiceShortcutCenter.shared.setShortcutSuggestions([...])
  }

  func removeFromSiri(_ shortcut: AppShortcut) {
    voiceShortcuts.removeAll { $0.shortcut.id == shortcut.id }
  }

  // MARK: - Shortcuts App Integration

  func donateShortcut(_ shortcut: AppShortcut) {
    // Create an INShortcut and donate it to the system
    // This would be implemented using the Intents framework

    NotificationCenter.default.post(
      name: .shortcutDonated,
      object: nil,
      userInfo: ["shortcut": shortcut]
    )
  }

  func getShortcutSuggestions() -> [AppShortcut] {
    return suggestedShortcuts
  }
}

// MARK: - Data Models

@available(iOS 18.0, *)
struct AppShortcut: Identifiable, Hashable {
  let id: String
  let title: String
  let subtitle: String
  let systemImage: String
  let intentType: String  // Store intent type as string for Hashable compliance
  let category: ShortcutCategory
  let glassEffectEnabled: Bool

  // Computed property to create the actual intent when needed
  var intent: any AppIntent {
    switch intentType {
    case "newPost":
      return NewPostIntent()
    case "search":
      return SearchIntent()
    case "checkNotifications":
      return CheckNotificationsIntent()
    case "viewProfile":
      return ViewProfileIntent()
    case "toggleGlassEffects":
      return ToggleGlassEffectsIntent()
    case "generateAISummary":
      return GenerateAISummaryIntent()
    default:
      return NewPostIntent()  // fallback
    }
  }

  enum ShortcutCategory {
    case navigation, content, settings, social

    var displayName: String {
      switch self {
      case .navigation: return "Navigation"
      case .content: return "Content"
      case .settings: return "Settings"
      case .social: return "Social"
      }
    }
  }
}

@available(iOS 18.0, *)
struct UserShortcut: Identifiable {
  let id: String
  let title: String
  let actions: [ShortcutAction]
  let glassEffectEnabled: Bool
  let createdDate: Date
}

@available(iOS 18.0, *)
struct VoiceShortcut {
  let phrase: String
  let shortcut: AppShortcut
  let isEnabled: Bool
}

@available(iOS 18.0, *)
struct ActionUsage {
  let count: Int
  let lastUsed: Date
}

@available(iOS 18.0, *)
enum ShortcutAction {
  case navigate(String)
  case execute(String)
  case toggle(String)
  case input(String)
}

// MARK: - App Intents

// MARK: - Shortcuts Widget View

@available(iOS 18.0, *)
struct ShortcutsWidgetView: View {
  @Environment(\.shortcutsIntegrationManager) var shortcutsManager

  let maxShortcuts: Int

  init(maxShortcuts: Int = 4) {
    self.maxShortcuts = maxShortcuts
  }

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
      ForEach(shortcutsManager.suggestedShortcuts.prefix(maxShortcuts), id: \.id) { shortcut in
        ShortcutButton(shortcut: shortcut)
      }
    }
    .padding()
  }
}

@available(iOS 18.0, *)
struct ShortcutButton: View {
  let shortcut: AppShortcut
  @Environment(\.shortcutsIntegrationManager) var shortcutsManager

  var body: some View {
    Button {
      shortcutsManager.executeShortcut(shortcut)
    } label: {
      VStack(spacing: 8) {
        Image(systemName: shortcut.systemImage)
          .font(.title2)
          .foregroundStyle(.blue)

        Text(shortcut.title)
          .font(.caption.weight(.medium))
          .foregroundStyle(.primary)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity, minHeight: 60)
      .padding(12)
      .background(
        shortcut.glassEffectEnabled ? .ultraThinMaterial : .regularMaterial,
        in: RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Environment Key

@available(iOS 18.0, *)
struct ShortcutsIntegrationManagerKey: EnvironmentKey {
  static let defaultValue = ShortcutsIntegrationManager()
}

@available(iOS 18.0, *)
extension EnvironmentValues {
  var shortcutsIntegrationManager: ShortcutsIntegrationManager {
    get { self[ShortcutsIntegrationManagerKey.self] }
    set { self[ShortcutsIntegrationManagerKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let shortcutExecuted = Notification.Name("shortcutExecuted")
  static let shortcutDonated = Notification.Name("shortcutDonated")
  static let toggleGlassEffects = Notification.Name("toggleGlassEffects")
}
