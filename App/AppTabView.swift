import AppRouter
import AuthUI
import Client
import ComposerUI
import DesignSystem
import Destinations
import FeedUI
import MediaUI
import NotificationsUI
import ProfileUI
import SettingsUI
import SwiftUI

struct AppTabView: View {
  @Environment(AppRouter.self) var router
  @State private var searchText: String = ""
  @State private var selectedTab: AppTab = .feed

  var body: some View {
    @Bindable var router = router

    // Unified NavigationStack at app level - follows IceCubesApp's pattern
    NavigationStack(path: $router[.feed]) {  // Use feed tab's navigation path as the main one
      TabView {
        Tab("Feed", systemImage: "square.stack") {
          FeedsListView()
            .onAppear { selectedTab = .feed }
        }

        Tab("Notifications", systemImage: "bell") {
          NotificationsListView()
            .onAppear { selectedTab = .notification }
        }

        Tab("Profile", systemImage: "person") {
          CurrentUserView()
            .onAppear { selectedTab = .profile }
        }

        Tab("Settings", systemImage: "gearshape") {
          SettingsView()
            .onAppear { selectedTab = .settings }
        }

        // Native search tab in tab bar
        Tab(role: .search) {
          Text("Search")
            .onAppear { selectedTab = .compose }
        }
      }
      .searchable(text: $searchText)
      .tint(.themePrimary)
      .tabBarMinimizeBehavior(.onScrollDown)
      .withAppDestinations()  // Apply navigation destinations once at app level
      .navigationTitle(navigationTitle)
      .navigationBarTitleDisplayMode(.large)
    }
  }

  private var navigationTitle: String {
    switch selectedTab {
    case .feed:
      return "Discover"
    case .notification:
      return "Notifications"
    case .profile:
      return "Profile"
    case .settings:
      return "Settings"
    case .compose:
      return "Search"
    }
  }
}

#Preview {
  AppTabView()
    .environment(AppRouter(initialTab: .feed))
}
