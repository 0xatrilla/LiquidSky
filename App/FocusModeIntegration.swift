import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
@Observable
@MainActor
class FocusModeManager {
  // Focus mode state
  var currentFocusMode: FocusMode?
  var isFocusModeActive = false
  var focusModeConfigurations: [String: FocusModeConfiguration] = [:]

  // UI adaptations
  var adaptedGlassEffects: GlassEffectConfiguration?
  var filteredNotifications: [String] = []
  var hiddenUIElements: Set<String> = []

  // Focus-specific settings
  var allowedInteractions: Set<InteractionType> = []
  var reducedAnimations = false
  var minimalistMode = false

  init() {
    setupFocusModeIntegration()
    createDefaultConfigurations()
  }

  private func setupFocusModeIntegration() {
    // Monitor Focus mode changes
    NotificationCenter.default.addObserver(
      forName: .focusModeDidChange,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        await self?.checkAndUpdateFocusMode()
      }
    }

    // Check current Focus mode
    checkCurrentFocusMode()
  }

  private func createDefaultConfigurations() {
    focusModeConfigurations = [
      "work": FocusModeConfiguration(
        id: "work",
        name: "Work",
        glassEffectLevel: .minimal,
        allowedNotifications: ["mentions", "direct-messages"],
        hiddenElements: ["trending", "suggestions", "ads"],
        allowedInteractions: [.reading, .composing, .searching],
        colorScheme: .neutral,
        reducedAnimations: true
      ),
      "personal": FocusModeConfiguration(
        id: "personal",
        name: "Personal",
        glassEffectLevel: .standard,
        allowedNotifications: ["all"],
        hiddenElements: ["work-related"],
        allowedInteractions: [.reading, .composing, .browsing, .social],
        colorScheme: .vibrant,
        reducedAnimations: false
      ),
      "sleep": FocusModeConfiguration(
        id: "sleep",
        name: "Sleep",
        glassEffectLevel: .disabled,
        allowedNotifications: ["emergency"],
        hiddenElements: ["all-content"],
        allowedInteractions: [.emergency],
        colorScheme: .dark,
        reducedAnimations: true
      ),
      "driving": FocusModeConfiguration(
        id: "driving",
        name: "Driving",
        glassEffectLevel: .minimal,
        allowedNotifications: ["navigation", "emergency"],
        hiddenElements: ["media", "social"],
        allowedInteractions: [.voice],
        colorScheme: .highContrast,
        reducedAnimations: true
      ),
      "fitness": FocusModeConfiguration(
        id: "fitness",
        name: "Fitness",
        glassEffectLevel: .enhanced,
        allowedNotifications: ["health", "fitness"],
        hiddenElements: ["social", "news"],
        allowedInteractions: [.reading, .tracking],
        colorScheme: .energetic,
        reducedAnimations: false
      ),
      "mindfulness": FocusModeConfiguration(
        id: "mindfulness",
        name: "Mindfulness",
        glassEffectLevel: .subtle,
        allowedNotifications: ["none"],
        hiddenElements: ["distracting-content"],
        allowedInteractions: [.reading, .meditation],
        colorScheme: .calm,
        reducedAnimations: true
      ),
    ]
  }

  private func checkCurrentFocusMode() {
    // In a real implementation, this would check the system Focus mode
    // For now, we'll simulate it
    currentFocusMode = nil
    isFocusModeActive = false
  }

  @MainActor
  private func checkAndUpdateFocusMode() async {
    // In a real implementation, this would check the system Focus mode
    // For now, we'll simulate it by checking if there's a current focus mode
    if currentFocusMode == nil {
      // Focus mode disabled
      disableFocusMode()
    } else {
      // Focus mode is active, keep current state
      // In a real implementation, you would check the actual system focus mode here
    }
  }

  @MainActor
  private func handleFocusModeChange(focusModeId: String?) async {
    guard let focusModeId = focusModeId else {
      // Focus mode disabled
      disableFocusMode()
      return
    }

    enableFocusMode(focusModeId)
  }

  // MARK: - Focus Mode Management

  func enableFocusMode(_ focusModeId: String) {
    guard let configuration = focusModeConfigurations[focusModeId] else { return }

    currentFocusMode = FocusMode(
      id: focusModeId,
      name: configuration.name,
      isActive: true,
      startTime: Date()
    )

    isFocusModeActive = true

    // Apply configuration
    applyFocusModeConfiguration(configuration)

    // Notify UI components
    NotificationCenter.default.post(
      name: .focusModeActivated,
      object: nil,
      userInfo: [
        "focusMode": currentFocusMode!,
        "configuration": configuration,
      ]
    )
  }

  func disableFocusMode() {
    guard let focusMode = currentFocusMode else { return }

    currentFocusMode = nil
    isFocusModeActive = false

    // Reset to default configuration
    resetToDefaultConfiguration()

    // Notify UI components
    NotificationCenter.default.post(
      name: .focusModeDeactivated,
      object: nil,
      userInfo: ["previousFocusMode": focusMode]
    )
  }

  private func applyFocusModeConfiguration(_ configuration: FocusModeConfiguration) {
    // Apply glass effect configuration
    adaptedGlassEffects = GlassEffectConfiguration(
      level: configuration.glassEffectLevel,
      colorScheme: configuration.colorScheme
    )

    // Filter notifications
    filteredNotifications = filterNotifications(configuration.allowedNotifications)

    // Hide UI elements
    hiddenUIElements = Set(configuration.hiddenElements)

    // Set allowed interactions
    allowedInteractions = configuration.allowedInteractions

    // Apply animation settings
    reducedAnimations = configuration.reducedAnimations

    // Set minimalist mode for certain focus modes
    minimalistMode =
      configuration.glassEffectLevel == .minimal || configuration.glassEffectLevel == .disabled

    // Apply color scheme
    applyColorScheme(configuration.colorScheme)
  }

  private func resetToDefaultConfiguration() {
    adaptedGlassEffects = nil
    filteredNotifications = []
    hiddenUIElements = []
    allowedInteractions = Set(InteractionType.allCases)
    reducedAnimations = false
    minimalistMode = false
  }

  private func filterNotifications(_ allowedTypes: [String]) -> [String] {
    // In a real implementation, this would filter actual notifications
    return allowedTypes
  }

  private func applyColorScheme(_ scheme: FocusColorScheme) {
    NotificationCenter.default.post(
      name: .focusModeColorSchemeChanged,
      object: nil,
      userInfo: ["colorScheme": scheme]
    )
  }

  // MARK: - UI Adaptation Helpers

  func shouldHideElement(_ elementId: String) -> Bool {
    return hiddenUIElements.contains(elementId) || hiddenUIElements.contains("all-content")
  }

  func isInteractionAllowed(_ interaction: InteractionType) -> Bool {
    return allowedInteractions.contains(interaction) || allowedInteractions.contains(.emergency)
  }

  func getAdaptedGlassEffect() -> Material? {
    guard let config = adaptedGlassEffects else { return nil }

    switch config.level {
    case .disabled:
      return nil
    case .minimal:
      return .thinMaterial
    case .subtle:
      return .regularMaterial
    case .standard:
      return .thickMaterial
    case .enhanced:
      return .ultraThickMaterial
    }
  }

  func shouldUseReducedAnimations() -> Bool {
    return reducedAnimations
  }

  func shouldUseMinimalistMode() -> Bool {
    return minimalistMode
  }

  // MARK: - Focus Mode Suggestions

  func suggestFocusMode(basedOn context: FocusContext) -> String? {
    let currentHour = Calendar.current.component(.hour, from: Date())
    let currentWeekday = Calendar.current.component(.weekday, from: Date())

    // Work hours suggestion (Monday-Friday, 9-17)
    if currentWeekday >= 2 && currentWeekday <= 6 && currentHour >= 9 && currentHour <= 17 {
      return "work"
    }

    // Sleep time suggestion (22-6)
    if currentHour >= 22 || currentHour <= 6 {
      return "sleep"
    }

    // Based on context
    switch context {
    case .calendar(let event):
      if event.contains("workout") || event.contains("gym") {
        return "fitness"
      } else if event.contains("meeting") || event.contains("work") {
        return "work"
      } else if event.contains("meditation") || event.contains("mindfulness") {
        return "mindfulness"
      }
    case .location(let location):
      if location.contains("gym") || location.contains("fitness") {
        return "fitness"
      } else if location.contains("office") || location.contains("work") {
        return "work"
      }
    case .activity(let activity):
      if activity == "driving" {
        return "driving"
      } else if activity == "exercising" {
        return "fitness"
      }
    }

    return nil
  }

  // MARK: - Custom Focus Modes

  func createCustomFocusMode(
    name: String,
    glassEffectLevel: GlassEffectLevel,
    allowedNotifications: [String],
    hiddenElements: [String],
    allowedInteractions: Set<InteractionType>,
    colorScheme: FocusColorScheme
  ) -> String {
    let id = UUID().uuidString

    let configuration = FocusModeConfiguration(
      id: id,
      name: name,
      glassEffectLevel: glassEffectLevel,
      allowedNotifications: allowedNotifications,
      hiddenElements: hiddenElements,
      allowedInteractions: allowedInteractions,
      colorScheme: colorScheme,
      reducedAnimations: glassEffectLevel == .minimal || glassEffectLevel == .disabled
    )

    focusModeConfigurations[id] = configuration

    return id
  }

  func deleteCustomFocusMode(_ id: String) {
    focusModeConfigurations.removeValue(forKey: id)
  }
}

