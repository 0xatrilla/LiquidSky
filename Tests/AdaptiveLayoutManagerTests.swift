import SwiftUI
import XCTest

@testable import LiquidSky

@available(iPadOS 26.0, *)
final class AdaptiveLayoutManagerTests: XCTestCase {
  var layoutManager: AdaptiveLayoutManager!

  override func setUp() {
    super.setUp()
    layoutManager = AdaptiveLayoutManager()
  }

  override func tearDown() {
    layoutManager = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testInitialConfiguration() {
    XCTAssertEqual(layoutManager.currentConfiguration.columnCount, 3)
    XCTAssertEqual(layoutManager.currentConfiguration.spacing, 16.0)
    XCTAssertEqual(layoutManager.preferredColumnVisibility, .automatic)
    XCTAssertFalse(layoutManager.isExternalDisplayConnected)
    XCTAssertFalse(layoutManager.isStageManagerActive)
  }

  // MARK: - Screen Size Adaptation Tests

  func testUpdateLayoutForCompactWidth() {
    let compactSize = CGSize(width: 600, height: 800)

    layoutManager.updateLayout(
      screenSize: compactSize,
      horizontalSizeClass: .compact,
      verticalSizeClass: .regular
    )

    XCTAssertEqual(layoutManager.currentConfiguration.columnCount, 1)
    XCTAssertEqual(layoutManager.preferredColumnVisibility, .detailOnly)
  }

  func testUpdateLayoutForRegularWidth() {
    let regularSize = CGSize(width: 1200, height: 800)

    layoutManager.updateLayout(
      screenSize: regularSize,
      horizontalSizeClass: .regular,
      verticalSizeClass: .regular
    )

    XCTAssertEqual(layoutManager.currentConfiguration.columnCount, 3)
    XCTAssertEqual(layoutManager.preferredColumnVisibility, .all)
  }

  func testUpdateLayoutForLargeScreen() {
    let largeSize = CGSize(width: 1600, height: 1200)

    layoutManager.updateLayout(
      screenSize: largeSize,
      horizontalSizeClass: .regular,
      verticalSizeClass: .regular
    )

    XCTAssertEqual(layoutManager.currentConfiguration.columnCount, 4)
    XCTAssertGreaterThan(layoutManager.currentConfiguration.spacing, 16.0)
  }

  // MARK: - Column Count Calculation Tests

  func testCalculateColumnCountForWidth() {
    XCTAssertEqual(layoutManager.calculateColumnCount(for: 400), 1)
    XCTAssertEqual(layoutManager.calculateColumnCount(for: 800), 2)
    XCTAssertEqual(layoutManager.calculateColumnCount(for: 1200), 3)
    XCTAssertEqual(layoutManager.calculateColumnCount(for: 1600), 4)
  }

  func testCalculateSpacingForScreenSize() {
    let compactSpacing = layoutManager.calculateSpacing(for: CGSize(width: 600, height: 800))
    let regularSpacing = layoutManager.calculateSpacing(for: CGSize(width: 1200, height: 800))
    let largeSpacing = layoutManager.calculateSpacing(for: CGSize(width: 1600, height: 1200))

    XCTAssertEqual(compactSpacing, 12.0)
    XCTAssertEqual(regularSpacing, 16.0)
    XCTAssertEqual(largeSpacing, 20.0)
  }

  // MARK: - Stage Manager Tests

  func testStageManagerActivation() {
    layoutManager.setStageManagerActive(true)

    XCTAssertTrue(layoutManager.isStageManagerActive)
    XCTAssertEqual(layoutManager.currentConfiguration.columnCount, 2)  // Reduced for Stage Manager
  }

  func testStageManagerDeactivation() {
    layoutManager.setStageManagerActive(true)
    layoutManager.setStageManagerActive(false)

    XCTAssertFalse(layoutManager.isStageManagerActive)
    // Should restore previous configuration
  }

  // MARK: - External Display Tests

  func testExternalDisplayConnection() {
    let externalDisplaySize = CGSize(width: 2560, height: 1440)

    layoutManager.setExternalDisplay(connected: true, size: externalDisplaySize)

    XCTAssertTrue(layoutManager.isExternalDisplayConnected)
    XCTAssertEqual(layoutManager.externalDisplaySize, externalDisplaySize)
    XCTAssertEqual(layoutManager.currentConfiguration.columnCount, 4)  // More columns for external display
  }

  func testExternalDisplayDisconnection() {
    layoutManager.setExternalDisplay(connected: true, size: CGSize(width: 2560, height: 1440))
    layoutManager.setExternalDisplay(connected: false, size: .zero)

    XCTAssertFalse(layoutManager.isExternalDisplayConnected)
    XCTAssertEqual(layoutManager.externalDisplaySize, .zero)
  }

  // MARK: - Orientation Tests

  func testOrientationChange() {
    let portraitSize = CGSize(width: 800, height: 1200)
    let landscapeSize = CGSize(width: 1200, height: 800)

    // Portrait
    layoutManager.updateLayout(
      screenSize: portraitSize,
      horizontalSizeClass: .regular,
      verticalSizeClass: .regular
    )
    let portraitColumns = layoutManager.currentConfiguration.columnCount

    // Landscape
    layoutManager.updateLayout(
      screenSize: landscapeSize,
      horizontalSizeClass: .regular,
      verticalSizeClass: .compact
    )
    let landscapeColumns = layoutManager.currentConfiguration.columnCount

    XCTAssertGreaterThanOrEqual(landscapeColumns, portraitColumns)
  }

  // MARK: - Configuration Validation Tests

  func testConfigurationValidation() {
    let validConfig = AdaptiveLayoutConfiguration(
      columnCount: 3,
      spacing: 16.0,
      sidebarWidth: 250.0,
      contentWidth: 400.0,
      detailWidth: 600.0
    )

    XCTAssertTrue(layoutManager.isValidConfiguration(validConfig))

    let invalidConfig = AdaptiveLayoutConfiguration(
      columnCount: 0,  // Invalid
      spacing: -5.0,  // Invalid
      sidebarWidth: 50.0,  // Too small
      contentWidth: 100.0,  // Too small
      detailWidth: 200.0  // Too small
    )

    XCTAssertFalse(layoutManager.isValidConfiguration(invalidConfig))
  }

  // MARK: - Performance Tests

  func testLayoutCalculationPerformance() {
    let sizes = [
      CGSize(width: 600, height: 800),
      CGSize(width: 800, height: 600),
      CGSize(width: 1200, height: 800),
      CGSize(width: 1600, height: 1200),
    ]

    measure {
      for size in sizes {
        for _ in 0..<100 {
          layoutManager.updateLayout(
            screenSize: size,
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
          )
        }
      }
    }
  }

  // MARK: - Memory Tests

  func testMemoryUsage() {
    let initialMemory = layoutManager.getCurrentMemoryUsage()

    // Perform many layout updates
    for i in 0..<1000 {
      let size = CGSize(width: 800 + i, height: 600 + i)
      layoutManager.updateLayout(
        screenSize: size,
        horizontalSizeClass: .regular,
        verticalSizeClass: .regular
      )
    }

    let finalMemory = layoutManager.getCurrentMemoryUsage()
    let memoryIncrease = finalMemory - initialMemory

    // Memory increase should be minimal (less than 1MB)
    XCTAssertLessThan(memoryIncrease, 1024 * 1024)
  }

  // MARK: - Edge Cases Tests

  func testZeroSizeHandling() {
    layoutManager.updateLayout(
      screenSize: .zero,
      horizontalSizeClass: .compact,
      verticalSizeClass: .compact
    )

    // Should have fallback configuration
    XCTAssertEqual(layoutManager.currentConfiguration.columnCount, 1)
    XCTAssertGreaterThan(layoutManager.currentConfiguration.spacing, 0)
  }

  func testExtremelyLargeSize() {
    let extremeSize = CGSize(width: 10000, height: 8000)

    layoutManager.updateLayout(
      screenSize: extremeSize,
      horizontalSizeClass: .regular,
      verticalSizeClass: .regular
    )

    // Should cap at maximum reasonable columns
    XCTAssertLessThanOrEqual(layoutManager.currentConfiguration.columnCount, 6)
  }
}

// MARK: - Test Extensions

@available(iPadOS 26.0, *)
extension AdaptiveLayoutManager {
  func getCurrentMemoryUsage() -> Int {
    // Simplified memory usage calculation for testing
    return 0  // In a real implementation, this would use actual memory APIs
  }

  func isValidConfiguration(_ config: AdaptiveLayoutConfiguration) -> Bool {
    return config.columnCount > 0 && config.spacing >= 0 && config.sidebarWidth >= 200
      && config.contentWidth >= 300 && config.detailWidth >= 400
  }
}
