import Foundation
import SwiftUI

@available(iOS 18.0, *)
@Observable
class AdvancedTrackpadManager {
  var isConnected = false
  var cursorPosition: CGPoint = .zero
  var scrollVelocity: CGPoint = .zero
  var isRightClickActive = false
  var isDragging = false

  // Cursor appearance
  var cursorStyle: CursorStyle = .default
  var customCursorVisible = false

  // Trackpad gestures
  var twoFingerScrollEnabled = true
  var pinchToZoomEnabled = true
  var rotationGesturesEnabled = true
  var forceClickEnabled = true

  // Hover states
  var hoveredElements: Set<String> = []
  var hoverPreviewDelay: TimeInterval = 0.5

  init() {
    setupTrackpadDetection()
  }

  private func setupTrackpadDetection() {
    NotificationCenter.default.addObserver(
      forName: .trackpadConnectionChanged,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      self?.isConnected = notification.userInfo?["connected"] as? Bool ?? false
    }
  }

  func updateCursorPosition(_ position: CGPoint) {
    cursorPosition = position

    NotificationCenter.default.post(
      name: .cursorPositionChanged,
      object: nil,
      userInfo: ["position": position]
    )
  }

  func updateScrollVelocity(_ velocity: CGPoint) {
    scrollVelocity = velocity

    NotificationCenter.default.post(
      name: .trackpadScrolled,
      object: nil,
      userInfo: ["velocity": velocity]
    )
  }

  func setCursorStyle(_ style: CursorStyle) {
    cursorStyle = style
    customCursorVisible = style != CursorStyle.default
  }

  func addHoveredElement(_ elementId: String) {
    hoveredElements.insert(elementId)
  }

  func removeHoveredElement(_ elementId: String) {
    hoveredElements.remove(elementId)
  }

  func performRightClick(at location: CGPoint) {
    isRightClickActive = true

    NotificationCenter.default.post(
      name: .rightClickPerformed,
      object: nil,
      userInfo: ["location": location]
    )

    // Reset after a short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.isRightClickActive = false
    }
  }

  func performForceClick(at location: CGPoint, pressure: CGFloat) {
    NotificationCenter.default.post(
      name: .forceClickPerformed,
      object: nil,
      userInfo: [
        "location": location,
        "pressure": pressure,
      ]
    )
  }
}

// MARK: - Cursor Styles

@available(iOS 18.0, *)
enum CursorStyle: Equatable {
  case `default`
  case pointer
  case text
  case crosshair
  case grab
  case grabbing
  case resize
  case custom(String)

  var systemImage: String {
    switch self {
    case .default: return "cursor.rays"
    case .pointer: return "hand.point.up.left"
    case .text: return "text.cursor"
    case .crosshair: return "plus"
    case .grab: return "hand.raised"
    case .grabbing: return "hand.raised.fill"
    case .resize: return "arrow.up.left.and.arrow.down.right"
    case .custom(let imageName): return imageName
    }
  }
}

// MARK: - Advanced Trackpad Hover Modifier

@available(iOS 18.0, *)
struct AdvancedTrackpadHoverModifier: ViewModifier {
  let elementId: String
  let cursorStyle: CursorStyle
  let hoverEffect: HoverEffect
  let onHover: (Bool) -> Void
  let onRightClick: (() -> Void)?

  @Environment(\.advancedTrackpadManager) var trackpadManager
  @State private var isHovering = false
  @State private var hoverTimer: Timer?
  @State private var showHoverPreview = false

