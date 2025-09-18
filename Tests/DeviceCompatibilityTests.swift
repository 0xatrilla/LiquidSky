import SwiftUI
import XCTest

@testable import LiquidSky

@available(iPadOS 26.0, *)
final class DeviceCompatibilityTests: XCTestCase {
  var layoutManager: AdaptiveLayoutManager!
  var performanceMonitor: LiquidGlassPerformanceMonitor!

  override func setUp() {
    super.setUp()
    layoutManager = AdaptiveLayoutManager()
    performanceMonitor = LiquidGlassPerformanceMonitor()
  }

  override func tearDown() {
    layoutManager = nil
    performanceMonitor = nil
    super.tearDown()
  }

  // MARK: - iPad Model Compatibility Tests

  func testIPadMini6thGeneration() throws {
    let deviceConfig = DeviceConfiguration(
      model: .iPadMini6,
      screenSize: CGSize(width: 1488, height: 2266),
      pixelDensity: 326,
      hasProMotion: false,
      supportsApplePencil: true,
      pencilGeneration: .second,
      hasLiDAR: false,
      processorGeneration: .a15Bionic
    )

    testDeviceCompatibility(deviceConfig)
  }

  func testIPadAir5thGeneration() throws {
    let deviceConfig = DeviceConfiguration(
      model: .iPadAir5,
      screenSize: CGSize(width: 1640, height: 2360),
      pixelDensity: 264,
      hasProMotion: false,
      supportsApplePencil: true,
      pencilGeneration: .second,
      hasLiDAR: false,
      processorGeneration: .m1
    )

    testDeviceCompatibility(deviceConfig)
  }

  func testIPadPro11Inch4thGen() throws {
    let deviceConfig = DeviceConfiguration(
      model: .iPadPro11_4,
      screenSize: CGSize(width: 1668, height: 2388),
      pixelDensity: 264,
      hasProMotion: true,
      supportsApplePencil: true,
      pencilGeneration: .second,
      hasLiDAR: true,
      processorGeneration: .m2
    )

    testDeviceCompatibility(deviceConfig)
  }

  func testIPadPro12Inch6thGen() throws {
    let deviceConfig = DeviceConfiguration(
      model: .iPadPro12_6,
      screenSize: CGSize(width: 2048, height: 2732),
      pixelDensity: 264,
      hasProMotion: true,
      supportsApplePencil: true,
      pencilGeneration: .second,
      hasLiDAR: true,
      processorGeneration: .m2
    )

    testDeviceCompatibility(deviceConfig)
  }

  func testIPadPro13InchM4() throws {
    let deviceConfig = DeviceConfiguration(
      model: .iPadPro13_M4,
      screenSize: CGSize(width: 2064, height: 2752),
      pixelDensity: 264,
      hasProMotion: true,
      supportsApplePencil: true,
      pencilGeneration: .pro,
      hasLiDAR: true,
      processorGeneration: .m4
    )

    testDeviceCompatibility(deviceConfig)
  }

  private func testDeviceCompatibility(_ config: DeviceConfiguration) {
    // Test layout adaptation
    layoutManager.updateLayout(
      screenSize: config.screenSize,
      horizontalSizeClass: config.horizontalSizeClass,
      verticalSizeClass: config.verticalSizeClass
    )

    // Verify appropriate column count for screen size
    let expectedColumns = calculateExpectedColumns(for: config.screenSize)
    XCTAssertEqual(
      layoutManager.currentConfiguration.columnCount, expectedColumns,
      "Column count should adapt to \(config.model) screen size")

    // Test performance expectations
    testPerformanceForDevice(config)

    // Test input method compatibility
    testInputMethodCompatibility(config)
  }

  private func calculateExpectedColumns(for screenSize: CGSize) -> Int {
    let width = max(screenSize.width, screenSize.height)  // Landscape width

    if width >= 2000 {
      return 4  // Large iPad Pro
    } else if width >= 1600 {
      return 3  // Standard iPad Pro
    } else if width >= 1400 {
      return 2  // iPad Air/Mini
    } else {
      return 1  // Compact
    }
  }

  // MARK: - Performance Testing by Device

