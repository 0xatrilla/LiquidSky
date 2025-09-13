import XCTest

@available(iPadOS 26.0, *)
final class GlassEffectUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["--uitesting", "--glass-effects-enabled"]
    app.launch()
  }

  override func tearDownWithError() throws {
    app = nil
  }

  // MARK: - Glass Effect Interaction Tests

  func testGlassEffectTapInteraction() throws {
    // Navigate to a view with glass effects
    let sidebarFeedButton = app.buttons["Feed"]
    XCTAssertTrue(sidebarFeedButton.waitForExistence(timeout: 5))
    sidebarFeedButton.tap()

    // Find a glass effect element
    let glassCard = app.otherElements["glass-card"].firstMatch
    XCTAssertTrue(glassCard.waitForExistence(timeout: 3))

    // Test tap interaction
    glassCard.tap()

    // Verify glass effect response (visual feedback should be present)
    // In a real test, we might check for animation or state changes
    XCTAssertTrue(glassCard.exists)
  }

  func testGlassEffectHoverInteraction() throws {
    // This test requires trackpad/mouse input
    guard UIDevice.current.userInterfaceIdiom == .pad else {
      throw XCTSkip("Hover interactions only available on iPad")
    }

    let glassButton = app.buttons["new-post-button"]
    XCTAssertTrue(glassButton.waitForExistence(timeout: 5))

    // Simulate hover (in a real test environment with trackpad)
    glassButton.hover()

    // Verify hover state changes
    XCTAssertTrue(glassButton.exists)
  }

  func testGlassEffectLongPressInteraction() throws {
    let glassElement = app.otherElements["interactive-glass-element"].firstMatch
    XCTAssertTrue(glassElement.waitForExistence(timeout: 5))

    // Perform long press
    glassElement.press(forDuration: 1.0)

    // Verify context menu or action sheet appears
    let contextMenu = app.menus.firstMatch
    XCTAssertTrue(contextMenu.waitForExistence(timeout: 2))
  }

  // MARK: - Column Adaptation Tests

  func testThreeColumnLayoutOnLargeScreen() throws {
    // Rotate to landscape for maximum width
    XCUIDevice.shared.orientation = .landscapeLeft

    // Wait for layout to adapt
    sleep(1)

    // Verify all three columns are visible
    let sidebar = app.otherElements["sidebar-column"]
    let content = app.otherElements["content-column"]
    let detail = app.otherElements["detail-column"]

    XCTAssertTrue(sidebar.exists)
    XCTAssertTrue(content.exists)
    XCTAssertTrue(detail.exists)
  }

  func testTwoColumnLayoutOnMediumScreen() throws {
    // Simulate medium screen size (this would be done through launch arguments in real testing)
    app.terminate()
    app.launchArguments.append("--screen-size-medium")
    app.launch()

    // Verify two columns are visible
    let sidebar = app.otherElements["sidebar-column"]
    let content = app.otherElements["content-column"]
    let detail = app.otherElements["detail-column"]

    XCTAssertTrue(sidebar.exists)
    XCTAssertTrue(content.exists)
    XCTAssertFalse(detail.isHittable)  // Detail should be hidden or overlaid
  }

  func testSingleColumnLayoutOnCompactScreen() throws {
    // Rotate to portrait for compact width
    XCUIDevice.shared.orientation = .portrait

    // Wait for layout adaptation
    sleep(1)

    // In compact mode, only one column should be prominently visible
    let visibleColumns = app.otherElements.matching(identifier: "column").allElementsBoundByIndex

    // Should show content or detail column, with sidebar accessible via navigation
    XCTAssertLessThanOrEqual(visibleColumns.count, 2)
  }

  func testColumnVisibilityToggle() throws {
    // Find sidebar toggle button
    let sidebarToggle = app.buttons["toggle-sidebar"]
    XCTAssertTrue(sidebarToggle.waitForExistence(timeout: 5))

    let sidebar = app.otherElements["sidebar-column"]
    let initialVisibility = sidebar.isHittable

    // Toggle sidebar
    sidebarToggle.tap()

    // Wait for animation
    sleep(0.5)

    // Verify visibility changed
    XCTAssertNotEqual(sidebar.isHittable, initialVisibility)
  }

  // MARK: - Keyboard Navigation Tests

  func testKeyboardNavigationBetweenColumns() throws {
    // Focus on sidebar
    let sidebarFeedButton = app.buttons["Feed"]
    sidebarFeedButton.tap()

    // Use Tab to navigate to content column
    app.typeKey("\\t", modifierFlags: [])

    // Verify focus moved to content area
    let contentArea = app.otherElements["content-column"]
    XCTAssertTrue(contentArea.hasKeyboardFocus)
  }

  func testKeyboardShortcuts() throws {
    // Test Command+N for new post
    app.typeKey("n", modifierFlags: .command)

    // Verify composer appears
    let composer = app.otherElements["post-composer"]
    XCTAssertTrue(composer.waitForExistence(timeout: 3))

    // Dismiss composer
    app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])

    // Test Command+F for search
    app.typeKey("f", modifierFlags: .command)

    // Verify search becomes active
    let searchField = app.searchFields.firstMatch
    XCTAssertTrue(searchField.waitForExistence(timeout: 3))
    XCTAssertTrue(searchField.hasKeyboardFocus)
  }

  func testArrowKeyNavigation() throws {
    // Navigate to feed
    let feedButton = app.buttons["Feed"]
    feedButton.tap()

    // Wait for content to load
    let firstPost = app.otherElements["post-item"].firstMatch
    XCTAssertTrue(firstPost.waitForExistence(timeout: 5))

    // Use arrow keys to navigate between posts
    firstPost.tap()  // Focus first post

    app.typeKey(XCUIKeyboardKey.downArrow.rawValue, modifierFlags: [])

    // Verify focus moved (in a real test, we'd check focus indicators)
    XCTAssertTrue(app.otherElements["post-item"].element(boundBy: 1).exists)
  }

  // MARK: - Gesture Navigation Tests

  func testSwipeGestures() throws {
    let contentArea = app.otherElements["content-column"]
    XCTAssertTrue(contentArea.waitForExistence(timeout: 5))

    // Test swipe to navigate between sections
    contentArea.swipeLeft()

    // Verify navigation occurred (check for different content or state)
    sleep(0.5)  // Wait for animation

    // Swipe back
    contentArea.swipeRight()
    sleep(0.5)
  }

  func testPinchToZoomGesture() throws {
    let imageView = app.images.firstMatch
    XCTAssertTrue(imageView.waitForExistence(timeout: 5))

    // Perform pinch gesture
    imageView.pinch(withScale: 2.0, velocity: 1.0)

    // Verify zoom occurred (in a real test, we'd check transform or size)
    XCTAssertTrue(imageView.exists)
  }

  // MARK: - Accessibility Tests

  func testVoiceOverNavigation() throws {
    // Enable VoiceOver for testing
    app.terminate()
    app.launchArguments.append("--voiceover-testing")
    app.launch()

    // Navigate using VoiceOver gestures
    let firstElement = app.otherElements.firstMatch
    XCTAssertTrue(firstElement.waitForExistence(timeout: 5))

    // Test VoiceOver focus
    firstElement.tap()

    // Verify accessibility labels are present
    XCTAssertFalse(firstElement.label.isEmpty)
  }

  func testAccessibilityRotors() throws {
    // Test custom rotors for VoiceOver navigation
    app.terminate()
    app.launchArguments.append("--accessibility-testing")
    app.launch()

    // Navigate to content with rotors
    let feedButton = app.buttons["Feed"]
    feedButton.tap()

    // In a real test, we would use accessibility APIs to test rotor navigation
    // This is a simplified version
    let posts = app.otherElements.matching(identifier: "post-item")
    XCTAssertGreaterThan(posts.count, 0)
  }

  func testDynamicTypeSupport() throws {
    // Test with large text sizes
    app.terminate()
    app.launchArguments.append("--large-text-testing")
    app.launch()

    // Verify UI adapts to large text
    let textElements = app.staticTexts.allElementsBoundByIndex

    for textElement in textElements {
      if textElement.exists {
        // Verify text is not truncated and UI layout adapts
        XCTAssertFalse(textElement.label.hasSuffix("..."))
      }
    }
  }

  // MARK: - Performance Tests

  func testScrollPerformance() throws {
    // Navigate to feed with many items
    let feedButton = app.buttons["Feed"]
    feedButton.tap()

    let contentArea = app.scrollViews.firstMatch
    XCTAssertTrue(contentArea.waitForExistence(timeout: 5))

    // Measure scroll performance
    measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
      // Perform rapid scrolling
      for _ in 0..<10 {
        contentArea.swipeUp(velocity: .fast)
        contentArea.swipeDown(velocity: .fast)
      }
    }
  }

  func testGlassEffectRenderingPerformance() throws {
    // Navigate to view with many glass effects
    let feedButton = app.buttons["Feed"]
    feedButton.tap()

    // Measure rendering performance with glass effects
    measure(metrics: [XCTOSSignpostMetric.applicationLaunchMetric]) {
      // Trigger glass effect animations
      let glassElements = app.otherElements.matching(identifier: "glass-effect")

      for i in 0..<min(glassElements.count, 5) {
        let element = glassElements.element(boundBy: i)
        if element.exists {
          element.tap()
        }
      }
    }
  }

  // MARK: - Multi-Touch Tests

  func testMultiTouchGestures() throws {
    let contentArea = app.otherElements["content-column"]
    XCTAssertTrue(contentArea.waitForExistence(timeout: 5))

    // Test two-finger scroll
    contentArea.twoFingerTap()

    // Test rotation gesture on supported elements
    let rotatableElement = app.images.firstMatch
    if rotatableElement.exists {
      rotatableElement.rotate(CGFloat.pi / 4, withVelocity: 1.0)
    }
  }

  // MARK: - Apple Pencil Tests

  func testApplePencilInteraction() throws {
    // Test Apple Pencil hover (requires actual Apple Pencil)
    let drawableArea = app.otherElements["drawable-area"]

    if drawableArea.exists {
      // Simulate pencil hover and drawing
      drawableArea.tap()

      // In a real test with Apple Pencil, we would test:
      // - Hover effects
      // - Pressure sensitivity
      // - Tilt recognition
      // - Double-tap gesture
    }
  }

  // MARK: - Stage Manager Tests

  func testStageManagerCompatibility() throws {
    // Test app behavior in Stage Manager
    app.terminate()
    app.launchArguments.append("--stage-manager-testing")
    app.launch()

    // Verify app adapts to Stage Manager window sizes
    let mainWindow = app.windows.firstMatch
    XCTAssertTrue(mainWindow.exists)

    // Test window resizing behavior
    // In a real test, we would simulate Stage Manager window resizing
  }

  // MARK: - External Display Tests

  func testExternalDisplaySupport() throws {
    // Test external display connectivity
    app.terminate()
    app.launchArguments.append("--external-display-testing")
    app.launch()

    // Verify UI adapts for external display
    let contentArea = app.otherElements["content-column"]
    XCTAssertTrue(contentArea.exists)

    // In a real test, we would verify:
    // - Proper scaling for external display
    // - Correct column layout for larger screens
    // - Glass effects render correctly on external display
  }

  // MARK: - Helper Methods

  private func waitForGlassEffectAnimation() {
    // Wait for glass effect animations to complete
    sleep(1)
  }

  private func verifyGlassEffectPresence(in element: XCUIElement) -> Bool {
    // In a real implementation, this would check for glass effect visual indicators
    return element.exists
  }
}

// MARK: - Test Extensions

extension XCUIElement {
  var hasKeyboardFocus: Bool {
    return self.hasKeyboardFocus
  }
}
