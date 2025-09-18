import SwiftUI
import XCTest

@testable import LiquidSky

@available(iPadOS 26.0, *)
final class PerformanceMonitoringTests: XCTestCase {
  var performanceMonitor: LiquidGlassPerformanceMonitor!
  var memoryManager: MemoryManagementSystem!

  override func setUp() {
    super.setUp()
    performanceMonitor = LiquidGlassPerformanceMonitor()
    memoryManager = MemoryManagementSystem()
  }

  override func tearDown() {
    performanceMonitor = nil
    memoryManager = nil
    super.tearDown()
  }

  // MARK: - Performance Monitor Tests

  func testInitialPerformanceState() {
    XCTAssertTrue(performanceMonitor.isMonitoring)
    XCTAssertEqual(performanceMonitor.currentFrameRate, 0.0)
    XCTAssertEqual(performanceMonitor.targetFrameRate, 120.0)
    XCTAssertEqual(performanceMonitor.performanceLevel, .optimal)
  }

  func testStartMonitoring() {
    performanceMonitor.stopMonitoring()
    XCTAssertFalse(performanceMonitor.isMonitoring)

    performanceMonitor.startMonitoring()
    XCTAssertTrue(performanceMonitor.isMonitoring)
  }

  func testFrameRateTracking() {
    performanceMonitor.startMonitoring()

    // Simulate frame updates
    for _ in 0..<120 {
      performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
    }

    XCTAssertGreaterThan(performanceMonitor.currentFrameRate, 0)
    XCTAssertLessThanOrEqual(performanceMonitor.currentFrameRate, 120.0)
  }

  func testPerformanceLevelDetection() {
    // Simulate low frame rate
    performanceMonitor.simulateFrameRate(30.0)
    XCTAssertEqual(performanceMonitor.performanceLevel, .degraded)

    // Simulate good frame rate
    performanceMonitor.simulateFrameRate(60.0)
    XCTAssertEqual(performanceMonitor.performanceLevel, .good)

    // Simulate optimal frame rate
    performanceMonitor.simulateFrameRate(120.0)
    XCTAssertEqual(performanceMonitor.performanceLevel, .optimal)
  }

  func testPerformanceWarnings() {
    var warningReceived = false

    performanceMonitor.onPerformanceWarning = { level in
      warningReceived = true
    }

    // Trigger performance warning
    performanceMonitor.simulateFrameRate(20.0)

    XCTAssertTrue(warningReceived)
  }

  func testEffectCountTracking() {
    performanceMonitor.recordActiveEffectCount(5)
    XCTAssertEqual(performanceMonitor.activeEffectCount, 5)

    performanceMonitor.recordActiveEffectCount(15)
    XCTAssertEqual(performanceMonitor.activeEffectCount, 15)

    // Should trigger optimization when effect count is high
    performanceMonitor.recordActiveEffectCount(50)
    XCTAssertTrue(performanceMonitor.shouldOptimizeEffects)
  }

  // MARK: - Memory Management Tests

  func testInitialMemoryState() {
    XCTAssertEqual(memoryManager.currentMemoryUsage, 0)
    XCTAssertEqual(memoryManager.memoryWarningLevel, .normal)
    XCTAssertTrue(memoryManager.isAutoCleanupEnabled)
  }

  func testMemoryTracking() {
    memoryManager.recordMemoryUsage(100 * 1024 * 1024)  // 100MB
    XCTAssertEqual(memoryManager.currentMemoryUsage, 100 * 1024 * 1024)
  }

  func testMemoryWarningLevels() {
    // Low memory
    memoryManager.recordMemoryUsage(50 * 1024 * 1024)  // 50MB
    XCTAssertEqual(memoryManager.memoryWarningLevel, .normal)

    // Medium memory
    memoryManager.recordMemoryUsage(200 * 1024 * 1024)  // 200MB
    XCTAssertEqual(memoryManager.memoryWarningLevel, .warning)

    // High memory
    memoryManager.recordMemoryUsage(500 * 1024 * 1024)  // 500MB
    XCTAssertEqual(memoryManager.memoryWarningLevel, .critical)
  }

  func testAutoCleanup() {
    memoryManager.enableAutoCleanup(true)

    // Simulate high memory usage
    memoryManager.recordMemoryUsage(400 * 1024 * 1024)  // 400MB

    // Should trigger cleanup
    XCTAssertTrue(memoryManager.shouldPerformCleanup)
  }

  func testMemoryCleanup() {
    // Add some cached items
    memoryManager.addCachedItem("item1", size: 10 * 1024 * 1024)  // 10MB
    memoryManager.addCachedItem("item2", size: 20 * 1024 * 1024)  // 20MB
    memoryManager.addCachedItem("item3", size: 15 * 1024 * 1024)  // 15MB

    let initialMemory = memoryManager.currentMemoryUsage

    memoryManager.performCleanup()

    XCTAssertLessThan(memoryManager.currentMemoryUsage, initialMemory)
  }

  // MARK: - Performance Optimization Tests

  func testAutomaticOptimization() {
    // Simulate poor performance conditions
    performanceMonitor.simulateFrameRate(25.0)
    performanceMonitor.recordActiveEffectCount(30)
    memoryManager.recordMemoryUsage(300 * 1024 * 1024)

    let optimizations = performanceMonitor.getRecommendedOptimizations()

    XCTAssertTrue(optimizations.contains(.reduceEffectCount))
    XCTAssertTrue(optimizations.contains(.lowerEffectQuality))
    XCTAssertTrue(optimizations.contains(.enableMemoryCleanup))
  }

