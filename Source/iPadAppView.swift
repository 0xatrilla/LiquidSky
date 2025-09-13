import AppRouter
import AuthUI
import Client
import ComposerUI
import DesignSystem
import Destinations
import FeedUI
import Foundation
import MediaUI
import Models
import NotificationsUI
import PostUI
import ProfileUI
import SettingsUI
import SwiftUI
import User
import ATProtoKit

@available(iOS 18.0, *)
@MainActor
struct iPadAppView: View {
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @Environment(CurrentUser.self) var currentUser
  @State private var settingsService = SettingsService.shared
  @State private var showingSummary = false
  @State private var summaryText = ""
  @State private var isGeneratingSummary = false
  @State private var badgeStore = NotificationBadgeStore.shared
  @Namespace private var glassEffectNamespace

  // State managers
  @State private var navigationState = iPadNavigationState()
  @State private var layoutManager = AdaptiveLayoutManager()
  @State private var glassEffectManager = LiquidGlassEffectManager()
  @State private var gestureCoordinator = GestureCoordinator()
  @State private var keyboardShortcutsManager = KeyboardShortcutsManager()
  @State private var focusManager = FocusManager()
  @State private var pinnedFeedsManager = PinnedFeedsManager()
  @State private var notificationBadgeSystem = NotificationBadgeSystem()
  @State private var badgeAnimationCoordinator = BadgeAnimationCoordinator()
  @State private var quickActionsSystem = QuickActionsSystem()
  @State private var pictureInPictureManager = PictureInPictureManager()
  @State private var advancedApplePencilManager = AdvancedApplePencilManager()
  @State private var advancedTrackpadManager = AdvancedTrackpadManager()
  @State private var advancedMultiTouchManager = AdvancedMultiTouchManager()
  @State private var lazyContentManager = LazyContentManager()
  @State private var memoryManagementSystem = MemoryManagementSystem()
  @State private var contentColumnManager = ContentColumnManager()
  @State private var detailColumnManager = DetailColumnManager()
  @State private var accessibilityManager = AccessibilityManager()
  @State private var voiceOverSupport = VoiceOverSupport()
  @State private var dynamicTypeSupport = DynamicTypeSupport()
  @State private var visualAccessibilitySupport = VisualAccessibilitySupport()
  @State private var assistiveTechnologySupport = AssistiveTechnologySupport()
  @State private var handoffManager = HandoffManager()
  @State private var shortcutsIntegrationManager = ShortcutsIntegrationManager()
  @State private var focusModeManager = FocusModeManager()
  @State private var sharingManager = SharingManager()
  @State private var iPadIntegration = iPadIntegrationManager()
  @State private var uiPolishManager = UIPolishManager()
  @State private var finalOptimizationManager = FinalOptimizationManager()

  // Adaptive layout configuration
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @Environment(\.verticalSizeClass) var verticalSizeClass

  private var adaptiveColumnVisibility: NavigationSplitViewVisibility {
    layoutManager.preferredColumnVisibility
  }

