import AppRouter
import AuthUI
// TODO: Re-enable ChatUI import when chat functionality is ready
// import ChatUI
import Client
import ComposerUI
import DesignSystem
import Destinations
import FeedUI
import MediaUI
import Models
import NotificationsUI
import PostUI
import ProfileUI
import SettingsUI
import SwiftUI
import User

@MainActor
struct AppTabView: View {
    @Environment(AppRouter.self) var router
    @Environment(BSkyClient.self) var client
    @State private var settingsService = SettingsService.shared
    @State private var showingSummary = false
    @State private var summaryText = ""
    @State private var isGeneratingSummary = false
    @State private var badgeStore = NotificationBadgeStore.shared
    @State private var showingDiscoverSheet = false
    @State private var currentFeed: FeedItem?

    // Use router's selectedTab instead of local state
    private var selectedTab: AppTab {
        router.selectedTab
    }

    // Computed binding for TabView selection
    private var tabSelectionBinding: Binding<AppTab> {
        Binding(
            get: { router.selectedTab },
            set: { router.selectedTab = $0 }
        )
    }

    // Computed property for tab keys
    private var tabKeys: [String] {
        settingsService.tabBarTabsRaw + settingsService.pinnedFeedURIs.map { "feed:\($0)" }
    }

    private var badgeCount: Int? {
        badgeStore.unreadCount > 0 ? badgeStore.unreadCount : nil
    }

