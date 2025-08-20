import AppRouter
import Auth
import Client
import DesignSystem
import Destinations
import FeedUI
import Models
import NotificationsUI
import PostUI
import ProfileUI
import SettingsUI
import SwiftUI

struct AppTabRootView: View {
  let router: AppRouter
  let tab: AppTab

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router[tab]) {
      tab.rootView()
        .withAppDestinations()
        .environment(\.currentTab, tab)
        .modifier(FeedTabNavigationModifier(tab: tab))
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            if tab == .feed {
              Button(action: {
                router.presentedSheet = .composer(mode: .newPost)
              }) {
                Image(systemName: "square.and.pencil")
                  .font(.title2)
                  .foregroundColor(.themePrimary)
              }
            }
          }
        }

    }
  }
}

// MARK: - Navigation Modifier

struct FeedTabNavigationModifier: ViewModifier {
  let tab: AppTab

  func body(content: Content) -> some View {
    switch tab {
    case .feed:
      content
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
    case .profile:
      content
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    case .notification:
      content
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    case .settings:
      content
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    case .compose:
      content
    }
  }
}

extension AppTab {
  @ViewBuilder
  fileprivate func rootView() -> some View {
    switch self {
    case .feed:
      FeedsListView()
    case .profile:
      CurrentUserView()
    case .notification:
      NotificationsListView()
    case .settings:
      SettingsView()
    case .compose:
      EmptyView()
    }
  }
}