  func body(content: Content) -> some View {
    content
      .scaleEffect(hoverEffect.scaleEffect(isHovering: isHovering))
      .brightness(hoverEffect.brightnessEffect(isHovering: isHovering))
      .overlay {
        if hoverEffect.showBorder && isHovering {
          RoundedRectangle(cornerRadius: 8)
            .stroke(.blue.opacity(0.5), lineWidth: 1)
            .background(.ultraThinMaterial.opacity(0.9))
            .background(.blue.opacity(0.1))
        }
      }
      .onHover { hovering in
        withAnimation(.smooth(duration: 0.2)) {
          isHovering = hovering
        }

        if hovering {
          trackpadManager.setCursorStyle(cursorStyle)
          trackpadManager.addHoveredElement(elementId)

          // Start hover preview timer
          hoverTimer = Timer.scheduledTimer(
            withTimeInterval: trackpadManager.hoverPreviewDelay, repeats: false
          ) { _ in
            showHoverPreview = true
          }
        } else {
          trackpadManager.setCursorStyle(.default)
          trackpadManager.removeHoveredElement(elementId)

          // Cancel hover preview
          hoverTimer?.invalidate()
          showHoverPreview = false
        }

        onHover(hovering)
      }
      .onReceive(NotificationCenter.default.publisher(for: .rightClickPerformed)) { notification in
        if isHovering {
          onRightClick?()
        }
      }
      .overlay {
        if showHoverPreview {
          TrackpadHoverPreview(elementId: elementId)
        }
      }
  }
}

// MARK: - Hover Effects

@available(iOS 18.0, *)
enum HoverEffect {
  case none
  case scale(CGFloat)
  case brightness(CGFloat)
  case scaleAndBrightness(scale: CGFloat, brightness: CGFloat)
  case border
  case custom

  var showBorder: Bool {
    switch self {
    case .border, .custom: return true
    default: return false
    }
  }

  func scaleEffect(isHovering: Bool) -> CGFloat {
    guard isHovering else { return 1.0 }

    switch self {
    case .scale(let scale): return scale
    case .scaleAndBrightness(let scale, _): return scale
    default: return 1.02
    }
  }

  func brightnessEffect(isHovering: Bool) -> CGFloat {
    guard isHovering else { return 0.0 }

    switch self {
    case .brightness(let brightness): return brightness
    case .scaleAndBrightness(_, let brightness): return brightness
    default: return 0.05
    }
  }
}

@available(iOS 18.0, *)
extension View {
  func advancedTrackpadHover(
    elementId: String,
    cursorStyle: CursorStyle = .pointer,
    hoverEffect: HoverEffect = .scaleAndBrightness(scale: 1.02, brightness: 0.05),
    onHover: @escaping (Bool) -> Void = { _ in },
    onRightClick: (() -> Void)? = nil
  ) -> some View {
    self.modifier(
      AdvancedTrackpadHoverModifier(
        elementId: elementId,
        cursorStyle: cursorStyle,
        hoverEffect: hoverEffect,
        onHover: onHover,
        onRightClick: onRightClick
      )
    )
  }
}

// MARK: - Trackpad Hover Preview

@available(iOS 18.0, *)
struct TrackpadHoverPreview: View {
  let elementId: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Quick Actions")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)

      Text("Right-click for more options")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
    .transition(.scale.combined(with: .opacity))
  }
}

// MARK: - Custom Cursor Overlay

@available(iOS 18.0, *)
struct CustomCursorOverlay: View {
  @Environment(\.advancedTrackpadManager) var trackpadManager

  var body: some View {
    if trackpadManager.customCursorVisible {
      Image(systemName: trackpadManager.cursorStyle.systemImage)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.primary)
        .background(
          Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 24, height: 24)
        )
        .position(trackpadManager.cursorPosition)
        .allowsHitTesting(false)
        .zIndex(999)
    }
  }
}

// MARK: - Trackpad Scroll Modifier

@available(iOS 18.0, *)
struct TrackpadScrollModifier: ViewModifier {
  let onScroll: (CGPoint) -> Void
  let scrollSensitivity: CGFloat

  @Environment(\.advancedTrackpadManager) var trackpadManager
  @State private var scrollOffset: CGSize = .zero

  func body(content: Content) -> some View {
    content
      .offset(scrollOffset)
      .onReceive(NotificationCenter.default.publisher(for: .trackpadScrolled)) { notification in
        guard let velocity = notification.userInfo?["velocity"] as? CGPoint else { return }

        let adjustedVelocity = CGPoint(
          x: velocity.x * scrollSensitivity,
          y: velocity.y * scrollSensitivity
        )

        withAnimation(.interactiveSpring()) {
          scrollOffset.width += adjustedVelocity.x
          scrollOffset.height += adjustedVelocity.y
        }

        onScroll(adjustedVelocity)
      }
  }
}

