import Foundation
import SwiftUI

// Replacement for Glass effect on older iOS versions
struct MaterialEffect {
  let material: Material
  let opacity: Double
  let tint: Color?
  let blendMode: BlendMode

  static let regular = MaterialEffect(
    material: .ultraThinMaterial,
    opacity: 1.0,
    tint: nil,
    blendMode: .normal
  )

  static let thick = MaterialEffect(
    material: .thickMaterial,
    opacity: 1.0,
    tint: nil,
    blendMode: .normal
  )

  static let thin = MaterialEffect(
    material: .thinMaterial,
    opacity: 1.0,
    tint: nil,
    blendMode: .normal
  )

  func opacity(_ value: Double) -> MaterialEffect {
    MaterialEffect(material: material, opacity: value, tint: tint, blendMode: blendMode)
  }

  func tint(_ color: Color) -> MaterialEffect {
    MaterialEffect(material: material, opacity: opacity, tint: color, blendMode: blendMode)
  }
}

@available(iOS 18.0, *)
@Observable
@MainActor
class UIPolishManager {
  // Animation configuration
  var animationTiming: AnimationTiming = .standard
  var microInteractionsEnabled = true
  var hapticFeedbackEnabled = true

  // Polish settings
  var glassEffectQuality: GlassEffectQuality = .high
  var transitionStyle: TransitionStyle = .fluid
  var loadingAnimationStyle: LoadingAnimationStyle = .glassOrb

  // Performance adaptation
  var shouldReduceAnimations = false
  var adaptiveQuality = true

  init() {
    setupUIPolish()
    configureAnimations()
  }

  private func setupUIPolish() {
    // Monitor performance for adaptive quality
    NotificationCenter.default.addObserver(
      forName: .performanceLevelChanged,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      // Extract data from notification to avoid data race
      let level = notification.userInfo?["level"] as? PerformanceLevel
      Task { @MainActor in
        await self?.adaptToPerformanceLevel(level)
      }
    }

    // Setup haptic feedback
    setupHapticFeedback()
  }

  private func configureAnimations() {
    // Configure default animation curves and timings
    setupAnimationCurves()
    setupTransitionTimings()
    setupMicroInteractions()
  }

  // MARK: - Animation Configuration

  private func setupAnimationCurves() {
    // Define custom easing curves for glass effects
    AnimationCurves.glassAppear = .timingCurve(0.25, 0.1, 0.25, 1.0)
    AnimationCurves.glassDisappear = .timingCurve(0.4, 0.0, 0.6, 1.0)
    AnimationCurves.glassInteraction = .timingCurve(0.2, 0.0, 0.38, 0.9)
    AnimationCurves.glassHover = .timingCurve(0.25, 0.46, 0.45, 0.94)
  }

  private func setupTransitionTimings() {
    // Configure transition durations
    TransitionTimings.glassEffectAppear = 0.4
    TransitionTimings.glassEffectDisappear = 0.3
    TransitionTimings.columnTransition = 0.5
    TransitionTimings.contentTransition = 0.35
    TransitionTimings.microInteraction = 0.15
  }