  public var body: some View {
    GeometryReader { geometry in
      NavigationSplitView(
        columnVisibility: $navigationState.columnVisibility,
        preferredCompactColumn: $navigationState.preferredCompactColumn
      ) {
        sidebarContent
          .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
          .background(.ultraThinMaterial)
      } content: {
        contentView
          .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
      } detail: {
        detailView
          .navigationSplitViewColumnWidth(min: 400, ideal: 600)
      }
      .navigationSplitViewStyle(.balanced)
      .onAppear {
        layoutManager.updateLayout(
          screenSize: geometry.size,
          horizontalSizeClass: horizontalSizeClass,
          verticalSizeClass: verticalSizeClass
        )
        navigationState.columnVisibility = adaptiveColumnVisibility
      }
      .sheet(isPresented: $showingSummary) {
        SummarySheetView(
          title: "Feed Summary",
          summary: summaryText,
          itemCount: 0,
          onDismiss: { showingSummary = false }
        )
        .presentationBackground(.ultraThinMaterial)
      }
      .environment(navigationState)
      .environment(layoutManager)
      .environment(glassEffectManager)
      .environment(gestureCoordinator)
      .environment(keyboardShortcutsManager)
      .environment(focusManager)
      .environment(pinnedFeedsManager)
      .environment(notificationBadgeSystem)
      .environment(badgeAnimationCoordinator)
      .environment(quickActionsSystem)
      .environment(accessibilityManager)
      .environment(voiceOverSupport)
      .environment(dynamicTypeSupport)
      .environment(visualAccessibilitySupport)
      .environment(assistiveTechnologySupport)
      .environment(handoffManager)
      .environment(shortcutsIntegrationManager)
      .environment(focusModeManager)
      .environment(sharingManager)
      .environment(uiPolishManager)
      .environment(finalOptimizationManager)
      .keyboardShortcuts()
      .onReceive(NotificationCenter.default.publisher(for: .navigateToFeed)) { _ in
        navigationState.selectSidebarItem(.feed)
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigateToNotifications)) { _ in
        navigationState.selectSidebarItem(.notifications)
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigateToSearch)) { _ in
        navigationState.selectSidebarItem(.search)
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigateToProfile)) { _ in
        navigationState.selectSidebarItem(.profile)
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigateToSettings)) { _ in
        navigationState.selectSidebarItem(.settings)
      }
      .onReceive(NotificationCenter.default.publisher(for: .newPost)) { _ in
        router.presentedSheet = .composer(mode: .newPost)
      }
      .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
        withAnimation(.smooth(duration: 0.3)) {
          let currentVisibility = navigationState.columnVisibility
          navigationState.columnVisibility = currentVisibility == .all ? .detailOnly : .all
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .refresh)) { _ in
        Task {
          await contentColumnManager.refreshCurrentContent()
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .showKeyboardShortcuts)) { _ in
        // Handle keyboard shortcuts display
      }
    }
  }

  // MARK: - Sidebar Content

  private var sidebarContent: some View {
    SidebarNavigationView()
      .onReceive(NotificationCenter.default.publisher(for: .generateSummary)) { _ in
        Task { await generateGlobalSummary() }
      }
  }

  // MARK: - Content View

  @ViewBuilder
  private var contentView: some View {
    NavigationStack {
      GlassEffectContainer(spacing: 16.0) {
        switch navigationState.selectedSidebarItem {
        case .feed:
          EnhancedFeedGridView()
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
            .environment(\.currentTab, .feed)
            .onAppear {
              contentColumnManager.switchContent(to: .feed)
            }

        case .notifications:
          EnhancedNotificationGridView()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
            .environment(\.currentTab, .notification)
            .onAppear {
              badgeStore.markSeenNow()
              contentColumnManager.switchContent(to: .notifications)
            }

        case .profile:
          EnhancedProfileView()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
            .environment(\.currentTab, .profile)
            .onAppear {
              contentColumnManager.switchContent(to: .profile)
            }

        case .search:
          EnhancedSearchView(client: client)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
            .environment(\.currentTab, .compose)
            .onAppear {
              contentColumnManager.switchContent(to: .search)
            }

        case .settings:
          AdaptiveSettingsView()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
            .environment(\.currentTab, .settings)
            .onAppear {
              contentColumnManager.switchContent(to: .settings)
            }

        case .pinnedFeed(let uri, _):
          let feedItem = createFeedItem(for: uri)
          EnhancedFeedGridView()
            .navigationTitle(feedItem.displayName)
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
            .environment(\.currentTab, .feed)
            .onAppear {
              contentColumnManager.switchContent(to: .pinnedFeed(uri: uri))
            }
        }
      }
    }
    .background(.ultraThinMaterial)
  }

  // MARK: - Helper Methods

  private func createFeedItem(for feedURI: String) -> FeedItem {
    FeedItem(
      uri: feedURI,
      displayName: settingsService.pinnedFeedNames[feedURI] ?? "Feed",
      description: nil,
      avatarImageURL: nil,
      creatorHandle: "",
      likesCount: 0,
      liked: false
    )
  }

  // MARK: - Detail View

  @ViewBuilder
  private var detailView: some View {
    DetailColumnView()
  }

  // MARK: - Helper Properties

  private var badgeCount: Int? {
    badgeStore.unreadCount > 0 ? badgeStore.unreadCount : nil
  }

  // MARK: - Summary Generation

  private func generateGlobalSummary() async {
    isGeneratingSummary = true

    do {
      let summary = await FeedSummaryService.shared.summarizeFeedPosts([], feedName: "your feeds")
      summaryText = summary
      showingSummary = true
    } catch {
      summaryText = "Unable to generate AI summary at this time. Please try again later."
      showingSummary = true
    }

    isGeneratingSummary = false
  }
}

// MARK: - Adaptive View Wrappers

@available(iOS 18.0, *)
struct AdaptiveFeedsListView: View {
  @Environment(\.horizontalSizeClass) var sizeClass

  var body: some View {
    GestureAwareGlassCard(cornerRadius: 12, isInteractive: true) {
      FeedsListView()
    }
  }
}

@available(iOS 18.0, *)
struct AdaptiveNotificationsListView: View {
  var body: some View {
    GestureAwareGlassCard(cornerRadius: 12, isInteractive: true) {
      NotificationsListView()
    }
  }
}

