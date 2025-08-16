import Auth
import DesignSystem
import MediaUI
import Models
import SwiftUI
import User

public struct SettingsView: View {
  @Environment(Auth.self) var auth
  @Environment(CurrentUser.self) var currentUser
  @State private var settingsService = SettingsService.shared
  @State private var showingResetAlert = false
  @State private var showingAboutSheet = false
  @State private var showingPrivacyPolicy = false
  @State private var showingTermsOfService = false
  @State private var showingChangePassword = false
  @State private var showingHelpFAQ = false
  @State private var showingBugReport = false
  @State private var showingFeatureRequest = false
  @State private var showingContactSupport = false

  public init() {}

  private func updateTheme() {
    let themeManager = ThemeManager.shared
    themeManager.useSystemTheme = settingsService.useSystemTheme
    themeManager.currentTheme = settingsService.selectedTheme
  }

  public var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          HeaderView(title: "Settings", showBack: false)
            .padding(.horizontal, 16)

          // Account Section
          accountSection

          // Display Section
          displaySection

          // Content Section
          contentSection

          // Video Section
          videoSection

          // Privacy Section
          privacySection

          // Feed Section
          feedSection

          // Media Section
          mediaSection

          // Support Section
          supportSection

          // About Section
          aboutSection

          // Sign Out Button
          signOutButton
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
      }
      .background(Color(uiColor: .systemGroupedBackground))
      .navigationBarHidden(true)
    }
    .alert("Reset Settings", isPresented: $showingResetAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Reset", role: .destructive) {
        settingsService.resetAllSettings()
      }
    } message: {
      Text("This will reset all settings to their default values. This action cannot be undone.")
    }
    .sheet(isPresented: $showingAboutSheet) {
      AboutView()
    }
    .sheet(isPresented: $showingPrivacyPolicy) {
      PrivacyPolicyView()
    }
    .sheet(isPresented: $showingTermsOfService) {
      TermsOfServiceView()
    }
    .sheet(isPresented: $showingChangePassword) {
      ChangePasswordView()
    }
    .sheet(isPresented: $showingHelpFAQ) {
      HelpFAQView()
    }
    .sheet(isPresented: $showingBugReport) {
      BugReportView()
    }
    .sheet(isPresented: $showingFeatureRequest) {
      FeatureRequestView()
    }
    .sheet(isPresented: $showingContactSupport) {
      ContactSupportView()
    }
  }

  // MARK: - Account Section
  private var accountSection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(title: "Account", icon: "person.circle.fill", color: .blue)

      if let profile = currentUser.profile {
        SettingsInfoRow(
          title: "Display Name",
          icon: "person.fill",
          iconColor: .blue,
          value: profile.displayName ?? "Not set"
        )

        SettingsInfoRow(
          title: "Handle",
          icon: "at",
          iconColor: .green,
          value: profile.actorHandle
        )

      }

      SettingsNavigationRow(
        title: "Change Password",
        subtitle: "Update your app password",
        icon: "lock.fill",
        iconColor: .red
      ) {
        showingChangePassword = true
      }
    }
  }

  // MARK: - Display Section
  private var displaySection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(title: "Display", icon: "paintbrush.fill", color: .blueskyBackground)

      SettingsToggleRow(
        title: "Use System Theme",
        subtitle: "Automatically match your device's appearance",
        icon: "gear",
        iconColor: .purple,
        isOn: $settingsService.useSystemTheme
      )
      .onChange(of: settingsService.useSystemTheme) { _, _ in
        updateTheme()
      }

      if !settingsService.useSystemTheme {
        SettingsPickerRow(
          title: "App Theme",
          subtitle: "Choose your preferred appearance",
          icon: "moon.fill",
          iconColor: .blue,
          selection: $settingsService.selectedTheme,
          options: AppTheme.allCases,
          optionTitle: { $0.displayName }
        )
        .onChange(of: settingsService.selectedTheme) { _, _ in
          updateTheme()
        }
      }

      SettingsToggleRow(
        title: "Show Timestamps",
        subtitle: "Display relative time for posts",
        icon: "clock.fill",
        iconColor: .blue,
        isOn: $settingsService.showTimestamps
      )

      SettingsToggleRow(
        title: "Compact Mode",
        subtitle: "Reduce spacing for more content",
        icon: "rectangle.compress.vertical",
        iconColor: .green,
        isOn: $settingsService.compactMode
      )
    }
  }

  // MARK: - Content Section
  private var contentSection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(title: "Content", icon: "doc.text.fill", color: .green)

      SettingsToggleRow(
        title: "Auto-play Videos",
        subtitle: "Automatically play videos in feed",
        icon: "play.fill",
        iconColor: .green,
        isOn: $settingsService.autoPlayVideos
      )

      SettingsToggleRow(
        title: "Show Sensitive Content",
        subtitle: "Display content marked as sensitive",
        icon: "eye.fill",
        iconColor: .orange,
        isOn: $settingsService.showSensitiveContent
      )

      SettingsToggleRow(
        title: "Push Notifications",
        subtitle: "Receive notifications for new activity",
        icon: "bell.fill",
        iconColor: .blue,
        isOn: $settingsService.enablePushNotifications
      )
    }
  }

  // MARK: - Privacy Section
  private var privacySection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(title: "Privacy", icon: "lock.shield.fill", color: .red)

      SettingsToggleRow(
        title: "Allow Mentions",
        subtitle: "Let others mention you in posts",
        icon: "at",
        iconColor: .blue,
        isOn: $settingsService.allowMentions
      )

      SettingsToggleRow(
        title: "Allow Replies",
        subtitle: "Let others reply to your posts",
        icon: "arrowshape.turn.up.left.fill",
        iconColor: .green,
        isOn: $settingsService.allowReplies
      )

      SettingsToggleRow(
        title: "Allow Quotes",
        subtitle: "Let others quote your posts",
        icon: "quote.bubble.fill",
        iconColor: .purple,
        isOn: $settingsService.allowQuotes
      )

      SettingsNavigationRow(
        title: "Privacy Policy",
        subtitle: "Read our privacy policy",
        icon: "doc.text.fill",
        iconColor: .blue
      ) {
        showingPrivacyPolicy = true
      }

      SettingsNavigationRow(
        title: "Terms of Service",
        subtitle: "Read our terms of service",
        icon: "doc.plaintext.fill",
        iconColor: .orange
      ) {
        showingTermsOfService = true
      }
    }
  }

  // MARK: - Video Section
  private var videoSection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(title: "Video Playback", icon: "video.fill", color: .blue)

      SettingsToggleRow(
        title: "Autoplay Videos",
        subtitle: "Automatically play videos in feed",
        icon: "play.fill",
        iconColor: .blue,
        isOn: Binding(
          get: { VideoFeedManager.shared.isAutoplayEnabled },
          set: { VideoFeedManager.shared.updateAutoplayEnabled($0) }
        )
      )

      SettingsToggleRow(
        title: "Muted by Default",
        subtitle: "Start videos without sound",
        icon: "speaker.slash.fill",
        iconColor: .blue,
        isOn: Binding(
          get: { VideoFeedManager.shared.isMutedByDefault },
          set: { VideoFeedManager.shared.updateMutedByDefault($0) }
        )
      )

      SettingsPickerRow(
        title: "Max Concurrent Videos",
        subtitle: "Limit videos playing simultaneously",
        icon: "number.circle.fill",
        iconColor: .blue,
        selection: Binding(
          get: { VideoFeedManager.shared.maxConcurrentVideos },
          set: { VideoFeedManager.shared.updateMaxConcurrentVideos($0) }
        ),
        options: [1, 2, 3, 4],
        optionTitle: { "\($0) video\($0 == 1 ? "" : "s")" }
      )
    }
  }

  // MARK: - Feed Section
  private var feedSection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(title: "Feed", icon: "list.bullet.fill", color: .orange)

      SettingsToggleRow(
        title: "Show Reposts",
        subtitle: "Display reposted content",
        icon: "arrow.2.squarepath",
        iconColor: .blue,
        isOn: $settingsService.showReposts
      )

      SettingsToggleRow(
        title: "Show Replies",
        subtitle: "Display reply content",
        icon: "bubble.left.and.bubble.right.fill",
        iconColor: .green,
        isOn: $settingsService.showReplies
      )
    }
  }

  // MARK: - Media Section
  private var mediaSection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(title: "Media", icon: "photo.fill", color: .pink)

      SettingsPickerRow(
        title: "Image Quality",
        subtitle: "Balance between quality and performance",
        icon: "photo.fill",
        iconColor: .pink,
        selection: $settingsService.imageQuality,
        options: ImageQuality.allCases,
        optionTitle: { $0.displayName }
      )

      SettingsToggleRow(
        title: "Preload Images",
        subtitle: "Load images before they're visible",
        icon: "arrow.down.circle.fill",
        iconColor: .blue,
        isOn: $settingsService.preloadImages
      )
    }
  }

  // MARK: - Support Section
  private var supportSection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(title: "Support", icon: "questionmark.circle.fill", color: .teal)

      SettingsNavigationRow(
        title: "Help & FAQ",
        subtitle: "Find answers to common questions",
        icon: "questionmark.circle.fill",
        iconColor: .teal
      ) {
        showingHelpFAQ = true
      }

      SettingsNavigationRow(
        title: "Report a Bug",
        subtitle: "Help us improve by reporting issues",
        icon: "exclamationmark.triangle.fill",
        iconColor: .orange
      ) {
        showingBugReport = true
      }

      SettingsNavigationRow(
        title: "Feature Request",
        subtitle: "Suggest new features",
        icon: "lightbulb.fill",
        iconColor: .yellow
      ) {
        showingFeatureRequest = true
      }

      SettingsNavigationRow(
        title: "Contact Support",
        subtitle: "Get help from our team",
        icon: "envelope.fill",
        iconColor: .blue
      ) {
        showingContactSupport = true
      }
    }
  }

  // MARK: - About Section
  private var aboutSection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(title: "About", icon: "info.circle.fill", color: .gray)

      SettingsNavigationRow(
        title: "About LiquidSky",
        subtitle: "Version 1.0.0 • Build 1",
        icon: "info.circle.fill",
        iconColor: .gray
      ) {
        showingAboutSheet = true
      }

      SettingsButtonRow(
        title: "Reset Settings",
        subtitle: "Restore all settings to defaults",
        icon: "arrow.clockwise",
        iconColor: .orange,
        buttonTitle: "Reset",
        buttonColor: .orange
      ) {
        showingResetAlert = true
      }
    }
  }

  // MARK: - Sign Out Button
  private var signOutButton: some View {
    Button {
      Task {
        do {
          try await auth.logout()
        } catch {
          // Handle error
        }
      }
    } label: {
      HStack {
        Image(systemName: "rectangle.portrait.and.arrow.right")
          .font(.title3)
        Text("Sign Out")
          .font(.body)
          .fontWeight(.medium)
      }
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.red)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - About View
private struct AboutView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // App Icon
          Image(systemName: "cloud.sun.fill")
            .font(.system(size: 80))
            .foregroundColor(.blue)
            .padding(.top, 40)

          // App Name
          Text("LiquidSky")
            .font(.largeTitle)
            .fontWeight(.bold)

          // Version
          Text("Version 1.0.0")
            .font(.title3)
            .foregroundColor(.secondary)

          // Description
          VStack(spacing: 16) {
            Text("A beautiful and modern Bluesky client for iOS and macOS")
              .font(.body)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)

            Text("Built with SwiftUI and designed for the modern web")
              .font(.caption)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
          }

          // Features
          VStack(spacing: 12) {
            FeatureRow(
              icon: "star.fill", title: "Modern Design", description: "Beautiful SwiftUI interface")
            FeatureRow(
              icon: "bolt.fill", title: "Fast Performance", description: "Optimized for speed")
            FeatureRow(
              icon: "lock.fill", title: "Privacy First", description: "Your data stays private")
            FeatureRow(
              icon: "gear", title: "Customizable", description: "Tailor the app to your needs")
          }
          .padding(.horizontal, 32)

          Spacer(minLength: 40)
        }
      }
      .navigationTitle("About")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

// MARK: - Feature Row
private struct FeatureRow: View {
  let icon: String
  let title: String
  let description: String

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.blue)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
          .fontWeight(.medium)

        Text(description)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
  }
}

#Preview {
  SettingsView()
    .environment(Auth())
}