  func testPerformanceRecovery() {
    // Start with poor performance
    performanceMonitor.simulateFrameRate(20.0)
    XCTAssertEqual(performanceMonitor.performanceLevel, .poor)

    // Apply optimizations
    performanceMonitor.applyOptimizations([.reduceEffectCount, .lowerEffectQuality])

    // Simulate improved performance
    performanceMonitor.simulateFrameRate(60.0)
    XCTAssertEqual(performanceMonitor.performanceLevel, .good)
  }

  // MARK: - Battery Usage Tests

  func testBatteryImpactTracking() {
    performanceMonitor.startBatteryTracking()

    // Simulate glass effect usage
    performanceMonitor.recordGlassEffectUsage(duration: 10.0, intensity: 0.8)

    let batteryImpact = performanceMonitor.estimatedBatteryImpact
    XCTAssertGreaterThan(batteryImpact, 0.0)

    performanceMonitor.stopBatteryTracking()
  }

  func testLowPowerModeAdaptation() {
    performanceMonitor.setLowPowerMode(true)

    XCTAssertTrue(performanceMonitor.isLowPowerModeActive)
    XCTAssertEqual(performanceMonitor.targetFrameRate, 60.0)  // Reduced from 120
  }

  // MARK: - Thermal Management Tests

  func testThermalStateMonitoring() {
    performanceMonitor.simulateThermalState(.nominal)
    XCTAssertEqual(performanceMonitor.thermalState, .nominal)

    performanceMonitor.simulateThermalState(.fair)
    XCTAssertEqual(performanceMonitor.thermalState, .fair)

    performanceMonitor.simulateThermalState(.serious)
    XCTAssertEqual(performanceMonitor.thermalState, .serious)
    XCTAssertTrue(performanceMonitor.shouldReducePerformance)
  }

  // MARK: - Performance Metrics Tests

  func testPerformanceMetricsCollection() {
    let metrics = performanceMonitor.collectPerformanceMetrics()

    XCTAssertNotNil(metrics.frameRate)
    XCTAssertNotNil(metrics.memoryUsage)
    XCTAssertNotNil(metrics.effectCount)
    XCTAssertNotNil(metrics.batteryImpact)
    XCTAssertNotNil(metrics.thermalState)
  }

  func testPerformanceHistory() {
    // Record performance over time
    for i in 0..<10 {
      performanceMonitor.simulateFrameRate(Double(60 + i))
      performanceMonitor.recordPerformanceSnapshot()
    }

    let history = performanceMonitor.getPerformanceHistory()
    XCTAssertEqual(history.count, 10)

    let averageFrameRate = performanceMonitor.getAverageFrameRate()
    XCTAssertGreaterThan(averageFrameRate, 60.0)
  }

  // MARK: - Performance Tests

  func testMonitoringPerformance() {
    measure {
      for _ in 0..<1000 {
        performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
        performanceMonitor.recordActiveEffectCount(Int.random(in: 1...20))
        memoryManager.recordMemoryUsage(Int64.random(in: 50...200) * 1024 * 1024)
      }
    }
  }

  func testMemoryCleanupPerformance() {
    // Add many cached items
    for i in 0..<1000 {
      memoryManager.addCachedItem("item\(i)", size: 1024 * 1024)  // 1MB each
    }

    measure {
      memoryManager.performCleanup()
    }
  }

  // MARK: - Edge Cases Tests

  func testZeroFrameRateHandling() {
    performanceMonitor.simulateFrameRate(0.0)
    XCTAssertEqual(performanceMonitor.performanceLevel, .poor)
  }

  func testExtremeMemoryUsage() {
    memoryManager.recordMemoryUsage(Int64.max)
    XCTAssertEqual(memoryManager.memoryWarningLevel, .critical)
  }

  func testNegativeValues() {
    performanceMonitor.simulateFrameRate(-10.0)
    XCTAssertGreaterThanOrEqual(performanceMonitor.currentFrameRate, 0.0)

    memoryManager.recordMemoryUsage(-1000)
    XCTAssertGreaterThanOrEqual(memoryManager.currentMemoryUsage, 0)
  }
}

// MARK: - Test Extensions

@available(iPadOS 26.0, *)
extension LiquidGlassPerformanceMonitor {
  func simulateFrameRate(_ frameRate: Double) {
    currentFrameRate = max(0, frameRate)
    updatePerformanceLevel()
  }

  func simulateThermalState(_ state: ThermalState) {
    thermalState = state
    updatePerformanceBasedOnThermalState()
  }

  func recordGlassEffectUsage(duration: TimeInterval, intensity: Double) {
    // Mock implementation for testing
  }

  private func updatePerformanceLevel() {
    if currentFrameRate >= 100 {
      performanceLevel = .optimal
    } else if currentFrameRate >= 50 {
      performanceLevel = .good
    } else if currentFrameRate >= 30 {
      performanceLevel = .degraded
    } else {
      performanceLevel = .poor
    }
  }

  private func updatePerformanceBasedOnThermalState() {
    shouldReducePerformance = thermalState == .serious || thermalState == .critical
  }
}

@available(iPadOS 26.0, *)
extension MemoryManagementSystem {
  func addCachedItem(_ id: String, size: Int64) {
    currentMemoryUsage += size
    updateMemoryWarningLevel()
  }

  private func updateMemoryWarningLevel() {
    let memoryMB = currentMemoryUsage / (1024 * 1024)

    if memoryMB < 100 {
      memoryWarningLevel = .normal
    } else if memoryMB < 300 {
      memoryWarningLevel = .warning
    } else {
      memoryWarningLevel = .critical
    }

    shouldPerformCleanup = memoryWarningLevel == .critical && isAutoCleanupEnabled
  }
}