// MARK: - Data Models

@available(iPadOS 26.0, *)
struct FocusMode: Sendable {
  let id: String
  let name: String
  let isActive: Bool
  let startTime: Date
}

@available(iPadOS 26.0, *)
struct FocusModeConfiguration: Sendable {
  let id: String
  let name: String
  let glassEffectLevel: GlassEffectLevel
  let allowedNotifications: [String]
  let hiddenElements: [String]
  let allowedInteractions: Set<InteractionType>
  let colorScheme: FocusColorScheme
  let reducedAnimations: Bool
}

@available(iPadOS 26.0, *)
struct GlassEffectConfiguration: Sendable {
  let level: GlassEffectLevel
  let colorScheme: FocusColorScheme
}

@available(iPadOS 26.0, *)
enum GlassEffectLevel: Sendable {
  case disabled, minimal, subtle, standard, enhanced
}

@available(iPadOS 26.0, *)
enum InteractionType: CaseIterable, Sendable {
  case reading, composing, browsing, social, searching, voice, tracking, meditation, emergency
}

@available(iPadOS 26.0, *)
enum FocusColorScheme: Sendable {
  case neutral, vibrant, dark, highContrast, energetic, calm

  var accentColor: Color {
    switch self {
    case .neutral: return .gray
    case .vibrant: return .blue
    case .dark: return .white
    case .highContrast: return .yellow
    case .energetic: return .orange
    case .calm: return .green
    }
  }