  private func setupMicroInteractions() {
    // Configure micro-interaction animations
    MicroInteractions.buttonPress = Animation.timingCurve(0.2, 0.0, 0.38, 0.9, duration: 0.1)
    MicroInteractions.hoverEffect = Animation.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.2)
    MicroInteractions.selectionChange = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.25)
  }

  // MARK: - Glass Effect Polish

  func getPolishedGlassEffect(for context: GlassEffectContext) -> MaterialEffect {
    let baseEffect = getBaseGlassEffect(for: context)

    // Apply quality adjustments
    let qualityAdjustedEffect = applyQualityAdjustments(baseEffect)

    // Apply performance optimizations if needed
    if shouldReduceAnimations {
      return applyPerformanceOptimizations(qualityAdjustedEffect)
    }

    return qualityAdjustedEffect
  }

  private func getBaseGlassEffect(for context: GlassEffectContext) -> MaterialEffect {
    switch context {
    case .navigation:
      return MaterialEffect.regular.tint(.blue.opacity(0.1))
    case .content:
      return MaterialEffect.regular.opacity(0.9)
    case .interactive:
      return MaterialEffect.regular.tint(.blue.opacity(0.2))
    case .modal:
      return MaterialEffect.thick.opacity(0.95)
    case .toolbar:
      return MaterialEffect.thin.tint(.gray.opacity(0.05))
    }
  }

  private func applyQualityAdjustments(_ effect: MaterialEffect) -> MaterialEffect {
    switch glassEffectQuality {
    case .low:
      return effect.opacity(0.7)
    case .medium:
      return effect.opacity(0.85)
    case .high:
      return effect
    case .ultra:
      return effect.tint(.white.opacity(0.05))
    }
  }

  private func applyPerformanceOptimizations(_ effect: MaterialEffect) -> MaterialEffect {
    // Reduce complexity for performance
    return effect.opacity(0.8)
  }

  // MARK: - Animation Polish

  func getPolishedAnimation(for type: AnimationType) -> Animation {
    let baseAnimation = getBaseAnimation(for: type)

    if shouldReduceAnimations {
      return getReducedMotionAnimation(for: type)
    }

    return baseAnimation
  }

  private func getBaseAnimation(for type: AnimationType) -> Animation {
    switch type {
    case .glassAppear:
      return Animation.timingCurve(
        0.25, 0.1, 0.25, 1.0, duration: TransitionTimings.glassEffectAppear)
    case .glassDisappear:
      return Animation.timingCurve(
        0.4, 0.0, 0.6, 1.0, duration: TransitionTimings.glassEffectDisappear)
    case .columnTransition:
      return Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: TransitionTimings.columnTransition)
    case .contentLoad:
      return Animation.timingCurve(
        0.25, 0.46, 0.45, 0.94, duration: TransitionTimings.contentTransition)
    case .microInteraction:
      return MicroInteractions.buttonPress
    case .hoverEffect:
      return MicroInteractions.hoverEffect
    }
  }

  private func getReducedMotionAnimation(for type: AnimationType) -> Animation {
    switch type {
    case .glassAppear, .glassDisappear:
      return .linear(duration: 0.1)
    case .columnTransition, .contentLoad:
      return .linear(duration: 0.15)
    case .microInteraction, .hoverEffect:
      return .linear(duration: 0.05)
    }
  }

  // MARK: - Haptic Feedback

  private func setupHapticFeedback() {
    // Configure haptic feedback patterns
    HapticPatterns.lightTap = UIImpactFeedbackGenerator(style: .light)
    HapticPatterns.mediumTap = UIImpactFeedbackGenerator(style: .medium)
    HapticPatterns.heavyTap = UIImpactFeedbackGenerator(style: .heavy)
    HapticPatterns.selection = UISelectionFeedbackGenerator()
    HapticPatterns.notification = UINotificationFeedbackGenerator()
  }

  func provideHapticFeedback(for interaction: HapticInteraction) {
    guard hapticFeedbackEnabled else { return }

    switch interaction {
    case .buttonPress:
      HapticPatterns.lightTap.impactOccurred(intensity: 0.7)
    case .glassEffectActivation:
      HapticPatterns.mediumTap.impactOccurred(intensity: 0.8)
    case .navigationChange:
      HapticPatterns.selection.selectionChanged()
    case .contentLoad:
      HapticPatterns.lightTap.impactOccurred(intensity: 0.5)
    case .error:
      HapticPatterns.notification.notificationOccurred(.error)
    case .success:
      HapticPatterns.notification.notificationOccurred(.success)
    case .warning:
      HapticPatterns.notification.notificationOccurred(.warning)
    }
  }

  // MARK: - Loading States

  func createLoadingView(style: LoadingAnimationStyle = .glassOrb) -> some View {
    switch style {
    case .glassOrb:
      return AnyView(GlassOrbLoadingView())
    case .liquidWave:
      return AnyView(LiquidWaveLoadingView())
    case .shimmer:
      return AnyView(ShimmerLoadingView())
    case .pulse:
      return AnyView(PulseLoadingView())
    }
  }

  // MARK: - Empty States

  func createEmptyStateView(for context: EmptyStateContext) -> some View {
    switch context {
    case .noContent:
      return AnyView(NoContentEmptyState())
    case .noResults:
      return AnyView(NoResultsEmptyState())
    case .offline:
      return AnyView(OfflineEmptyState())
    case .error:
      return AnyView(ErrorEmptyState())
    }
  }

  // MARK: - Performance Adaptation

  @MainActor
  private func adaptToPerformanceLevel(_ level: PerformanceLevel?) async {
    guard let level = level else { return }

    switch level {
    case .optimal:
      glassEffectQuality = .ultra
      shouldReduceAnimations = false
    case .good:
      glassEffectQuality = .high
      shouldReduceAnimations = false
    case .degraded:
      glassEffectQuality = .medium
      shouldReduceAnimations = true
    case .poor:
      glassEffectQuality = .low
      shouldReduceAnimations = true
    }
  }
}

