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
  @State private var selectedTab: AppTab = .feed

  public var body: some View {
    TabView(selection: $selectedTab) {
      // Feed (showing FeedsListView with Discover title)
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
            .withAppDestinations()
        }

      } label: {
        Label("Feed", systemImage: "square.stack")
      }

      // Notifications
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
            .withAppDestinations()
        }

      } label: {
        Label("Notifications", systemImage: "bell")
      }

      // Profile
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
            .withAppDestinations()
        }

      } label: {
        Label("Profile", systemImage: "person")
      }

      // Settings
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
            .withAppDestinations()
        }

      } label: {
        Label("Settings", systemImage: "gearshape")
      }

      // Native search tab in tab bar
      Tab(value: AppTab.compose, role: .search) {
        NavigationStack(
          path: Binding(
            get: { router[.compose] },
            set: { router[.compose] = $0 }
          )
        ) {
          SimpleSearchView(client: client)
            .withAppDestinations()
        }
        .onAppear { selectedTab = .compose }
      } label: {
        Label("Search", systemImage: "magnifyingglass")
      }
    }
    .tint(.themePrimary)

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
    case .notification: return "Notifications"
    case .profile: return "Profile"
    case .settings: return "Settings"
    case .compose: return "Search"
    }
  }
}