  var backgroundColor: Color {
    switch self {
    case .neutral: return .clear
    case .vibrant: return .blue.opacity(0.1)
    case .dark: return .black.opacity(0.3)
    case .highContrast: return .black
    case .energetic: return .orange.opacity(0.1)
    case .calm: return .green.opacity(0.1)
    }
  }
}

@available(iPadOS 26.0, *)
enum FocusContext: Sendable {
  case calendar(String)
  case location(String)
  case activity(String)
}

// MARK: - Focus Mode UI Components

@available(iPadOS 26.0, *)
struct FocusModeIndicator: View {
  @Environment(\.focusModeManager) var focusModeManager

  var body: some View {
    if focusModeManager.isFocusModeActive,
      let focusMode = focusModeManager.currentFocusMode
    {
      HStack(spacing: 6) {
        Image(systemName: "moon.circle.fill")
          .font(.caption)
          .foregroundStyle(.purple)

        Text(focusMode.name)
          .font(.caption.weight(.medium))
          .foregroundStyle(.primary)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.ultraThinMaterial, in: Capsule())
      .background(focusModeManager.getAdaptedGlassEffect() ?? .regularMaterial)
    }
  }
}

@available(iPadOS 26.0, *)
struct FocusModeAdaptiveView<Content: View>: View {
  let content: Content
  let elementId: String

  @Environment(\.focusModeManager) var focusModeManager

  init(elementId: String, @ViewBuilder content: () -> Content) {
    self.elementId = elementId
    self.content = content()
  }

  var body: some View {
    if !focusModeManager.shouldHideElement(elementId) {
      content
        .opacity(focusModeManager.minimalistMode ? 0.8 : 1.0)
        .animation(
          focusModeManager.shouldUseReducedAnimations()
            ? .linear(duration: 0.1) : .smooth(duration: 0.3),
          value: focusModeManager.isFocusModeActive
        )
    }
  }
}

@available(iPadOS 26.0, *)
struct FocusModeGlassEffect: ViewModifier {
  @Environment(\.focusModeManager) var focusModeManager

  func body(content: Content) -> some View {
    if let adaptedGlass = focusModeManager.getAdaptedGlassEffect() {
      content.background(adaptedGlass)
    } else {
      content
    }
  }
}

@available(iPadOS 26.0, *)
extension View {
  func focusModeAdaptive(elementId: String) -> some View {
    FocusModeAdaptiveView(elementId: elementId) {
      self
    }
  }

  func focusModeGlassEffect() -> some View {
    self.modifier(FocusModeGlassEffect())
  }
}

// MARK: - Environment Key

@available(iPadOS 26.0, *)
struct FocusModeManagerKey: EnvironmentKey {
  static let defaultValue = FocusModeManager()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var focusModeManager: FocusModeManager {
    get { self[FocusModeManagerKey.self] }
    set { self[FocusModeManagerKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let focusModeDidChange = Notification.Name("focusModeDidChange")
  static let focusModeActivated = Notification.Name("focusModeActivated")
  static let focusModeDeactivated = Notification.Name("focusModeDeactivated")
  static let focusModeColorSchemeChanged = Notification.Name("focusModeColorSchemeChanged")
}