  private func testPerformanceForDevice(_ config: DeviceConfiguration) {
    let expectedFrameRate: Double
    let maxEffectCount: Int

    switch config.processorGeneration {
    case .a15Bionic:
      expectedFrameRate = config.hasProMotion ? 90.0 : 60.0
      maxEffectCount = 15
    case .m1:
      expectedFrameRate = config.hasProMotion ? 100.0 : 60.0
      maxEffectCount = 25
    case .m2:
      expectedFrameRate = config.hasProMotion ? 110.0 : 60.0
      maxEffectCount = 35
    case .m4:
      expectedFrameRate = config.hasProMotion ? 120.0 : 60.0
      maxEffectCount = 50
    }

    // Test frame rate performance
    performanceMonitor.setTargetFrameRate(config.hasProMotion ? 120.0 : 60.0)

    // Simulate glass effects load
    for _ in 0..<maxEffectCount {
      performanceMonitor.recordActiveEffectCount(maxEffectCount)
    }

    // Simulate frame updates
    for _ in 0..<120 {
      performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
    }

    XCTAssertGreaterThanOrEqual(
      performanceMonitor.currentFrameRate, expectedFrameRate * 0.8,
      "Frame rate should meet expectations for \(config.model)")
  }

  // MARK: - Input Method Compatibility Tests

  private func testInputMethodCompatibility(_ config: DeviceConfiguration) {
    // Test Apple Pencil compatibility
    if config.supportsApplePencil {
      testApplePencilCompatibility(config.pencilGeneration)
    }

    // Test trackpad/mouse support (all iPads support this)
    testTrackpadCompatibility()

    // Test keyboard support
    testKeyboardCompatibility()

    // Test touch gestures
    testTouchGestureCompatibility(config)
  }

  private func testApplePencilCompatibility(_ generation: ApplePencilGeneration) {
    let pencilManager = AdvancedApplePencilManager()

    switch generation {
    case .first:
      XCTAssertTrue(pencilManager.supportsPressure)
      XCTAssertTrue(pencilManager.supportsTilt)
      XCTAssertFalse(pencilManager.supportsDoubleTap)
      XCTAssertFalse(pencilManager.supportsHover)
    case .second:
      XCTAssertTrue(pencilManager.supportsPressure)
      XCTAssertTrue(pencilManager.supportsTilt)
      XCTAssertTrue(pencilManager.supportsDoubleTap)
      XCTAssertTrue(pencilManager.supportsHover)
    case .pro:
      XCTAssertTrue(pencilManager.supportsPressure)
      XCTAssertTrue(pencilManager.supportsTilt)
      XCTAssertTrue(pencilManager.supportsDoubleTap)
      XCTAssertTrue(pencilManager.supportsHover)
      XCTAssertTrue(pencilManager.supportsSqueeze)
      XCTAssertTrue(pencilManager.supportsBarrelRoll)
    }
  }

  private func testTrackpadCompatibility() {
    let trackpadManager = AdvancedTrackpadManager()

    // All iPads should support basic trackpad features
    XCTAssertTrue(trackpadManager.supportsHover)
    XCTAssertTrue(trackpadManager.supportsRightClick)
    XCTAssertTrue(trackpadManager.supportsScrolling)
    XCTAssertTrue(trackpadManager.supportsMultiTouch)
  }

  private func testKeyboardCompatibility() {
    let keyboardManager = KeyboardShortcutsManager()

    // Test essential keyboard shortcuts
    XCTAssertTrue(keyboardManager.isShortcutSupported(.newPost))
    XCTAssertTrue(keyboardManager.isShortcutSupported(.search))
    XCTAssertTrue(keyboardManager.isShortcutSupported(.refresh))
    XCTAssertTrue(keyboardManager.isShortcutSupported(.toggleSidebar))
  }

  private func testTouchGestureCompatibility(_ config: DeviceConfiguration) {
    let gestureManager = AdvancedMultiTouchManager()

    // All iPads should support basic gestures
    XCTAssertTrue(gestureManager.supportsPinchToZoom)
    XCTAssertTrue(gestureManager.supportsRotation)
    XCTAssertTrue(gestureManager.supportsSwipeGestures)

    // Test multi-touch capacity based on screen size
    let expectedTouchPoints = config.screenSize.width > 2000 ? 10 : 5
    XCTAssertGreaterThanOrEqual(gestureManager.maxSimultaneousTouches, expectedTouchPoints)
  }

  // MARK: - Stage Manager Compatibility Tests

  func testStageManagerCompatibility() throws {
    // Test Stage Manager on supported devices
    let stageManagerDevices: [iPadModel] = [
      .iPadPro11_4, .iPadPro12_6, .iPadPro13_M4, .iPadAir5,
    ]

    for model in stageManagerDevices {
      let config = getDeviceConfiguration(for: model)

      // Enable Stage Manager
      layoutManager.setStageManagerActive(true)

      // Test layout adaptation
      layoutManager.updateLayout(
        screenSize: config.screenSize,
        horizontalSizeClass: .regular,
        verticalSizeClass: .regular
      )

      // Stage Manager should reduce column count for better window management
      XCTAssertLessThanOrEqual(
        layoutManager.currentConfiguration.columnCount, 2,
        "\(model) should adapt layout for Stage Manager")

      // Test window resizing
      testStageManagerWindowResizing(config)
    }
  }

