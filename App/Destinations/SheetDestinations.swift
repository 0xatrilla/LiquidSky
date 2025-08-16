import AppRouter
import Auth
import AuthUI
import Client
import ComposerUI
import Destinations
import MediaUI
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
        switch presentedSheet {
        case .auth:
          AuthView()
            .environment(auth)
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
        case .composer(let mode):
          if let client, let currentUser {
            switch mode {
            case .newPost:
              ComposerView(mode: .newPost)
                .environment(client)
                .environment(currentUser)
            case .reply(let post):
              ComposerView(mode: .reply(post))
                .environment(client)
                .environment(currentUser)
            }
          }
        }
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
