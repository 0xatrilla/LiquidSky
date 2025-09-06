import AppRouter
import AuthUI
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

struct AppTabView: View {
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @State private var settingsService = SettingsService.shared
  @State private var selectedTab: AppTab = .feed
  @State private var showingSummary = false
  @State private var summaryText = ""
  @State private var isGeneratingSummary = false

  public var body: some View {
    TabView(selection: $selectedTab) {
      // Feed (showing FeedsListView with Discover title)
      if settingsService.tabBarTabsRaw.contains(AppTab.feed.rawValue) {
        Tab(value: AppTab.feed) {
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
                  // Summary button
                  Button(action: {
                    Task {
                      await generateGlobalSummary()
                    }
                  }) {
                    if isGeneratingSummary {
                      ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.themeSecondary)
                    } else {
                      Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.themeSecondary)
                    }
                  }
                  .disabled(isGeneratingSummary)

                  // Post creation button
                  Button(action: {
                    router.presentedSheet = .composer(mode: .newPost)
                  }) {
                    Image(systemName: "square.and.pencil")
                      .font(.title2)
                      .foregroundColor(.themePrimary)
                  }
                }
              }
              .withAppDestinations()
          }

        } label: {
          Label("Feed", systemImage: "square.stack")
        }
      }

      // Notifications
      if settingsService.tabBarTabsRaw.contains(AppTab.notification.rawValue) {
        Tab(value: AppTab.notification) {
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
                  // Summary button
                  Button(action: {
                    Task {
                      await generateGlobalSummary()
                    }
                  }) {
                    if isGeneratingSummary {
                      ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.themeSecondary)
                    } else {
                      Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.themeSecondary)
                    }
                  }
                  .disabled(isGeneratingSummary)

                  // Post creation button
                  Button(action: {
                    router.presentedSheet = .composer(mode: .newPost)
                  }) {
                    Image(systemName: "square.and.pencil")
                      .font(.title2)
                      .foregroundColor(.themePrimary)
                  }
                }
              }
              .withAppDestinations()
          }

        } label: {
          Label("Notifications", systemImage: "bell")
        }
      }

      // Profile
      if settingsService.tabBarTabsRaw.contains(AppTab.profile.rawValue) {
        Tab(value: AppTab.profile) {
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
                  // Summary button
                  Button(action: {
                    Task {
                      await generateGlobalSummary()
                    }
                  }) {
                    if isGeneratingSummary {
                      ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.themeSecondary)
                    } else {
                      Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.themeSecondary)
                    }
                  }
                  .disabled(isGeneratingSummary)

                  // Post creation button
                  Button(action: {
                    router.presentedSheet = .composer(mode: .newPost)
                  }) {
                    Image(systemName: "square.and.pencil")
                      .font(.title2)
                      .foregroundColor(.themePrimary)
                  }
                }
              }
              .withAppDestinations()
          }

        } label: {
          Label("Profile", systemImage: "person")
        }
      }

      // Settings
      if settingsService.tabBarTabsRaw.contains(AppTab.settings.rawValue) {
        Tab(value: AppTab.settings) {
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
                  // Summary button
                  Button(action: {
                    Task {
                      await generateGlobalSummary()
                    }
                  }) {
                    if isGeneratingSummary {
                      ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.themeSecondary)
                    } else {
                      Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.themeSecondary)
                    }
                  }
                  .disabled(isGeneratingSummary)

                  // Post creation button
                  Button(action: {
                    router.presentedSheet = .composer(mode: .newPost)
                  }) {
                    Image(systemName: "square.and.pencil")
                      .font(.title2)
                      .foregroundColor(.themePrimary)
                  }
                }
              }
              .withAppDestinations()
          }

        } label: {
          Label("Settings", systemImage: "gearshape")
        }
      }

      // Enhanced search tab with trending content
      if settingsService.tabBarTabsRaw.contains(AppTab.compose.rawValue) {
        Tab(value: AppTab.compose, role: .search) {
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
                  // Summary button
                  Button(action: {
                    Task {
                      await generateGlobalSummary()
                    }
                  }) {
                    if isGeneratingSummary {
                      ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.themeSecondary)
                    } else {
                      Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.themeSecondary)
                    }
                  }
                  .disabled(isGeneratingSummary)

                  // Post creation button
                  Button(action: {
                    router.presentedSheet = .composer(mode: .newPost)
                  }) {
                    Image(systemName: "square.and.pencil")
                      .font(.title2)
                      .foregroundColor(.themePrimary)
                  }
                }
              }
              .withAppDestinations()
          }
          .onAppear { selectedTab = .compose }
        } label: {
          Label("", systemImage: "magnifyingglass")
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

#Preview {
  AppTabView()
    .environment(AppRouter(initialTab: .feed))
}

// MARK: - Extensions
extension AppTab {
  var displayName: String {
    switch self {
    case .feed: return "Feed"
    case .messages: return "Messages"
    case .notification: return "Notifications"
    case .profile: return "Profile"
    case .settings: return "Settings"
    case .compose: return "Search"
    }
  }
}
