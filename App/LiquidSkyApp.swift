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
          EnhancedSimpleLoginView(router: router, auth: auth)
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
                router.selectedTab = .feed
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
          let _ = print("Direct sheet: Creating enhanced login screen")
          EnhancedSimpleLoginView(router: router, auth: auth)
            .onAppear {
              print("Direct sheet: Enhanced login screen appeared successfully")
            }
            .onDisappear {
              print("Direct sheet: Enhanced login screen disappeared")
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

// MARK: - iOS 26 Liquid Glass Login View
struct EnhancedSimpleLoginView: View {
  let router: AppRouter
  let auth: Auth
  @State private var handle = ""
  @State private var appPassword = ""
  @State private var isLoading = false
  @State private var errorMessage = ""
  @State private var animateGradient = false
  @State private var showPassword = false
  @State private var inputFocused = false
  @State private var selectedTheme: ColorTheme = .bluesky

  var body: some View {
    ZStack {
      // iOS 26 Liquid Glass Background
      liquidGlassBackground

      // Floating liquid elements
      floatingLiquidElements

      // Main content
      VStack(spacing: 0) {
        // iOS 26 Liquid Glass Header
        liquidGlassHeader
      }
      .padding(.horizontal, 24)

      // Bottom glass sheet inset with curved top corners
      VStack {
        Spacer()
        bottomGlassSheet
      }
    }
    .overlay(alignment: .top) {
      Image("cloud")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 160, height: 160)
        .padding(.top, 28)
    }
    .ignoresSafeArea(.container, edges: .top)
    .preferredColorScheme(.dark)
    .onAppear {
      withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
        animateGradient = true
      }
    }
  }

  // MARK: - iOS 26 Liquid Glass Background
  @ViewBuilder
  private var liquidGlassBackground: some View {
    ZStack {
      // iOS 26 Dynamic Color Background
      LinearGradient(
        colors: [
          Color(.systemIndigo).opacity(0.8),
          Color(.systemPurple).opacity(0.6),
          Color(.systemBlue).opacity(0.4),
        ],
        startPoint: animateGradient ? .topLeading : .bottomTrailing,
        endPoint: animateGradient ? .bottomTrailing : .topLeading
      )
      .ignoresSafeArea()

      // Subtle noise texture for depth
      Rectangle()
        .fill(.ultraThinMaterial)
        .overlay(
          Image(systemName: "sparkles")
            .font(.system(size: 200))
            .foregroundStyle(.white.opacity(0.03))
            .rotationEffect(.degrees(animateGradient ? 360 : 0))
            .animation(
              .linear(duration: 20).repeatForever(autoreverses: false), value: animateGradient)
        )
        .ignoresSafeArea()
    }
  }

  // MARK: - Floating Liquid Elements
  @ViewBuilder
  private var floatingLiquidElements: some View {
    ZStack {
      // Large floating liquid orbs
      ForEach(0..<3, id: \.self) { index in
        Circle()
          .fill(.ultraThinMaterial)
          .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
          .blur(radius: 40)
          .overlay(
            Circle()
              .stroke(.white.opacity(0.1), lineWidth: 1)
          )
          .offset(
            x: CGFloat.random(in: -150...150),
            y: CGFloat.random(in: -300...300)
          )
          .scaleEffect(animateGradient ? 1.1 : 0.9)
          .animation(
            .easeInOut(duration: Double.random(in: 8...16))
              .repeatForever(autoreverses: true)
              .delay(Double(index) * 0.5),
            value: animateGradient
          )
      }

      // Medium floating liquid orbs
      ForEach(0..<5, id: \.self) { index in
        Circle()
          .fill(.ultraThinMaterial)
          .frame(width: 60 + CGFloat(index * 20), height: 60 + CGFloat(index * 20))
          .blur(radius: 30)
          .overlay(
            Circle()
              .stroke(.white.opacity(0.08), lineWidth: 1)
          )
          .offset(
            x: CGFloat.random(in: -200...200),
            y: CGFloat.random(in: -400...400)
          )
          .scaleEffect(animateGradient ? 1.2 : 0.8)
          .animation(
            .easeInOut(duration: Double.random(in: 6...14))
              .repeatForever(autoreverses: true)
              .delay(Double(index) * 0.3),
            value: animateGradient
          )
      }

      // Small floating liquid orbs
      ForEach(0..<8, id: \.self) { index in
        Circle()
          .fill(.ultraThinMaterial)
          .frame(width: 30 + CGFloat(index * 10), height: 30 + CGFloat(index * 10))
          .blur(radius: 20)
          .overlay(
            Circle()
              .stroke(.white.opacity(0.06), lineWidth: 1)
          )
          .offset(
            x: CGFloat.random(in: -250...250),
            y: CGFloat.random(in: -500...500)
          )
          .scaleEffect(animateGradient ? 1.3 : 0.7)
          .animation(
            .easeInOut(duration: Double.random(in: 4...12))
              .repeatForever(autoreverses: true)
              .delay(Double(index) * 0.2),
            value: animateGradient
          )
      }
    }
  }

  // MARK: - iOS 26 Liquid Glass Header
  @ViewBuilder
  private var liquidGlassHeader: some View {
    VStack(spacing: 40) {
      Spacer(minLength: 80)

      // iOS 26 Liquid Glass Icon Container
      ZStack {
        // Outer liquid glass rings
        ForEach(0..<4, id: \.self) { index in
          Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 160 + CGFloat(index * 30), height: 160 + CGFloat(index * 30))
            .blur(radius: 30)
            .overlay(
              Circle()
                .stroke(.white.opacity(0.2 - Double(index) * 0.05), lineWidth: 1)
            )
        }
      }
      .scaleEffect(animateGradient ? 1.05 : 1.0)
      .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)

      VStack(spacing: 20) {
        Text("LiquidSky")
          .font(.system(size: 48, weight: .thin, design: .default))
          .foregroundStyle(
            LinearGradient(
              colors: [.white, Color(.systemBlue).opacity(0.7)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )

        Text("Your gateway to Bluesky")
          .font(.system(size: 22, weight: .light))
          .foregroundColor(.white.opacity(0.8))
      }
    }
  }

  // MARK: - Bottom Glass Sheet
  @ViewBuilder
  private var bottomGlassSheet: some View {
    VStack(spacing: 0) {
      liquidGlassForm
        .padding(.bottom, max(24, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 24))
    }
    .background(
      RoundedCorner(radius: 32, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedCorner(radius: 32, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
            .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    )
    .ignoresSafeArea(edges: .bottom)
  }

  // MARK: - iOS 26 Liquid Glass Form
  @ViewBuilder
  private var liquidGlassForm: some View {
    VStack(spacing: 32) {
      // iOS 26 Liquid Glass Input Fields
      liquidGlassInputField(
        icon: "at",
        placeholder: "yourhandle.bsky.social",
        text: $handle,
        isSecure: false
      )

      liquidGlassInputField(
        icon: "lock",
        placeholder: "Enter your app password",
        text: $appPassword,
        isSecure: true
      )

      // iOS 26 Liquid Glass Error Message
      if !errorMessage.isEmpty {
        liquidGlassErrorMessage
      }

      // iOS 26 Liquid Glass Login Button
      liquidGlassLoginButton

      // iOS 26 Liquid Glass Help Text
      liquidGlassHelpText
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 40)
  }

  // MARK: - iOS 26 Liquid Glass Input Field
  @ViewBuilder
  private func liquidGlassInputField(
    icon: String,
    placeholder: String,
    text: Binding<String>,
    isSecure: Bool
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(isSecure ? "App Password" : "Handle")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(.white.opacity(0.9))

      HStack(spacing: 20) {
        Image(systemName: icon)
          .foregroundColor(Color(.systemBlue).opacity(0.8))
          .frame(width: 24)
          .font(.system(size: 18, weight: .medium))

        if isSecure {
          SecureField(placeholder, text: text)
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 18))
            .foregroundColor(.white)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        } else {
          TextField(placeholder, text: text)
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 18))
            .foregroundColor(.white)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        }
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 20)
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 24)
              .stroke(.white.opacity(0.25), lineWidth: 1)
          )
      )
      .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
  }

  // MARK: - iOS 26 Liquid Glass Error Message
  @ViewBuilder
  private var liquidGlassErrorMessage: some View {
    HStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundColor(.orange)
        .font(.system(size: 18, weight: .medium))

      Text(errorMessage)
        .font(.system(size: 16))
        .foregroundColor(.orange)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 18)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(.orange.opacity(0.4), lineWidth: 1)
        )
    )
    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
  }

  // MARK: - iOS 26 Liquid Glass Login Button
  @ViewBuilder
  private var liquidGlassLoginButton: some View {
    Button(action: {
      Task {
        await login()
      }
    }) {
      HStack(spacing: 16) {
        if isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(0.9)
        } else {
          Image(systemName: "arrow.right")
            .font(.system(size: 20, weight: .medium))
        }

        Text(isLoading ? "Signing In..." : "Sign In to Bluesky")
          .font(.system(size: 20, weight: .medium))
      }
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 24)
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(
            LinearGradient(
              colors: [Color(.systemBlue), Color(.systemPurple)],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .shadow(color: Color(.systemBlue).opacity(0.5), radius: 20, x: 0, y: 10)
      )
    }
    .disabled(handle.isEmpty || appPassword.isEmpty || isLoading)
    .opacity((handle.isEmpty || appPassword.isEmpty || isLoading) ? 0.6 : 1.0)
    .scaleEffect((handle.isEmpty || appPassword.isEmpty || isLoading) ? 0.98 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: handle.isEmpty || appPassword.isEmpty || isLoading)
  }

  // MARK: - iOS 26 Liquid Glass Help Text
  @ViewBuilder
  private var liquidGlassHelpText: some View {
    VStack(spacing: 12) {
      Text("Don't have an app password?")
        .font(.system(size: 16))
        .foregroundColor(.white.opacity(0.7))

      Link(
        "Create one at bsky.app/settings/app-passwords",
        destination: URL(string: "https://bsky.app/settings/app-passwords")!
      )
      .font(.system(size: 16))
      .foregroundColor(Color(.systemBlue).opacity(0.9))
      .underline()
    }
    .padding(.top, 16)
  }

  private func login() async {
    guard !handle.isEmpty && !appPassword.isEmpty else { return }

    isLoading = true
    errorMessage = ""

    do {
      // Use the new multi-account system
      let _ = try await auth.addAccount(handle: handle, appPassword: appPassword)
      // No need to manually dismiss - the view will be recreated due to .id() modifier
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }
}
