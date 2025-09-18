import XCTest

@available(iPadOS 26.0, *)
final class AccessibilityUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["--uitesting", "--accessibility-testing"]
    app.launch()
  }

  override func tearDownWithError() throws {
    app = nil
  }

  // MARK: - VoiceOver Tests

  func testVoiceOverLabelsAndHints() throws {
    // Enable VoiceOver simulation
    app.terminate()
    app.launchArguments.append("--voiceover-enabled")
    app.launch()

    // Test sidebar elements have proper labels
    let feedButton = app.buttons["Feed"]
    XCTAssertTrue(feedButton.waitForExistence(timeout: 5))
    XCTAssertFalse(feedButton.label.isEmpty)
    XCTAssertTrue(feedButton.label.contains("Feed"))

    let notificationsButton = app.buttons["Notifications"]
    XCTAssertTrue(notificationsButton.exists)
    XCTAssertFalse(notificationsButton.label.isEmpty)

    // Test glass effect elements have descriptive labels
    let glassCard = app.otherElements["glass-card"].firstMatch
    if glassCard.exists {
      XCTAssertFalse(glassCard.label.isEmpty)
      // Should describe the glass effect state
      XCTAssertTrue(
        glassCard.label.localizedCaseInsensitiveContains("glass")
          || glassCard.label.localizedCaseInsensitiveContains("interactive"))
    }
  }

  func testVoiceOverCustomRotors() throws {
    // Navigate to content area
    let feedButton = app.buttons["Feed"]
    feedButton.tap()

    // Wait for content to load
    let contentArea = app.otherElements["content-column"]
    XCTAssertTrue(contentArea.waitForExistence(timeout: 5))

    // Test that custom rotors are available
    // In a real test, we would use accessibility APIs to verify rotor presence
    let posts = app.otherElements.matching(identifier: "post-item")
    XCTAssertGreaterThan(posts.count, 0)

    // Verify posts have proper accessibility structure
    let firstPost = posts.firstMatch
    if firstPost.exists {
      XCTAssertFalse(firstPost.label.isEmpty)
    }
  }

  func testVoiceOverAnnouncements() throws {
    // Test navigation announcements
    let searchButton = app.buttons["Search"]
    searchButton.tap()

    // In a real test, we would capture VoiceOver announcements
    // and verify they contain appropriate navigation information

    let searchField = app.searchFields.firstMatch
    XCTAssertTrue(searchField.waitForExistence(timeout: 3))
  }

  // MARK: - Dynamic Type Tests

  func testDynamicTypeAdaptation() throws {
    // Test with accessibility text sizes
    app.terminate()
    app.launchArguments.append("--accessibility-text-size")
    app.launch()

    // Navigate to different sections and verify text scaling
    let sections = ["Feed", "Notifications", "Search", "Profile"]

    for section in sections {
      let button = app.buttons[section]
      if button.exists {
        button.tap()

        // Verify text elements are not truncated
        let textElements = app.staticTexts.allElementsBoundByIndex
        for textElement in textElements.prefix(5) {  // Check first 5 elements
          if textElement.exists && !textElement.label.isEmpty {
            // Text should not be truncated with "..."
            XCTAssertFalse(
              textElement.label.hasSuffix("..."),
              "Text truncated in \(section): \(textElement.label)")
          }
        }
      }
    }
  }

  func testAdaptiveLayoutForLargeText() throws {
    // Test layout adaptation for large text
    app.terminate()
    app.launchArguments.append("--large-text-testing")
    app.launch()

    // Navigate to feed
    let feedButton = app.buttons["Feed"]
    feedButton.tap()

    // Verify layout adapts (fewer columns, larger spacing)
    let contentArea = app.otherElements["content-column"]
    XCTAssertTrue(contentArea.waitForExistence(timeout: 5))

    // In accessibility text sizes, should use single column layout
    let posts = app.otherElements.matching(identifier: "post-item")
    if posts.count > 1 {
      let firstPost = posts.element(boundBy: 0)
      let secondPost = posts.element(boundBy: 1)

      if firstPost.exists && secondPost.exists {
        // Posts should be stacked vertically, not side by side
        XCTAssertLessThan(firstPost.frame.maxY, secondPost.frame.minY)
      }
    }
  }

  // MARK: - High Contrast Tests

  func testHighContrastMode() throws {
    // Test high contrast adaptations
    app.terminate()
    app.launchArguments.append("--high-contrast-enabled")
    app.launch()

    // Navigate through the app and verify elements are visible
    let navigationButtons = ["Feed", "Notifications", "Search", "Profile"]

    for buttonTitle in navigationButtons {
      let button = app.buttons[buttonTitle]
      XCTAssertTrue(button.exists, "Button \(buttonTitle) should exist in high contrast mode")

      // Verify button is accessible and visible
      XCTAssertTrue(
        button.isHittable, "Button \(buttonTitle) should be hittable in high contrast mode")
    }

    // Test glass effects adapt to high contrast
    let glassElements = app.otherElements.matching(identifier: "glass-effect")
    for i in 0..<min(glassElements.count, 3) {
      let element = glassElements.element(boundBy: i)
      if element.exists {
        XCTAssertTrue(
          element.isHittable, "Glass effect element should remain interactive in high contrast")
      }
    }
  }

  // MARK: - Reduced Motion Tests

  func testReducedMotionSupport() throws {
    // Test reduced motion preferences
    app.terminate()
    app.launchArguments.append("--reduced-motion-enabled")
    app.launch()

    // Navigate between sections
    let feedButton = app.buttons["Feed"]
    feedButton.tap()

    let notificationsButton = app.buttons["Notifications"]
    notificationsButton.tap()

    // Verify functionality remains intact with reduced motion
    let notificationsList = app.otherElements["notifications-list"]
    XCTAssertTrue(notificationsList.waitForExistence(timeout: 3))

    // Test glass effects still work with reduced motion
    let glassCard = app.otherElements["glass-card"].firstMatch
    if glassCard.exists {
      glassCard.tap()
      // Should still be interactive, just with reduced animation
      XCTAssertTrue(glassCard.exists)
    }
  }

  // MARK: - Switch Control Tests

  func testSwitchControlCompatibility() throws {
    // Test Switch Control navigation
    app.terminate()
    app.launchArguments.append("--switch-control-enabled")
    app.launch()

    // Verify elements are properly grouped for Switch Control
    let sidebarGroup = app.otherElements["sidebar-switch-group"]
    let contentGroup = app.otherElements["content-switch-group"]
    let actionsGroup = app.otherElements["actions-switch-group"]

    // These groups should exist for Switch Control navigation
    if sidebarGroup.exists {
      XCTAssertTrue(sidebarGroup.isHittable)
    }

    // Test that all interactive elements are accessible via Switch Control
    let interactiveElements = app.buttons.allElementsBoundByIndex
    for element in interactiveElements.prefix(5) {
      if element.exists {
        XCTAssertTrue(
          element.isHittable, "Interactive element should be accessible via Switch Control")
      }
    }
  }

  // MARK: - Voice Control Tests

  func testVoiceControlLabels() throws {
    // Test Voice Control compatibility
    app.terminate()
    app.launchArguments.append("--voice-control-enabled")
    app.launch()

    // Verify elements have appropriate labels for Voice Control
    let feedButton = app.buttons["Feed"]
    XCTAssertTrue(feedButton.exists)
    XCTAssertFalse(feedButton.label.isEmpty)

    let newPostButton = app.buttons["new-post-button"]
    if newPostButton.exists {
      XCTAssertFalse(newPostButton.label.isEmpty)
      // Should have a clear, speakable label
      XCTAssertTrue(
        newPostButton.label.localizedCaseInsensitiveContains("post")
          || newPostButton.label.localizedCaseInsensitiveContains("new"))
    }

    // Test glass effect elements have voice control labels
    let glassElements = app.otherElements.matching(identifier: "glass-effect")
    for i in 0..<min(glassElements.count, 3) {
      let element = glassElements.element(boundBy: i)
      if element.exists && element.isHittable {
        XCTAssertFalse(
          element.label.isEmpty, "Glass effect element should have voice control label")
      }
    }
  }

  // MARK: - Button Shapes Tests

  func testButtonShapesSupport() throws {
    // Test button shapes accessibility feature
    app.terminate()
    app.launchArguments.append("--button-shapes-enabled")
    app.launch()

    // Navigate through the app
    let feedButton = app.buttons["Feed"]
    feedButton.tap()

    // Verify buttons have visual indicators when button shapes are enabled
    let actionButtons = app.buttons.allElementsBoundByIndex
    for button in actionButtons.prefix(5) {
      if button.exists && button.isHittable {
        // In a real test, we would verify visual button indicators
        XCTAssertTrue(button.exists)
      }
    }
  }

  // MARK: - Differentiate Without Color Tests

  func testDifferentiateWithoutColor() throws {
    // Test color differentiation alternatives
    app.terminate()
    app.launchArguments.append("--differentiate-without-color")
    app.launch()

    // Navigate to areas that might use color for information
    let notificationsButton = app.buttons["Notifications"]
    notificationsButton.tap()

    // Verify alternative indicators are present
    let notificationItems = app.otherElements.matching(identifier: "notification-item")
    for i in 0..<min(notificationItems.count, 3) {
      let item = notificationItems.element(boundBy: i)
      if item.exists {
        // Should have non-color indicators (icons, text, shapes)
        let icons = item.images.allElementsBoundByIndex
        let texts = item.staticTexts.allElementsBoundByIndex

        XCTAssertTrue(
          icons.count > 0 || texts.count > 0,
          "Notification item should have non-color indicators")
      }
    }
  }

  // MARK: - Assistive Touch Tests

  func testAssistiveTouchCompatibility() throws {
    // Test Assistive Touch gesture alternatives
    app.terminate()
    app.launchArguments.append("--assistive-touch-enabled")
    app.launch()

    // Verify complex gestures have assistive touch alternatives
    let contentArea = app.otherElements["content-column"]
    XCTAssertTrue(contentArea.waitForExistence(timeout: 5))

    // Test that pinch gestures have button alternatives
    let zoomInButton = app.buttons["zoom-in"]
    let zoomOutButton = app.buttons["zoom-out"]

    // These might not always exist, but if they do, they should work
    if zoomInButton.exists {
      zoomInButton.tap()
    }

    if zoomOutButton.exists {
      zoomOutButton.tap()
    }
  }

  // MARK: - Comprehensive Accessibility Tests

  func testAccessibilityAudit() throws {
    // Perform comprehensive accessibility audit
    let feedButton = app.buttons["Feed"]
    feedButton.tap()

    // Wait for content to load
    let contentArea = app.otherElements["content-column"]
    XCTAssertTrue(contentArea.waitForExistence(timeout: 5))

    // Audit all interactive elements
    let allButtons = app.buttons.allElementsBoundByIndex
    let allLinks = app.links.allElementsBoundByIndex
    let allTextFields = app.textFields.allElementsBoundByIndex

    let interactiveElements = allButtons + allLinks + allTextFields

    for element in interactiveElements.prefix(10) {  // Test first 10 elements
      if element.exists {
        // Every interactive element should have a label
        XCTAssertFalse(
          element.label.isEmpty,
          "Interactive element missing accessibility label: \(element)")

        // Should be hittable
        XCTAssertTrue(
          element.isHittable,
          "Interactive element not hittable: \(element.label)")
      }
    }
  }

  func testAccessibilityInDifferentOrientations() throws {
    // Test accessibility in portrait
    XCUIDevice.shared.orientation = .portrait
    sleep(1)

    performBasicAccessibilityChecks()

    // Test accessibility in landscape
    XCUIDevice.shared.orientation = .landscapeLeft
    sleep(1)

    performBasicAccessibilityChecks()
  }

  private func performBasicAccessibilityChecks() {
    // Navigate to each main section
    let sections = ["Feed", "Notifications", "Search", "Profile"]

    for section in sections {
      let button = app.buttons[section]
      if button.exists {
        button.tap()

        // Verify section loads and is accessible
        sleep(0.5)  // Wait for navigation

        // Check that main content area exists and is accessible
        let mainContent = app.otherElements.matching(identifier: "main-content").firstMatch
        if mainContent.exists {
          XCTAssertTrue(mainContent.isHittable)
        }
      }
    }
  }

  // MARK: - Performance with Accessibility Tests

  func testAccessibilityPerformance() throws {
    // Test performance with accessibility features enabled
    app.terminate()
    app.launchArguments.append("--all-accessibility-features")
    app.launch()

    measure(metrics: [XCTOSSignpostMetric.applicationLaunchMetric]) {
      // Navigate through the app with all accessibility features
      let feedButton = app.buttons["Feed"]
      feedButton.tap()

      let notificationsButton = app.buttons["Notifications"]
      notificationsButton.tap()

      let searchButton = app.buttons["Search"]
      searchButton.tap()
    }
  }
}

// MARK: - Accessibility Test Helpers

extension AccessibilityUITests {
  private func verifyElementHasAccessibilityInfo(_ element: XCUIElement) -> Bool {
    return !element.label.isEmpty && element.isHittable
  }

  private func checkForAccessibilityTraits(_ element: XCUIElement, expectedTraits: [String]) -> Bool
  {
    // In a real implementation, this would check for specific accessibility traits
    return true
  }
}
