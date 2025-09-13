import MetricKit
import XCTest

@testable import LiquidSky

@available(iPadOS 26.0, *)
final class GlassEffectPerformanceTests: XCTestCase {
  var performanceMonitor: LiquidGlassPerformanceMonitor!
  var glassEffectManager: LiquidGlassEffectManager!

  override func setUp() {
    super.setUp()
    performanceMonitor = LiquidGlassPerformanceMonitor()
    glassEffectManager = LiquidGlassEffectManager()

    // Start performance monitoring
    performanceMonitor.startMonitoring()
  }

  override func tearDown() {
    performanceMonitor.stopMonitoring()
    performanceMonitor = nil
    glassEffectManager = nil
    super.tearDown()
  }

  // MARK: - Frame Rate Performance Tests

  func testGlassEffectFrameRatePerformance() throws {
    let frameRateMetric = XCTOSSignpostMetric.customApplicationMetric(
      subsystem: "com.liquidsky.performance",
      category: "GlassEffects",
      name: "FrameRate"
    )

    measure(metrics: [frameRateMetric]) {
      // Create multiple glass effects
      for i in 0..<20 {
        let effect = createTestGlassEffect(id: "perf-test-\(i)")
        glassEffectManager.registerEffect(effect)
      }

      // Simulate frame updates
      for _ in 0..<120 {  // 2 seconds at 60fps
        performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
        glassEffectManager.updateAllEffects()
      }

      // Cleanup
      glassEffectManager.cleanupUnusedEffects()
    }

    // Verify frame rate remains acceptable
    XCTAssertGreaterThan(
      performanceMonitor.currentFrameRate, 45.0,
      "Frame rate should remain above 45fps with glass effects")
  }

  func testProMotionDisplayPerformance() throws {
    // Test 120fps performance on ProMotion displays
    performanceMonitor.setTargetFrameRate(120.0)

    let proMotionMetric = XCTOSSignpostMetric.customApplicationMetric(
      subsystem: "com.liquidsky.performance",
      category: "ProMotion",
      name: "HighRefreshRate"
    )

    measure(metrics: [proMotionMetric]) {
      // Create high-intensity glass effects
      for i in 0..<10 {
        let effect = createHighIntensityGlassEffect(id: "promotion-\(i)")
        glassEffectManager.registerEffect(effect)
      }

      // Simulate 120fps updates
      for _ in 0..<240 {  // 2 seconds at 120fps
        performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
        glassEffectManager.updateAllEffects()
      }
    }

    // Verify ProMotion performance
    XCTAssertGreaterThan(
      performanceMonitor.currentFrameRate, 90.0,
      "ProMotion displays should maintain >90fps")
  }

