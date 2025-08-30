import AppRouter
import Auth
import AuthUI
import Client
import ComposerUI
import Destinations
import FeedUI
import MediaUI
import Models
import PostUI
import ProfileUI
import SwiftUI
import User

public struct SheetDestinations: ViewModifier {
  @Binding var router: AppRouter
  let auth: Auth
  let client: BSkyClient?
  let currentUser: CurrentUser?
  let postDataControllerProvider: PostContextProvider
  let settingsService: SettingsService

  public func body(content: Content) -> some View {
    content
      .sheet(item: $router.presentedSheet) { presentedSheet in
        #if DEBUG
          let _ = print("SheetDestinations: Creating sheet for \(presentedSheet)")
        #endif
        switch presentedSheet {
        case .auth:
          #if DEBUG
            let _ = print("SheetDestinations: Creating AuthView")
          #endif
          Group {
            AuthView()
              .environment(auth)
              .environment(router)
              .onAppear {
                #if DEBUG
                  print("SheetDestinations: AuthView appeared successfully")
                #endif
              }
              .onDisappear {
                #if DEBUG
                  print("SheetDestinations: AuthView disappeared")
                #endif
              }
          }
          .onAppear {
            #if DEBUG
              print("SheetDestinations: Auth sheet container appeared")
            #endif
          }
          .onDisappear {
            #if DEBUG
              print("SheetDestinations: Auth sheet container disappeared")
            #endif
          }
        case .feedsList:
          FeedsListView()
            .environment(client)
            .environment(currentUser)
            .environment(router)
        case .fullScreenMedia(let images, let preloadedImage, let namespace):
          FullScreenMediaView(
            images: images,
            preloadedImage: preloadedImage,
            namespace: namespace
          )
          .environment(router)
        case .fullScreenProfilePicture(let imageURL, let namespace):
          FullScreenProfilePictureView(
            imageURL: imageURL,
            namespace: namespace
          )
          .environment(router)
        case .fullScreenVideo(let media, let namespace):
          FullScreenVideoViewWrapper(
            media: media,
            namespace: namespace
          )
          .environment(router)
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
            .environment(router)
            .environment(postDataControllerProvider)
            .environment(settingsService)
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
          .environment(client)
          .environment(currentUser)
          .environment(router)
          .environment(postDataControllerProvider)
          .environment(settingsService)
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
          .environment(client)
          .environment(currentUser)
          .environment(router)
          .environment(postDataControllerProvider)
          .environment(settingsService)
        case .translate(let post):
          TranslateView(post: post)
            .presentationDetents([.medium, .large])
            .environment(client)
            .environment(currentUser)
            .environment(router)
            .environment(postDataControllerProvider)
            .environment(settingsService)
        }
      }
      .onChange(of: router.presentedSheet) {
        #if DEBUG
          print("SheetDestinations: Sheet changed")
        #endif
      }
  }
}

extension View {
  public func withSheetDestinations(
    router: Binding<AppRouter>,
    auth: Auth,
    client: BSkyClient? = nil,
    currentUser: CurrentUser? = nil,
    postDataControllerProvider: PostContextProvider,
    settingsService: SettingsService
  ) -> some View {
    modifier(
      SheetDestinations(
        router: router,
        auth: auth,
        client: client,
        currentUser: currentUser,
        postDataControllerProvider: postDataControllerProvider,
        settingsService: settingsService
      ))
  }
}
