import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
@Observable
class GestureCoordinator {
  var isApplePencilConnected = false
  var isTrackpadConnected = false
  var isKeyboardConnected = false
  var currentHoverLocation: CGPoint?
  var activeHoverElements: Set<String> = []

  // Apple Pencil state
  var pencilHoverDistance: CGFloat = 0
  var pencilTilt: CGFloat = 0
  var pencilAzimuth: CGFloat = 0

  // Trackpad/Mouse state
  var cursorPosition: CGPoint = .zero
  var isRightClickActive = false

  // Keyboard state
  var focusedElement: String?
  var keyboardShortcuts: [String: () -> Void] = [:]

  init() {
    setupInputDeviceDetection()
    setupKeyboardShortcuts()
  }

  private func setupInputDeviceDetection() {
    // Monitor for Apple Pencil connection
    NotificationCenter.default.addObserver(
      forName: .pencilConnectionChanged,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      self?.isApplePencilConnected = notification.userInfo?["connected"] as? Bool ?? false
    }

    // Monitor for trackpad/mouse connection
    NotificationCenter.default.addObserver(
      forName: .trackpadConnectionChanged,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      self?.isTrackpadConnected = notification.userInfo?["connected"] as? Bool ?? false
    }

    // Monitor for keyboard connection
    NotificationCenter.default.addObserver(
      forName: .keyboardConnectionChanged,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      self?.isKeyboardConnected = notification.userInfo?["connected"] as? Bool ?? false
    }
  }

  private func setupKeyboardShortcuts() {
    keyboardShortcuts = [
      "cmd+n": { /* New Post */  },
      "cmd+f": { /* Search */  },
      "cmd+1": { /* Feed Tab */  },
      "cmd+2": { /* Notifications Tab */  },
      "cmd+3": { /* Search Tab */  },
      "cmd+4": { /* Profile Tab */  },
      "cmd+5": { /* Settings Tab */  },
      "cmd+w": { /* Close Detail */  },
      "cmd+r": { /* Refresh */  },
      "esc": { /* Cancel/Back */  },
    ]
  }

  func registerHoverElement(_ id: String) {
    activeHoverElements.insert(id)
  }

  func unregisterHoverElement(_ id: String) {
    activeHoverElements.remove(id)
  }

  func handlePencilHover(location: CGPoint, distance: CGFloat, tilt: CGFloat, azimuth: CGFloat) {
    currentHoverLocation = location
    pencilHoverDistance = distance
    pencilTilt = tilt
    pencilAzimuth = azimuth

    // Post hover update notification
    NotificationCenter.default.post(
      name: .pencilHoverUpdate,
      object: nil,
      userInfo: [
        "location": location,
        "distance": distance,
        "tilt": tilt,
        "azimuth": azimuth,
      ]
    )
  }

  func handleCursorMove(to location: CGPoint) {
    cursorPosition = location

    NotificationCenter.default.post(
      name: .cursorMoved,
      object: nil,
      userInfo: ["location": location]
    )
  }

  func executeKeyboardShortcut(_ shortcut: String) {
    keyboardShortcuts[shortcut]?()
  }
}

// MARK: - Apple Pencil Hover Support

@available(iPadOS 26.0, *)
struct ApplePencilHoverModifier: ViewModifier {
  let id: String
  let onHover: (Bool, CGPoint?, CGFloat) -> Void

  @Environment(\.gestureCoordinator) var gestureCoordinator
  @State private var isHovering = false
  @State private var hoverIntensity: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .onAppear {
        gestureCoordinator.registerHoverElement(id)
      }
      .onDisappear {
        gestureCoordinator.unregisterHoverElement(id)
      }
      .onReceive(NotificationCenter.default.publisher(for: .pencilHoverUpdate)) { notification in
        guard let userInfo = notification.userInfo,
          let location = userInfo["location"] as? CGPoint,
          let distance = userInfo["distance"] as? CGFloat
        else { return }

        // Calculate hover intensity based on distance (closer = higher intensity)
        let maxDistance: CGFloat = 20.0
        let intensity = max(0, min(1, (maxDistance - distance) / maxDistance))

        let wasHovering = isHovering
        isHovering = intensity > 0.1
        hoverIntensity = intensity

        if wasHovering != isHovering {
          onHover(isHovering, location, intensity)
        }
      }
  }
}

@available(iPadOS 26.0, *)
extension View {
  func applePencilHover(
    id: String,
    onHover: @escaping (Bool, CGPoint?, CGFloat) -> Void
  ) -> some View {
    self.modifier(ApplePencilHoverModifier(id: id, onHover: onHover))
  }
}

// MARK: - Enhanced Hover Effects

@available(iPadOS 26.0, *)
struct EnhancedHoverEffect: ViewModifier {
  let id: String
  let glassEffect: Bool

  @State private var isHovering = false
  @State private var hoverIntensity: CGFloat = 0
  @State private var hoverLocation: CGPoint = .zero

  func body(content: Content) -> some View {
    content
      .scaleEffect(1 + (hoverIntensity * 0.05))
      .brightness(hoverIntensity * 0.1)
      .overlay {
        if glassEffect && isHovering {
          RoundedRectangle(cornerRadius: 8)
            .stroke(.blue.opacity(hoverIntensity), lineWidth: 2)
            .background {
              if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: 8)
                  .glassEffect(.regular.tint(.blue), in: .rect(cornerRadius: 8))
              }
            }
        }
      }
      .applePencilHover(id: id) { hovering, location, intensity in
        withAnimation(.smooth(duration: 0.2)) {
          isHovering = hovering
          hoverIntensity = intensity
          if let location = location {
            hoverLocation = location
          }
        }
      }
      .onHover { hovering in
        // Also support regular cursor hover
        withAnimation(.smooth(duration: 0.2)) {
          if !isHovering {  // Don't override Apple Pencil hover
            isHovering = hovering
            hoverIntensity = hovering ? 1.0 : 0.0
          }
        }
      }
  }
}