// MARK: - Loading Views

@available(iOS 18.0, *)
struct GlassOrbLoadingView: View {
  @State private var isAnimating = false

  var body: some View {
    Circle()
      .fill(.ultraThinMaterial)
      .frame(width: 60, height: 60)
      .scaleEffect(isAnimating ? 1.2 : 0.8)
      .opacity(isAnimating ? 0.3 : 1.0)
      .background(.ultraThinMaterial.opacity(0.9))
      .background(.blue.opacity(0.1))
      .animation(
        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
        value: isAnimating
      )
      .onAppear {
        isAnimating = true
      }
  }
}

@available(iOS 18.0, *)
struct LiquidWaveLoadingView: View {
  @State private var waveOffset: CGFloat = 0

  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(.ultraThinMaterial)
      .frame(height: 4)
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .fill(
            LinearGradient(
              colors: [.clear, .blue.opacity(0.6), .clear],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .offset(x: waveOffset)
      }
      .clipped()
      .background(.thinMaterial)
      .onAppear {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
          waveOffset = 200
        }
      }
  }
}

@available(iOS 18.0, *)
struct ShimmerLoadingView: View {
  @State private var shimmerOffset: CGFloat = -200

  var body: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(.quaternary)
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .fill(
            LinearGradient(
              colors: [.clear, .white.opacity(0.4), .clear],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .offset(x: shimmerOffset)
      }
      .clipped()
      .background(.thinMaterial)
      .onAppear {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
          shimmerOffset = 200
        }
      }
  }
}

@available(iOS 18.0, *)
struct PulseLoadingView: View {
  @State private var isPulsing = false

  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(.tertiary)
      .opacity(isPulsing ? 0.3 : 1.0)
      .background(.ultraThinMaterial)
      .animation(
        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
        value: isPulsing
      )
      .onAppear {
        isPulsing = true
      }
  }
}

// MARK: - Empty State Views

@available(iOS 18.0, *)
struct NoContentEmptyState: View {
  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "tray")
        .font(.system(size: 60))
        .foregroundStyle(.tertiary)

      VStack(spacing: 8) {
        Text("No Content")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.primary)

        Text("There's nothing here yet. Check back later or try refreshing.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .padding(40)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .background(.ultraThinMaterial)
  }
}

@available(iOS 18.0, *)
struct NoResultsEmptyState: View {
  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 60))
        .foregroundStyle(.tertiary)

      VStack(spacing: 8) {
        Text("No Results")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.primary)

        Text("Try adjusting your search terms or filters.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .padding(40)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .background(.ultraThinMaterial)
  }
}

