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
  @Environment(BSkyClient.self) var client
  @State private var searchText: String = ""
  @State private var selectedTab: AppTab = .feed

  public var body: some View {
    @Bindable var router = router

    TabView(selection: $router.selectedTab) {
      // Feed
      Tab(value: AppTab.feed) {
        NavigationStack(path: $router[.feed]) {
          FeedsListView()
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
        }
        .searchable(text: $searchText)
        .onAppear { selectedTab = .feed }
      } label: {
        Label("Feed", systemImage: "square.stack")
      }

      // Notifications
      Tab(value: AppTab.notification) {
        NavigationStack(path: $router[.notification]) {
          NotificationsListView()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
        }
        .onAppear { selectedTab = .notification }
      } label: {
        Label("Notifications", systemImage: "bell")
      }

      // Profile
      Tab(value: AppTab.profile) {
        NavigationStack(path: $router[.profile]) {
          CurrentUserView()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
        }
        .onAppear { selectedTab = .profile }
      } label: {
        Label("Profile", systemImage: "person")
      }

      // Settings
      Tab(value: AppTab.settings) {
        NavigationStack(path: $router[.settings]) {
          SettingsView()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
        }
        .onAppear { selectedTab = .settings }
      } label: {
        Label("Settings", systemImage: "gearshape")
      }

      // Native search tab in tab bar
      Tab(value: AppTab.compose, role: .search) {
        NavigationStack(path: $router[.compose]) {
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
