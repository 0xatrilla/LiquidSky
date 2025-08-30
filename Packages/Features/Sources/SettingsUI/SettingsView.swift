import Auth
import DesignSystem
import Models
import StoreKit
import SwiftUI
import UIKit
import User

public struct SettingsView: View {
  @Environment(Auth.self) var auth
  @Environment(CurrentUser.self) var currentUser
  @Environment(AccountManager.self) var accountManager

  @State private var settingsService = SettingsService.shared
  @State private var colorThemeManager = ColorThemeManager.shared
  @State private var showingResetAlert = false
  @State private var showingAboutSheet = false
  @State private var showingChangePassword = false
  @State private var showingAppIconPicker = false
  @State private var showingAcknowledgementsSheet = false
  @State private var showingAccountSwitcher = false
  @State private var showingTippingView = false
  @State private var showingBlockedUsers = false

  public init() {}

  private func updateTheme() {
    let themeManager = ThemeManager.shared
    themeManager.useSystemTheme = settingsService.useSystemTheme
    themeManager.currentTheme = settingsService.selectedTheme
  }

  private func updateColorTheme() {
    colorThemeManager.currentTheme = settingsService.selectedColorTheme
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Current Account Header
        CurrentAccountHeader()
          .padding(.horizontal, 16)
          .onTapGesture {
            showingAccountSwitcher = true
          }

        // Account Section
        accountSection

        // Display Section
        displaySection

        // Content Section
        contentSection

        // Privacy Section
        privacySection

        // Intelligence Section
        intelligenceSection

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
    .background(Color(.systemGroupedBackground))
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.large)
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
    .sheet(isPresented: $showingChangePassword) {
      ChangePasswordView()
    }
    .sheet(isPresented: $showingAppIconPicker) {
      AppIconPickerView(selectedIcon: $settingsService.selectedAppIcon)
    }
    .sheet(isPresented: $showingAcknowledgementsSheet) {
      AcknowledgementsView()
    }
    .sheet(isPresented: $showingAccountSwitcher) {
      AccountSwitcherView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showingTippingView) {
      SimpleTippingView()
    }
    .sheet(isPresented: $showingBlockedUsers) {
      BlockedUsersView()
    }

  }

  // MARK: - Privacy Section
  private var privacySection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(title: "Privacy", icon: "lock.shield.fill", color: .red)

      SettingsNavigationRow(
        title: "Blocked & Muted Users",
        subtitle: "Manage users you've blocked or muted",
        icon: "person.slash",
        iconColor: .red
      ) {
        showingBlockedUsers = true
      }
    }
  }

  // MARK: - Intelligence Section
  private var intelligenceSection: some View {
    VStack(spacing: 16) {
      SettingsSectionHeader(
        title: "Intelligence", icon: "sparkles", color: .purple, useMulticolor: true)

      SettingsToggleRow(
        title: "AI Summaries (Experimental)",
        subtitle: "Generate concise summaries of feeds using Apple Intelligence when available",
        icon: "sparkles",
        iconColor: .purple,
        useMulticolor: true,
        isOn: $settingsService.aiSummariesEnabled
      )

      SettingsToggleRow(
        title: "Enable on Device (Experimental)",
        subtitle:
          "Allows Apple Intelligence to run on your device if supported (iOS 26+). May be unstable on some configurations.",
        icon: "iphone",
        iconColor: .purple,
        isOn: $settingsService.aiDeviceExperimentalEnabled
      )

      Text(
        "Requires iOS 26.0 and an Apple Intelligence–supported device. This is for testing and may crash on some setups. Turn off if you see instability."
      )
      .font(.caption)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.leading)
      .padding(.horizontal, 16)
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
      SettingsSectionHeader(title: "Display", icon: "paintbrush.fill", color: .themePrimary)

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

      SettingsNavigationRow(
        title: "App Icon",
        subtitle: "Choose your preferred app icon",
        icon: "app.badge",
        iconColor: .orange
      ) {
        showingAppIconPicker = true
      }

      SettingsPickerRow(
        title: "Color Theme",
        subtitle: "Choose your preferred color scheme",
        icon: "paintbrush.fill",
        iconColor: .themePrimary,
        selection: $settingsService.selectedColorTheme,
        options: ColorTheme.allCases,
        optionTitle: { $0.displayName }
      )
      .onChange(of: settingsService.selectedColorTheme) { _, _ in
        updateColorTheme()
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
      SettingsSectionHeader(title: "Support", icon: "heart.fill", color: .red)

      SettingsNavigationRow(
        title: "Send a Tip",
        subtitle: "Support continued development",
        icon: "heart.fill",
        iconColor: .red
      ) {
        showingTippingView = true
      }

      Text(
        "Tips help cover development costs and motivate continued improvements to Horizon."
      )
      .font(.caption2)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 16)
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

      SettingsNavigationRow(
        title: "Acknowledgements",
        subtitle: "Open source libraries and licenses",
        icon: "doc.text.fill",
        iconColor: .green
      ) {
        showingAcknowledgementsSheet = true
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
          Image("cloud")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 80)
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

          // Social Links
          VStack(spacing: 20) {
            Text("Connect with us")
              .font(.headline)
              .foregroundColor(.secondary)

            HStack(spacing: 40) {
              // GitHub Logo
              Button {
                if let url = URL(string: "https://github.com/0xatrilla/LiquidSky") {
                  UIApplication.shared.open(url)
                }
              } label: {
                VStack(spacing: 8) {
                  // Use actual GitHub logo from assets
                  Image("GitHubLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)

                  Text("GitHub")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              }
              .buttonStyle(PlainButtonStyle())

              // Bluesky Logo
              Button {
                if let url = URL(string: "https://bsky.app/profile/acxtrilla.xyz") {
                  UIApplication.shared.open(url)
                }
              } label: {
                VStack(spacing: 8) {
                  // Use actual Bluesky logo from assets
                  Image("BlueskyLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)

                  Text("Bluesky")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              }
              .buttonStyle(PlainButtonStyle())
            }
          }
          .padding(.horizontal, 32)

          Spacer(minLength: 40)
        }
        .padding()
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

// MARK: - Acknowledgements View
private struct AcknowledgementsView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 8) {
            Image(systemName: "doc.text.fill")
              .font(.system(size: 80))
              .foregroundColor(.green)
              .padding(.top, 40)

            Text("Acknowledgements")
              .font(.largeTitle)
              .fontWeight(.bold)

            Text("Open source libraries and licenses")
              .font(.title3)
              .foregroundColor(.secondary)
          }

          // Description
          VStack(spacing: 16) {
            Text(
              "This app uses several open source libraries to provide a better experience. We're grateful to the developers who maintain these projects."
            )
            .font(.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
          }

          // Dependencies List
          VStack(spacing: 16) {
            Text("Dependencies")
              .font(.headline)
              .foregroundColor(.secondary)

            VStack(spacing: 12) {
              DependencyRow(
                name: "ATProtoKit",
                description: "Bluesky AT Protocol client library",
                url: "https://github.com/MasterJ93/ATProtoKit"
              )

              DependencyRow(
                name: "AppRouter",
                description: "SwiftUI navigation and routing",
                url: "https://github.com/Dimillian/AppRouter"
              )

              DependencyRow(
                name: "Nuke",
                description: "Image loading and caching framework",
                url: "https://github.com/kean/Nuke"
              )

              DependencyRow(
                name: "KeychainSwift",
                description: "Keychain wrapper for Swift",
                url: "https://github.com/evgenyneu/keychain-swift"
              )

              DependencyRow(
                name: "ViewInspector",
                description: "SwiftUI testing framework",
                url: "https://github.com/nalexn/ViewInspector"
              )
            }
            .padding(.horizontal, 32)
          }

          Spacer(minLength: 40)
        }
      }
      .navigationTitle("Acknowledgements")
      .navigationBarTitleDisplayMode(.large)
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

// MARK: - Dependency Row
private struct DependencyRow: View {
  let name: String
  let description: String
  let url: String

  var body: some View {
    Button {
      if let url = URL(string: url) {
        UIApplication.shared.open(url)
      }
    } label: {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(name)
            .font(.headline)
            .foregroundColor(.primary)

          Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        Image(systemName: "arrow.up.right.square")
          .font(.system(size: 16))
          .foregroundColor(.blue)
      }
      .padding()
      .background(Color(.systemGray6))
      .cornerRadius(12)
    }
    .buttonStyle(PlainButtonStyle())
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

// MARK: - Simple Tipping View
private struct SimpleTippingView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var purchaseService = InAppPurchaseService.shared
  @State private var selectedTipAmount: InAppPurchaseService.TipAmount?
  @State private var isPurchasing = false
  @State private var showThankYou = false
  @State private var showError = false
  @State private var errorMessage = ""

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 16) {
            Image(systemName: "heart.fill")
              .font(.system(size: 60))
              .foregroundColor(.red)

            Text("Support Horizon")
              .font(.largeTitle)
              .fontWeight(.bold)

            Text(
              "If you enjoy using Horizon, consider sending a tip to support continued development and improvements."
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
          }
          .padding(.top)

          // Tip Options
          if purchaseService.isLoading {
            VStack(spacing: 16) {
              ProgressView("Loading products...")
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
          } else if purchaseService.products.isEmpty {
            VStack(spacing: 16) {
              Text("No products available")
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
          } else {
            LazyVGrid(
              columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
              ], spacing: 16
            ) {
              ForEach(purchaseService.products, id: \.id) { product in
                TipOptionCard(
                  amount: Double(truncating: product.price as NSDecimalNumber),
                  isSelected: selectedTipAmount?.rawValue == product.id,
                  onTap: {
                    selectedTipAmount = InAppPurchaseService.TipAmount(rawValue: product.id)
                  }
                )
              }
            }
            .padding(.horizontal)
          }

          // Purchase Button
          if let selectedTip = selectedTipAmount,
            let product = purchaseService.products.first(where: { $0.id == selectedTip.rawValue })
          {
            VStack(spacing: 16) {
              Button(action: {
                Task {
                  await performPurchase(product: product)
                }
              }) {
                HStack {
                  if isPurchasing {
                    ProgressView()
                      .scaleEffect(0.8)
                      .tint(.white)
                  } else {
                    Image(systemName: "heart.fill")
                      .font(.headline)
                  }

                  Text("Send \(product.displayName)")
                    .font(.headline)
                    .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                  LinearGradient(
                    colors: [.red, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
              }
              .disabled(isPurchasing || purchaseService.purchaseInProgress)

              Text("You'll be charged \(product.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
          }

          Spacer(minLength: 40)
        }
      }
      .navigationTitle("Support Horizon")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .sheet(isPresented: $showThankYou) {
      ThankYouView()
    }
    .alert("Purchase Error", isPresented: $showError) {
      Button("OK") {}
    } message: {
      Text(errorMessage)
    }
    .task {
      // Load products when view appears
      await purchaseService.loadProducts()
    }
  }

  private func performPurchase(product: Product) async {
    isPurchasing = true

    let success = await purchaseService.purchase(product)

    if success {
      showThankYou = true
    } else {
      errorMessage = purchaseService.errorMessage ?? "Purchase failed. Please try again."
      showError = true
    }

    isPurchasing = false
  }
}

// MARK: - Tip Option Card
private struct TipOptionCard: View {
  let amount: Double
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 12) {
        Text(getEmoji(for: amount))
          .font(.system(size: 32))

        Text(getTitle(for: amount))
          .font(.headline)
          .fontWeight(.semibold)

        Text("$\(String(format: "%.2f", amount))")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.blue)

        Text(getDescription(for: amount))
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
          .overlay(
            RoundedRectangle(cornerRadius: 16)
              .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
  }

  private func getEmoji(for amount: Double) -> String {
    switch amount {
    case 0.99: return "☕️"
    case 2.99: return "🍕"
    case 4.99: return "🎉"
    case 9.99: return "💝"
    default: return "💙"
    }
  }

  private func getTitle(for amount: Double) -> String {
    switch amount {
    case 0.99: return "Small Tip"
    case 2.99: return "Medium Tip"
    case 4.99: return "Large Tip"
    case 9.99: return "Custom Amount"
    default: return "Tip"
    }
  }

  private func getDescription(for amount: Double) -> String {
    switch amount {
    case 0.99: return "Show your appreciation"
    case 2.99: return "A generous tip"
    case 4.99: return "A substantial tip"
    case 9.99: return "Choose your own amount"
    default: return "Support development"
    }
  }
}

// MARK: - Thank You View
private struct ThankYouView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "heart.fill")
        .font(.system(size: 80))
        .foregroundColor(.red)

      Text("Thank You! 💙")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("Your tip has been received and will help support continued development of Horizon.")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      Button("You're Welcome!") {
        dismiss()
      }
      .buttonStyle(.borderedProminent)
      .tint(.red)
    }
    .padding()
  }
}

#Preview {
  let accountManager = AccountManager()
  let auth = Auth(accountManager: accountManager)
  SettingsView()
    .environment(accountManager)
    .environment(auth)
}
