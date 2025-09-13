import Foundation
import PencilKit
import SwiftUI

@available(iPadOS 26.0, *)
@Observable
@MainActor
class AdvancedApplePencilManager {
  var isConnected = false
  var currentTool: PKTool?
  var hoverPreviewEnabled = true
  var pressureSensitivity: CGFloat = 1.0
  var tiltSensitivity: CGFloat = 1.0

  // Hover state tracking
  var activeHoverElements: [String: HoverElementState] = [:]
  var hoverPreviewContent: HoverPreviewContent?
  var hoverNavigationEnabled = true

  // Advanced pencil properties
  var currentPressure: CGFloat = 0
  var currentTilt: CGFloat = 0
  var currentAzimuth: CGFloat = 0
  var currentAltitude: CGFloat = 0

  init() {
    setupPencilDetection()
  }

  private func setupPencilDetection() {
    // Monitor Apple Pencil connection status
    NotificationCenter.default.addObserver(
      forName: .pencilConnectionChanged,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      let isConnected = notification.userInfo?["connected"] as? Bool ?? false
      Task { @MainActor in
        await self?.handlePencilConnectionChange(isConnected: isConnected)
      }
    }
  }

  @MainActor
  private func handlePencilConnectionChange(isConnected: Bool) async {
    self.isConnected = isConnected
  }

  func updateHoverState(
    elementId: String,
    isHovering: Bool,
    location: CGPoint,
    distance: CGFloat,
    pressure: CGFloat,
    tilt: CGFloat,
    azimuth: CGFloat
  ) {
    if isHovering {
      activeHoverElements[elementId] = HoverElementState(
        location: location,
        distance: distance,
        pressure: pressure,
        tilt: tilt,
        azimuth: azimuth,
        timestamp: Date()
      )
    } else {
      activeHoverElements.removeValue(forKey: elementId)
    }

    // Update global pencil state
    currentPressure = pressure
    currentTilt = tilt
    currentAzimuth = azimuth

    // Generate hover preview if enabled
    if hoverPreviewEnabled && isHovering {
      generateHoverPreview(for: elementId, at: location)
    }
  }

  private func generateHoverPreview(for elementId: String, at location: CGPoint) {
    // Generate contextual hover preview based on element type
    if elementId.contains("post") {
      hoverPreviewContent = HoverPreviewContent(
        type: .post,
        title: "Post Preview",
        subtitle: "Tap to view full post",
        location: location
      )
    } else if elementId.contains("profile") {
      hoverPreviewContent = HoverPreviewContent(
        type: .profile,
        title: "Profile Preview",
        subtitle: "Tap to view profile",
        location: location
      )
    } else if elementId.contains("media") {
      hoverPreviewContent = HoverPreviewContent(
        type: .media,
        title: "Media Preview",
        subtitle: "Tap to view full size",
        location: location
      )
    }
  }

  func clearHoverPreview() {
    hoverPreviewContent = nil
  }

  func enableHoverNavigation() {
    hoverNavigationEnabled = true
  }

  func disableHoverNavigation() {
    hoverNavigationEnabled = false
  }
}

// MARK: - Hover Element State

@available(iPadOS 26.0, *)
struct HoverElementState {
  let location: CGPoint
  let distance: CGFloat
  let pressure: CGFloat
  let tilt: CGFloat
  let azimuth: CGFloat
  let timestamp: Date

  var intensity: CGFloat {
    // Calculate hover intensity based on distance and pressure
    let maxDistance: CGFloat = 20.0
    let distanceIntensity = max(0, min(1, (maxDistance - distance) / maxDistance))
    let pressureIntensity = min(1, pressure * 2.0)
    return (distanceIntensity + pressureIntensity) / 2.0
  }
}

// MARK: - Hover Preview Content

@available(iPadOS 26.0, *)
struct HoverPreviewContent {
  let type: PreviewType
  let title: String
  let subtitle: String
  let location: CGPoint

  enum PreviewType {
    case post, profile, media, link, button
  }
}

// MARK: - Advanced Apple Pencil Hover Modifier

@available(iPadOS 26.0, *)
struct AdvancedApplePencilHoverModifier: ViewModifier {
  let elementId: String
  let previewType: HoverPreviewContent.PreviewType
  let onHover: (Bool, HoverElementState?) -> Void
  let onTap: (() -> Void)?

  @Environment(\.advancedApplePencilManager) var pencilManager
  @State private var currentHoverState: HoverElementState?
  @State private var hoverIntensity: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .scaleEffect(1 + (hoverIntensity * 0.03))
      .brightness(hoverIntensity * 0.08)
      .overlay {
        if hoverIntensity > 0.1 {
          RoundedRectangle(cornerRadius: 8)
            .stroke(.blue.opacity(hoverIntensity * 0.6), lineWidth: 2)
            .background(.ultraThinMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
            )
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .advancedPencilHover)) { notification in
        guard let userInfo = notification.userInfo,
          let hoveredElementId = userInfo["elementId"] as? String,
          hoveredElementId == elementId
        else { return }

        let isHovering = userInfo["isHovering"] as? Bool ?? false
        let location = userInfo["location"] as? CGPoint ?? .zero
        let distance = userInfo["distance"] as? CGFloat ?? 0
        let pressure = userInfo["pressure"] as? CGFloat ?? 0
        let tilt = userInfo["tilt"] as? CGFloat ?? 0
        let azimuth = userInfo["azimuth"] as? CGFloat ?? 0

        let hoverState = HoverElementState(
          location: location,
          distance: distance,
          pressure: pressure,
          tilt: tilt,
          azimuth: azimuth,
          timestamp: Date()
        )

        withAnimation(.smooth(duration: 0.2)) {
          currentHoverState = isHovering ? hoverState : nil
          hoverIntensity = isHovering ? hoverState.intensity : 0
        }

        pencilManager.updateHoverState(
          elementId: elementId,
          isHovering: isHovering,
          location: location,
          distance: distance,
          pressure: pressure,
          tilt: tilt,
          azimuth: azimuth
        )

        onHover(isHovering, isHovering ? hoverState : nil)
      }
      .onTapGesture {
        onTap?()
      }
  }
}

