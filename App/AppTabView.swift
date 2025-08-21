import AppRouter
import AuthUI
import Client
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
          Text("Search")
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
        // Simple feed view to avoid compilation errors
        VStack(spacing: 20) {
          // Feed header
          HStack {
            AsyncImage(url: feed.avatarImageURL) { phase in
              switch phase {
              case .success(let image):
                image
                  .resizable()
                  .scaledToFit()
                  .frame(width: 64, height: 64)
                  .clipShape(Circle())
              default:
                Image(systemName: "list.bullet.circle.fill")
                  .font(.system(size: 64))
                  .foregroundStyle(.blue)
              }
            }
            
            VStack(alignment: .leading, spacing: 4) {
              Text(feed.displayName)
                .font(.title2)
                .fontWeight(.semibold)
              
              Text("by @\(feed.creatorHandle)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
          }
          
          // Feed description
          if let description = feed.description, !description.isEmpty {
            Text(description)
              .font(.body)
              .lineLimit(nil)
              .multilineTextAlignment(.leading)
          }
          
          // Feed stats
          HStack(spacing: 24) {
            HStack(spacing: 4) {
              Image(systemName: "heart")
              Text("\(feed.likesCount)")
            }
            
            HStack(spacing: 4) {
              Image(systemName: "list.bullet")
              Text("Feed")
            }
          }
          .foregroundStyle(.secondary)
          
          Spacer()
          
          Button("Done") {
            router.presentedSheet = nil
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
      case .post(let post):
        // Simple post view to avoid compilation errors
        VStack(spacing: 20) {
          // Author info
          HStack {
            AsyncImage(url: post.author.avatarImageURL) { phase in
              switch phase {
              case .success(let image):
                image
                  .resizable()
                  .scaledToFit()
                  .frame(width: 48, height: 48)
                  .clipShape(Circle())
              default:
                Image(systemName: "person.circle.fill")
                  .font(.title)
                  .foregroundStyle(.secondary)
                  .frame(width: 48, height: 48)
              }
            }
            
            VStack(alignment: .leading, spacing: 4) {
              Text(post.author.displayName ?? post.author.handle)
                .font(.headline)
                .fontWeight(.semibold)
              
              Text("@\(post.author.handle)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
          }
          
          // Post content
          Text(post.content)
            .font(.body)
            .lineLimit(nil)
          
          // Post stats
          HStack(spacing: 24) {
            HStack(spacing: 4) {
              Image(systemName: "heart")
              Text("\(post.likeCount)")
            }
            
            HStack(spacing: 4) {
              Image(systemName: "arrow.2.squarepath")
              Text("\(post.repostCount)")
            }
            
            HStack(spacing: 4) {
              Image(systemName: "bubble.left")
              Text("\(post.replyCount)")
            }
          }
          .foregroundStyle(.secondary)
          
          Spacer()
          
          Button("Done") {
            router.presentedSheet = nil
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
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
