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
  @State private var selectedDetailContent: RouterDestination?

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
  
  // Detail content view based on current selection
  @ViewBuilder
  private var detailContentView: some View {
    if let detailContent = selectedDetailContent {
      // Show the selected detail content
      NavigationLink(value: detailContent) {
        EmptyView()
      }
    } else {
      // Show placeholder when no detail is selected
      VStack {
        Image(systemName: "sidebar.right")
          .font(.system(size: 60))
          .foregroundStyle(.secondary)
        
        Text("Select content to view details")
          .font(.title2.weight(.medium))
          .foregroundStyle(.secondary)
        
        Text("Choose a post, notification, or other content from the sidebar to see detailed information here.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.ultraThinMaterial)
    }
  }

  public var body: some View {
    NavigationSplitView {
      // Sidebar
      iPadSidebarView()
        .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
    } content: {
      // Main content area
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
      .navigationSplitViewColumnWidth(min: 400, ideal: 500, max: 700)
    } detail: {
      // Detail view for iPad - shows selected content
      NavigationStack {
        detailContentView
          .withAppDestinations()
      }
      .navigationSplitViewColumnWidth(min: 500, ideal: 600, max: 800)
    }
    .navigationSplitViewStyle(.balanced)
    .sheet(isPresented: $showingSummary) {
      SummarySheetView(
        title: "Feed Summary",
        summary: summaryText,
        itemCount: 0,
        onDismiss: { showingSummary = false }
      )
      .presentationDetents([.medium, .large]) // iPad-optimized sheet presentation
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
      FeedsListView()
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          ToolbarItemGroup(placement: .topBarTrailing) {
            summaryButton
            composeButton
          }
        }
        .withAppDestinations()
        .environment(\.currentTab, .feed)
        .padding(.horizontal, 16) // iPad-optimized horizontal padding
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
        .padding(.horizontal, 16) // iPad-optimized horizontal padding
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
        .padding(.horizontal, 16) // iPad-optimized horizontal padding
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
        .padding(.horizontal, 16) // iPad-optimized horizontal padding
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
        .padding(.horizontal, 16) // iPad-optimized horizontal padding
    }
  }

  // MARK: - Button Components

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
      let summary = await FeedSummaryService.shared.summarizeFeedPosts([], feedName: "your feeds")
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
