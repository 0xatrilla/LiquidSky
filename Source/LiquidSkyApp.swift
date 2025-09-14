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
import PostUI
import ProfileUI
import SwiftUI
import User
import UserNotifications
import WidgetKit

@main
struct LiquidSkyApp: App {
  @Environment(\.scenePhase) var scenePhase

  // Add AppDelegate
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  @State var appState: AppState = .resuming
  @State var accountManager: AccountManager
  @State var auth: Auth
  @State var router: AppRouter = .init(initialTab: .feed)
  @State var postDataControllerProvider: PostContextProvider = .init()
  @State var postFilterService: PostFilterService = .shared
  @State var imageQualityService: ImageQualityService = .shared
  @State var settingsService: SettingsService = .shared

  // New services
  @State var pushNotificationService: PushNotificationService = .shared
  // @State var cloudKitSyncService: CloudKitSyncService = .shared
  @State var inAppPurchaseService: InAppPurchaseService = .shared

  init() {
    #if DEBUG
      print("LiquidSkyApp: Initializing...")
    #endif

    // Initialize accountManager first
    let accountManager = AccountManager()
    self.accountManager = accountManager

    // Initialize auth with the same accountManager instance
    self.auth = Auth(accountManager: accountManager)

    ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
    #if DEBUG
      print("LiquidSkyApp: ImagePipeline configured")
    #endif
    // Note: ImageQualityService configuration moved to avoid potential deadlocks
  }

