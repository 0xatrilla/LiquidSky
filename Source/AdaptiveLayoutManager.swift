import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
@Observable
class AdaptiveLayoutManager {
  var screenSize: CGSize = .zero
  var sizeClass: (horizontal: UserInterfaceSizeClass?, vertical: UserInterfaceSizeClass?) = (
    nil, nil
  )
  var isStageManager: Bool = false
  var isExternalDisplay: Bool = false

  var supportedColumnCount: Int {
    switch (sizeClass.horizontal, screenSize.width) {
    case (.regular, let width) where width > 1000:
      return 3
    case (.regular, _):
      return 2
    default:
      return 1
    }
  }

  var preferredColumnVisibility: NavigationSplitViewVisibility {
    switch supportedColumnCount {
    case 3: return .all
    case 2: return .doubleColumn
    default: return .detailOnly
    }
  }

  func updateLayout(
    screenSize: CGSize, horizontalSizeClass: UserInterfaceSizeClass?,
    verticalSizeClass: UserInterfaceSizeClass?
  ) {
    self.screenSize = screenSize
    self.sizeClass = (horizontalSizeClass, verticalSizeClass)

    // Detect Stage Manager (simplified detection)
    self.isStageManager = screenSize.width < UIScreen.main.bounds.width * 0.9

    // Detect external display (simplified detection)
    self.isExternalDisplay = screenSize.width > 2000
  }

  func calculateColumnWidths() -> (
    sidebar: (min: CGFloat, ideal: CGFloat, max: CGFloat),
    content: (min: CGFloat, ideal: CGFloat, max: CGFloat),
    detail: (min: CGFloat, ideal: CGFloat, max: CGFloat)
  ) {
    let totalWidth = screenSize.width

    switch supportedColumnCount {
    case 3:
      let sidebarWidth = min(300, totalWidth * 0.25)
      let contentWidth = min(500, totalWidth * 0.35)
      let detailWidth = totalWidth - sidebarWidth - contentWidth

      return (
        sidebar: (min: sidebarWidth * 0.8, ideal: sidebarWidth, max: sidebarWidth * 1.2),
        content: (min: contentWidth * 0.8, ideal: contentWidth, max: contentWidth * 1.2),
        detail: (min: detailWidth * 0.8, ideal: detailWidth, max: detailWidth * 1.2)
      )

    case 2:
      let sidebarWidth = min(350, totalWidth * 0.4)
      let detailWidth = totalWidth - sidebarWidth

      return (
        sidebar: (min: sidebarWidth * 0.8, ideal: sidebarWidth, max: sidebarWidth * 1.2),
        content: (min: 0, ideal: 0, max: 0),  // Not used in 2-column
        detail: (min: detailWidth * 0.8, ideal: detailWidth, max: detailWidth * 1.2)
      )

    default:
      return (
        sidebar: (min: 200, ideal: 300, max: 400),
        content: (min: 0, ideal: 0, max: 0),
        detail: (min: 0, ideal: 0, max: 0)
      )
    }
  }
}

@available(iPadOS 26.0, *)
struct AdaptiveLayoutConfiguration {
  let screenSize: CGSize
  let sizeClass: (horizontal: UserInterfaceSizeClass?, vertical: UserInterfaceSizeClass?)
  let isStageManager: Bool
  let isExternalDisplay: Bool

  var supportedColumnCount: Int {
    switch (sizeClass.horizontal, screenSize.width) {
    case (.regular, let width) where width > 1000:
      return 3
    case (.regular, _):
      return 2
    default:
      return 1
    }
  }

  var preferredColumnVisibility: NavigationSplitViewVisibility {
    switch supportedColumnCount {
    case 3: return .all
    case 2: return .doubleColumn
    default: return .detailOnly
    }
  }

  static func current(
    from geometry: GeometryProxy,
    horizontalSizeClass: UserInterfaceSizeClass?,
    verticalSizeClass: UserInterfaceSizeClass?
  ) -> AdaptiveLayoutConfiguration {
    let screenSize = geometry.size

    return AdaptiveLayoutConfiguration(
      screenSize: screenSize,
      sizeClass: (horizontalSizeClass, verticalSizeClass),
      isStageManager: screenSize.width < UIScreen.main.bounds.width * 0.9,
      isExternalDisplay: screenSize.width > 2000
    )
  }
}

// MARK: - Environment Key for Layout Manager

@available(iPadOS 26.0, *)
struct AdaptiveLayoutManagerKey: EnvironmentKey {
  static let defaultValue = AdaptiveLayoutManager()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var adaptiveLayoutManager: AdaptiveLayoutManager {
    get { self[AdaptiveLayoutManagerKey.self] }
    set { self[AdaptiveLayoutManagerKey.self] = newValue }
  }
}
