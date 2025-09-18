import Foundation
import SwiftUI

@available(iOS 18.0, *)
@Observable
@MainActor
class LiquidGlassEffectManager {
  // MARK: - Properties
  
  var isEnabled = true
  var intensity: GlassEffectIntensity = .regular
  var tintColor: Color = .blue
  var isInteractive = false
  var animationDuration: Double = 0.3
  
  // MARK: - Glass Effect Intensities
  
  enum GlassEffectIntensity: CaseIterable {
    case subtle
    case regular
    case prominent
    case intense
    
    var opacity: Double {
      switch self {
      case .subtle: return 0.1
      case .regular: return 0.2
      case .prominent: return 0.3
      case .intense: return 0.4
      }
    }
    
    var blurRadius: CGFloat {
      switch self {
      case .subtle: return 5
      case .regular: return 10
      case .prominent: return 15
      case .intense: return 20
      }
    }
  }
  
  // MARK: - Glass Effect Transition
  
  enum GlassEffectTransition {
    case fade
    case slide
    case scale
    case morph
  }
  
  // MARK: - Initialization
  
  init() {
    setupDefaultConfiguration()
  }
  
  private func setupDefaultConfiguration() {
    // Configure default glass effect settings
    isEnabled = true
    intensity = .regular
    tintColor = .blue
    isInteractive = false
    animationDuration = 0.3
  }
  
  // MARK: - Glass Effect Creation
  
  func createGlassEffect(
    intensity: GlassEffectIntensity = .regular,
    tint: Color? = nil,
    interactive: Bool = false
  ) -> GlassEffect {
    let effect = GlassEffect(
      intensity: intensity,
      tint: tint ?? tintColor,
      interactive: interactive || isInteractive
    )
    return effect
  }
  
  // MARK: - Dynamic Glass Effects
  
  func updateGlassEffectForSize(_ size: CGSize) {
    // Adjust glass effect based on screen size
    if size.width > 1000 {
      intensity = .prominent
    } else if size.width > 600 {
      intensity = .regular
    } else {
      intensity = .subtle
    }
  }
  
  func updateGlassEffectForOrientation(_ orientation: UIDeviceOrientation) {
    // Adjust glass effect based on device orientation
    switch orientation {
    case .landscapeLeft, .landscapeRight:
      intensity = .prominent
    case .portrait, .portraitUpsideDown:
      intensity = .regular
    default:
      intensity = .regular
    }
  }
  
  // MARK: - Effect Registration
  
  func registerEffect(id: String, interactive: Bool = false) {
    // Register effect for tracking
    print("Registering effect: \(id), interactive: \(interactive)")
  }
  
  func unregisterEffect(id: String) {
    // Unregister effect
    print("Unregistering effect: \(id)")
  }
  
  func setTransition(_ transition: GlassEffectTransition, for id: String) {
    // Set transition for effect
    print("Setting transition for \(id): \(transition)")
  }
  
  func shouldUseSimplifiedEffects() -> Bool {
    // Return whether to use simplified effects based on performance
    return false
  }
  
  // MARK: - Animation Support
  
  func animateGlassEffectChange(
    from oldIntensity: GlassEffectIntensity,
    to newIntensity: GlassEffectIntensity
  ) {
    withAnimation(.easeInOut(duration: animationDuration)) {
      intensity = newIntensity
    }
  }
  
  func animateTintColorChange(to newColor: Color) {
    withAnimation(.easeInOut(duration: animationDuration)) {
      tintColor = newColor
    }
  }
}

// MARK: - Glass Effect Protocol

@available(iOS 18.0, *)
protocol GlassEffectProtocol {
  var intensity: LiquidGlassEffectManager.GlassEffectIntensity { get }
  var tint: Color { get }
  var interactive: Bool { get }
}

// MARK: - Glass Effect Implementation

@available(iOS 18.0, *)
struct GlassEffect: GlassEffectProtocol {
  let intensity: LiquidGlassEffectManager.GlassEffectIntensity
  let tint: Color
  let interactive: Bool
  
  init(
    intensity: LiquidGlassEffectManager.GlassEffectIntensity = .regular,
    tint: Color = .blue,
    interactive: Bool = false
  ) {
    self.intensity = intensity
    self.tint = tint
    self.interactive = interactive
  }
  
  // MARK: - Glass Effect Modifiers
  
  func tint(_ color: Color) -> GlassEffect {
    GlassEffect(
      intensity: intensity,
      tint: color,
      interactive: interactive
    )
  }
  
  func makeInteractive() -> GlassEffect {
    GlassEffect(
      intensity: intensity,
      tint: tint,
      interactive: true
    )
  }
  