  var body: some Scene {
    WindowGroup {
      Group {
        switch appState {
        case .resuming:
          // Show loading screen instead of AuthView to prevent flickering
          VStack(spacing: 24) {
            // App icon or logo placeholder
            ZStack {
              Circle()
                .fill(.blue.opacity(0.1))
                .frame(width: 80, height: 80)

              Image(systemName: "cloud.fill")
                .font(.system(size: 32))
                .foregroundStyle(.blue)
            }

            VStack(spacing: 8) {
              Text("Horizon")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

              ProgressView()
                .scaleEffect(0.8)

              Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color(.systemGroupedBackground))
          .environment(accountManager)
          .environment(auth)
          .environment(router)
          .environment(postDataControllerProvider)
          .environment(postFilterService)
          .environment(imageQualityService)
          .environment(settingsService)
          .environment(ColorThemeManager.shared)
          .environment(pushNotificationService)
          // .environment(cloudKitSyncService)
          .environment(inAppPurchaseService)
        case .authenticated(let client, let currentUser):
          Group {
            // Use iPad-optimized view on iPadOS 26+ with larger screens
            if UIDevice.current.userInterfaceIdiom == .pad,
              #available(iOS 26.0, *)
            {
              iPadAppView()
            } else {
              AppTabView()
            }
          }
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
          .environment(pushNotificationService)
          // .environment(cloudKitSyncService)
          .environment(inAppPurchaseService)
          .id(auth.currentAccountId)  // CRITICAL: Forces complete view recreation on account switch
          .withTheme()
          .themeAware()
          .modelContainer(for: RecentFeedItem.self)
          .withSheetDestinations(
            router: .constant(router), auth: auth, client: client, currentUser: currentUser,
            postDataControllerProvider: postDataControllerProvider,
            settingsService: settingsService
          )
          .onAppear {
            #if DEBUG
              print("LiquidSkyApp: Showing authenticated state")
            #endif
          }
          .onReceive(NotificationCenter.default.publisher(for: .openComposerNewPostFromShortcut)) {
            _ in
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
          .onReceive(NotificationCenter.default.publisher(for: .notificationTapped)) {
            notification in
            // Handle push notification taps
            handleNotificationTap(notification)
          }
        case .unauthenticated:
          AuthView()
            .environment(accountManager)
            .environment(auth)
            .environment(router)
            .environment(postDataControllerProvider)
            .environment(postFilterService)
            .environment(imageQualityService)
            .environment(settingsService)
            .environment(ColorThemeManager.shared)
            .environment(pushNotificationService)
            // .environment(cloudKitSyncService)
            .environment(inAppPurchaseService)
            .onAppear {
              #if DEBUG
                print("LiquidSkyApp: Showing unauthenticated state")
              #endif
            }
        case .error(let error):
          Text("Error: \(error.localizedDescription)")
            .onAppear {
              #if DEBUG
                print("LiquidSkyApp: Showing error state: \(error)")
              #endif
            }
        }
      }
      .sheet(item: $router.presentedSheet) { presentedSheet in
        #if DEBUG
          let _ = print("Direct sheet: Creating sheet for \(presentedSheet)")
        #endif
        switch presentedSheet {
        case .auth:
          #if DEBUG
            let _ = print("Direct sheet: Creating auth view")
          #endif
          AuthView()
            .environment(auth)
            .environment(accountManager)
            .environment(router)
            .environment(pushNotificationService)
            // .environment(cloudKitSyncService)
            .onAppear {
              #if DEBUG
                print("Direct sheet: Auth view appeared successfully")
              #endif
            }
            .onDisappear {
              #if DEBUG
                print("Direct sheet: Auth view disappeared")
              #endif
            }
        case .feedsList:
          FeedsListView()
            .environment(appState.client)
            .environment(appState.currentUser)
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
          if let client = appState.client, let currentUser = appState.currentUser {
            if #available(iOS 26.0, *) {
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
            } else {
              LegacyComposerView(mode: mode)
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
            .environment(router)
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
          .environment(router)
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
          .environment(router)
        case .translate(let post):
          TranslateView(post: post)
            .presentationDetents([.medium, .large])
            .environment(appState.client)
            .environment(appState.currentUser)
            .environment(router)
            .environment(postDataControllerProvider)
            .environment(settingsService)
        case .followingList(let profile):
          FollowingListView(profile: profile)
            .environment(appState.client)
            .environment(appState.currentUser)
            .environment(router)
            .environment(postDataControllerProvider)
            .environment(settingsService)
        case .followersList(let profile):
          FollowersListView(profile: profile)
            .environment(appState.client)
            .environment(appState.currentUser)
            .environment(router)
            .environment(postDataControllerProvider)
            .environment(settingsService)
        }
      }
      .onAppear {
        #if DEBUG
          print("LiquidSkyApp: App appeared")
        #endif
        // Safety check for auth
        #if DEBUG
          print("Auth is properly initialized: \(auth)")
        #endif

        // Ensure auth screen shows if no configuration exists
        if auth.configuration == nil && router.presentedSheet != .auth {
          #if DEBUG
            print("Fallback: Ensuring auth screen is shown")
          #endif
          router.presentedSheet = .auth
        }

        // Request push notification permissions
        Task {
          await requestPushNotificationPermissions()
        }
      }
      .task(id: scenePhase) {
        #if DEBUG
          print("LiquidSkyApp: Scene phase changed to: \(scenePhase)")
        #endif
        if scenePhase == .active {
          #if DEBUG
            print("LiquidSkyApp: Scene became active")
          #endif
          // Session restoration is now handled in the main task
          // No need to refresh here as it could interfere with the restoration process
        }
      }
      .task {
        #if DEBUG
          print("LiquidSkyApp: Main task started")
        #endif

        // Wait for initial session restoration attempt with timeout
        #if DEBUG
          print("Waiting for initial session restoration...")
        #endif

        // Add timeout to prevent long loading times
        await withTaskGroup(of: Void.self) { group in
          group.addTask {
            await auth.restoreSession()
          }

          group.addTask {
            try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3 second timeout
            #if DEBUG
              print("Session restoration timeout reached")
            #endif
          }

          await group.next()
          group.cancelAll()
        }

        // Check if we have an initial configuration after restoration attempt
        if auth.configuration == nil {
          #if DEBUG
            print("No initial configuration after restoration, showing auth screen")
          #endif
          await MainActor.run {
            appState = .unauthenticated
            #if DEBUG
              print("Auth screen requested after failed restoration")
            #endif
          }
        } else {
          #if DEBUG
            print("Initial configuration found after restoration, proceeding with authentication")
          #endif
        }

        // Safety net: if we are still in resuming state after the timeout, move on
        let isStillResuming = await MainActor.run { () -> Bool in
          if case .resuming = appState { return true } else { return false }
        }
        if isStillResuming {
          #if DEBUG
            print("Safety fallback engaged: transitioning to unauthenticated state")
          #endif
          await MainActor.run { appState = .unauthenticated }
        }

        for await configuration in auth.configurationUpdates {
          #if DEBUG
            print(
              "LiquidSkyApp: Received configuration update: \(configuration != nil ? "available" : "nil")"
            )
          #endif
          if let configuration {
            // Keep the auth sheet visible while we're setting up the environment
            // Only clear it after authentication is fully complete
            await refreshEnvWith(configuration: configuration)

            // Now that authentication is complete, clear the auth sheet
            if router.presentedSheet == .auth {
              #if DEBUG
                print("Authentication complete, clearing auth sheet")
              #endif
              router.presentedSheet = nil
            }
          } else {
            #if DEBUG
              print("No configuration available, showing auth screen")
            #endif
            appState = .unauthenticated
            router.presentedSheet = .auth
            #if DEBUG
              print("Auth sheet requested after configuration update")
            #endif
          }
        }
      }
      .onChange(of: router.presentedSheet) {
        #if DEBUG
          print(
            "LiquidSkyApp: Sheet changed to \(router.presentedSheet != nil ? "\(router.presentedSheet!)" : "nil")"
          )
        #endif
      }
    }
  }

  private func refreshEnvWith(configuration: ATProtocolConfiguration) async {
    #if DEBUG
      print("refreshEnvWith: Starting environment refresh...")
    #endif
    do {
      #if DEBUG
        print("Creating BSkyClient...")
      #endif
      let client = try await BSkyClient(configuration: configuration)
      #if DEBUG
        print("BSkyClient created successfully")
      #endif

      #if DEBUG
        print("Creating CurrentUser...")
      #endif
      let currentUser = try await CurrentUser(client: client)
      #if DEBUG
        print("CurrentUser created successfully")
      #endif

      // Set user ID for CloudKit sync
      if let profile = currentUser.profile {
        // cloudKitSyncService.setCurrentUserId(profile.profile.did)
      }

      // Publish follower count to widget after profile is fetched
      Task {
        if let profile = currentUser.profile {
          WidgetDataPublisher.publishFollowerCount(profile.profile.followersCount)
        }
      }

      #if DEBUG
        print("Configuring ImageQualityService...")
      #endif
      // Configure image quality service after authentication is complete
      ImageQualityService.shared.configureImagePipeline()
      #if DEBUG
        print("ImageQualityService configured successfully")
      #endif

      #if DEBUG
        print("Setting app state to authenticated...")
      #endif
      await MainActor.run {
        appState = .authenticated(client: client, currentUser: currentUser)
        #if DEBUG
          print("App state set to authenticated successfully")
        #endif
      }

      // Publish initial notification data to widget
      Task {
        // Wait a bit for the UI to load, then publish a sample notification
        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds

        // Publish welcome notification
        WidgetDataPublisher.publishRecentNotification(
          title: "Welcome to Horizon!",
          subtitle: "Your Bluesky client is ready"
        )

        // Publish sample feed activity
        WidgetDataPublisher.publishSampleFeedActivity()

        // Simulate some real activity data
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        WidgetDataPublisher.publishRealFeedData(
          feedName: "Following",
          postCount: Int.random(in: 5...20),
          followerCount: Int.random(in: 1...8)
        )

        // Start continuous widget updates
        WidgetDataPublisher.startContinuousUpdates()
      }

      // Perform initial iCloud sync
      Task {
        // await cloudKitSyncService.performFullSync()
      }
    } catch {
      #if DEBUG
        print("refreshEnvWith failed: \(error)")
      #endif
      // Don't set to unauthenticated while auth sheet is showing
      // This prevents the "Unauthenticated" screen from appearing
      if router.presentedSheet != .auth {
        await MainActor.run {
          appState = .unauthenticated
          #if DEBUG
            print("App state set to unauthenticated due to error")
          #endif
        }
      } else {
        #if DEBUG
          print("Auth sheet is showing, keeping current state to avoid 'Unauthenticated' screen")
        #endif
      }
    }
  }

  // MARK: - Push Notification Methods

  private func requestPushNotificationPermissions() async {
    let granted = await pushNotificationService.requestPermission()
    if granted {
      print("PushNotificationService: Permission granted")
    } else {
      print("PushNotificationService: Permission denied")
    }
  }

  private func handleNotificationTap(_ notification: Notification) {
    guard let userInfo = notification.userInfo else {
      router.selectedTab = .notification
      return
    }

    if let destination = userInfo["destination"] as? String {
      switch destination {
      case "post":
        if let uri = userInfo["uri"] as? String, let client = appState.client {
          Task { @MainActor in
            router.selectedTab = .notification
            do {
              let posts = try await client.protoClient.getPosts([uri]).posts
              if let item = posts.first?.postItem {
                router[.notification].append(.post(item))
              }
            } catch {
              router.selectedTab = .notification
            }
          }
        } else {
          router.selectedTab = .notification
        }
      default:
        router.selectedTab = .notification
      }
    } else {
      router.selectedTab = .notification
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
