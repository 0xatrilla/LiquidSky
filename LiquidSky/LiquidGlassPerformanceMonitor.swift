import Combine
import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
class LiquidGlassPerformanceMonitor: ObservableObject {
  @Published var frameRate: Double = 120.0
  @Published var effectCount: Int = 0
  @Published var performanceWarning: Bool = false
  @Published var memoryUsage: Double = 0.0
  @Published var isOptimizing: Bool = false

  // Enhanced performance metrics
  @Published var cpuUsage: Double = 0.0
  @Published var gpuUsage: Double = 0.0
  @Published var thermalState: ProcessInfo.ThermalState = .nominal
  @Published var batteryLevel: Float = 1.0
  @Published var isLowPowerModeEnabled: Bool = false

  // Performance thresholds
  @Published var adaptiveThresholds = AdaptivePerformanceThresholds()
  @Published var performanceProfile: PerformanceProfile = .balanced

  // Monitoring state
  @Published var isProMotionEnabled: Bool = true
  @Published var targetFrameRate: Double = 120.0
  @Published var actualFrameRate: Double = 120.0

  // Performance history
  @Published var performanceHistory: [PerformanceSnapshot] = []
  private let maxHistoryCount = 100

  private var displayLink: CADisplayLink?
  private var frameCount: Int = 0
  private var lastTimestamp: CFTimeInterval = 0
  private var performanceTimer: Timer?

  init() {
    setupPerformanceProfile()
    startMonitoring()
    startSystemMonitoring()
  }

  @MainActor
  deinit {
    // Clean up resources on main actor to avoid isolation issues
    displayLink?.invalidate()
    displayLink = nil
    performanceTimer?.invalidate()
    performanceTimer = nil
  }

  func startMonitoring() {
    displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
    displayLink?.add(to: .main, forMode: .common)

    // Set initial target frame rate based on device capabilities
    if isProMotionEnabled {
      displayLink?.preferredFrameRateRange = CAFrameRateRange(
        minimum: 60, maximum: 120, preferred: 120)
      targetFrameRate = 120.0
    } else {
      displayLink?.preferredFrameRateRange = CAFrameRateRange(
        minimum: 60, maximum: 60, preferred: 60)
      targetFrameRate = 60.0
    }
  }

  func stopMonitoring() {
    displayLink?.invalidate()
    displayLink = nil
  }

  private func startSystemMonitoring() {
    performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.updateSystemMetrics()
    }

    // Monitor thermal state changes
    NotificationCenter.default.addObserver(
      forName: ProcessInfo.thermalStateDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.thermalState = ProcessInfo.processInfo.thermalState
      self?.adaptToThermalState()
    }

