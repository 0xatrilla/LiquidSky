import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
@Observable
@MainActor
class AccessibilityManager {
  // VoiceOver support
  var isVoiceOverEnabled = false
  var voiceOverFocusedElement: String?
  var customRotorItems: [AccessibilityRotorItem] = []

  // Motion and animation preferences
  var isReduceMotionEnabled = false
  var isReduceTransparencyEnabled = false
  var prefersCrossFadeTransitions = false

  // Visual accessibility
  var isHighContrastEnabled = false
  var isDarkModeEnabled = false
  var preferredContentSizeCategory: ContentSizeCategory = .large
  var isButtonShapesEnabled = false
  var isOnOffLabelsEnabled = false

  // Assistive technology support
  var isSwitchControlEnabled = false
  var isVoiceControlEnabled = false
  var isAssistiveTouchEnabled = false

  // Custom accessibility settings
  var glassEffectAccessibilityMode: GlassEffectAccessibilityMode = .standard
  var navigationAnnouncements = true
  var detailedDescriptions = true
  var hapticFeedbackLevel: HapticFeedbackLevel = .standard

  init() {
    setupAccessibilityObservers()
    updateAccessibilitySettings()
  }

  private func setupAccessibilityObservers() {
    // VoiceOver
    NotificationCenter.default.addObserver(
      forName: UIAccessibility.voiceOverStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
      self?.adaptToVoiceOver()
    }

    // Reduce Motion
    NotificationCenter.default.addObserver(
      forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
      self?.adaptToMotionPreferences()
    }

    // Reduce Transparency
    NotificationCenter.default.addObserver(
      forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
      self?.adaptToTransparencyPreferences()
    }

    // High Contrast
    NotificationCenter.default.addObserver(
      forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
      self?.adaptToContrastPreferences()
    }

    // Button Shapes
    NotificationCenter.default.addObserver(
      forName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isButtonShapesEnabled = UIAccessibility.buttonShapesEnabled
      self?.adaptToButtonShapes()
    }

    // Switch Control
    NotificationCenter.default.addObserver(
      forName: UIAccessibility.switchControlStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
      self?.adaptToSwitchControl()
    }
  }

  private func updateAccessibilitySettings() {
    isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
    isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
    isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    isButtonShapesEnabled = UIAccessibility.buttonShapesEnabled
    isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning

    // Apply initial adaptations
    adaptToVoiceOver()
    adaptToMotionPreferences()
    adaptToTransparencyPreferences()
    adaptToContrastPreferences()
  }

  private func adaptToVoiceOver() {
    if isVoiceOverEnabled {
      // Simplify glass effects for VoiceOver
      glassEffectAccessibilityMode = .simplified

      // Enable detailed descriptions
      detailedDescriptions = true

      // Announce navigation changes
      navigationAnnouncements = true
    }

    NotificationCenter.default.post(
      name: .accessibilityVoiceOverChanged,
      object: nil,
      userInfo: ["enabled": isVoiceOverEnabled]
    )
  }

  private func adaptToMotionPreferences() {
    if isReduceMotionEnabled {
      prefersCrossFadeTransitions = true
    }

    NotificationCenter.default.post(
      name: .accessibilityMotionChanged,
      object: nil,
      userInfo: ["reduceMotion": isReduceMotionEnabled]
    )
  }

  private func adaptToTransparencyPreferences() {
    if isReduceTransparencyEnabled {
      glassEffectAccessibilityMode = .highContrast
    }

    NotificationCenter.default.post(
      name: .accessibilityTransparencyChanged,
      object: nil,
      userInfo: ["reduceTransparency": isReduceTransparencyEnabled]
    )
  }

  private func adaptToContrastPreferences() {
    if isHighContrastEnabled {
      glassEffectAccessibilityMode = .highContrast
    }

    NotificationCenter.default.post(
      name: .accessibilityContrastChanged,
      object: nil,
      userInfo: ["highContrast": isHighContrastEnabled]
    )
  }

  private func adaptToButtonShapes() {
    NotificationCenter.default.post(
      name: .accessibilityButtonShapesChanged,
      object: nil,
      userInfo: ["enabled": isButtonShapesEnabled]
    )
  }

  private func adaptToSwitchControl() {
    if isSwitchControlEnabled {
      // Simplify interactions for Switch Control
      glassEffectAccessibilityMode = .simplified
    }

    NotificationCenter.default.post(
      name: .accessibilitySwitchControlChanged,
      object: nil,
      userInfo: ["enabled": isSwitchControlEnabled]
    )
  }

  func announceNavigation(to destination: String) {
    guard navigationAnnouncements else { return }

    let announcement = "Navigated to \(destination)"
    UIAccessibility.post(notification: .screenChanged, argument: announcement)
  }

  func announceAction(_ action: String) {
    guard isVoiceOverEnabled else { return }

    UIAccessibility.post(notification: .announcement, argument: action)
  }

  func setVoiceOverFocus(to elementId: String) {
    voiceOverFocusedElement = elementId

    NotificationCenter.default.post(
      name: .accessibilityFocusChanged,
      object: nil,
      userInfo: ["elementId": elementId]
    )
  }

