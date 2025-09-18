import SwiftUI
import XCTest

@testable import LiquidSky

@available(iPadOS 26.0, *)
final class iPadNavigationStateTests: XCTestCase {
  var navigationState: iPadNavigationState!

  override func setUp() {
    super.setUp()
    navigationState = iPadNavigationState()
  }

  override func tearDown() {
    navigationState = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testInitialState() {
    XCTAssertEqual(navigationState.selectedSidebarItem, .feed)
    XCTAssertEqual(navigationState.columnVisibility, .automatic)
    XCTAssertEqual(navigationState.preferredCompactColumn, .sidebar)
    XCTAssertNil(navigationState.selectedContentItem)
    XCTAssertNil(navigationState.selectedDetailItem)
  }

  // MARK: - Sidebar Selection Tests

  func testSelectSidebarItem() {
    navigationState.selectSidebarItem(.notifications)
    XCTAssertEqual(navigationState.selectedSidebarItem, .notifications)
  }

  func testSelectSidebarItemClearsSelection() {
    navigationState.selectedContentItem = "test-item"
    navigationState.selectedDetailItem = "test-detail"

    navigationState.selectSidebarItem(.profile)

    XCTAssertEqual(navigationState.selectedSidebarItem, .profile)
    XCTAssertNil(navigationState.selectedContentItem)
    XCTAssertNil(navigationState.selectedDetailItem)
  }

  func testSelectPinnedFeed() {
    let feedURI = "at://test.feed"
    let feedName = "Test Feed"

    navigationState.selectSidebarItem(.pinnedFeed(uri: feedURI, name: feedName))

    if case .pinnedFeed(let uri, let name) = navigationState.selectedSidebarItem {
      XCTAssertEqual(uri, feedURI)
      XCTAssertEqual(name, feedName)
    } else {
      XCTFail("Expected pinned feed selection")
    }
  }

  // MARK: - Column Visibility Tests

  func testUpdateColumnVisibilityForCompactSize() {
    navigationState.updateColumnVisibility(for: (.compact, .regular))
    XCTAssertEqual(navigationState.columnVisibility, .detailOnly)
  }

  func testUpdateColumnVisibilityForRegularSize() {
    navigationState.updateColumnVisibility(for: (.regular, .regular))
    XCTAssertEqual(navigationState.columnVisibility, .all)
  }

  func testUpdateColumnVisibilityForCompactHeight() {
    navigationState.updateColumnVisibility(for: (.regular, .compact))
    XCTAssertEqual(navigationState.columnVisibility, .doubleColumn)
  }

  // MARK: - Content Selection Tests

  func testSelectContentItem() {
    let contentId = "test-content-123"
    navigationState.selectContentItem(contentId)

    XCTAssertEqual(navigationState.selectedContentItem, contentId)
    XCTAssertNil(navigationState.selectedDetailItem)  // Should clear detail selection
  }

  func testSelectDetailItem() {
    let detailId = "test-detail-456"
    navigationState.selectDetailItem(detailId)

    XCTAssertEqual(navigationState.selectedDetailItem, detailId)
  }

  // MARK: - Navigation Path Tests

  func testNavigationPathManagement() {
    let path1 = "path1"
    let path2 = "path2"

    navigationState.pushToNavigationPath(path1, for: .feed)
    navigationState.pushToNavigationPath(path2, for: .feed)

    let feedPath = navigationState.getNavigationPath(for: .feed)
    XCTAssertEqual(feedPath.count, 2)
    XCTAssertEqual(feedPath[0] as? String, path1)
    XCTAssertEqual(feedPath[1] as? String, path2)
  }

  func testClearNavigationPath() {
    navigationState.pushToNavigationPath("test", for: .notifications)
    navigationState.clearNavigationPath(for: .notifications)

    let notificationPath = navigationState.getNavigationPath(for: .notifications)
    XCTAssertTrue(notificationPath.isEmpty)
  }

  // MARK: - State Restoration Tests

  func testSaveAndRestoreState() {
    // Setup state
    navigationState.selectSidebarItem(.search)
    navigationState.selectedContentItem = "content-123"
    navigationState.selectedDetailItem = "detail-456"
    navigationState.columnVisibility = .doubleColumn

    // Save state
    let savedState = navigationState.saveState()

    // Create new instance and restore
    let newNavigationState = iPadNavigationState()
    newNavigationState.restoreState(savedState)

    // Verify restoration
    XCTAssertEqual(newNavigationState.selectedSidebarItem, .search)
    XCTAssertEqual(newNavigationState.selectedContentItem, "content-123")
    XCTAssertEqual(newNavigationState.selectedDetailItem, "detail-456")
    XCTAssertEqual(newNavigationState.columnVisibility, .doubleColumn)
  }

  // MARK: - Performance Tests

  func testNavigationStatePerformance() {
    measure {
      for i in 0..<1000 {
        navigationState.selectSidebarItem(.feed)
        navigationState.selectContentItem("content-\(i)")
        navigationState.selectDetailItem("detail-\(i)")
      }
    }
  }

  // MARK: - Thread Safety Tests

  func testConcurrentAccess() {
    let expectation = XCTestExpectation(description: "Concurrent access")
    expectation.expectedFulfillmentCount = 10

    DispatchQueue.concurrentPerform(iterations: 10) { index in
      navigationState.selectSidebarItem(.feed)
      navigationState.selectContentItem("content-\(index)")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5.0)
  }
}

// MARK: - Mock Data Extensions

@available(iPadOS 26.0, *)
extension iPadNavigationState {
  static var mock: iPadNavigationState {
    let state = iPadNavigationState()
    state.selectedSidebarItem = .feed
    state.selectedContentItem = "mock-content"
    state.selectedDetailItem = "mock-detail"
    return state
  }
}