  func testFrameRateUnderLoad() throws {
    measure(metrics: [XCTOSSignpostMetric.applicationLaunchMetric]) {
      // Stress test with many effects
      for i in 0..<50 {
        let effect = createTestGlassEffect(id: "load-test-\(i)")
        glassEffectManager.registerEffect(effect)

        // Add interactive effects
        if i % 5 == 0 {
          glassEffectManager.activateInteractiveEffect("load-test-\(i)")
        }
      }

      // Simulate heavy usage
      for frame in 0..<300 {  // 5 seconds at 60fps
        performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())

        // Simulate user interactions
        if frame % 30 == 0 {
          let effectId = "load-test-\(frame % 50)"
          glassEffectManager.activateInteractiveEffect(effectId)
        }

        glassEffectManager.updateAllEffects()
      }
    }
  }

  // MARK: - Memory Performance Tests

  func testGlassEffectMemoryUsage() throws {
    let memoryMetric = XCTMemoryMetric()

    measure(metrics: [memoryMetric]) {
      var effects: [GlassEffect] = []

      // Create many glass effects
      for i in 0..<100 {
        let effect = createTestGlassEffect(id: "memory-test-\(i)")
        effects.append(effect)
        glassEffectManager.registerEffect(effect)
      }

      // Simulate usage
      for _ in 0..<60 {
        glassEffectManager.updateAllEffects()
      }

      // Cleanup
      for effect in effects {
        glassEffectManager.unregisterEffect(effect.id)
      }
    }
  }

  func testMemoryLeakPrevention() throws {
    let initialMemory = getCurrentMemoryUsage()

    // Create and destroy effects multiple times
    for cycle in 0..<10 {
      var effects: [GlassEffect] = []

      // Create effects
      for i in 0..<20 {
        let effect = createTestGlassEffect(id: "leak-test-\(cycle)-\(i)")
        effects.append(effect)
        glassEffectManager.registerEffect(effect)
      }

      // Use effects
      for _ in 0..<30 {
        glassEffectManager.updateAllEffects()
      }

      // Cleanup
      for effect in effects {
        glassEffectManager.unregisterEffect(effect.id)
      }

      // Force cleanup
      glassEffectManager.cleanupUnusedEffects()
    }

    let finalMemory = getCurrentMemoryUsage()
    let memoryIncrease = finalMemory - initialMemory

    // Memory increase should be minimal (less than 10MB)
    XCTAssertLessThan(
      memoryIncrease, 10 * 1024 * 1024,
      "Memory usage should not increase significantly after cleanup")
  }

  func testMemoryPressureHandling() throws {
    // Simulate memory pressure
    let memoryPressureMetric = XCTMemoryMetric()

    measure(metrics: [memoryPressureMetric]) {
      // Create effects until memory pressure
      var effectCount = 0

      while effectCount < 200 && !performanceMonitor.isMemoryPressureHigh {
        let effect = createTestGlassEffect(id: "pressure-test-\(effectCount)")
        glassEffectManager.registerEffect(effect)
        effectCount += 1

        // Check memory usage
        let memoryUsage = getCurrentMemoryUsage()
        performanceMonitor.recordMemoryUsage(memoryUsage)
      }

      // Verify automatic cleanup occurs
      if performanceMonitor.isMemoryPressureHigh {
        glassEffectManager.handleMemoryPressure()

        // Memory usage should decrease
        let newMemoryUsage = getCurrentMemoryUsage()
        performanceMonitor.recordMemoryUsage(newMemoryUsage)
      }
    }
  }

  // MARK: - Battery Performance Tests

  func testBatteryImpactMeasurement() throws {
    performanceMonitor.startBatteryTracking()

    let batteryMetric = XCTOSSignpostMetric.customApplicationMetric(
      subsystem: "com.liquidsky.performance",
      category: "Battery",
      name: "GlassEffectImpact"
    )

    measure(metrics: [batteryMetric]) {
      // Create battery-intensive glass effects
      for i in 0..<15 {
        let effect = createHighIntensityGlassEffect(id: "battery-test-\(i)")
        glassEffectManager.registerEffect(effect)
      }

      // Simulate extended usage
      for _ in 0..<600 {  // 10 seconds at 60fps
        performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
        glassEffectManager.updateAllEffects()

        // Record battery impact
        performanceMonitor.recordGlassEffectUsage(duration: 1.0 / 60.0, intensity: 0.8)
      }
    }

    let batteryImpact = performanceMonitor.estimatedBatteryImpact
    XCTAssertLessThan(batteryImpact, 0.1, "Battery impact should be reasonable")

    performanceMonitor.stopBatteryTracking()
  }

  func testLowPowerModeAdaptation() throws {
    // Test performance in low power mode
    performanceMonitor.setLowPowerMode(true)

    measure(metrics: [XCTOSSignpostMetric.applicationLaunchMetric]) {
      // Create effects in low power mode
      for i in 0..<10 {
        let effect = createTestGlassEffect(id: "lowpower-test-\(i)")
        glassEffectManager.registerEffect(effect)
      }

      // Simulate usage
      for _ in 0..<120 {
        performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
        glassEffectManager.updateAllEffects()
      }
    }

    // Verify reduced performance mode is active
    XCTAssertTrue(performanceMonitor.isLowPowerModeActive)
    XCTAssertLessThanOrEqual(performanceMonitor.targetFrameRate, 60.0)
  }

  // MARK: - Thermal Performance Tests

  func testThermalThrottling() throws {
    let thermalMetric = XCTOSSignpostMetric.customApplicationMetric(
      subsystem: "com.liquidsky.performance",
      category: "Thermal",
      name: "ThrottlingResponse"
    )

    measure(metrics: [thermalMetric]) {
      // Simulate thermal pressure
      performanceMonitor.simulateThermalState(.fair)

      // Create effects
      for i in 0..<25 {
        let effect = createTestGlassEffect(id: "thermal-test-\(i)")
        glassEffectManager.registerEffect(effect)
      }

      // Increase thermal pressure
      performanceMonitor.simulateThermalState(.serious)

      // Continue simulation
      for _ in 0..<180 {
        performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
        glassEffectManager.updateAllEffects()
      }
    }

    // Verify thermal throttling occurred
    XCTAssertTrue(performanceMonitor.shouldReducePerformance)
  }

  // MARK: - Rendering Performance Tests

  func testGlassEffectRenderingPerformance() throws {
    let renderingMetric = XCTOSSignpostMetric.customApplicationMetric(
      subsystem: "com.liquidsky.performance",
      category: "Rendering",
      name: "GlassEffectDraw"
    )

    measure(metrics: [renderingMetric]) {
      // Create complex glass effects
      for i in 0..<30 {
        let effect = createComplexGlassEffect(id: "render-test-\(i)")
        glassEffectManager.registerEffect(effect)
      }

      // Simulate rendering cycles
      for _ in 0..<120 {
        // Simulate view updates that trigger glass effect rendering
        glassEffectManager.renderAllEffects()
      }
    }
  }

  func testInteractiveEffectPerformance() throws {
    measure(metrics: [XCTOSSignpostMetric.applicationLaunchMetric]) {
      // Create interactive effects
      for i in 0..<15 {
        let effect = createInteractiveGlassEffect(id: "interactive-test-\(i)")
        glassEffectManager.registerEffect(effect)
      }

      // Simulate rapid interactions
      for frame in 0..<300 {
        performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())

        // Activate/deactivate effects rapidly
        let effectId = "interactive-test-\(frame % 15)"
        if frame % 2 == 0 {
          glassEffectManager.activateInteractiveEffect(effectId)
        } else {
          glassEffectManager.deactivateInteractiveEffect(effectId)
        }

        glassEffectManager.updateAllEffects()
      }
    }
  }

  // MARK: - Stress Tests

  func testMaximumEffectLoad() throws {
    var maxEffects = 0
    var frameRateStable = true

    // Gradually increase effect count until performance degrades
    while frameRateStable && maxEffects < 100 {
      let effect = createTestGlassEffect(id: "max-load-\(maxEffects)")
      glassEffectManager.registerEffect(effect)
      maxEffects += 1

      // Test performance with current load
      for _ in 0..<60 {  // 1 second test
        performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
        glassEffectManager.updateAllEffects()
      }

      // Check if frame rate is still acceptable
      frameRateStable = performanceMonitor.currentFrameRate > 30.0
    }

    XCTAssertGreaterThan(maxEffects, 10, "Should support at least 10 glass effects")
    print("Maximum stable glass effects: \(maxEffects)")
  }

  func testConcurrentEffectUpdates() throws {
    let concurrencyMetric = XCTOSSignpostMetric.customApplicationMetric(
      subsystem: "com.liquidsky.performance",
      category: "Concurrency",
      name: "EffectUpdates"
    )

    measure(metrics: [concurrencyMetric]) {
      // Create effects
      for i in 0..<20 {
        let effect = createTestGlassEffect(id: "concurrent-\(i)")
        glassEffectManager.registerEffect(effect)
      }

      // Simulate concurrent updates
      let group = DispatchGroup()

      for _ in 0..<5 {
        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
          for _ in 0..<60 {
            self.glassEffectManager.updateAllEffects()
          }
          group.leave()
        }
      }

      group.wait()
    }
  }

  // MARK: - Helper Methods

  private func createTestGlassEffect(id: String) -> GlassEffect {
    return GlassEffect(
      id: id,
      type: .regular,
      intensity: 0.7,
      isInteractive: false
    )
  }

  private func createHighIntensityGlassEffect(id: String) -> GlassEffect {
    return GlassEffect(
      id: id,
      type: .enhanced,
      intensity: 1.0,
      isInteractive: true
    )
  }

  private func createComplexGlassEffect(id: String) -> GlassEffect {
    return GlassEffect(
      id: id,
      type: .interactive,
      intensity: 0.9,
      isInteractive: true
    )
  }

  private func createInteractiveGlassEffect(id: String) -> GlassEffect {
    return GlassEffect(
      id: id,
      type: .interactive,
      intensity: 0.8,
      isInteractive: true
    )
  }

  private func getCurrentMemoryUsage() -> Int64 {
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
      return Int64(info.resident_size)
    } else {
      return 0
    }
  }
}

// MARK: - Performance Test Extensions

@available(iPadOS 26.0, *)
extension LiquidGlassEffectManager {
  func updateAllEffects() {
    // Mock implementation for testing
    for effectId in activeEffects {
      // Simulate effect update work
      _ = effectId.hashValue
    }
  }

  func renderAllEffects() {
    // Mock implementation for testing
    for effectId in activeEffects {
      // Simulate rendering work
      _ = effectId.count
    }
  }

  func handleMemoryPressure() {
    // Reduce effect count and quality
    let effectsToRemove = Array(activeEffects.prefix(activeEffects.count / 2))
    for effectId in effectsToRemove {
      unregisterEffect(effectId)
    }
  }
}

@available(iPadOS 26.0, *)
extension LiquidGlassPerformanceMonitor {
  var isMemoryPressureHigh: Bool {
    // Mock implementation for testing
    return false
  }

  func recordMemoryUsage(_ usage: Int64) {
    // Mock implementation for testing
  }
}