  func addCustomRotorItem(_ item: AccessibilityRotorItem) {
    customRotorItems.append(item)
  }

  func removeCustomRotorItem(withId id: String) {
    customRotorItems.removeAll { $0.id == id }
  }

  func getAccessibilityConfiguration() -> AccessibilityConfiguration {
    AccessibilityConfiguration(
      isVoiceOverEnabled: isVoiceOverEnabled,
      isReduceMotionEnabled: isReduceMotionEnabled,
      isReduceTransparencyEnabled: isReduceTransparencyEnabled,
      isHighContrastEnabled: isHighContrastEnabled,
      glassEffectMode: glassEffectAccessibilityMode,
      hapticLevel: hapticFeedbackLevel
    )
  }
}

// MARK: - Accessibility Configuration

@available(iPadOS 26.0, *)
struct AccessibilityConfiguration {
  let isVoiceOverEnabled: Bool
  let isReduceMotionEnabled: Bool
  let isReduceTransparencyEnabled: Bool
  let isHighContrastEnabled: Bool
  let glassEffectMode: GlassEffectAccessibilityMode
  let hapticLevel: HapticFeedbackLevel
}

@available(iPadOS 26.0, *)
enum GlassEffectAccessibilityMode: CaseIterable {
  case standard
  case simplified
  case highContrast
  case disabled

  var displayName: String {
    switch self {
    case .standard: return "Standard"
    case .simplified: return "Simplified"
    case .highContrast: return "High Contrast"
    case .disabled: return "Disabled"
    }
  }

  var description: String {
    switch self {
    case .standard: return "Full glass effects with all visual enhancements"
    case .simplified: return "Reduced glass effects for better performance and clarity"
    case .highContrast: return "High contrast glass effects for better visibility"
    case .disabled: return "Glass effects disabled for maximum accessibility"
    }
  }
}

@available(iPadOS 26.0, *)
enum HapticFeedbackLevel: CaseIterable {
  case disabled
  case light
  case standard
  case strong

  var displayName: String {
    switch self {
    case .disabled: return "Disabled"
    case .light: return "Light"
    case .standard: return "Standard"
    case .strong: return "Strong"
    }
  }
}

// MARK: - Accessibility Rotor Item

@available(iPadOS 26.0, *)
struct AccessibilityRotorItem: Identifiable {
  let id: String
  let label: String
  let textRange: NSRange?
  let targetElement: String

  init(id: String, label: String, textRange: NSRange? = nil, targetElement: String) {
    self.id = id
    self.label = label
    self.textRange = textRange
    self.targetElement = targetElement
  }
}

// MARK: - Accessible Glass Effect Modifier

@available(iPadOS 26.0, *)
struct AccessibleGlassEffectModifier: ViewModifier {
  let accessibilityLabel: String?
  let accessibilityHint: String?
  let accessibilityValue: String?
  let accessibilityTraits: AccessibilityTraits

  @Environment(\.accessibilityManager) var accessibilityManager

  func body(content: Content) -> some View {
    content
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
      .accessibilityLabel(accessibilityLabel ?? "")
      .accessibilityHint(accessibilityHint ?? "")
      .accessibilityValue(accessibilityValue ?? "")
      .accessibilityAddTraits(accessibilityTraits)
      .accessibilityAction(.default) {
        accessibilityManager.announceAction("Activated")
      }
  }

}

@available(iPadOS 26.0, *)
extension View {
  func accessibleGlassEffect(
    label: String? = nil,
    hint: String? = nil,
    value: String? = nil,
    traits: AccessibilityTraits = []
  ) -> some View {
    self.modifier(
      AccessibleGlassEffectModifier(
        accessibilityLabel: label,
        accessibilityHint: hint,
        accessibilityValue: value,
        accessibilityTraits: traits
      )
    )
  }
}

// MARK: - VoiceOver Navigation Support

@available(iPadOS 26.0, *)
struct VoiceOverNavigationModifier: ViewModifier {
  let navigationItems: [VoiceOverNavigationItem]

  @Environment(\.accessibilityManager) var accessibilityManager

  func body(content: Content) -> some View {
    content
      .accessibilityElement(children: .contain)
      .accessibilityRotor("Navigation") {
        ForEach(navigationItems, id: \.id) { item in
          AccessibilityRotorEntry(item.label, id: item.id) {
            // Focus on the navigation item
            accessibilityManager.setVoiceOverFocus(to: item.targetElementId)
          }
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .accessibilityFocusChanged)) {
        notification in
        if let elementId = notification.userInfo?["elementId"] as? String {
          // Handle focus change
          handleFocusChange(to: elementId)
        }
      }
  }

  private func handleFocusChange(to elementId: String) {
    if let item = navigationItems.first(where: { $0.targetElementId == elementId }) {
      accessibilityManager.announceNavigation(to: item.label)
    }
  }
}

@available(iPadOS 26.0, *)
struct VoiceOverNavigationItem {
  let id: String
  let label: String
  let targetElementId: String
}

