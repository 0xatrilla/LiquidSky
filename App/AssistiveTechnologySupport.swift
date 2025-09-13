import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
@Observable
class AssistiveTechnologySupport {
  // Switch Control support
  var isSwitchControlEnabled = false
  var switchControlActions: [SwitchControlAction] = []
  var switchControlGroups: [SwitchControlGroup] = []

  // Voice Control support
  var isVoiceControlEnabled = false
  var voiceControlCommands: [VoiceControlCommand] = []
  var customVoiceCommands: [CustomVoiceCommand] = []

  // Assistive Touch support
  var isAssistiveTouchEnabled = false
  var assistiveTouchGestures: [AssistiveTouchGesture] = []

  // External device support
  var connectedAssistiveDevices: [AssistiveDevice] = []
  var deviceInputMappings: [String: InputMapping] = [:]

  init() {
    setupAssistiveTechnologySupport()
    createDefaultActions()
    createDefaultVoiceCommands()
  }

  private func setupAssistiveTechnologySupport() {
    updateAssistiveTechnologyStatus()

    // Switch Control observer
    NotificationCenter.default.addObserver(
      forName: UIAccessibility.switchControlStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
      self?.handleSwitchControlChange()
    }

    // Voice Control observer - Not available in current UIKit version
    // TODO: Add Voice Control support when available in future iOS versions
    /*
    NotificationCenter.default.addObserver(
      forName: UIAccessibility.voiceControlStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isVoiceControlEnabled = UIAccessibility.isVoiceControlRunning
      self?.handleVoiceControlChange()
    }
    */

    // Assistive Touch observer
    NotificationCenter.default.addObserver(
      forName: UIAccessibility.assistiveTouchStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isAssistiveTouchEnabled = UIAccessibility.isAssistiveTouchRunning
      self?.handleAssistiveTouchChange()
    }
  }

  private func updateAssistiveTechnologyStatus() {
    isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
    isVoiceControlEnabled = UIAccessibility.isVoiceControlRunning
    isAssistiveTouchEnabled = UIAccessibility.isAssistiveTouchRunning
  }

  private func handleSwitchControlChange() {
    if isSwitchControlEnabled {
      setupSwitchControlSupport()
    } else {
      cleanupSwitchControlSupport()
    }

    NotificationCenter.default.post(
      name: .assistiveTechnologySwitchControlChanged,
      object: nil,
      userInfo: ["enabled": isSwitchControlEnabled]
    )
  }

  private func handleVoiceControlChange() {
    if isVoiceControlEnabled {
      setupVoiceControlSupport()
    } else {
      cleanupVoiceControlSupport()
    }

    NotificationCenter.default.post(
      name: .assistiveTechnologyVoiceControlChanged,
      object: nil,
      userInfo: ["enabled": isVoiceControlEnabled]
    )
  }

  private func handleAssistiveTouchChange() {
    if isAssistiveTouchEnabled {
      setupAssistiveTouchSupport()
    } else {
      cleanupAssistiveTouchSupport()
    }

    NotificationCenter.default.post(
      name: .assistiveTechnologyAssistiveTouchChanged,
      object: nil,
      userInfo: ["enabled": isAssistiveTouchEnabled]
    )
  }

  // MARK: - Switch Control Support

  private func setupSwitchControlSupport() {
    // Configure switch control groups for glass effect elements
    switchControlGroups = [
      SwitchControlGroup(
        id: "navigation",
        name: "Navigation",
        elements: ["sidebar", "content", "detail"],
        priority: .high
      ),
      SwitchControlGroup(
        id: "actions",
        name: "Actions",
        elements: ["new-post", "search", "settings"],
        priority: .medium
      ),
      SwitchControlGroup(
        id: "content",
        name: "Content",
        elements: ["posts", "notifications", "profile"],
        priority: .low
      ),
    ]
  }

  private func cleanupSwitchControlSupport() {
    switchControlGroups.removeAll()
    switchControlActions.removeAll()
  }

  private func createDefaultActions() {
    switchControlActions = [
      SwitchControlAction(
        id: "tap",
        label: "Tap",
        inputLabel: "Activate element",
        handler: { }
      ),
      SwitchControlAction(
        id: "scroll-up",
        label: "Scroll Up",
        inputLabel: "Scroll up",
        handler: { }
      ),
      SwitchControlAction(
        id: "scroll-down",
        label: "Scroll Down",
        inputLabel: "Scroll down",
        handler: { }
      ),
      SwitchControlAction(
        id: "back",
        label: "Go Back",
        inputLabel: "Navigate back",
        handler: { }
      ),
    ]
  }

  // MARK: - Voice Control Support

  private func setupVoiceControlSupport() {
    // Register custom voice commands for glass effect interactions
    registerVoiceCommands()
  }

  private func cleanupVoiceControlSupport() {
    voiceControlCommands.removeAll()
    customVoiceCommands.removeAll()
  }

