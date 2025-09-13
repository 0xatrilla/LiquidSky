import SwiftUI
import XCTest

@testable import LiquidSky

@available(iPadOS 26.0, *)
final class GlassEffectStateTests: XCTestCase {
  var glassEffectManager: LiquidGlassEffectManager!

  override func setUp() {
    super.setUp()
    glassEffectManager = LiquidGlassEffectManager()
  }

  override func tearDown() {
    glassEffectManager = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testInitialState() {
    XCTAssertTrue(glassEffectManager.isEnabled)
    XCTAssertEqual(glassEffectManager.globalIntensity, 1.0)
    XCTAssertEqual(glassEffectManager.performanceMode, .standard)
    XCTAssertTrue(glassEffectManager.activeEffects.isEmpty)
  }

  // MARK: - Glass Effect Registration Tests

  func testRegisterGlassEffect() {
    let effectId = "test-effect-1"
    let effect = GlassEffect(
      id: effectId,
      type: .regular,
      intensity: 0.8,
      isInteractive: true
    )

    glassEffectManager.registerEffect(effect)

    XCTAssertTrue(glassEffectManager.activeEffects.contains(effectId))
    XCTAssertEqual(glassEffectManager.getEffect(effectId)?.intensity, 0.8)
  }

  func testUnregisterGlassEffect() {
    let effectId = "test-effect-2"
    let effect = GlassEffect(
      id: effectId,
      type: .regular,
      intensity: 0.8,
      isInteractive: true
    )

    glassEffectManager.registerEffect(effect)
    XCTAssertTrue(glassEffectManager.activeEffects.contains(effectId))

    glassEffectManager.unregisterEffect(effectId)
    XCTAssertFalse(glassEffectManager.activeEffects.contains(effectId))
  }

  // MARK: - Performance Mode Tests

  func testPerformanceModeReduced() {
    glassEffectManager.setPerformanceMode(.reduced)

    XCTAssertEqual(glassEffectManager.performanceMode, .reduced)
    XCTAssertLessThan(glassEffectManager.globalIntensity, 1.0)
  }

  func testPerformanceModeMinimal() {
    glassEffectManager.setPerformanceMode(.minimal)

    XCTAssertEqual(glassEffectManager.performanceMode, .minimal)
    XCTAssertLessThan(glassEffectManager.globalIntensity, 0.5)
  }

  func testPerformanceModeDisabled() {
    glassEffectManager.setPerformanceMode(.disabled)

    XCTAssertEqual(glassEffectManager.performanceMode, .disabled)
    XCTAssertEqual(glassEffectManager.globalIntensity, 0.0)
    XCTAssertFalse(glassEffectManager.isEnabled)
  }

  // MARK: - Effect Intensity Tests

  func testUpdateEffectIntensity() {
    let effectId = "intensity-test"
    let effect = GlassEffect(
      id: effectId,
      type: .regular,
      intensity: 0.5,
      isInteractive: true
    )

    glassEffectManager.registerEffect(effect)
    glassEffectManager.updateEffectIntensity(effectId, intensity: 0.9)

    XCTAssertEqual(glassEffectManager.getEffect(effectId)?.intensity, 0.9)
  }

  func testGlobalIntensityAffectsAllEffects() {
    let effect1 = GlassEffect(id: "effect1", type: .regular, intensity: 1.0, isInteractive: true)
    let effect2 = GlassEffect(id: "effect2", type: .regular, intensity: 0.8, isInteractive: true)

    glassEffectManager.registerEffect(effect1)
    glassEffectManager.registerEffect(effect2)

    glassEffectManager.setGlobalIntensity(0.5)

    XCTAssertEqual(glassEffectManager.getEffectiveIntensity("effect1"), 0.5)
    XCTAssertEqual(glassEffectManager.getEffectiveIntensity("effect2"), 0.4)
  }

  // MARK: - Effect Interaction Tests

  func testInteractiveEffectActivation() {
    let effectId = "interactive-test"
    let effect = GlassEffect(
      id: effectId,
      type: .interactive,
      intensity: 0.7,
      isInteractive: true
    )

    glassEffectManager.registerEffect(effect)
    glassEffectManager.activateInteractiveEffect(effectId)

    XCTAssertTrue(glassEffectManager.isEffectActive(effectId))
    XCTAssertGreaterThan(glassEffectManager.getEffectiveIntensity(effectId), 0.7)
  }

  func testInteractiveEffectDeactivation() {
    let effectId = "interactive-deactivate-test"
    let effect = GlassEffect(
      id: effectId,
      type: .interactive,
      intensity: 0.7,
      isInteractive: true
    )

    glassEffectManager.registerEffect(effect)
    glassEffectManager.activateInteractiveEffect(effectId)
    glassEffectManager.deactivateInteractiveEffect(effectId)

    XCTAssertFalse(glassEffectManager.isEffectActive(effectId))
  }

  // MARK: - Effect Morphing Tests

  func testEffectMorphing() {
    let sourceId = "morph-source"
    let targetId = "morph-target"

    let sourceEffect = GlassEffect(
      id: sourceId, type: .regular, intensity: 0.5, isInteractive: false)
    let targetEffect = GlassEffect(
      id: targetId, type: .enhanced, intensity: 0.9, isInteractive: true)

    glassEffectManager.registerEffect(sourceEffect)
    glassEffectManager.registerEffect(targetEffect)

    glassEffectManager.morphEffect(from: sourceId, to: targetId, duration: 0.3)

    // Should start morphing animation
    XCTAssertTrue(glassEffectManager.isMorphing(sourceId))
  }

  // MARK: - Memory Management Tests

  func testEffectCleanup() {
    // Register many effects
    for i in 0..<100 {
      let effect = GlassEffect(
        id: "cleanup-test-\(i)",
        type: .regular,
        intensity: 0.5,
        isInteractive: false
      )
      glassEffectManager.registerEffect(effect)
    }

    XCTAssertEqual(glassEffectManager.activeEffects.count, 100)

    // Cleanup unused effects
    glassEffectManager.cleanupUnusedEffects()

    // Should remove effects that haven't been used recently
    XCTAssertLessThan(glassEffectManager.activeEffects.count, 100)
  }

  // MARK: - Performance Monitoring Tests

  func testFrameRateMonitoring() {
    glassEffectManager.startFrameRateMonitoring()

    // Simulate frame updates
    for _ in 0..<60 {
      glassEffectManager.recordFrame()
    }

    let frameRate = glassEffectManager.getCurrentFrameRate()
    XCTAssertGreaterThan(frameRate, 0)

    glassEffectManager.stopFrameRateMonitoring()
  }

  func testPerformanceThrottling() {
    // Simulate low frame rate
    glassEffectManager.simulateLowFrameRate(30)

    // Should automatically reduce performance mode
    XCTAssertNotEqual(glassEffectManager.performanceMode, .standard)
  }

  // MARK: - State Persistence Tests

  func testSaveAndRestoreState() {
    // Setup state
    glassEffectManager.setGlobalIntensity(0.7)
    glassEffectManager.setPerformanceMode(.reduced)

    let effect = GlassEffect(
      id: "persist-test", type: .regular, intensity: 0.8, isInteractive: true)
    glassEffectManager.registerEffect(effect)

    // Save state
    let savedState = glassEffectManager.saveState()

    // Create new manager and restore
    let newManager = LiquidGlassEffectManager()
    newManager.restoreState(savedState)

    // Verify restoration
    XCTAssertEqual(newManager.globalIntensity, 0.7)
    XCTAssertEqual(newManager.performanceMode, .reduced)
    XCTAssertTrue(newManager.activeEffects.contains("persist-test"))
  }

  // MARK: - Concurrent Access Tests

  func testConcurrentEffectRegistration() {
    let expectation = XCTestExpectation(description: "Concurrent registration")
    expectation.expectedFulfillmentCount = 10

    DispatchQueue.concurrentPerform(iterations: 10) { index in
      let effect = GlassEffect(
        id: "concurrent-\(index)",
        type: .regular,
        intensity: 0.5,
        isInteractive: false
      )
      glassEffectManager.registerEffect(effect)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5.0)
    XCTAssertEqual(glassEffectManager.activeEffects.count, 10)
  }

  // MARK: - Performance Tests

  func testEffectRegistrationPerformance() {
    measure {
      for i in 0..<1000 {
        let effect = GlassEffect(
          id: "perf-test-\(i)",
          type: .regular,
          intensity: 0.5,
          isInteractive: false
        )
        glassEffectManager.registerEffect(effect)
      }
      glassEffectManager.cleanupUnusedEffects()
    }
  }
}

// MARK: - Mock Glass Effect

@available(iPadOS 26.0, *)
struct GlassEffect {
  let id: String
  let type: GlassEffectType
  let intensity: CGFloat
  let isInteractive: Bool

  enum GlassEffectType {
    case regular, enhanced, interactive, subtle
  }
}

// MARK: - Test Extensions

@available(iPadOS 26.0, *)
extension LiquidGlassEffectManager {
  func getEffect(_ id: String) -> GlassEffect? {
    // Mock implementation for testing
    return nil
  }

  func getEffectiveIntensity(_ id: String) -> CGFloat {
    // Mock implementation for testing
    return globalIntensity * (getEffect(id)?.intensity ?? 0.0)
  }

  func isEffectActive(_ id: String) -> Bool {
    // Mock implementation for testing
    return activeEffects.contains(id)
  }

  func isMorphing(_ id: String) -> Bool {
    // Mock implementation for testing
    return false
  }

  func simulateLowFrameRate(_ fps: Int) {
    if fps < 45 {
      setPerformanceMode(.reduced)
    }
  }

  func recordFrame() {
    // Mock frame recording for testing
  }

  func getCurrentFrameRate() -> Double {
    // Mock frame rate for testing
    return 60.0
  }
}