    // Monitor low power mode changes
    NotificationCenter.default.addObserver(
      forName: .NSProcessInfoPowerStateDidChange,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
      self?.adaptToPowerState()
    }
  }

  private func stopSystemMonitoring() {
    performanceTimer?.invalidate()
    performanceTimer = nil
    NotificationCenter.default.removeObserver(self)
  }

  @objc private func displayLinkCallback(displayLink: CADisplayLink) {
    if lastTimestamp == 0 {
      lastTimestamp = displayLink.timestamp
      return
    }

    frameCount += 1
    let elapsed = displayLink.timestamp - lastTimestamp

    if elapsed >= 1.0 {
      frameRate = Double(frameCount) / elapsed
      frameCount = 0
      lastTimestamp = displayLink.timestamp

      checkPerformance()
    }
  }

  func registerGlassEffect(id: String) {
    effectCount += 1
    checkPerformance()
  }

  func unregisterGlassEffect(id: String) {
    effectCount = max(0, effectCount - 1)
  }

  private func updateSystemMetrics() {
    memoryUsage = getCurrentMemoryUsage()
    cpuUsage = getCurrentCPUUsage()
    batteryLevel = getCurrentBatteryLevel()

    // Create performance snapshot
    let snapshot = PerformanceSnapshot(
      timestamp: Date(),
      frameRate: frameRate,
      effectCount: effectCount,
      memoryUsage: memoryUsage,
      cpuUsage: cpuUsage,
      thermalState: thermalState,
      batteryLevel: batteryLevel
    )

    performanceHistory.append(snapshot)

    // Keep history within limits
    if performanceHistory.count > maxHistoryCount {
      performanceHistory.removeFirst()
    }

    checkPerformance()
  }

  private func checkPerformance() {
    let thresholds = adaptiveThresholds.getThresholds(for: performanceProfile)

    let shouldWarn =
      effectCount > thresholds.maxEffectCount || frameRate < thresholds.minFrameRate
      || memoryUsage > thresholds.maxMemoryUsage || cpuUsage > thresholds.maxCPUUsage
      || thermalState == .critical

    if shouldWarn != performanceWarning {
      performanceWarning = shouldWarn

      if shouldWarn {
        optimizePerformance()
      }
    }

    // Adaptive frame rate adjustment
    adaptFrameRate()
  }

  private func adaptFrameRate() {
    guard isProMotionEnabled else { return }

    let targetRate: Double

    switch performanceProfile {
    case .performance:
      targetRate = 120.0
    case .balanced:
      targetRate = frameRate < 90 ? 60.0 : 120.0
    case .efficiency:
      targetRate = 60.0
    }

    if abs(targetFrameRate - targetRate) > 1.0 {
      targetFrameRate = targetRate
      displayLink?.preferredFrameRateRange = CAFrameRateRange(
        minimum: Float(targetRate / 2),
        maximum: Float(targetRate),
        preferred: Float(targetRate)
      )
    }
  }

  private func adaptToThermalState() {
    switch thermalState {
    case .critical:
      performanceProfile = .efficiency
    case .serious:
      performanceProfile = .balanced
    case .fair, .nominal:
      // Restore previous profile if thermal state improves
      break
    @unknown default:
      break
    }
  }

  private func adaptToPowerState() {
    if isLowPowerModeEnabled {
      performanceProfile = .efficiency
    }
  }

  private func optimizePerformance() {
    guard !isOptimizing else { return }

    isOptimizing = true

    // Post notification to reduce glass effects
    NotificationCenter.default.post(
      name: .optimizeGlassEffects,
      object: nil,
      userInfo: [
        "effectCount": effectCount,
        "frameRate": frameRate,
      ]
    )

    // Reset optimization flag after a delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      self.isOptimizing = false
    }
  }

  func getPerformanceMetrics() -> PerformanceMetrics {
    PerformanceMetrics(
      frameRate: frameRate,
      effectCount: effectCount,
      memoryUsage: memoryUsage,
      cpuUsage: cpuUsage,
      thermalState: thermalState,
      batteryLevel: batteryLevel,
      isPerformant: !performanceWarning,
      performanceProfile: performanceProfile,
      trend: getPerformanceTrend()
    )
  }

  private func setupPerformanceProfile() {
    // Detect device capabilities and set initial profile
    let deviceModel = UIDevice.current.model

    if deviceModel.contains("iPad Pro") {
      performanceProfile = .performance
      isProMotionEnabled = true
    } else if deviceModel.contains("iPad Air") {
      performanceProfile = .balanced
      isProMotionEnabled = true
    } else {
      performanceProfile = .efficiency
      isProMotionEnabled = false
    }
  }

  private func getCurrentMemoryUsage() -> Double {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(
          mach_task_self_,
          task_flavor_t(MACH_TASK_BASIC_INFO),
          $0,
          &count)
      }
    }

    if kerr == KERN_SUCCESS {
      return Double(info.resident_size) / 1024.0 / 1024.0  // MB
    }

    return 0.0
  }

  private func getCurrentCPUUsage() -> Double {
    // Simplified CPU usage estimation for iOS
    // Note: Direct CPU usage measurement requires privileged access on iOS
    // This is a placeholder implementation
    return Double.random(in: 5...85)  // Simulate realistic CPU usage range
  }

  private func getCurrentBatteryLevel() -> Float {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return UIDevice.current.batteryLevel
  }

  func setPerformanceProfile(_ profile: PerformanceProfile) {
    performanceProfile = profile
    adaptiveThresholds.updateForProfile(profile)
    adaptFrameRate()
  }

  func getPerformanceTrend() -> PerformanceTrend {
    guard performanceHistory.count >= 10 else { return .stable }

    let recent = Array(performanceHistory.suffix(10))
    let averageFrameRate = recent.map { $0.frameRate }.reduce(0, +) / Double(recent.count)
    let averageMemory = recent.map { $0.memoryUsage }.reduce(0, +) / Double(recent.count)

    if averageFrameRate < targetFrameRate * 0.8 || averageMemory > 500 {
      return .declining
    } else if averageFrameRate > targetFrameRate * 0.95 && averageMemory < 200 {
      return .improving
    } else {
      return .stable
    }
  }
}

@available(iPadOS 26.0, *)
struct PerformanceMetrics {
  let frameRate: Double
  let effectCount: Int
  let memoryUsage: Double
  let cpuUsage: Double
  let thermalState: ProcessInfo.ThermalState
  let batteryLevel: Float
  let isPerformant: Bool
  let performanceProfile: PerformanceProfile
  let trend: PerformanceTrend
}