  private func createDefaultVoiceCommands() {
    voiceControlCommands = [
      VoiceControlCommand(
        phrase: "Show sidebar",
        action: .showSidebar,
        description: "Display the navigation sidebar"
      ),
      VoiceControlCommand(
        phrase: "Hide sidebar",
        action: .hideSidebar,
        description: "Hide the navigation sidebar"
      ),
      VoiceControlCommand(
        phrase: "New post",
        action: .newPost,
        description: "Create a new post"
      ),
      VoiceControlCommand(
        phrase: "Search",
        action: .search,
        description: "Open search interface"
      ),
      VoiceControlCommand(
        phrase: "Go to feed",
        action: .navigateToFeed,
        description: "Navigate to main feed"
      ),
      VoiceControlCommand(
        phrase: "Go to notifications",
        action: .navigateToNotifications,
        description: "Navigate to notifications"
      ),
      VoiceControlCommand(
        phrase: "Go to profile",
        action: .navigateToProfile,
        description: "Navigate to profile"
      ),
      VoiceControlCommand(
        phrase: "Settings",
        action: .openSettings,
        description: "Open app settings"
      ),
    ]
  }

  private func registerVoiceCommands() {
    // In a real implementation, this would register commands with the system
    // For now, we'll just prepare the command structure
    customVoiceCommands = voiceControlCommands.map { command in
      CustomVoiceCommand(
        identifier: command.phrase.lowercased().replacingOccurrences(of: " ", with: "-"),
        phrase: command.phrase,
        action: command.action
      )
    }
  }

  // MARK: - Assistive Touch Support

  private func setupAssistiveTouchSupport() {
    // Create assistive touch gesture alternatives
    assistiveTouchGestures = [
      AssistiveTouchGesture(
        id: "single-tap",
        name: "Single Tap",
        description: "Activate element",
        alternativeAction: .tap
      ),
      AssistiveTouchGesture(
        id: "double-tap",
        name: "Double Tap",
        description: "Secondary action",
        alternativeAction: .doubleTap
      ),
      AssistiveTouchGesture(
        id: "long-press",
        name: "Long Press",
        description: "Context menu",
        alternativeAction: .longPress
      ),
      AssistiveTouchGesture(
        id: "scroll",
        name: "Scroll",
        description: "Scroll content",
        alternativeAction: .scroll
      ),
    ]
  }

  private func cleanupAssistiveTouchSupport() {
    assistiveTouchGestures.removeAll()
  }

  // MARK: - External Device Support

  func registerAssistiveDevice(_ device: AssistiveDevice) {
    connectedAssistiveDevices.append(device)

    // Create input mapping for the device
    let mapping = InputMapping(
      deviceId: device.id,
      inputMappings: device.supportedInputs.reduce(into: [:]) { result, input in
        result[input.id] = mapInputToAction(input)
      }
    )

    deviceInputMappings[device.id] = mapping

    NotificationCenter.default.post(
      name: .assistiveDeviceConnected,
      object: nil,
      userInfo: ["device": device]
    )
  }

  func unregisterAssistiveDevice(_ deviceId: String) {
    connectedAssistiveDevices.removeAll { $0.id == deviceId }
    deviceInputMappings.removeValue(forKey: deviceId)

    NotificationCenter.default.post(
      name: .assistiveDeviceDisconnected,
      object: nil,
      userInfo: ["deviceId": deviceId]
    )
  }

  private func mapInputToAction(_ input: DeviceInput) -> AssistiveAction {
    switch input.type {
    case .button:
      return .tap
    case .joystick:
      return .navigate
    case .switchInput:
      return .select
    case .sensor:
      return .gesture
    }
  }

  func handleDeviceInput(_ deviceId: String, input: DeviceInput) {
    guard let mapping = deviceInputMappings[deviceId],
      let action = mapping.inputMappings[input.id]
    else {
      return
    }

    executeAssistiveAction(action, with: input.value)
  }

  private func executeAssistiveAction(_ action: AssistiveAction, with value: Any?) {
    switch action {
    case .tap:
      // Execute tap action
      break
    case .navigate:
      // Execute navigation action
      break
    case .select:
      // Execute selection action
      break
    case .gesture:
      // Execute gesture action
      break
    case .scroll:
      // Execute scroll action
      break
    }
  }
}

// MARK: - Data Models

@available(iPadOS 26.0, *)
struct SwitchControlGroup {
  let id: String
  let name: String
  let elements: [String]
  let priority: Priority

  enum Priority {
    case high, medium, low
  }
}

@available(iPadOS 26.0, *)
// SwitchControlAction is defined in AccessibilityManager.swift

@available(iPadOS 26.0, *)
struct VoiceControlCommand {
  let phrase: String
  let action: VoiceAction
  let description: String

  enum VoiceAction {
    case showSidebar, hideSidebar, newPost, search
    case navigateToFeed, navigateToNotifications, navigateToProfile
    case openSettings, goBack, refresh
  }
}

@available(iPadOS 26.0, *)
struct CustomVoiceCommand {
  let identifier: String
  let phrase: String
  let action: VoiceControlCommand.VoiceAction
}