@available(iOS 18.0, *)
struct AdaptiveCurrentUserView: View {
  var body: some View {
    GestureAwareGlassCard(cornerRadius: 12, isInteractive: true) {
      CurrentUserView()
    }
  }
}

@available(iOS 18.0, *)
struct AdaptiveSearchView: View {
  let client: BSkyClient

  var body: some View {
    GestureAwareGlassCard(cornerRadius: 12, isInteractive: true) {
      EnhancedSearchView(client: client)
    }
  }
}

@available(iOS 18.0, *)
struct AdaptiveSettingsView: View {
  var body: some View {
    GestureAwareGlassCard(cornerRadius: 12, isInteractive: true) {
      SettingsView()
    }
  }
}

@available(iOS 18.0, *)
struct AdaptivePostsFeedView: View {
  let feedItem: FeedItem

  var body: some View {
    GestureAwareGlassCard(cornerRadius: 12, isInteractive: true) {
      PostsFeedView(feedItem: feedItem)
    }
  }
}

@available(iOS 18.0, *)
struct GlassDetailContentView: View {
  var body: some View {
    GestureAwareGlassCard(cornerRadius: 16, isInteractive: true) {
      VStack(spacing: 20) {
        Text("Detail Content")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.primary)

        Text("Enhanced detail view with Liquid Glass effects and gesture support")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        Text("Try Apple Pencil hover, trackpad gestures, or keyboard navigation")
          .font(.caption)
          .foregroundStyle(.tertiary)
          .multilineTextAlignment(.center)

        Spacer()
      }
    }
  }
}

@available(iOS 18.0, *)
struct GlassEmptyStateView: View {
  var body: some View {
    GestureAwareGlassCard(cornerRadius: 20, isInteractive: true) {
      ContentUnavailableView(
        "Select an item",
        systemImage: "sidebar.right",
        description: Text("Choose something from the sidebar to view details")
      )
    }
  }
}

// MARK: - Sidebar Item Model

enum SidebarItem: Hashable, CaseIterable, Identifiable {
  case feed
  case notifications
  case profile
  case search
  case settings
  case pinnedFeed(uri: String, name: String)

  static var allCases: [SidebarItem] {
    [.feed, .notifications, .profile, .search, .settings]
  }

  static var mainItems: [SidebarItem] {
    [.feed, .notifications, .search, .profile, .settings]
  }

  var id: String {
    switch self {
    case .feed: return "feed"
    case .notifications: return "notifications"
    case .profile: return "profile"
    case .search: return "search"
    case .settings: return "settings"
    case .pinnedFeed(let uri, _): return "pinned-\(uri)"
    }
  }

  var title: String {
    switch self {
    case .feed: return "Feed"
    case .notifications: return "Notifications"
    case .profile: return "Profile"
    case .search: return "Search"
    case .settings: return "Settings"
    case .pinnedFeed(_, let name): return name
    }
  }

  var systemImage: String {
    switch self {
    case .feed: return "square.stack"
    case .notifications: return "bell"
    case .profile: return "person"
    case .search: return "magnifyingglass"
    case .settings: return "gearshape"
    case .pinnedFeed: return "dot.radiowaves.left.and.right"
    }
  }

  var routerDestination: String {
    switch self {
    case .feed, .pinnedFeed: return "feed"
    case .notifications: return "notifications"
    case .profile: return "profile"
    case .search: return "search"
    case .settings: return "settings"
    }
  }
}

// MARK: - Glass Sidebar Row

@available(iOS 18.0, *)
struct GlassSidebarRow: View {
  let item: SidebarItem
  let isSelected: Bool
  let badgeCount: Int?

  init(item: SidebarItem, isSelected: Bool = false, badgeCount: Int? = nil) {
    self.item = item
    self.isSelected = isSelected
    self.badgeCount = badgeCount
  }

  var body: some View {
    HStack {
      Label(item.title, systemImage: item.systemImage)
        .font(.subheadline.weight(isSelected ? .semibold : .regular))
        .foregroundStyle(isSelected ? .primary : .secondary)

      Spacer()

      if let badgeCount = badgeCount, badgeCount > 0 {
        Text("\(badgeCount)")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.red, in: Capsule())
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isSelected ? .blue.opacity(0.1) : .clear)
    )
    .animation(.smooth(duration: 0.2), value: isSelected)
  }
}

// MARK: - Preview

#Preview {
  if #available(iOS 18.0, *) {
    iPadAppView()
      .environment(AppRouter(initialTab: .feed))
  } else {
    Text("iOS 18.0 required")
  }
}