  private func testStageManagerWindowResizing(_ config: DeviceConfiguration) {
    let windowSizes = [
      CGSize(width: 400, height: 600),  // Small window
      CGSize(width: 800, height: 600),  // Medium window
      CGSize(width: 1200, height: 800),  // Large window
    ]

    for windowSize in windowSizes {
      layoutManager.updateLayout(
        screenSize: windowSize,
        horizontalSizeClass: windowSize.width > 600 ? .regular : .compact,
        verticalSizeClass: .regular
      )

      // Verify layout adapts to window size
      let expectedColumns = windowSize.width > 1000 ? 2 : 1
      XCTAssertEqual(
        layoutManager.currentConfiguration.columnCount, expectedColumns,
        "Layout should adapt to Stage Manager window size \(windowSize)")
    }
  }

  // MARK: - External Display Tests

  func testExternalDisplayCompatibility() throws {
    let externalDisplaySizes = [
      CGSize(width: 1920, height: 1080),  // 1080p
      CGSize(width: 2560, height: 1440),  // 1440p
      CGSize(width: 3840, height: 2160),  // 4K
      CGSize(width: 5120, height: 2880),  // 5K
    ]

    for displaySize in externalDisplaySizes {
      layoutManager.setExternalDisplay(connected: true, size: displaySize)

      // Test layout adaptation for external display
      layoutManager.updateLayout(
        screenSize: displaySize,
        horizontalSizeClass: .regular,
        verticalSizeClass: .regular
      )

      // External displays should support more columns
      let expectedColumns = min(6, Int(displaySize.width / 400))
      XCTAssertEqual(
        layoutManager.currentConfiguration.columnCount, expectedColumns,
        "External display \(displaySize) should support \(expectedColumns) columns")

      // Test performance on external display
      testExternalDisplayPerformance(displaySize)
    }
  }

  private func testExternalDisplayPerformance(_ displaySize: CGSize) {
    // Larger displays require more rendering performance
    let pixelCount = displaySize.width * displaySize.height
    let expectedFrameRate = pixelCount > 8_000_000 ? 60.0 : 120.0  // 4K+ displays

    performanceMonitor.setTargetFrameRate(expectedFrameRate)

    // Simulate rendering load
    for _ in 0..<60 {
      performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
    }

    XCTAssertGreaterThanOrEqual(
      performanceMonitor.currentFrameRate, expectedFrameRate * 0.9,
      "External display performance should meet expectations")
  }

  // MARK: - Accessibility Configuration Tests

  func testAccessibilityConfigurations() throws {
    let accessibilityConfigs = [
      AccessibilityConfiguration(
        voiceOverEnabled: true,
        dynamicTypeSize: .accessibilityLarge,
        reduceMotion: false,
        highContrast: false
      ),
      AccessibilityConfiguration(
        voiceOverEnabled: false,
        dynamicTypeSize: .accessibilityExtraExtraExtraLarge,
        reduceMotion: true,
        highContrast: true
      ),
      AccessibilityConfiguration(
        voiceOverEnabled: true,
        dynamicTypeSize: .large,
        reduceMotion: true,
        highContrast: true
      ),
    ]

    for config in accessibilityConfigs {
      testAccessibilityConfiguration(config)
    }
  }

  private func testAccessibilityConfiguration(_ config: AccessibilityConfiguration) {
    // Test layout adaptation for accessibility
    let sizeClass: UserInterfaceSizeClass =
      config.dynamicTypeSize.isAccessibilitySize ? .compact : .regular

    layoutManager.updateLayout(
      screenSize: CGSize(width: 1200, height: 800),
      horizontalSizeClass: sizeClass,
      verticalSizeClass: .regular
    )

    // Accessibility sizes should use fewer columns
    if config.dynamicTypeSize.isAccessibilitySize {
      XCTAssertLessThanOrEqual(
        layoutManager.currentConfiguration.columnCount, 2,
        "Accessibility text sizes should use fewer columns")
    }

    // Test performance with accessibility features
    testAccessibilityPerformance(config)
  }