  func intensity(_ newIntensity: LiquidGlassEffectManager.GlassEffectIntensity) -> GlassEffect {
    GlassEffect(
      intensity: newIntensity,
      tint: tint,
      interactive: interactive
    )
  }
}

// MARK: - View Extensions

@available(iOS 26.0, *)
extension View {
  func glassEffect(_ effect: GlassEffect) -> some View {
    self
      .background(.ultraThinMaterial)
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .fill(effect.tint.opacity(effect.intensity.opacity))
          .blur(radius: effect.intensity.blurRadius)
      }
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .scaleEffect(effect.interactive ? 1.0 : 1.0)
      .animation(.easeInOut(duration: 0.3), value: effect.interactive)
  }
  
  func glassEffect(
    _ intensity: LiquidGlassEffectManager.GlassEffectIntensity = .regular,
    tint: Color = .blue,
    interactive: Bool = false
  ) -> some View {
    let effect = GlassEffect(
      intensity: intensity,
      tint: tint,
      interactive: interactive
    )
    return self.glassEffect(effect)
  }
}

// MARK: - Environment Key

@available(iOS 18.0, *)
private struct LiquidGlassEffectManagerKey: EnvironmentKey {
  static let defaultValue = LiquidGlassEffectManager()
}

@available(iOS 18.0, *)
extension EnvironmentValues {
  var glassEffectManager: LiquidGlassEffectManager {
    get { self[LiquidGlassEffectManagerKey.self] }
    set { self[LiquidGlassEffectManagerKey.self] = newValue }
  }
}

// MARK: - Glass Effect Presets

@available(iOS 26.0, *)
extension GlassEffect {
  static let subtle = GlassEffect(intensity: .subtle)
  static let regular = GlassEffect(intensity: .regular)
  static let prominent = GlassEffect(intensity: .prominent)
  static let intense = GlassEffect(intensity: .intense)
  
  static let blue = GlassEffect(tint: .blue)
  static let green = GlassEffect(tint: .green)
  static let red = GlassEffect(tint: .red)
  static let orange = GlassEffect(tint: .orange)
  static let purple = GlassEffect(tint: .purple)
  
  static let interactiveEffect = GlassEffect(interactive: true)
  static let blueInteractive = GlassEffect(tint: .blue, interactive: true)
  static let greenInteractive = GlassEffect(tint: .green, interactive: true)
  static let redInteractive = GlassEffect(tint: .red, interactive: true)
}

// MARK: - Glass Effect Animations

@available(iOS 26.0, *)
extension View {
  func glassEffectAnimation(
    _ isActive: Bool,
    duration: Double = 0.3
  ) -> some View {
    self
      .scaleEffect(isActive ? 1.05 : 1.0)
      .opacity(isActive ? 0.8 : 1.0)
      .animation(.easeInOut(duration: duration), value: isActive)
  }
  
  func glassEffectHover(
    _ isHovering: Bool,
    duration: Double = 0.2
  ) -> some View {
    self
      .scaleEffect(isHovering ? 1.02 : 1.0)
      .brightness(isHovering ? 0.1 : 0.0)
      .animation(.easeInOut(duration: duration), value: isHovering)
  }
}


// MARK: - Glass Effect Cards

@available(iOS 26.0, *)
struct GlassEffectCard<Content: View>: View {
  let content: Content
  let effect: GlassEffect
  let cornerRadius: CGFloat
  
  init(
    cornerRadius: CGFloat = 12,
    effect: GlassEffect = .regular,
    @ViewBuilder content: () -> Content
  ) {
    self.cornerRadius = cornerRadius
    self.effect = effect
    self.content = content()
  }
  
  var body: some View {
    content
      .padding(16)
      .background(.ultraThinMaterial)
      .glassEffect(effect)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
  }
}

// MARK: - Glass Effect Buttons

@available(iOS 26.0, *)
struct GlassEffectButton: View {
  let title: String
  let icon: String?
  let action: () -> Void
  let effect: GlassEffect
  
  @State private var isPressed = false
  @State private var isHovering = false
  
  init(
    _ title: String,
    icon: String? = nil,
    effect: GlassEffect = .blueInteractive,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.icon = icon
    self.effect = effect
    self.action = action
  }
  
  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if let icon = icon {
          Image(systemName: icon)
            .font(.subheadline.weight(.medium))
        }
        
        Text(title)
          .font(.subheadline.weight(.medium))
      }
      .foregroundStyle(.white)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(.blue, in: Capsule())
      .glassEffect(effect)
    }
    .buttonStyle(.plain)
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .glassEffectHover(isHovering)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovering = hovering
      }
    }
    .onTapGesture {
      withAnimation(.easeInOut(duration: 0.1)) {
        isPressed = true
      }
      action()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        withAnimation(.easeInOut(duration: 0.1)) {
          isPressed = false
        }
      }
    }
  }
}
