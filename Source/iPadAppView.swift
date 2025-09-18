import ATProtoKit
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

@available(iOS 26.0, *)
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
    @State private var detailColumnManager = DetailColumnManager()
    @State private var showingDiscoverSheet = false
    @State private var currentFeed: FeedItem?

    // Use router's selectedTab instead of local state
    private var selectedTab: AppTab {
        router.selectedTab
    }

    private var badgeCount: Int? {
        badgeStore.unreadCount > 0 ? badgeStore.unreadCount : nil
    }

    // Detail content view based on current selection
    @ViewBuilder
    private var detailContentView: some View {
        if detailColumnManager.isShowingDetail,
            let destination = detailColumnManager.currentDestination
        {
            // Show the selected detail content
            NavigationLink(value: destination) {
                EmptyView()
            }
        } else {
            // Show placeholder when no detail is selected
            placeholderView
        }
    }

    @ViewBuilder
    private var placeholderView: some View {
        VStack {
            Image(systemName: "sidebar.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Select content to view details")
                .font(.title2.weight(.medium))
                .foregroundStyle(.secondary)

            Text(
                "Choose a post, notification, or other content from the sidebar to see detailed information here."
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    public var body: some View {
        NavigationSplitView {
            // Sidebar
            iPadSidebarView()
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } content: {
            // Main content area - show content based on selected tab
            Group {
                switch selectedTab {
                case .feed:
                    feedNavigationStack
                case .notification:
                    notificationNavigationStack
                case .profile:
                    profileNavigationStack
                case .settings:
                    settingsNavigationStack
                case .compose:
                    composeNavigationStack
                case .bookmarks:
                    bookmarksNavigationStack
                }
            }
            .environment(\.detailColumnManager, detailColumnManager)
            .withDetailNavigation()
            .withDetailPaneRedirect()
            .navigationSplitViewColumnWidth(min: 400, ideal: 500, max: 700)
        } detail: {
            // Detail view for iPad - shows selected content
            NavigationStack {
                detailContentView
                    .withAppDestinations()
            }
            .environment(\.detailColumnManager, detailColumnManager)
            .withDetailNavigation()
            .navigationSplitViewColumnWidth(min: 500, ideal: 600, max: 800)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingSummary) {
            SummarySheetView(
                title: "Feed Summary",
                summary: summaryText,
                itemCount: 0,
                onDismiss: { showingSummary = false },
                onViewAll: {
                    // Scroll to top of the current feed
                    // This will be handled by the feed view itself
                }
            )
            .presentationDetents([.medium, .large])  // iPad-optimized sheet presentation
        }
        .sheet(isPresented: $showingDiscoverSheet) {
            NavigationStack {
                DiscoverFeedsListView { selectedFeed in
                    currentFeed = selectedFeed
                    showingDiscoverSheet = false
                }
                .navigationTitle("Discover Feeds")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showingDiscoverSheet = false
                        }
                        .buttonStyle(.bordered)
                    }
                    ToolbarSpacer()
                }
                .safeAreaInset(edge: .top) {
                    if currentFeed != nil {
                        Text("Currently: \(currentFeed!.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
                }
                .withAppDestinations()
                .environment(\.currentTab, .feed)
                .padding(.horizontal, 16)  // iPad-optimized horizontal padding
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
                .padding(.horizontal, 16)  // iPad-optimized horizontal padding
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
                .padding(.horizontal, 16)  // iPad-optimized horizontal padding
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
                .padding(.horizontal, 16)  // iPad-optimized horizontal padding
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
                .padding(.horizontal, 16)  // iPad-optimized horizontal padding
        }
    }

    private var bookmarksNavigationStack: some View {
        NavigationStack(
            path: Binding(
                get: { router[.bookmarks] },
                set: { router[.bookmarks] = $0 }
            )
        ) {
            BookmarksListView()
                .navigationTitle("Bookmarks")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        composeButton
                    }
                }
                .withAppDestinations()
                .environment(\.currentTab, .bookmarks)
                .padding(.horizontal, 16)  // iPad-optimized horizontal padding
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

    // Helper property to get current feed name
    private var currentFeedName: String {
        currentFeed?.displayName ?? "Following"
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
            let summary: String
            if let feed = currentFeed {
                // Fetch posts from custom feed
                let feedResponse = try await client.protoClient.getFeed(by: feed.uri, cursor: nil)
                let processedPosts = await processFeed(
                    feedResponse.feed, client: client.protoClient)
                summary = await FeedSummaryService.shared.summarizeFeedPosts(
                    processedPosts, feedName: feed.displayName)
            } else {
                // Fetch posts from following timeline
                let feed = try await client.protoClient.getTimeline()
                let processedPosts = await processFeed(feed.feed, client: client.protoClient)
                summary = await FeedSummaryService.shared.summarizeFeedPosts(
                    processedPosts, feedName: "Following")
            }
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

// MARK: - Preview

#Preview {
    if #available(iOS 26.0, *) {
        iPadAppView()
            .environment(AppRouter(initialTab: .feed))
    } else {
        Text("iOS 26.0 required")
    }
}
