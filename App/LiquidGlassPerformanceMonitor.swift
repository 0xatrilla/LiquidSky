import Combine
import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
@Observable
class LiquidGlassPerformanceMonitor {
  var frameRate: Double = 120.0
  var effectCount: Int = 0
  var performanceWarning: Bool = false
  var memoryUsage: Double = 0.0
  var isOptimizing: Bool = false

  private var displayLink: CADisplayLink?
  private var frameCount: Int = 0
  private var lastTimestamp: CFTimeInterval = 0
  private let maxEffectCount = 25
  private let minFrameRate: Double = 60.0

  init() {
    startMonitoring()
  }

  deinit {
    stopMonitoring()
  }

  func startMonitoring() {
    displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
    displayLink?.add(to: .main, forMode: .common)
  }

  func stopMonitoring() {
    displayLink?.invalidate()
    displayLink = nil
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

  private func checkPerformance() {
    let shouldWarn = effectCount > maxEffectCount || frameRate < minFrameRate

    if shouldWarn != performanceWarning {
      performanceWarning = shouldWarn

      if shouldWarn {
        optimizePerformance()
      }
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
      memoryUsage: getCurrentMemoryUsage(),
      isPerformant: !performanceWarning
    )
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
}

@available(iPadOS 26.0, *)
struct PerformanceMetrics {
  let frameRate: Double
  let effectCount: Int
  let memoryUsage: Double
  let isPerformant: Bool
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
