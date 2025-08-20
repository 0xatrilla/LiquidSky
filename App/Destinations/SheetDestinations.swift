import AppRouter
import Auth
import AuthUI
import Client
import ComposerUI
import Destinations
import FeedUI
import MediaUI
import Models
import ProfileUI
import SwiftUI
import User

public struct SheetDestinations: ViewModifier {
  @Binding var router: AppRouter
  let auth: Auth
  let client: BSkyClient?
  let currentUser: CurrentUser?

  public func body(content: Content) -> some View {
    content
      .sheet(item: $router.presentedSheet) { presentedSheet in
        let _ = print("SheetDestinations: Creating sheet for \(presentedSheet)")
        switch presentedSheet {
        case .auth:
          let _ = print("SheetDestinations: Creating AuthView")
          Group {
            AuthView()
              .environment(auth)
              .onAppear {
                print("SheetDestinations: AuthView appeared successfully")
              }
              .onDisappear {
                print("SheetDestinations: AuthView disappeared")
              }
          }
          .onAppear {
            print("SheetDestinations: Auth sheet container appeared")
          }
          .onDisappear {
            print("SheetDestinations: Auth sheet container disappeared")
          }
        case .feedsList:
          FeedsListView()
            .environment(client)
            .environment(currentUser)
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
          FullScreenVideoViewWrapper(
            media: media,
            namespace: namespace
          )
        case .composer(let mode):
          if let client, let currentUser {
            switch mode {
            case .newPost:
              ComposerView(mode: .newPost)
                .environment(client)
                .environment(currentUser)
                .environment(PostFilterService.shared)
                .environment(router)
            case .reply(let post):
              ComposerView(mode: .reply(post))
                .environment(client)
                .environment(currentUser)
                .environment(PostFilterService.shared)
                .environment(router)
            }
          }
        case .profile(let profile):
          ProfileView(profile: profile, isCurrentUser: false)
            .environment(client)
            .environment(currentUser)
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
      .onChange(of: router.presentedSheet) {
        print("SheetDestinations: Sheet changed")
      }
  }
}

extension View {
  public func withSheetDestinations(
    router: Binding<AppRouter>,
    auth: Auth,
    client: BSkyClient? = nil,
    currentUser: CurrentUser? = nil
  ) -> some View {
    modifier(
      SheetDestinations(
        router: router,
        auth: auth,
        client: client,
        currentUser: currentUser
      ))
  }
}
