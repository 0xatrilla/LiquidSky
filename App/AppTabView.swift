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

  var body: some View {
    @Bindable var router = router

    // Unified NavigationStack at app level - follows IceCubesApp's pattern
    NavigationStack(path: $router[.feed]) {  // Use feed tab's navigation path as the main one
      TabView {
        Tab("Feed", systemImage: "square.stack") {
          FeedsListView()
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
        }
        Tab("Notifications", systemImage: "bell") {
          NotificationsListView()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
        }
        Tab("Profile", systemImage: "person") {
          CurrentUserView()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        Tab("Settings", systemImage: "gearshape") {
          SettingsView()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }

        // Native search tab in tab bar
        Tab(role: .search) {
          Text("Search")
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
      }
      .searchable(text: $searchText)
      .tint(.themePrimary)
      .tabBarMinimizeBehavior(.onScrollDown)
      .withAppDestinations()  // Apply navigation destinations once at app level
    }
  }
}

#Preview {
  AppTabView()
    .environment(AppRouter(initialTab: .feed))
}