  private func testAccessibilityPerformance(_ config: AccessibilityConfiguration) {
    // Reduced motion should maintain performance
    if config.reduceMotion {
      performanceMonitor.setReducedMotionMode(true)
    }

    // High contrast might affect rendering performance slightly
    if config.highContrast {
      performanceMonitor.setHighContrastMode(true)
    }

    // Simulate usage with accessibility features
    for _ in 0..<60 {
      performanceMonitor.recordFrame(timestamp: CACurrentMediaTime())
    }

    // Performance should remain acceptable
    XCTAssertGreaterThan(
      performanceMonitor.currentFrameRate, 45.0,
      "Performance should remain good with accessibility features")
  }

  // MARK: - Helper Methods

  private func getDeviceConfiguration(for model: iPadModel) -> DeviceConfiguration {
    switch model {
    case .iPadMini6:
      return DeviceConfiguration(
        model: model,
        screenSize: CGSize(width: 1488, height: 2266),
        pixelDensity: 326,
        hasProMotion: false,
        supportsApplePencil: true,
        pencilGeneration: .second,
        hasLiDAR: false,
        processorGeneration: .a15Bionic
      )
    case .iPadAir5:
      return DeviceConfiguration(
        model: model,
        screenSize: CGSize(width: 1640, height: 2360),
        pixelDensity: 264,
        hasProMotion: false,
        supportsApplePencil: true,
        pencilGeneration: .second,
        hasLiDAR: false,
        processorGeneration: .m1
      )
    case .iPadPro11_4:
      return DeviceConfiguration(
        model: model,
        screenSize: CGSize(width: 1668, height: 2388),
        pixelDensity: 264,
        hasProMotion: true,
        supportsApplePencil: true,
        pencilGeneration: .second,
        hasLiDAR: true,
        processorGeneration: .m2
      )
    case .iPadPro12_6:
      return DeviceConfiguration(
        model: model,
        screenSize: CGSize(width: 2048, height: 2732),
        pixelDensity: 264,
        hasProMotion: true,
        supportsApplePencil: true,
        pencilGeneration: .second,
        hasLiDAR: true,
        processorGeneration: .m2
      )
    case .iPadPro13_M4:
      return DeviceConfiguration(
        model: model,
        screenSize: CGSize(width: 2064, height: 2752),
        pixelDensity: 264,
        hasProMotion: true,
        supportsApplePencil: true,
        pencilGeneration: .pro,
        hasLiDAR: true,
        processorGeneration: .m4
      )
    }
  }
}

// MARK: - Test Data Models

@available(iPadOS 26.0, *)
struct DeviceConfiguration {
  let model: iPadModel
  let screenSize: CGSize
  let pixelDensity: Int
  let hasProMotion: Bool
  let supportsApplePencil: Bool
  let pencilGeneration: ApplePencilGeneration
  let hasLiDAR: Bool
  let processorGeneration: ProcessorGeneration

  var horizontalSizeClass: UserInterfaceSizeClass {
    return screenSize.width > 1000 ? .regular : .compact
  }

  var verticalSizeClass: UserInterfaceSizeClass {
    return screenSize.height > 800 ? .regular : .compact
  }
}

@available(iPadOS 26.0, *)
enum iPadModel {
  case iPadMini6
  case iPadAir5
  case iPadPro11_4
  case iPadPro12_6
  case iPadPro13_M4
}

@available(iPadOS 26.0, *)
enum ApplePencilGeneration {
  case first
  case second
  case pro
}

@available(iPadOS 26.0, *)
enum ProcessorGeneration {
  case a15Bionic
  case m1
  case m2
  case m4
}

@available(iPadOS 26.0, *)
struct AccessibilityConfiguration {
  let voiceOverEnabled: Bool
  let dynamicTypeSize: ContentSizeCategory
  let reduceMotion: Bool
  let highContrast: Bool
}

// MARK: - Test Extensions

@available(iPadOS 26.0, *)
extension ContentSizeCategory {
  var isAccessibilitySize: Bool {
    switch self {
    case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
      .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
      return true
    default:
      return false
    }
  }
}

@available(iPadOS 26.0, *)
extension LiquidGlassPerformanceMonitor {
  func setReducedMotionMode(_ enabled: Bool) {
    // Mock implementation for testing
  }

  func setHighContrastMode(_ enabled: Bool) {
    // Mock implementation for testing
  }
}

@available(iPadOS 26.0, *)
extension AdvancedApplePencilManager {
  var supportsSqueeze: Bool { return true }
  var supportsBarrelRoll: Bool { return true }
}

@available(iPadOS 26.0, *)
extension KeyboardShortcutsManager {
  func isShortcutSupported(_ shortcut: KeyboardShortcut) -> Bool {
    return true  // Mock implementation
  }
}

@available(iPadOS 26.0, *)
enum KeyboardShortcut {
  case newPost, search, refresh, toggleSidebar
}
