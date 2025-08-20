import AppRouter
import DesignSystem
import Destinations
import FeedUI
import SwiftUI

struct AppTabView: View {
  @Environment(AppRouter.self) var router
  @State private var searchText: String = ""

  var body: some View {
    @Bindable var router = router
    TabView {
      Tab("Feed", systemImage: "square.stack") {
        AppTabRootView(router: router, tab: .feed)
      }
      Tab("Notifications", systemImage: "bell") {
        AppTabRootView(router: router, tab: .notification)
      }
      Tab("Profile", systemImage: "person") {
        AppTabRootView(router: router, tab: .profile)
      }
      Tab("Settings", systemImage: "gearshape") {
        AppTabRootView(router: router, tab: .settings)
      }

      // Native search tab in tab bar
      Tab(role: .search) {
        NavigationStack {
          SearchView()
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
      }
    }
    .searchable(text: $searchText)
    .tint(.themePrimary)
    .onChange(
      of: router.selectedTab,
      { oldTab, newTab in
        if newTab == .compose {
          router.presentedSheet = .composer(mode: .newPost)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            router.selectedTab = oldTab
          }
        }
      })
  }
}

#Preview {
  AppTabView()
    .environment(AppRouter(initialTab: .feed))
}