@available(iPadOS 26.0, *)
extension View {
  func enhancedHover(id: String, glassEffect: Bool = true) -> some View {
    self.modifier(EnhancedHoverEffect(id: id, glassEffect: glassEffect))
  }
}

// MARK: - Trackpad and Mouse Support

@available(iPadOS 26.0, *)
struct TrackpadGestureModifier: ViewModifier {
  let onRightClick: (() -> Void)?
  let onScroll: ((CGFloat, CGFloat) -> Void)?

  @Environment(\.gestureCoordinator) var gestureCoordinator
  @State private var dragOffset: CGSize = .zero

  func body(content: Content) -> some View {
    content
      .onTapGesture(count: 1) {
        // Handle left click
      }
      .simultaneousGesture(
        // Right click simulation (long press)
        LongPressGesture(minimumDuration: 0.5)
          .onEnded { _ in
            onRightClick?()
          }
      )
      .simultaneousGesture(
        // Scroll gesture
        DragGesture()
          .onChanged { value in
            let deltaX = value.translation.width - dragOffset.width
            let deltaY = value.translation.height - dragOffset.height
            dragOffset = value.translation
            onScroll?(deltaX, deltaY)
          }
          .onEnded { _ in
            dragOffset = .zero
          }
      )
  }
}

@available(iPadOS 26.0, *)
extension View {
  func trackpadGestures(
    onRightClick: (() -> Void)? = nil,
    onScroll: ((CGFloat, CGFloat) -> Void)? = nil
  ) -> some View {
    self.modifier(TrackpadGestureModifier(onRightClick: onRightClick, onScroll: onScroll))
  }
}

// MARK: - Keyboard Navigation Support

@available(iPadOS 26.0, *)
struct KeyboardNavigationModifier: ViewModifier {
  let id: String
  let onFocus: (Bool) -> Void
  let onKeyPress: ((KeyEquivalent) -> Bool)?

  @Environment(\.gestureCoordinator) var gestureCoordinator
  @FocusState private var isFocused: Bool

  func body(content: Content) -> some View {
    content
      .focused($isFocused)
      .onChange(of: isFocused) { _, focused in
        onFocus(focused)
        if focused {
          gestureCoordinator.focusedElement = id
        } else if gestureCoordinator.focusedElement == id {
          gestureCoordinator.focusedElement = nil
        }
      }
      .onKeyPress { keyPress in
        return onKeyPress?(keyPress.key) == true ? .handled : .ignored
      }
  }
}

@available(iPadOS 26.0, *)
extension View {
  func keyboardNavigation(
    id: String,
    onFocus: @escaping (Bool) -> Void = { _ in },
    onKeyPress: ((KeyEquivalent) -> Bool)? = nil
  ) -> some View {
    self.modifier(KeyboardNavigationModifier(id: id, onFocus: onFocus, onKeyPress: onKeyPress))
  }
}

// MARK: - Multi-touch Gesture Support

@available(iPadOS 26.0, *)
struct MultiTouchGestureModifier: ViewModifier {
  let onPinch: ((CGFloat) -> Void)?
  let onRotate: ((Angle) -> Void)?
  let onDrag: ((DragGesture.Value) -> Void)?

  @State private var currentScale: CGFloat = 1.0
  @State private var currentRotation: Angle = .zero

  func body(content: Content) -> some View {
    content
      .scaleEffect(currentScale)
      .rotationEffect(currentRotation)
      .simultaneousGesture(
        // Pinch to zoom
        MagnificationGesture()
          .onChanged { scale in
            currentScale = scale
            onPinch?(scale)
          }
          .onEnded { scale in
            withAnimation(.smooth(duration: 0.3)) {
              currentScale = 1.0
            }
          }
      )
      .simultaneousGesture(
        // Rotation gesture
        RotationGesture()
          .onChanged { rotation in
            currentRotation = rotation
            onRotate?(rotation)
          }
          .onEnded { rotation in
            withAnimation(.smooth(duration: 0.3)) {
              currentRotation = .zero
            }
          }
      )
      .simultaneousGesture(
        // Drag gesture
        DragGesture()
          .onChanged { value in
            onDrag?(value)
          }
      )
  }
}

@available(iPadOS 26.0, *)
extension View {
  func multiTouchGestures(
    onPinch: ((CGFloat) -> Void)? = nil,
    onRotate: ((Angle) -> Void)? = nil,
    onDrag: ((DragGesture.Value) -> Void)? = nil
  ) -> some View {
    self.modifier(MultiTouchGestureModifier(onPinch: onPinch, onRotate: onRotate, onDrag: onDrag))
  }
}

// MARK: - Notifications

extension Notification.Name {
  static let pencilConnectionChanged = Notification.Name("pencilConnectionChanged")
  static let trackpadConnectionChanged = Notification.Name("trackpadConnectionChanged")
  static let keyboardConnectionChanged = Notification.Name("keyboardConnectionChanged")
  static let pencilHoverUpdate = Notification.Name("pencilHoverUpdate")
  static let cursorMoved = Notification.Name("cursorMoved")
}

// MARK: - Environment Key

@available(iPadOS 26.0, *)
struct GestureCoordinatorKey: EnvironmentKey {
  static let defaultValue = GestureCoordinator()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var gestureCoordinator: GestureCoordinator {
    get { self[GestureCoordinatorKey.self] }
    set { self[GestureCoordinatorKey.self] = newValue }
  }
}