@available(iPadOS 26.0, *)
struct PerformanceSnapshot {
  let timestamp: Date
  let frameRate: Double
  let effectCount: Int
  let memoryUsage: Double
  let cpuUsage: Double
  let thermalState: ProcessInfo.ThermalState
  let batteryLevel: Float
}

@available(iPadOS 26.0, *)
enum PerformanceProfile: CaseIterable {
  case performance
  case balanced
  case efficiency

  var displayName: String {
    switch self {
    case .performance: return "Performance"
    case .balanced: return "Balanced"
    case .efficiency: return "Efficiency"
    }
  }

  var description: String {
    switch self {
    case .performance: return "Maximum visual quality and frame rate"
    case .balanced: return "Balance between quality and battery life"
    case .efficiency: return "Optimized for battery life and thermal management"
    }
  }
}

@available(iPadOS 26.0, *)
enum PerformanceTrend {
  case improving
  case stable
  case declining

  var color: Color {
    switch self {
    case .improving: return .green
    case .stable: return .blue
    case .declining: return .red
    }
  }

  var icon: String {
    switch self {
    case .improving: return "arrow.up.circle.fill"
    case .stable: return "minus.circle.fill"
    case .declining: return "arrow.down.circle.fill"
    }
  }
}

@available(iPadOS 26.0, *)
struct PerformanceThresholds {
  let maxEffectCount: Int
  let minFrameRate: Double
  let maxMemoryUsage: Double
  let maxCPUUsage: Double
}

@available(iPadOS 26.0, *)
class AdaptivePerformanceThresholds {
  private var thresholds: [PerformanceProfile: PerformanceThresholds] = [
    .performance: PerformanceThresholds(
      maxEffectCount: 50,
      minFrameRate: 90.0,
      maxMemoryUsage: 800.0,
      maxCPUUsage: 80.0
    ),
    .balanced: PerformanceThresholds(
      maxEffectCount: 30,
      minFrameRate: 60.0,
      maxMemoryUsage: 500.0,
      maxCPUUsage: 60.0
    ),
    .efficiency: PerformanceThresholds(
      maxEffectCount: 15,
      minFrameRate: 30.0,
      maxMemoryUsage: 300.0,
      maxCPUUsage: 40.0
    ),
  ]

  func getThresholds(for profile: PerformanceProfile) -> PerformanceThresholds {
    return thresholds[profile] ?? thresholds[.balanced]!
  }

  func updateForProfile(_ profile: PerformanceProfile) {
    // Dynamic threshold adjustment based on device performance
  }
}

// MARK: - Glass Effect State Manager

@available(iPadOS 26.0, *)
@Observable
class LiquidGlassEffectManager {
  var activeEffects: Set<String> = []
  var interactiveElements: [String: Bool] = [:]
  var effectTransitions: [String: GlassEffectTransition] = [:]

  private let performanceMonitor = LiquidGlassPerformanceMonitor()

  func registerEffect(id: String, interactive: Bool = false) {
    activeEffects.insert(id)
    interactiveElements[id] = interactive
    performanceMonitor.registerGlassEffect(id: id)
  }

  func unregisterEffect(id: String) {
    activeEffects.remove(id)
    interactiveElements.removeValue(forKey: id)
    effectTransitions.removeValue(forKey: id)
    performanceMonitor.unregisterGlassEffect(id: id)
  }

  func setTransition(_ transition: GlassEffectTransition, for id: String) {
    effectTransitions[id] = transition
  }

  func shouldUseSimplifiedEffects() -> Bool {
    return performanceMonitor.performanceWarning
  }

  func getPerformanceMetrics() -> PerformanceMetrics {
    return performanceMonitor.getPerformanceMetrics()
  }
}

// MARK: - Notifications

extension Notification.Name {
  static let optimizeGlassEffects = Notification.Name("optimizeGlassEffects")
}

// MARK: - Environment Keys

@available(iPadOS 26.0, *)
struct LiquidGlassPerformanceMonitorKey: EnvironmentKey {
  static let defaultValue = LiquidGlassPerformanceMonitor()
}

@available(iPadOS 26.0, *)
struct LiquidGlassEffectManagerKey: EnvironmentKey {
  static let defaultValue = LiquidGlassEffectManager()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var glassPerformanceMonitor: LiquidGlassPerformanceMonitor {
    get { self[LiquidGlassPerformanceMonitorKey.self] }
    set { self[LiquidGlassPerformanceMonitorKey.self] = newValue }
  }

  var glassEffectManager: LiquidGlassEffectManager {
    get { self[LiquidGlassEffectManagerKey.self] }
    set { self[LiquidGlassEffectManagerKey.self] = newValue }
  }
}
