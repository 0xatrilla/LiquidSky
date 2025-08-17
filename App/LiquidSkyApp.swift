import ATProtoKit
import AppRouter
import Auth
import AuthUI
import Client
import ComposerUI
import DesignSystem
import Destinations
import MediaUI
import Models
import Nuke
import NukeUI
import SwiftUI
import User

@main
struct LiquidSkyApp: App {
  @Environment(\.scenePhase) var scenePhase

  @State var appState: AppState = .resuming
  @State var auth: Auth = .init()
  @State var router: AppRouter = .init(initialTab: .feed)
  @State var postDataControllerProvider: PostContextProvider = .init()
  @State var postFilterService: PostFilterService = .shared
  @State var imageQualityService: ImageQualityService = .shared
  @State var settingsService: SettingsService = .shared

  init() {
    print("LiquidSkyApp: Initializing...")
    ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
    print("LiquidSkyApp: ImagePipeline configured")
    // Note: ImageQualityService configuration moved to avoid potential deadlocks
  }

  var body: some Scene {
    WindowGroup {
      Group {
        switch appState {
        case .resuming:
          ProgressView()
            .containerRelativeFrame([.horizontal, .vertical])
            .onAppear {
              print("LiquidSkyApp: Showing resuming state")
            }
        case .authenticated(let client, let currentUser):
          AppTabView()
            .environment(client)
            .environment(currentUser)
            .environment(auth)
            .environment(router)
            .environment(postDataControllerProvider)
            .environment(postFilterService)
            .environment(imageQualityService)
            .environment(settingsService)
            .withTheme()
            .onAppear {
              print("LiquidSkyApp: Showing authenticated state")
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
          let _ = print("Direct sheet: Creating simple login screen")
          SimpleLoginView(router: router, auth: auth)
            .onAppear {
              print("Direct sheet: Simple login screen appeared successfully")
            }
            .onDisappear {
              print("Direct sheet: Simple login screen disappeared")
            }
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
          print("LiquidSkyApp: Scene became active, refreshing auth...")
          // Only refresh if we're not currently showing the auth sheet
          if router.presentedSheet != .auth {
            await auth.refresh()
          } else {
            print("Skipping auth refresh while auth sheet is showing")
          }
        }
      }
      .task {
        print("LiquidSkyApp: Main task started")
        // Check if we have an initial configuration
        if auth.configuration == nil {
          print("No initial configuration, immediately showing auth screen")
          await MainActor.run {
            appState = .unauthenticated
            router.presentedSheet = .auth
            print("Auth screen immediately requested")
          }

          // Wait a moment to ensure the sheet is presented before checking for updates
          try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
        } else {
          print("Initial configuration found, proceeding with authentication")
        }

        for await configuration in auth.configurationUpdates {
          print(
            "LiquidSkyApp: Received configuration update: \(configuration != nil ? "available" : "nil")"
          )
          if let configuration {
            // Only clear the auth sheet if it's currently showing
            if router.presentedSheet == .auth {
              print("Clearing auth sheet and proceeding with authentication")
              router.presentedSheet = nil
            }
            await refreshEnvWith(configuration: configuration)
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
      let client = await BSkyClient(configuration: configuration)
      print("BSkyClient created successfully")

      print("Creating CurrentUser...")
      let currentUser = try await CurrentUser(client: client)
      print("CurrentUser created successfully")

      print("Configuring ImageQualityService...")
      // Configure image quality service after authentication is complete
      ImageQualityService.shared.configureImagePipeline()
      print("ImageQualityService configured successfully")

      print("Setting app state to authenticated...")
      await MainActor.run {
        appState = .authenticated(client: client, currentUser: currentUser)
        print("App state set to authenticated successfully")
      }
    } catch {
      print("refreshEnvWith failed: \(error)")
      // Don't crash, just log the error
      await MainActor.run {
        appState = .unauthenticated
        print("App state set to unauthenticated due to error")
      }
    }
  }
}

// MARK: - Simple Login View
struct SimpleLoginView: View {
  let router: AppRouter
  let auth: Auth
  @State private var handle = ""
  @State private var appPassword = ""
  @State private var isLoading = false
  @State private var errorMessage = ""
  @State private var isAnimating = false

  var body: some View {
    ZStack {
      // Animated background gradient
      LinearGradient(
        colors: [
          Color.blue.opacity(0.3),
          Color.purple.opacity(0.2),
          Color.blue.opacity(0.1),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
      .scaleEffect(isAnimating ? 1.1 : 1.0)
      .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: isAnimating)

      // Floating orbs
      Circle()
        .fill(Color.blue.opacity(0.1))
        .frame(width: 200, height: 200)
        .blur(radius: 50)
        .offset(x: -150, y: -300)
        .scaleEffect(isAnimating ? 1.2 : 0.8)
        .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: isAnimating)

      Circle()
        .fill(Color.purple.opacity(0.1))
        .frame(width: 150, height: 150)
        .blur(radius: 40)
        .offset(x: 150, y: 300)
        .scaleEffect(isAnimating ? 0.8 : 1.2)
        .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: isAnimating)

      ScrollView {
        VStack(spacing: 32) {
          // Header section
          VStack(spacing: 20) {
            // App icon with glow effect
            ZStack {
              Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 120, height: 120)
                .blur(radius: 20)

              Image(systemName: "cloud.sun.fill")
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(
                  LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
            }
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(
              .easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

            VStack(spacing: 8) {
              Text("LiquidSky")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                  LinearGradient(
                    colors: [.white, .blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )

              Text("Your gateway to Bluesky")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            }
          }
          .padding(.top, 40)

          // Login form with liquid glass effect
          VStack(spacing: 24) {
            // Handle input field
            VStack(alignment: .leading, spacing: 8) {
              Text("Handle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

              HStack {
                Image(systemName: "at")
                  .foregroundColor(.blue.opacity(0.7))
                  .frame(width: 20)

                TextField("yourhandle.bsky.social", text: $handle)
                  .textFieldStyle(PlainTextFieldStyle())
                  .font(.system(size: 16))
                  .foregroundColor(.white)
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 14)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(.ultraThinMaterial)
                  .overlay(
                    RoundedRectangle(cornerRadius: 16)
                      .stroke(Color.white.opacity(0.2), lineWidth: 1)
                  )
              )
            }

            // App password input field
            VStack(alignment: .leading, spacing: 8) {
              Text("App Password")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

              HStack {
                Image(systemName: "lock")
                  .foregroundColor(.blue.opacity(0.7))
                  .frame(width: 20)

                SecureField("Enter your app password", text: $appPassword)
                  .textFieldStyle(PlainTextFieldStyle())
                  .font(.system(size: 16))
                  .foregroundColor(.white)
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 14)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(.ultraThinMaterial)
                  .overlay(
                    RoundedRectangle(cornerRadius: 16)
                      .stroke(Color.white.opacity(0.2), lineWidth: 1)
                  )
              )
            }

            // Error message
            if !errorMessage.isEmpty {
              HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundColor(.orange)
                Text(errorMessage)
                  .font(.system(size: 14))
                  .foregroundColor(.orange)
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 12)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(.ultraThinMaterial)
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                  )
              )
            }

            // Sign in button
            Button(action: signIn) {
              HStack {
                if isLoading {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                } else {
                  Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                }

                Text(isLoading ? "Signing In..." : "Sign In")
                  .font(.system(size: 18, weight: .semibold))
              }
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 18)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(
                    LinearGradient(
                      colors: [.blue, .cyan],
                      startPoint: .leading,
                      endPoint: .trailing
                    )
                  )
                  .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
              )
            }
            .disabled(handle.isEmpty || appPassword.isEmpty || isLoading)
            .opacity((handle.isEmpty || appPassword.isEmpty || isLoading) ? 0.6 : 1.0)
            .scaleEffect((handle.isEmpty || appPassword.isEmpty || isLoading) ? 0.98 : 1.0)
            .animation(
              .easeInOut(duration: 0.2), value: handle.isEmpty || appPassword.isEmpty || isLoading)

            // Help text
            VStack(spacing: 8) {
              Text("Don't have an app password?")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))

              Link(
                "Create one at bsky.app/settings/app-passwords",
                destination: URL(string: "https://bsky.app/settings/app-passwords")!
              )
              .font(.system(size: 14))
              .foregroundColor(.blue.opacity(0.8))
              .underline()
            }
            .padding(.top, 8)
          }
          .padding(.horizontal, 24)
          .padding(.vertical, 32)
          .background(
            RoundedRectangle(cornerRadius: 24)
              .fill(.ultraThinMaterial)
              .overlay(
                RoundedRectangle(cornerRadius: 24)
                  .stroke(Color.white.opacity(0.1), lineWidth: 1)
              )
          )
          .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)

          Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
      }
    }
    .onAppear {
      isAnimating = true
    }
  }

  private func signIn() {
    guard !handle.isEmpty && !appPassword.isEmpty else { return }

    isLoading = true
    errorMessage = ""

    Task {
      do {
        print("SimpleLoginView: Attempting authentication with handle: \(handle)")
        try await auth.authenticate(handle: handle, appPassword: appPassword)
        print("SimpleLoginView: Authentication successful!")

        // The main app will automatically handle the configuration update
        // and close the auth sheet, so we don't need to do anything here
      } catch {
        print("SimpleLoginView: Authentication failed: \(error)")
        await MainActor.run {
          isLoading = false
          errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
      }
    }
  }
}