@available(iPadOS 26.0, *)
struct AssistiveTouchGesture {
  let id: String
  let name: String
  let description: String
  let alternativeAction: AlternativeAction

  enum AlternativeAction {
    case tap, doubleTap, longPress, scroll, pinch, rotate
  }
}

@available(iPadOS 26.0, *)
struct AssistiveDevice {
  let id: String
  let name: String
  let type: DeviceType
  let supportedInputs: [DeviceInput]
  let capabilities: [DeviceCapability]

  enum DeviceType {
    case switchDevice, eyeTracker, headPointer, joystick, customController
  }

  enum DeviceCapability {
    case singleSwitch, multiSwitch, eyeGaze, headMovement, joystickControl
  }
}

@available(iPadOS 26.0, *)
struct DeviceInput {
  let id: String
  let type: InputType
  let value: Any?

  enum InputType {
    case button, joystick, switchInput, sensor
  }
}

@available(iPadOS 26.0, *)
struct InputMapping {
  let deviceId: String
  let inputMappings: [String: AssistiveAction]
}

@available(iPadOS 26.0, *)
enum AssistiveAction {
  case tap, navigate, select, gesture, scroll
}

// MARK: - Assistive Technology Modifier

@available(iPadOS 26.0, *)
struct AssistiveTechnologyModifier: ViewModifier {
  let elementId: String
  let switchControlGroup: String?
  let voiceControlLabel: String?
  let assistiveTouchEnabled: Bool

  @Environment(\.assistiveTechnologySupport) var assistiveTechnologySupport

  func body(content: Content) -> some View {
    content
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(accessibilityTraits)
      .accessibilityLabel(effectiveLabel)
      .accessibilityAction(.default) {
        handleDefaultAction()
      }
      .accessibilityAction(.activate) {
        handleActivateAction()
      }
      .onReceive(
        NotificationCenter.default.publisher(for: .assistiveTechnologySwitchControlChanged)
      ) { _ in
        updateSwitchControlSupport()
      }
      .onReceive(NotificationCenter.default.publisher(for: .assistiveTechnologyVoiceControlChanged))
    { _ in
      updateVoiceControlSupport()
    }
  }

  private var accessibilityTraits: AccessibilityTraits {
    var traits: AccessibilityTraits = []

    if assistiveTechnologySupport.isSwitchControlEnabled {
      traits.insert(.isButton)
    }

    if assistiveTechnologySupport.isVoiceControlEnabled {
      traits.insert(.allowsDirectInteraction)
    }

    return traits
  }

  private var effectiveLabel: String {
    if let voiceLabel = voiceControlLabel,
      assistiveTechnologySupport.isVoiceControlEnabled
    {
      return voiceLabel
    }

    return elementId.replacingOccurrences(of: "-", with: " ").capitalized
  }

  private func handleDefaultAction() {
    // Handle default assistive technology action
    NotificationCenter.default.post(
      name: .assistiveTechnologyActionTriggered,
      object: nil,
      userInfo: [
        "elementId": elementId,
        "action": "default",
      ]
    )
  }

  private func handleActivateAction() {
    // Handle activate action for assistive technologies
    NotificationCenter.default.post(
      name: .assistiveTechnologyActionTriggered,
      object: nil,
      userInfo: [
        "elementId": elementId,
        "action": "activate",
      ]
    )
  }

  private func updateSwitchControlSupport() {
    // Update switch control configuration for this element
  }

  private func updateVoiceControlSupport() {
    // Update voice control configuration for this element
  }
}

@available(iPadOS 26.0, *)
extension View {
  func assistiveTechnologySupport(
    elementId: String,
    switchControlGroup: String? = nil,
    voiceControlLabel: String? = nil,
    assistiveTouchEnabled: Bool = true
  ) -> some View {
    self.modifier(
      AssistiveTechnologyModifier(
        elementId: elementId,
        switchControlGroup: switchControlGroup,
        voiceControlLabel: voiceControlLabel,
        assistiveTouchEnabled: assistiveTouchEnabled
      )
    )
  }
}

// MARK: - Environment Key

@available(iPadOS 26.0, *)
struct AssistiveTechnologySupportKey: EnvironmentKey {
  static let defaultValue = AssistiveTechnologySupport()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var assistiveTechnologySupport: AssistiveTechnologySupport {
    get { self[AssistiveTechnologySupportKey.self] }
    set { self[AssistiveTechnologySupportKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let assistiveTechnologySwitchControlChanged = Notification.Name(
    "assistiveTechnologySwitchControlChanged")
  static let assistiveTechnologyVoiceControlChanged = Notification.Name(
    "assistiveTechnologyVoiceControlChanged")
  static let assistiveTechnologyAssistiveTouchChanged = Notification.Name(
    "assistiveTechnologyAssistiveTouchChanged")
  static let assistiveTechnologyActionTriggered = Notification.Name(
    "assistiveTechnologyActionTriggered")
  static let assistiveDeviceConnected = Notification.Name("assistiveDeviceConnected")
  static let assistiveDeviceDisconnected = Notification.Name("assistiveDeviceDisconnected")
}