@available(iOS 18.0, *)
extension View {
  func trackpadScroll(
    sensitivity: CGFloat = 1.0,
    onScroll: @escaping (CGPoint) -> Void = { _ in }
  ) -> some View {
    self.modifier(TrackpadScrollModifier(onScroll: onScroll, scrollSensitivity: sensitivity))
  }
}

// MARK: - Force Click Support

@available(iOS 18.0, *)
struct ForceClickModifier: ViewModifier {
  let onForceClick: (CGFloat) -> Void
  let threshold: CGFloat

  @State private var currentPressure: CGFloat = 0
  @State private var isForceClicking = false

  func body(content: Content) -> some View {
    content
      .scaleEffect(isForceClicking ? 0.95 : 1.0)
      .onReceive(NotificationCenter.default.publisher(for: .forceClickPerformed)) { notification in
        guard let pressure = notification.userInfo?["pressure"] as? CGFloat else { return }

        currentPressure = pressure

        if pressure >= threshold && !isForceClicking {
          withAnimation(.smooth(duration: 0.1)) {
            isForceClicking = true
          }

          onForceClick(pressure)

          // Provide haptic feedback
          let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
          impactFeedback.impactOccurred()

          // Reset after a short delay
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.smooth(duration: 0.1)) {
              isForceClicking = false
            }
          }
        }
      }
  }
}

@available(iOS 18.0, *)
extension View {
  func forceClick(
    threshold: CGFloat = 0.7,
    onForceClick: @escaping (CGFloat) -> Void
  ) -> some View {
    self.modifier(ForceClickModifier(onForceClick: onForceClick, threshold: threshold))
  }
}

// MARK: - Right-Click Context Menu

@available(iOS 18.0, *)
struct RightClickContextMenu<MenuContent: View>: ViewModifier {
  let menuContent: MenuContent

  @State private var showingContextMenu = false
  @State private var contextMenuLocation: CGPoint = .zero

  init(@ViewBuilder menuContent: () -> MenuContent) {
    self.menuContent = menuContent()
  }

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: .rightClickPerformed)) { notification in
        guard let location = notification.userInfo?["location"] as? CGPoint else { return }

        contextMenuLocation = location
        showingContextMenu = true
      }
      .overlay {
        if showingContextMenu {
          RightClickMenuOverlay(
            content: menuContent,
            location: contextMenuLocation,
            isPresented: $showingContextMenu
          )
        }
      }
  }
}

@available(iOS 18.0, *)
struct RightClickMenuOverlay<MenuContent: View>: View {
  let content: MenuContent
  let location: CGPoint
  @Binding var isPresented: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      content
    }
    .padding(8)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    .position(x: location.x, y: location.y)
    .transition(.scale.combined(with: .opacity))
    .zIndex(1000)
    .onTapGesture {
      isPresented = false
    }
  }
}

@available(iOS 18.0, *)
extension View {
  func rightClickContextMenu<MenuContent: View>(
    @ViewBuilder menuContent: @escaping () -> MenuContent
  ) -> some View {
    self.modifier(RightClickContextMenu(menuContent: menuContent))
  }
}

// MARK: - Environment Key

@available(iOS 18.0, *)
struct AdvancedTrackpadManagerKey: EnvironmentKey {
  static let defaultValue = AdvancedTrackpadManager()
}

@available(iOS 18.0, *)
extension EnvironmentValues {
  var advancedTrackpadManager: AdvancedTrackpadManager {
    get { self[AdvancedTrackpadManagerKey.self] }
    set { self[AdvancedTrackpadManagerKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let cursorPositionChanged = Notification.Name("cursorPositionChanged")
  static let trackpadScrolled = Notification.Name("trackpadScrolled")
  static let rightClickPerformed = Notification.Name("rightClickPerformed")
  static let forceClickPerformed = Notification.Name("forceClickPerformed")
}