@available(iOS 18.0, *)
struct OfflineEmptyState: View {
  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "wifi.slash")
        .font(.system(size: 60))
        .foregroundStyle(.orange)

      VStack(spacing: 8) {
        Text("You're Offline")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.primary)

        Text("Check your internet connection and try again.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .padding(40)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .background(.ultraThinMaterial.opacity(0.9))
    .background(.orange.opacity(0.1))
  }
}

@available(iOS 18.0, *)
struct ErrorEmptyState: View {
  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 60))
        .foregroundStyle(.red)

      VStack(spacing: 8) {
        Text("Something Went Wrong")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.primary)

        Text("We encountered an error. Please try again.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      Button("Try Again") {
        // Handle retry action
      }
      .buttonStyle(.borderedProminent)
      .background(.ultraThinMaterial.opacity(0.9))
      .background(.blue.opacity(0.1))
    }
    .padding(40)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .background(.ultraThinMaterial.opacity(0.9))
    .background(.red.opacity(0.1))
  }
}

// MARK: - Data Models and Enums

@available(iOS 18.0, *)
enum AnimationTiming {
  case fast, standard, slow
  case custom(Double)

  var duration: Double {
    switch self {
    case .fast: return 0.2
    case .standard: return 0.3
    case .slow: return 0.5
    case .custom(let duration): return duration
    }
  }
}

@available(iOS 18.0, *)
enum GlassEffectQuality {
  case low, medium, high, ultra
}

@available(iOS 18.0, *)
enum TransitionStyle {
  case fluid, sharp, bouncy
}

@available(iOS 18.0, *)
enum LoadingAnimationStyle {
  case glassOrb, liquidWave, shimmer, pulse
}

@available(iOS 18.0, *)
enum GlassEffectContext {
  case navigation, content, interactive, modal, toolbar
}

@available(iOS 18.0, *)
enum AnimationType {
  case glassAppear, glassDisappear, columnTransition, contentLoad, microInteraction, hoverEffect
}

@available(iOS 18.0, *)
enum HapticInteraction {
  case buttonPress, glassEffectActivation, navigationChange, contentLoad, error, success, warning
}

@available(iOS 18.0, *)
enum EmptyStateContext {
  case noContent, noResults, offline, error
}

@available(iOS 18.0, *)
enum PerformanceLevel {
  case optimal, good, degraded, poor
}

// MARK: - Animation Constants

@available(iOS 18.0, *)
struct AnimationCurves {
  static var glassAppear: Animation = .easeOut
  static var glassDisappear: Animation = .easeIn
  static var glassInteraction: Animation = .easeInOut
  static var glassHover: Animation = .easeOut
}

@available(iOS 18.0, *)
struct TransitionTimings {
  static var glassEffectAppear: Double = 0.4
  static var glassEffectDisappear: Double = 0.3
  static var columnTransition: Double = 0.5
  static var contentTransition: Double = 0.35
  static var microInteraction: Double = 0.15
}

@available(iOS 18.0, *)
struct MicroInteractions {
  static var buttonPress: Animation = .easeInOut(duration: 0.1)
  static var hoverEffect: Animation = .easeOut(duration: 0.2)
  static var selectionChange: Animation = .easeInOut(duration: 0.25)
}

@available(iOS 18.0, *)
struct HapticPatterns {
  static var lightTap: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  static var mediumTap: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
  static var heavyTap: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
  static var selection: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()
  static var notification: UINotificationFeedbackGenerator = UINotificationFeedbackGenerator()
}

// MARK: - Environment Key

@available(iOS 18.0, *)
struct UIPolishManagerKey: EnvironmentKey {
  static let defaultValue = UIPolishManager()
}

@available(iOS 18.0, *)
extension EnvironmentValues {
  var uiPolishManager: UIPolishManager {
    get { self[UIPolishManagerKey.self] }
    set { self[UIPolishManagerKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let performanceLevelChanged = Notification.Name("performanceLevelChanged")
}
