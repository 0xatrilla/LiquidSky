import AppRouter
import Foundation
import Models
import SwiftUI
import UIKit

@available(iPadOS 26.0, *)
struct SidebarNavigationView: View {
  @Environment(\.iPadNavigationState) var navigationState
  @Environment(\.gestureCoordinator) var gestureCoordinator
  @Environment(\.focusManager) var focusManager
  @Environment(\.glassEffectManager) var glassEffectManager
  @Environment(\.pinnedFeedsManager) var pinnedFeedsManager
  @Environment(\.notificationBadgeSystem) var notificationBadgeSystem
  @Environment(\.quickActionsSystem) var quickActionsSystem
  @State private var settingsService = SettingsService.shared
  @State private var badgeStore = NotificationBadgeStore.shared
  @State private var showingFeedPicker = false
  @Namespace private var sidebarNamespace

  // Focus management
  @FocusState private var isSidebarFocused: Bool
  @State private var focusedItemIndex = 0

  var body: some View {
    mainContent
      .navigationTitle("Horizon")
      .toolbar {
        toolbarContent
      }
      .onAppear {
        setupFocusManagement()
      }
      .onChange(of: focusManager.focusedColumn) { _, newColumn in
        isSidebarFocused = (newColumn == .sidebar)
      }
      .onChange(of: focusManager.focusedItemIndex) { _, newIndex in
        focusedItemIndex = newIndex
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigateNext)) { _ in
        if focusManager.focusedColumn == .sidebar {
          navigateToNextItem()
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigatePrevious)) { _ in
        if focusManager.focusedColumn == .sidebar {
          navigateToPreviousItem()
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .activateSelected)) { _ in
        if focusManager.focusedColumn == .sidebar {
          activateSelectedItem()
        }
      }
  }
  
  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarLeading) {
      sidebarToggleButton
    }

    ToolbarItemGroup(placement: .topBarTrailing) {
      keyboardShortcutsButton
    }
  }
  
  @ViewBuilder
  private var mainContent: some View {
    GlassEffectContainer(spacing: 8.0) {
      List {
        mainNavigationSection
        pinnedFeedsSection
        quickActionsSection
      }
      .listStyle(.sidebar)
      .focused($isSidebarFocused)
    }
  }

  // MARK: - Main Navigation Section

  @ViewBuilder
  private var mainNavigationSection: some View {
    Section {
      ForEach(Array(SidebarItem.mainItems.enumerated()), id: \.element) { index, item in
        SidebarNavigationRow(
          item: item,
          isSelected: navigationState.selectedSidebarItem == item,
          isFocused: focusManager.focusedColumn == .sidebar && focusedItemIndex == index,
          badgeCount: item == .notifications ? badgeCount : nil,
          onSelect: {
            selectItem(item, at: index)
          }
        )
        .tag(item)
        .id(item.id)
      }
    } header: {
      SidebarSectionHeader(
        title: "Navigation",
        subtitle: "Main app sections"
      )
    }
  }

  // MARK: - Pinned Feeds Section

  @ViewBuilder
  private var pinnedFeedsSection: some View {
    if !pinnedFeedsManager.pinnedFeeds.isEmpty {
      Section {
        ForEach(Array(pinnedFeedsManager.pinnedFeeds.enumerated()), id: \.element.id) {
          index, pinnedFeed in
          let feedItem = SidebarItem.pinnedFeed(
            uri: pinnedFeed.uri,
            name: pinnedFeed.displayName
          )
          let adjustedIndex = SidebarItem.mainItems.count + index

          SidebarNavigationRow(
            item: feedItem,
            isSelected: navigationState.selectedSidebarItem == feedItem,
            isFocused: focusManager.focusedColumn == .sidebar && focusedItemIndex == adjustedIndex,
            badgeCount: notificationBadgeSystem.getBadgeCount(for: pinnedFeed.uri),
            onSelect: {
              selectItem(feedItem, at: adjustedIndex)
            }
          )
          .tag(feedItem)
          .id(feedItem.id)
          .contextMenu {
            pinnedFeedContextMenu(for: pinnedFeed)
          }
        }

        // Add feed button
        Button {
          showingFeedPicker = true
        } label: {
          HStack {
            Image(systemName: "plus.circle.fill")
              .foregroundStyle(.blue)
            Text("Add Feed")
              .font(.subheadline.weight(.medium))
              .foregroundStyle(.blue)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
      } header: {
        SidebarSectionHeader(
          title: "Pinned Feeds",
          subtitle: "\(pinnedFeedsManager.pinnedFeeds.count) feeds"
        )
      }
    } else {
      Section {
        Button {
          showingFeedPicker = true
        } label: {
          VStack(spacing: 8) {
            Image(systemName: "pin.circle")
              .font(.title2)
              .foregroundStyle(.secondary)

            Text("Pin your first feed")
              .font(.subheadline.weight(.medium))
              .foregroundStyle(.primary)

            Text("Tap to discover feeds")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 16)
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
      } header: {
        SidebarSectionHeader(
          title: "Pinned Feeds",
          subtitle: "Quick access to favorites"
        )
      }
    }
  }

  // MARK: - Quick Actions Section

  @ViewBuilder
  private var quickActionsSection: some View {
    Section {
      quickActionButtons
    } header: {
      SidebarSectionHeader(
        title: "Quick Actions",
        subtitle: "Common tasks"
      )
    }
  }

  @ViewBuilder
  private var quickActionButtons: some View {
    VStack(spacing: 8) {
      // Primary actions from QuickActionsSystem
      let primaryActions = quickActionsSystem.getActionsByCategory(.primary)

      ForEach(primaryActions.prefix(2), id: \.id) { action in
        SidebarActionButton(
          title: action.title,
          systemImage: action.systemImage,
          style: .prominent,
          shortcut: action.shortcut
        ) {
          Task {
            await quickActionsSystem.performAction(action)
          }
        }
      }

      // Secondary actions
      let navigationActions = quickActionsSystem.getActionsByCategory(.navigation)

      ForEach(navigationActions.prefix(1), id: \.id) { action in
        SidebarActionButton(
          title: action.title,
          systemImage: action.systemImage,
          style: .secondary,
          shortcut: action.shortcut
        ) {
          Task {
            await quickActionsSystem.performAction(action)
          }
        }
      }

      // Show all actions button
      Button {
        // Show QuickActionsPanel
      } label: {
        HStack {
          Image(systemName: "ellipsis.circle")
            .foregroundStyle(.secondary)
          Text("More Actions")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
      }
      .buttonStyle(.plain)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    .padding(.vertical, 8)
  }

  // MARK: - Toolbar Components

  @ViewBuilder
  private var sidebarToggleButton: some View {
    GestureAwareGlassButton(
      "Toggle Sidebar",
      systemImage: "sidebar.left",
      style: .interactive
    ) {
      withAnimation(.smooth(duration: 0.3)) {
        let currentVisibility = navigationState.columnVisibility
        navigationState.columnVisibility = currentVisibility == .all ? .detailOnly : .all
      }
    }
  }

  @ViewBuilder
  private var keyboardShortcutsButton: some View {
    GestureAwareGlassButton(
      "Shortcuts",
      systemImage: "keyboard",
      style: .interactive
    ) {
      // Show keyboard shortcuts help
      NotificationCenter.default.post(name: .showKeyboardShortcuts, object: nil)
    }
  }

  // MARK: - Context Menus

  @ViewBuilder
  private func pinnedFeedContextMenu(for pinnedFeed: PinnedFeed) -> some View {
    Button("Rename Feed") {
      // Handle rename via settings service or custom UI
    }

    Button("Move Up") {
      if let index = pinnedFeedsManager.pinnedFeeds.firstIndex(where: { $0.uri == pinnedFeed.uri }) {
        pinnedFeedsManager.moveFeed(from: index, to: index - 1)
      }
    }

    Button("Move Down") {
      if let index = pinnedFeedsManager.pinnedFeeds.firstIndex(where: { $0.uri == pinnedFeed.uri }) {
        pinnedFeedsManager.moveFeed(from: index, to: index + 1)
      }
    }

    Divider()

    Button("Unpin Feed", role: .destructive) {
      pinnedFeedsManager.unpinFeed(pinnedFeed.uri)
    }
  }

  // MARK: - Helper Properties

  private var badgeCount: Int? {
    let totalCount = notificationBadgeSystem.totalUnreadCount
    return totalCount > 0 ? totalCount : nil
  }

  private var totalItemCount: Int {
    SidebarItem.mainItems.count + pinnedFeedsManager.pinnedFeeds.count
  }

  // MARK: - Navigation Methods

  private func selectItem(_ item: SidebarItem, at index: Int) {
    navigationState.selectSidebarItem(item)
    focusedItemIndex = index

    // Provide haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred()
  }

  private func navigateToNextItem() {
    let maxIndex = totalItemCount - 1
    if focusedItemIndex < maxIndex {
      focusedItemIndex += 1
      focusManager.focusedItemIndex = focusedItemIndex
    }
  }

  private func navigateToPreviousItem() {
    if focusedItemIndex > 0 {
      focusedItemIndex -= 1
      focusManager.focusedItemIndex = focusedItemIndex
    }
  }

  private func activateSelectedItem() {
    let allItems =
      SidebarItem.mainItems
      + pinnedFeedsManager.pinnedFeeds.map { pinnedFeed in
        SidebarItem.pinnedFeed(
          uri: pinnedFeed.uri,
          name: pinnedFeed.displayName
        )
      }

    if focusedItemIndex < allItems.count {
      let item = allItems[focusedItemIndex]
      selectItem(item, at: focusedItemIndex)
    }
  }

  private func setupFocusManagement() {
    focusManager.updateMaxItems(for: .sidebar, count: totalItemCount)
  }
}

// MARK: - Sidebar Navigation Row

@available(iPadOS 26.0, *)
struct SidebarNavigationRow: View {
  let item: SidebarItem
  let isSelected: Bool
  let isFocused: Bool
  let badgeCount: Int?
  let onSelect: () -> Void

  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0

  private let rowId = UUID().uuidString

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 12) {
        // Icon with glass effect
        Image(systemName: item.systemImage)
          .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
          .foregroundStyle(iconColor)
          .frame(width: 20, height: 20)

        // Title
        Text(item.title)
          .font(.subheadline.weight(isSelected ? .semibold : .regular))
          .foregroundStyle(textColor)

        Spacer()

        // Badge
        if let badgeCount = badgeCount, badgeCount > 0 {
          BadgeView(count: badgeCount)
        }

        // Keyboard shortcut indicator
        if let shortcut = keyboardShortcut {
          Text(shortcut)
            .font(.caption2.monospaced())
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(backgroundView)
    }
    .buttonStyle(.plain)
    .scaleEffect(scaleEffect)
    .brightness(hoverIntensity * 0.1)
    .overlay(focusOverlay)
    .applePencilHover(id: rowId) { hovering, location, intensity in
      withAnimation(.smooth(duration: 0.2)) {
        isPencilHovering = hovering
        hoverIntensity = intensity
      }
    }
    .onHover { hovering in
      withAnimation(.smooth(duration: 0.2)) {
        isHovering = hovering && !isPencilHovering
      }
    }
    .keyboardNavigation(id: rowId) { focused in
      // Focus is managed by parent view
    } onKeyPress: { key in
      if key == .space || key == .return {
        onSelect()
        return true
      }
      return false
    }
    .animation(.smooth(duration: 0.2), value: isSelected)
  }

  // MARK: - Computed Properties

  private var iconColor: Color {
    if isSelected {
      return .blue
    } else if isPencilHovering || isHovering {
      return .primary
    } else {
      return .secondary
    }
  }

  private var textColor: Color {
    isSelected ? .primary : .secondary
  }

  private var scaleEffect: CGFloat {
    if isPencilHovering {
      return 1.02
    } else if isHovering {
      return 1.01
    } else {
      return 1.0
    }
  }

  private var keyboardShortcut: String? {
    switch item {
    case .feed: return "⌘1"
    case .notifications: return "⌘2"
    case .search: return "⌘3"
    case .profile: return "⌘4"
    case .settings: return "⌘5"
    default: return nil
    }
  }

  @ViewBuilder
  private var backgroundView: some View {
    RoundedRectangle(cornerRadius: 10)
      .fill(backgroundFill)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(isSelected ? .blue.opacity(0.3) : .clear, lineWidth: 1)
      )
  }

  private var backgroundFill: Color {
    if isSelected {
      return .blue.opacity(0.15)
    } else if isPencilHovering || isHovering {
      return .primary.opacity(0.05)
    } else {
      return .clear
    }
  }

  @ViewBuilder
  private var focusOverlay: some View {
    if isFocused {
      RoundedRectangle(cornerRadius: 10)
        .stroke(.blue, lineWidth: 2)
        .background(.blue.opacity(0.1), in: Circle())
        .overlay(Circle().stroke(.blue.opacity(0.3), lineWidth: 1))
    }

    if isPencilHovering {
      RoundedRectangle(cornerRadius: 10)
        .stroke(.blue.opacity(hoverIntensity), lineWidth: 2)
        .background(.blue.opacity(0.1), in: Circle())
        .overlay(Circle().stroke(.blue.opacity(0.3), lineWidth: 1))
    }
  }
}

// MARK: - Sidebar Section Header

@available(iPadOS 26.0, *)
struct SidebarSectionHeader: View {
  let title: String
  let subtitle: String?

  init(title: String, subtitle: String? = nil) {
    self.title = title
    self.subtitle = subtitle
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.headline.weight(.semibold))
        .foregroundStyle(.primary)

      if let subtitle = subtitle {
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
  }
}

// MARK: - Sidebar Action Button

@available(iPadOS 26.0, *)
struct SidebarActionButton: View {
  let title: String
  let systemImage: String
  let style: Style
  let shortcut: String?
  let action: () -> Void

  enum Style {
    case prominent, secondary
  }

  init(
    title: String,
    systemImage: String,
    style: Style = .secondary,
    shortcut: String? = nil,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.systemImage = systemImage
    self.style = style
    self.shortcut = shortcut
    self.action = action
  }

  var body: some View {
    GestureAwareGlassButton(
      title,
      systemImage: systemImage,
      style: glassButtonStyle
    ) {
      action()
    }
    .overlay(alignment: .trailing) {
      if let shortcut = shortcut {
        Text(shortcut)
          .font(.caption2.monospaced())
          .foregroundStyle(.tertiary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
          .padding(.trailing, 8)
      }
    }
  }

  private var glassButtonStyle: GlassButton.GlassButtonStyle {
    switch style {
    case .prominent:
      return .tinted(.blue)
    case .secondary:
      return .interactive
    }
  }
}

// MARK: - Badge View

@available(iPadOS 26.0, *)
struct BadgeView: View {
  let count: Int
  @Environment(\.badgeAnimationCoordinator) var badgeAnimationCoordinator

  var body: some View {
    if count > 0 {
      EnhancedBadgeView(
        badgeInfo: BadgeInfo(
          count: count,
          type: .notification,
          lastUpdated: Date(),
          isNew: false
        ),
        style: .standard,
        size: .small
      )
      .scaleEffect(count > 99 ? 0.9 : 1.0)
    }
  }
}

// MARK: - Notification Extensions

extension Notification.Name {
  static let generateSummary = Notification.Name("generateSummary")
  static let showKeyboardShortcuts = Notification.Name("showKeyboardShortcuts")
}
// MARK: - Environment Keys

@available(iPadOS 26.0, *)
extension EnvironmentValues {

  var badgeAnimationCoordinator: BadgeAnimationCoordinator {
    get { self[BadgeAnimationCoordinatorKey.self] }
    set { self[BadgeAnimationCoordinatorKey.self] = newValue }
  }

}

@available(iPadOS 26.0, *)
struct BadgeAnimationCoordinatorKey: EnvironmentKey {
  static let defaultValue = BadgeAnimationCoordinator()
}
