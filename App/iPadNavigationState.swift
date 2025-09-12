import AppRouter
import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
@Observable
class iPadNavigationState {
  var selectedSidebarItem: SidebarItem = .feed
  var selectedContentItem: ContentItem?
  var columnVisibility: NavigationSplitViewVisibility = .all
  var preferredCompactColumn: NavigationSplitViewColumn = .detail

  // Navigation paths for each column
  var sidebarPath = NavigationPath()
  var contentPath = NavigationPath()
  var detailPath = NavigationPath()

  // Selection states for different content types
  var feedSelection: Set<String> = []
  var notificationSelection: Set<String> = []
  var searchSelection: Set<String> = []
  var profileSelection: Set<String> = []

  // Content loading states
  var isLoadingContent = false
  var isLoadingDetail = false

  // Error states
  var contentError: Error?
  var detailError: Error?

  init() {
    // Initialize with default state
  }

  func selectSidebarItem(_ item: SidebarItem) {
    selectedSidebarItem = item
    selectedContentItem = nil

    // Clear previous selections when switching sidebar items
    clearSelections()

    // Reset content path when switching sidebar items
    contentPath = NavigationPath()
  }

  func selectContentItem(_ item: ContentItem) {
    selectedContentItem = item

    // Navigate to detail view if in compact mode
    if columnVisibility == .detailOnly {
      preferredCompactColumn = .detail
    }
  }

  func clearSelections() {
    feedSelection.removeAll()
    notificationSelection.removeAll()
    searchSelection.removeAll()
    profileSelection.removeAll()
  }

  func updateColumnVisibility(
    for sizeClass: (horizontal: UserInterfaceSizeClass?, vertical: UserInterfaceSizeClass?)
  ) {
    let newVisibility: NavigationSplitViewVisibility

    switch (sizeClass.horizontal, sizeClass.vertical) {
    case (.regular, .regular):
      newVisibility = .all  // Three columns on large iPads
    case (.regular, .compact):
      newVisibility = .doubleColumn  // Two columns in landscape
    case (.compact, _):
      newVisibility = .detailOnly  // Single column on small screens
    default:
      newVisibility = .automatic
    }

    if newVisibility != columnVisibility {
      withAnimation(.smooth(duration: 0.3)) {
        columnVisibility = newVisibility
      }
    }
  }

  func handleBackNavigation() {
    if !detailPath.isEmpty {
      detailPath.removeLast()
    } else if !contentPath.isEmpty {
      contentPath.removeLast()
    } else {
      // Navigate back to sidebar if possible
      if columnVisibility == .detailOnly {
        preferredCompactColumn = .sidebar
      }
    }
  }
}

// MARK: - Content Item Model

@available(iPadOS 26.0, *)
struct ContentItem: Identifiable, Hashable {
  let id: String
  let type: ContentType
  let title: String
  let subtitle: String?
  let imageURL: URL?
  let metadata: [String: Any]

  enum ContentType {
    case post
    case profile
    case feed
    case notification
    case search
  }

  init(
    id: String, type: ContentType, title: String, subtitle: String? = nil, imageURL: URL? = nil,
    metadata: [String: Any] = [:]
  ) {
    self.id = id
    self.type = type
    self.title = title
    self.subtitle = subtitle
    self.imageURL = imageURL
    self.metadata = metadata
  }

  static func == (lhs: ContentItem, rhs: ContentItem) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - Environment Key for Navigation State

@available(iPadOS 26.0, *)
struct iPadNavigationStateKey: EnvironmentKey {
  static let defaultValue = iPadNavigationState()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var iPadNavigationState: iPadNavigationState {
    get { self[iPadNavigationStateKey.self] }
    set { self[iPadNavigationStateKey.self] = newValue }
  }
}