    public var body: some View {
        TabView(selection: tabSelectionBinding) {
            ForEach(tabKeys, id: \.self) { key in
                if let tab = AppTab(rawValue: key) {
                    switch tab {
                    case .feed:
                        Tab(value: AppTab.feed) {
                            feedNavigationStack
                        } label: {
                            Label("Feed", systemImage: "square.stack")
                        }

                    case .notification:
                        Group {
                            if let count = badgeCount {
                                Tab(value: AppTab.notification) {
                                    notificationNavigationStack
                                } label: {
                                    Label("Notifications", systemImage: "bell")
                                }
                                .badge(count)
                            } else {
                                Tab(value: AppTab.notification) {
                                    notificationNavigationStack
                                } label: {
                                    Label("Notifications", systemImage: "bell")
                                }
                            }
                        }

                    case .profile:
                        Tab(value: AppTab.profile) {
                            profileNavigationStack
                        } label: {
                            Label("Profile", systemImage: "person")
                        }

                    case .settings:
                        Tab(value: AppTab.settings) {
                            settingsNavigationStack
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }

                    case .compose:
                        Tab(value: AppTab.compose, role: .search) {
                            composeNavigationStack
                                .onAppear { router.selectedTab = .compose }
                        } label: {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                    }
                } else if key.hasPrefix("feed:") {
                    let feedURI = String(key.dropFirst(5))
                    let feedItem = createFeedItem(for: feedURI)

                    Tab(value: AppTab.feed) {
                        NavigationStack(
                            path: Binding(
                                get: { router[.feed] },
                                set: { router[.feed] = $0 }
                            )
                        ) {
                            PostsFeedView(feedItem: feedItem)
                                .withAppDestinations()
                                .environment(\.currentTab, .feed)
                        }
                    } label: {
                        Label(
                            settingsService.pinnedFeedNames[feedURI] ?? "Feed",
                            systemImage: "dot.radiowaves.left.and.right"
                        )
                    }
                }
            }
        }
        .tint(.themePrimary)
        .sheet(isPresented: $showingSummary) {
            SummarySheetView(
                title: "Feed Summary",
                summary: summaryText,
                itemCount: 0,
                onDismiss: { showingSummary = false }
            )
        }
        .sheet(isPresented: $showingDiscoverSheet) {
            DiscoverFeedsListView { selectedFeed in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentFeed = selectedFeed
                    showingDiscoverSheet = false
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
            .glassEffect()
        }
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

    // MARK: - Navigation Stacks

    private var feedNavigationStack: some View {
        NavigationStack(
            path: Binding(
                get: { router[.feed] },
                set: { router[.feed] = $0 }
            )
        ) {
            SwitchableFeedView(feed: currentFeed)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        discoverButton
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        summaryButton
                        composeButton
                    }
                }
                .withAppDestinations()
                .environment(\.currentTab, .feed)
        }
    }

    private var notificationNavigationStack: some View {
        NavigationStack(
            path: Binding(
                get: { router[.notification] },
                set: { router[.notification] = $0 }
            )
        ) {
            NotificationsListView()
                .navigationTitle("Notifications")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        composeButton
                    }
                }
                .withAppDestinations()
                .environment(\.currentTab, .notification)
                .onAppear {
                    badgeStore.markSeenNow()
                }
        }
    }

    private var profileNavigationStack: some View {
        NavigationStack(
            path: Binding(
                get: { router[.profile] },
                set: { router[.profile] = $0 }
            )
        ) {
            CurrentUserView()
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        composeButton
                    }
                }
                .withAppDestinations()
                .environment(\.currentTab, .profile)
        }
    }

    private var settingsNavigationStack: some View {
        NavigationStack(
            path: Binding(
                get: { router[.settings] },
                set: { router[.settings] = $0 }
            )
        ) {
            SettingsView()
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        composeButton
                    }
                }
                .withAppDestinations()
                .environment(\.currentTab, .settings)
        }
    }

    private var composeNavigationStack: some View {
        NavigationStack(
            path: Binding(
                get: { router[.compose] },
                set: { router[.compose] = $0 }
            )
        ) {
            EnhancedSearchView(client: client)
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        composeButton
                    }
                }
                .withAppDestinations()
                .environment(\.currentTab, .compose)
        }
    }

    // MARK: - Button Components

    private var discoverButton: some View {
        Button(action: {
            if currentFeed != nil {
                // If we're showing a custom feed, go back to following
                currentFeed = nil
            } else {
                // If we're on following, show the discover sheet
                showingDiscoverSheet = true
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: currentFeed != nil ? "arrow.left" : "square.grid.2x2")
                if currentFeed != nil {
                    Text("Following")
                        .font(.caption)
                }
            }
            .foregroundColor(.themePrimary)
        }
        .help(currentFeed != nil ? "Back to Following feed" : "Switch to a different feed")
    }

    private var summaryButton: some View {
        Button(action: {
            Task { await generateGlobalSummary() }
        }) {
            if isGeneratingSummary {
                ProgressView()
                    .scaleEffect(0.8)
                    .foregroundColor(.themeSecondary)
            } else {
                Image(systemName: "sparkles")
                    .foregroundColor(.themeSecondary)
            }
        }
        .disabled(isGeneratingSummary)
    }

    private var composeButton: some View {
        Button(action: { router.presentedSheet = .composer(mode: .newPost) }) {
            Image(systemName: "square.and.pencil")
                .foregroundColor(.themePrimary)
        }
    }

    // MARK: - Summary Generation

    private func generateGlobalSummary() async {
        isGeneratingSummary = true

        do {
            // Use the existing FeedSummaryService to generate a summary
            let summary = await FeedSummaryService.shared.summarizeFeedPosts(
                [], feedName: "your feeds")
            summaryText = summary
            showingSummary = true
        } catch {
            // Fallback to a simple summary if the service fails
            summaryText = "Unable to generate AI summary at this time. Please try again later."
            showingSummary = true
        }

        isGeneratingSummary = false
    }
}

extension AppTabView {
    fileprivate var currentTabs: [AppTab] {
        settingsService.tabBarTabsRaw.compactMap { AppTab(rawValue: $0) }
    }
}

#Preview {
    AppTabView()
        .environment(AppRouter(initialTab: .feed))
}

// MARK: - Extensions
extension AppTab {
    var displayName: String {
        switch self {
        case .feed: return "Feed"
        // TODO: Re-enable messages case when chat functionality is ready
        // case .messages: return "Messages"
        case .notification: return "Notifications"
        case .profile: return "Profile"
        case .settings: return "Settings"
        case .compose: return "Search"
        }
    }
}