@available(iPadOS 26.0, *)
extension View {
  func voiceOverNavigation(items: [VoiceOverNavigationItem]) -> some View {
    self.modifier(VoiceOverNavigationModifier(navigationItems: items))
  }
}

// MARK: - Reduced Motion Support

@available(iPadOS 26.0, *)
struct ReducedMotionModifier: ViewModifier {
  let standardAnimation: Animation
  let reducedMotionAnimation: Animation

  @Environment(\.accessibilityManager) var accessibilityManager

  func body(content: Content) -> some View {
    content
      .animation(
        accessibilityManager.isReduceMotionEnabled ? reducedMotionAnimation : standardAnimation,
        value: UUID()  // This should be replaced with actual animated value
      )
  }
}

@available(iPadOS 26.0, *)
extension View {
  func adaptiveAnimation(
    standard: Animation = .smooth(duration: 0.3),
    reducedMotion: Animation = .linear(duration: 0.1)
  ) -> some View {
    self.modifier(
      ReducedMotionModifier(
        standardAnimation: standard,
        reducedMotionAnimation: reducedMotion
      )
    )
  }
}

// MARK: - High Contrast Support

@available(iPadOS 26.0, *)
struct HighContrastModifier: ViewModifier {
  let standardColors: ColorScheme
  let highContrastColors: ColorScheme

  @Environment(\.accessibilityManager) var accessibilityManager

  struct ColorScheme {
    let foreground: Color
    let background: Color
    let accent: Color
  }

  func body(content: Content) -> some View {
    let colors = accessibilityManager.isHighContrastEnabled ? highContrastColors : standardColors

    content
      .foregroundStyle(colors.foreground)
      .background(colors.background)
      .accentColor(colors.accent)
  }
}

@available(iPadOS 26.0, *)
extension View {
  func adaptiveColors(
    standard: HighContrastModifier.ColorScheme,
    highContrast: HighContrastModifier.ColorScheme
  ) -> some View {
    self.modifier(
      HighContrastModifier(
        standardColors: standard,
        highContrastColors: highContrast
      )
    )
  }
}

// MARK: - Switch Control Support

@available(iPadOS 26.0, *)
struct SwitchControlModifier: ViewModifier {
  let switchControlActions: [AccessibleSwitchAction]

  @Environment(\.accessibilityManager) var accessibilityManager

  func body(content: Content) -> some View {
    content
      .accessibilityActions {
        // SwiftUI does not support dynamic collections inside accessibilityActions
        // Register up to three common actions using Button inside accessibilityActions
        if let first = switchControlActions.first {
          Button(first.label) {
            first.handler()
          }
        }
        if switchControlActions.count > 1 {
          let a = switchControlActions[1]
          Button(a.label) {
            a.handler()
          }
        }
        if switchControlActions.count > 2 {
          let a = switchControlActions[2]
          Button(a.label) {
            a.handler()
          }
        }
      }
      .accessibilityInputLabels(switchControlActions.map { $0.inputLabel })
  }
}

@available(iPadOS 26.0, *)
struct AccessibleSwitchAction {
  let id: String
  let label: String
  let inputLabel: String
  let handler: () -> Void
}

@available(iPadOS 26.0, *)
extension View {
  func switchControlActions(_ actions: [AccessibleSwitchAction]) -> some View {
    self.modifier(SwitchControlModifier(switchControlActions: actions))
  }
}

// Backwards compatibility alias to resolve ambiguity
@available(iPadOS 26.0, *)
typealias SwitchControlAction = AccessibleSwitchAction

// MARK: - Accessibility Announcements

@available(iPadOS 26.0, *)
struct AccessibilityAnnouncementManager {
  static func announceContentChange(_ message: String) {
    UIAccessibility.post(notification: .screenChanged, argument: message)
  }

  static func announceLayoutChange(_ message: String) {
    UIAccessibility.post(notification: .layoutChanged, argument: message)
  }

  static func announcePageScrolled(_ message: String) {
    UIAccessibility.post(notification: .pageScrolled, argument: message)
  }

  static func announceCustom(_ message: String) {
    UIAccessibility.post(notification: .announcement, argument: message)
  }
}

// MARK: - Environment Key

@available(iPadOS 26.0, *)
struct AccessibilityManagerKey: EnvironmentKey {
  static let defaultValue = AccessibilityManager()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var accessibilityManager: AccessibilityManager {
    get { self[AccessibilityManagerKey.self] }
    set { self[AccessibilityManagerKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let accessibilityVoiceOverChanged = Notification.Name("accessibilityVoiceOverChanged")
  static let accessibilityMotionChanged = Notification.Name("accessibilityMotionChanged")
  static let accessibilityTransparencyChanged = Notification.Name(
    "accessibilityTransparencyChanged")
  static let accessibilityContrastChanged = Notification.Name("accessibilityContrastChanged")
  static let accessibilityButtonShapesChanged = Notification.Name(
    "accessibilityButtonShapesChanged")
  static let accessibilitySwitchControlChanged = Notification.Name(
    "accessibilitySwitchControlChanged")
  static let accessibilityFocusChanged = Notification.Name("accessibilityFocusChanged")
}
