import AppRouter
import AuthUI
import ComposerUI
import DesignSystem
import Destinations
import FeedUI
import MediaUI
import ProfileUI
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
    .tabBarMinimizeBehavior(.onScrollDown)
    .sheet(item: $router.presentedSheet) { sheetDestination in
      switch sheetDestination {
      case .auth:
        AuthView()
      case .feedsList:
        FeedsListView()
      case .fullScreenMedia(let images, let preloadedImage, let namespace):
        FullScreenMediaView(
          images: images,
          preloadedImage: preloadedImage,
          namespace: namespace
        )
      case .fullScreenProfilePicture(let imageURL, let namespace):
        FullScreenProfilePictureView(
          imageURL: imageURL,
          namespace: namespace
        )
      case .fullScreenVideo(let media, let namespace):
        FullScreenVideoView(
          media: media,
          namespace: namespace
        )
      case .composer(let mode):
        let composerMode = convertToComposerMode(mode)
        ComposerView(mode: composerMode)
      case .profile(let profile):
        ProfileView(profile: profile, isCurrentUser: false)
      case .feed(let feed):
        // For now, show a placeholder view - we'll implement proper feed view later
        VStack {
          Text("Feed: \(feed.displayName)")
            .font(.title)
          Text("URI: \(feed.uri)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      case .post(let post):
        // For now, show a placeholder view - we'll implement proper post view later
        VStack {
          Text("Post")
            .font(.title)
          Text("URI: \(post.uri)")
            .font(.caption)
            .foregroundStyle(.secondary)
          if !post.content.isEmpty {
            Text(post.content)
              .font(.body)
              .padding()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }
}

// MARK: - Helper Functions
extension AppTabView {
  fileprivate func convertToComposerMode(_ destinationMode: ComposerDestinationMode) -> ComposerMode
  {
    switch destinationMode {
    case .newPost:
      return .newPost
    case .reply(let post):
      return .reply(post)
    }
  }
}

#Preview {
  AppTabView()
    .environment(AppRouter(initialTab: .feed))
}