@available(iPadOS 26.0, *)
extension View {
  func advancedApplePencilHover(
    elementId: String,
    previewType: HoverPreviewContent.PreviewType = .button,
    onHover: @escaping (Bool, HoverElementState?) -> Void = { _, _ in },
    onTap: (() -> Void)? = nil
  ) -> some View {
    self.modifier(
      AdvancedApplePencilHoverModifier(
        elementId: elementId,
        previewType: previewType,
        onHover: onHover,
        onTap: onTap
      )
    )
  }
}

// MARK: - Hover Preview Overlay

@available(iPadOS 26.0, *)
struct HoverPreviewOverlay: View {
  @Environment(\.advancedApplePencilManager) var pencilManager

  var body: some View {
    if let previewContent = pencilManager.hoverPreviewContent {
      HoverPreviewCard(content: previewContent)
        .position(x: previewContent.location.x, y: previewContent.location.y - 60)
        .transition(.scale.combined(with: .opacity))
        .zIndex(1000)
    }
  }
}

@available(iPadOS 26.0, *)
struct HoverPreviewCard: View {
  let content: HoverPreviewContent

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(content.title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)

      Text(content.subtitle)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .stroke(.blue.opacity(0.3), lineWidth: 1)
    }
  }
}

// MARK: - Hover Navigation Shortcuts

@available(iPadOS 26.0, *)
struct HoverNavigationModifier: ViewModifier {
  @Environment(\.advancedApplePencilManager) var pencilManager
  @Environment(\.detailColumnManager) var detailManager

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: .pencilHoverNavigation)) {
        notification in
        guard pencilManager.hoverNavigationEnabled,
          let userInfo = notification.userInfo,
          let action = userInfo["action"] as? String
        else { return }

        switch action {
        case "showDetail":
          if let itemId = userInfo["itemId"] as? String,
            let itemType = userInfo["itemType"] as? String
          {
            handleHoverNavigation(itemId: itemId, itemType: itemType)
          }
        case "quickAction":
          if let actionId = userInfo["actionId"] as? String {
            handleQuickAction(actionId: actionId)
          }
        default:
          break
        }
      }
  }

  private func handleHoverNavigation(itemId: String, itemType: String) {
    switch itemType {
    case "post":
      detailManager.showPostDetail(postId: itemId, title: "Post")
    case "profile":
      detailManager.showProfileDetail(profileId: itemId, title: "Profile")
    case "media":
      detailManager.showMediaDetail(mediaId: itemId, title: "Media")
    default:
      break
    }
  }

  private func handleQuickAction(actionId: String) {
    NotificationCenter.default.post(
      name: .executeQuickAction,
      object: nil,
      userInfo: ["actionId": actionId]
    )
  }
}

@available(iPadOS 26.0, *)
extension View {
  func hoverNavigation() -> some View {
    self.modifier(HoverNavigationModifier())
  }
}

// MARK: - Pencil Pressure Sensitivity

@available(iPadOS 26.0, *)
struct PencilPressureSensitiveModifier: ViewModifier {
  let onPressureChange: (CGFloat) -> Void

  @Environment(\.advancedApplePencilManager) var pencilManager
  @State private var currentPressure: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .scaleEffect(1 + (currentPressure * 0.1))
      .opacity(0.7 + (currentPressure * 0.3))
      .onChange(of: pencilManager.currentPressure) { _, newPressure in
        withAnimation(.smooth(duration: 0.1)) {
          currentPressure = newPressure
        }
        onPressureChange(newPressure)
      }
  }
}

@available(iPadOS 26.0, *)
extension View {
  func pencilPressureSensitive(
    onPressureChange: @escaping (CGFloat) -> Void = { _ in }
  ) -> some View {
    self.modifier(PencilPressureSensitiveModifier(onPressureChange: onPressureChange))
  }
}

// MARK: - Environment Key

@available(iPadOS 26.0, *)
struct AdvancedApplePencilManagerKey: EnvironmentKey {
  static let defaultValue = AdvancedApplePencilManager()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var advancedApplePencilManager: AdvancedApplePencilManager {
    get { self[AdvancedApplePencilManagerKey.self] }
    set { self[AdvancedApplePencilManagerKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let advancedPencilHover = Notification.Name("advancedPencilHover")
  static let pencilHoverNavigation = Notification.Name("pencilHoverNavigation")
  static let executeQuickAction = Notification.Name("executeQuickAction")
}
