import ATProtoKit
import AppRouter
import Auth
import AuthUI
import Client
import ComposerUI
import DesignSystem
import Destinations
import FeedUI
import MediaUI
import Models
import Nuke
import NukeUI
import ProfileUI
import SwiftUI
import User
import WidgetKit

@main
struct LiquidSkyApp: App {
  @Environment(\.scenePhase) var scenePhase

  @State var appState: AppState = .resuming
  @State var accountManager: AccountManager
  @State var auth: Auth
  @State var router: AppRouter = .init(initialTab: .feed)
  @State var postDataControllerProvider: PostContextProvider = .init()
  @State var postFilterService: PostFilterService = .shared
  @State var imageQualityService: ImageQualityService = .shared
  @State var settingsService: SettingsService = .shared

  init() {
    print("LiquidSkyApp: Initializing...")

    // Initialize accountManager first
    let accountManager = AccountManager()
    self.accountManager = accountManager

    // Initialize auth with the same accountManager instance
    self.auth = Auth(accountManager: accountManager)

    ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
    print("LiquidSkyApp: ImagePipeline configured")
    // Note: ImageQualityService configuration moved to avoid potential deadlocks
  }

  var body: some Scene {
    WindowGroup {
      Group {
        switch appState {
        case .resuming:
          AuthView()
            .environment(accountManager)
            .environment(auth)
            .environment(router)
            .environment(postDataControllerProvider)
            .environment(postFilterService)
            .environment(imageQualityService)
            .environment(settingsService)
            .environment(ColorThemeManager.shared)
        case .authenticated(let client, let currentUser):
          AppTabView()
            .environment(client)
            .environment(currentUser)
            .environment(auth)
            .environment(accountManager)
            .environment(router)
            .environment(postDataControllerProvider)
            .environment(postFilterService)
            .environment(imageQualityService)
            .environment(settingsService)
            .environment(ColorThemeManager.shared)
            .id(auth.currentAccountId)  // CRITICAL: Forces complete view recreation on account switch
            .withTheme()
            .themeAware()
            .withSheetDestinations(
              router: .constant(router), auth: auth, client: client, currentUser: currentUser
            )
            .onAppear {
              print("LiquidSkyApp: Showing authenticated state")
            }
            .onReceive(NotificationCenter.default.publisher(for: .openComposerNewPostFromShortcut))
          { _ in
            Task { @MainActor in
              router.presentedSheet = .composer(mode: .newPost)
            }
          }
            .onReceive(NotificationCenter.default.publisher(for: .openNotificationsFromShortcut)) {
              _ in
              Task { @MainActor in
                router.selectedTab = .notification
              }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openSearchFromShortcut)) { _ in
              Task { @MainActor in
                router.selectedTab = .compose
              }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openProfileFromShortcut)) { _ in
              Task { @MainActor in
                router.selectedTab = .profile
              }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openFeedFromShortcut)) { _ in
              Task { @MainActor in
                router.selectedTab = .feed
              }
            }
            .onReceive(NotificationCenter.default.publisher(for: .notificationsUpdated)) {
              notification in
              if let userInfo = notification.userInfo,
                let title = userInfo["title"] as? String,
                let subtitle = userInfo["subtitle"] as? String
              {
                let defaults = UserDefaults(suiteName: "group.com.acxtrilla.LiquidSky")
                defaults?.set(title, forKey: "widget.recent.notification.title")
                defaults?.set(subtitle, forKey: "widget.recent.notification.subtitle")

                // Reload widget timeline
                if #available(iOS 14.0, *) {
                  WidgetCenter.shared.reloadTimelines(ofKind: "RecentNotificationWidget")
                }
              }
            }
        case .unauthenticated:
          VStack {
            Text("Unauthenticated")
              .font(.title)
              .foregroundColor(.secondary)

            Button("Show Auth Screen") {
              print("Manual auth button tapped")
              router.presentedSheet = .auth
            }
            .buttonStyle(.borderedProminent)
            .padding()
          }
          .onAppear {
            print("LiquidSkyApp: Showing unauthenticated state")
          }
        case .error(let error):
          Text("Error: \(error.localizedDescription)")
            .onAppear {
              print("LiquidSkyApp: Showing error state: \(error)")
            }
        }
      }
      .modelContainer(for: RecentFeedItem.self)
      .sheet(item: $router.presentedSheet) { presentedSheet in
        let _ = print("Direct sheet: Creating sheet for \(presentedSheet)")
        switch presentedSheet {
        case .auth:
          let _ = print("Direct sheet: Creating auth view")
          AuthView()
            .environment(auth)
            .environment(accountManager)
            .environment(router)
            .onAppear {
              print("Direct sheet: Auth view appeared successfully")
            }
            .onDisappear {
              print("Direct sheet: Auth view disappeared")
            }
        case .feedsList:
          FeedsListView()
            .environment(appState.client)
            .environment(appState.currentUser)
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
          if let client = appState.client, let currentUser = appState.currentUser {
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
            .environment(appState.client)
            .environment(appState.currentUser)
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
          .environment(appState.client)
          .environment(appState.currentUser)
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
          .environment(appState.client)
          .environment(appState.currentUser)
        }
      }
      .onAppear {
        print("LiquidSkyApp: App appeared")
        // Safety check for auth
        print("Auth is properly initialized: \(auth)")

        // Ensure auth screen shows if no configuration exists
        if auth.configuration == nil && router.presentedSheet != .auth {
          print("Fallback: Ensuring auth screen is shown")
          router.presentedSheet = .auth
        }
      }
      .task(id: scenePhase) {
        print("LiquidSkyApp: Scene phase changed to: \(scenePhase)")
        if scenePhase == .active {
          print("LiquidSkyApp: Scene became active")
          // Session restoration is now handled in the main task
          // No need to refresh here as it could interfere with the restoration process
        }
      }
      .task {
        print("LiquidSkyApp: Main task started")

        // Wait for initial session restoration attempt
        print("Waiting for initial session restoration...")
        await auth.restoreSession()

        // Check if we have an initial configuration after restoration attempt
        if auth.configuration == nil {
          print("No initial configuration after restoration, showing auth screen")
          await MainActor.run {
            appState = .unauthenticated
            router.presentedSheet = .auth
            print("Auth screen requested after failed restoration")
          }
        } else {
          print("Initial configuration found after restoration, proceeding with authentication")
        }

        for await configuration in auth.configurationUpdates {
          print(
            "LiquidSkyApp: Received configuration update: \(configuration != nil ? "available" : "nil")"
          )
          if let configuration {
            // Keep the auth sheet visible while we're setting up the environment
            // Only clear it after authentication is fully complete
            await refreshEnvWith(configuration: configuration)

            // Now that authentication is complete, clear the auth sheet
            if router.presentedSheet == .auth {
              print("Authentication complete, clearing auth sheet")
              router.presentedSheet = nil
            }
          } else {
            print("No configuration available, showing auth screen")
            appState = .unauthenticated
            router.presentedSheet = .auth
            print("Auth sheet requested after configuration update")
          }
        }
      }
      .onChange(of: router.presentedSheet) {
        print(
          "LiquidSkyApp: Sheet changed to \(router.presentedSheet != nil ? "\(router.presentedSheet!)" : "nil")"
        )
      }
    }
  }

  private func refreshEnvWith(configuration: ATProtocolConfiguration) async {
    print("refreshEnvWith: Starting environment refresh...")
    do {
      print("Creating BSkyClient...")
      let client = try await BSkyClient(configuration: configuration)
      print("BSkyClient created successfully")

      print("Creating CurrentUser...")
      let currentUser = try await CurrentUser(client: client)
      print("CurrentUser created successfully")

      // Publish follower count to widget after profile is fetched
      Task {
        if let profile = await currentUser.profile {
          let defaults = UserDefaults(suiteName: "group.com.acxtrilla.LiquidSky")
          defaults?.set(profile.profile.followersCount, forKey: "widget.followers.count")

          // Reload widget timeline
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "FollowerCountWidget")
          }
        }
      }

      print("Configuring ImageQualityService...")
      // Configure image quality service after authentication is complete
      ImageQualityService.shared.configureImagePipeline()
      print("ImageQualityService configured successfully")

      print("Setting app state to authenticated...")
      await MainActor.run {
        appState = .authenticated(client: client, currentUser: currentUser)
        print("App state set to authenticated successfully")
      }

      // Publish initial notification data to widget
      Task {
        // Wait a bit for the UI to load, then publish a sample notification
        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        NotificationCenter.default.post(
          name: .notificationsUpdated,
          object: nil,
          userInfo: [
            "title": "Welcome to LiquidSky!",
            "subtitle": "Your Bluesky client is ready",
          ]
        )
      }
    } catch {
      print("refreshEnvWith failed: \(error)")
      // Don't set to unauthenticated while auth sheet is showing
      // This prevents the "Unauthenticated" screen from appearing
      if router.presentedSheet != .auth {
        await MainActor.run {
          appState = .unauthenticated
          print("App state set to unauthenticated due to error")
        }
      } else {
        print("Auth sheet is showing, keeping current state to avoid 'Unauthenticated' screen")
      }
    }
  }
}

// MARK: - Utility: RoundedCorner shape
private struct RoundedCorner: Shape {
  let radius: CGFloat
  let corners: UIRectCorner

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}
