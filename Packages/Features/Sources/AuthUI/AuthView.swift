import ATProtoKit
import Auth
import Client
import DesignSystem
import Models
import SafariServices
import SwiftUI

public struct AuthView: View {
  @Environment(Auth.self) private var auth
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dismiss) private var dismiss

  @State private var handle: String = ""
  @State private var appPassword: String = ""
  @State private var error: String? = nil
  @State private var isLoading = false
  @State private var showPassword = false
  @State private var keyboardHeight: CGFloat = 0
  @State private var isKeyboardVisible = false
  @FocusState private var isHandleFocused: Bool
  @FocusState private var isPasswordFocused: Bool

  public init() {}

  public var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: isKeyboardVisible ? 8 : 0) {
          // Header section
          headerSection
            .padding(.top, isKeyboardVisible ? 10 : 40)
            .padding(.bottom, isKeyboardVisible ? 15 : 32)

          // Form section
          formSection
            .padding(.vertical, isKeyboardVisible ? 8 : 24)

          // Action section
          actionSection
            .padding(.vertical, isKeyboardVisible ? 8 : 24)

          // Help section
          helpSection
            .padding(.top, isKeyboardVisible ? 8 : 32)
            .padding(.bottom, isKeyboardVisible ? 8 : 16)
        }
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.3), value: isKeyboardVisible)
      }
      .background(
        ZStack {
          // Base background (bottom layer)
          Color(.systemGroupedBackground)
            .ignoresSafeArea()

          // Static gradient background (on top of base)
          LinearGradient(
            colors: [
              Color.blueskyPrimary.opacity(0.1),
              Color.blueskyPrimary.opacity(0.05),
              Color.clear,
              Color.blueskyPrimary.opacity(0.05),
              Color.blueskyPrimary.opacity(0.1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .ignoresSafeArea()

          // Floating Bluesky logos background
          FloatingBlueskyLogosView()
            .allowsHitTesting(false)
        }
      )
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden()
      .sheet(isPresented: $showingSafari) {
        if let url = safariURL {
          SafariView(url: url)
        }
      }
      .onReceive(
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
      ) { notification in
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
          as? CGRect
        {
          keyboardHeight = keyboardFrame.height
          withAnimation(.easeInOut(duration: 0.3)) {
            isKeyboardVisible = true
          }
        }
      }
      .onReceive(
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
      ) { _ in
        keyboardHeight = 0
        withAnimation(.easeInOut(duration: 0.3)) {
          isKeyboardVisible = false
        }
      }

    }
    .navigationViewStyle(.stack)
  }

  // MARK: - Header Section

  @ViewBuilder
  private var headerSection: some View {
    VStack(spacing: isKeyboardVisible ? 12 : 32) {
      if !isKeyboardVisible {
        Spacer(minLength: 40)
      }

      // App icon
      Image("cloud")
        .resizable()
        .scaledToFit()
        .frame(width: isKeyboardVisible ? 60 : 90, height: isKeyboardVisible ? 60 : 90)
        .foregroundStyle(.white)
        .shadow(
          color: Color.blueskyPrimary.opacity(0.8), radius: isKeyboardVisible ? 10 : 15, x: 0, y: 0
        )
        .shadow(
          color: Color.blueskyPrimary.opacity(0.6), radius: isKeyboardVisible ? 15 : 25, x: 0, y: 0
        )
        .shadow(
          color: Color.blueskyPrimary.opacity(0.4), radius: isKeyboardVisible ? 20 : 35, x: 0, y: 0)

      // Title and subtitle
      VStack(spacing: isKeyboardVisible ? 4 : 8) {
        HStack(spacing: 0) {
          Text("Welcome to ")
            .font(.custom("AlbraBookTRIAL-Light", size: isKeyboardVisible ? 22 : 34))
          Text("Horizon")
            .font(.custom("AlbraBookTRIAL-Light", size: isKeyboardVisible ? 22 : 34))
            .italic()
        }
        .multilineTextAlignment(.center)

        if !isKeyboardVisible {
          Text("Sign in to your Bluesky account to get started")
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
        }
      }

      if !isKeyboardVisible {
        Spacer(minLength: 20)
      }
    }
  }

  // MARK: - Form Section

  @ViewBuilder
  private var formSection: some View {
    VStack(spacing: isKeyboardVisible ? 16 : 24) {
      // Handle field
      VStack(alignment: .leading, spacing: 8) {
        Text("Handle or Email")
          .font(.headline)
          .foregroundStyle(.primary)

        HStack(spacing: 12) {
          Image(systemName: "at")
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(width: 20)

          TextField("john@bsky.social", text: $handle)
            .textFieldStyle(.plain)
            .font(.body)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.emailAddress)
            .focused($isHandleFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(
                  isHandleFocused ? Color.blueskyPrimary : Color(.separator),
                  lineWidth: isHandleFocused ? 2 : 1)
            )
        )
      }

      // App Password field
      VStack(alignment: .leading, spacing: 8) {
        Text("App Password")
          .font(.headline)
          .foregroundStyle(.primary)

        HStack(spacing: 12) {
          Image(systemName: "lock")
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(width: 20)

          Group {
            if showPassword {
              TextField("Enter your app password", text: $appPassword)
                .textFieldStyle(.plain)
            } else {
              SecureField("Enter your app password", text: $appPassword)
            }
          }
          .font(.body)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .focused($isPasswordFocused)

          Button {
            withAnimation(.easeInOut(duration: 0.2)) {
              showPassword.toggle()
            }
            // Safe haptic feedback
            safeHapticFeedback(.light)
          } label: {
            Image(systemName: showPassword ? "eye.slash" : "eye")
              .font(.body)
              .foregroundStyle(.secondary)
              .frame(width: 24, height: 24)
          }
          .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(
                  isPasswordFocused ? Color.blueskyPrimary : Color(.separator),
                  lineWidth: isPasswordFocused ? 2 : 1)
            )
        )
      }

      // Error message
      if let error {
        HStack(spacing: 8) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
            .font(.caption)

          Text(error)
            .font(.caption)
            .foregroundStyle(.red)
            .multilineTextAlignment(.leading)

          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(.red.opacity(0.1))
        )
        .transition(
          .asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
          ))
      }
    }
  }

  // MARK: - Action Section

  @ViewBuilder
  private var actionSection: some View {
    VStack(spacing: isKeyboardVisible ? 12 : 16) {
      // Sign in button
      Button {
        Task {
          await performLogin()
        }
      } label: {
        HStack(spacing: 12) {
          if isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
              .scaleEffect(0.8)
          } else {
            Image(systemName: "arrow.right")
              .font(.body)
              .fontWeight(.semibold)
          }

          Text(isLoading ? "Signing In..." : "Sign In")
            .font(.headline)
            .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(canSignIn ? Color.blueskyPrimary : Color.secondary)
        )
      }
      .disabled(!canSignIn || isLoading)
      .buttonStyle(.plain)

      // Help text
      Text("You'll need to create an app password in your Bluesky account settings")
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(3)
    }
  }

  // MARK: - Help Section

  @ViewBuilder
  private var helpSection: some View {
    VStack(spacing: 24) {
      Divider()

      VStack(spacing: 16) {
        Text("Need help?")
          .font(.headline)
          .foregroundStyle(.primary)

        HStack(spacing: 24) {
          Button("Create Account") {
            safeHapticFeedback(.light)
            openBlueskyWebsite(url: "https://bsky.app/join")
          }
          .font(.body)
          .foregroundStyle(Color.blueskyPrimary)
          .buttonStyle(.plain)

          Button("Forgot Password?") {
            safeHapticFeedback(.light)
            openBlueskyWebsite(url: "https://bsky.app/forgot-password")
          }
          .font(.body)
          .foregroundStyle(Color.blueskyPrimary)
          .buttonStyle(.plain)
        }
      }

      Spacer(minLength: 40)
    }
  }

  // MARK: - Computed Properties

  private var canSignIn: Bool {
    !handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !appPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  // MARK: - Helper Methods

  private func safeHapticFeedback(_ style: ImpactStyle) {
    // Safe haptic feedback with error handling
    do {
      HapticManager.shared.impact(style)
    } catch {
      // Silently fail if haptic feedback fails
      print("Haptic feedback failed: \(error)")
    }
  }

  @State private var showingSafari = false
  @State private var safariURL: URL?

  private func openBlueskyWebsite(url: String) {
    guard let url = URL(string: url) else { return }
    safariURL = url
    showingSafari = true
  }

  // MARK: - Login Logic

  private func performLogin() async {
    isLoading = true
    error = nil

    let trimmedHandle = handle.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedPassword = appPassword.trimmingCharacters(in: .whitespacesAndNewlines)

    do {
      // Use addAccount to persist the account and its keychain identifier
      _ = try await auth.addAccount(handle: trimmedHandle, appPassword: trimmedPassword)
    } catch {
      withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
        self.error = error.localizedDescription
      }
    }

    isLoading = false
  }
}

// MARK: - Safari View Wrapper

struct SafariView: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context: Context) -> SFSafariViewController {
    let safariVC = SFSafariViewController(url: url)
    safariVC.preferredControlTintColor = UIColor(Color.blueskyPrimary)
    return safariVC
  }

  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    // No updates needed
  }
}

// MARK: - Floating Bluesky Logos View

struct FloatingBlueskyLogosView: View {
  @State private var logo1 = LogoState()
  @State private var logo2 = LogoState()
  @State private var logo3 = LogoState()
  @State private var logo4 = LogoState()
  @State private var logo5 = LogoState()
  @State private var logo6 = LogoState()
  @State private var logo7 = LogoState()
  @State private var logo8 = LogoState()

  var body: some View {
    ZStack {
      // Logo 1
      Image("BlueskyLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 60, height: 60)
        .opacity(0.08)
        .rotationEffect(.degrees(logo1.rotation))
        .offset(x: logo1.x, y: logo1.y)
        .animation(
          .easeInOut(duration: logo1.duration)
            .repeatForever(autoreverses: true),
          value: logo1.x
        )
        .onAppear {
          logo1.startAnimation()
        }

      // Logo 2
      Image("BlueskyLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 50, height: 50)
        .opacity(0.06)
        .rotationEffect(.degrees(logo2.rotation))
        .offset(x: logo2.x, y: logo2.y)
        .animation(
          .easeInOut(duration: logo2.duration)
            .repeatForever(autoreverses: true),
          value: logo2.x
        )
        .onAppear {
          logo2.startAnimation()
        }

      // Logo 3
      Image("BlueskyLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 45, height: 45)
        .opacity(0.05)
        .rotationEffect(.degrees(logo3.rotation))
        .offset(x: logo3.x, y: logo3.y)
        .animation(
          .easeInOut(duration: logo3.duration)
            .repeatForever(autoreverses: true),
          value: logo3.x
        )
        .onAppear {
          logo3.startAnimation()
        }

      // Logo 4
      Image("BlueskyLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 55, height: 55)
        .opacity(0.07)
        .rotationEffect(.degrees(logo4.rotation))
        .offset(x: logo4.x, y: logo4.y)
        .animation(
          .easeInOut(duration: logo4.duration)
            .repeatForever(autoreverses: true),
          value: logo4.x
        )
        .onAppear {
          logo4.startAnimation()
        }

      // Logo 5
      Image("BlueskyLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 40, height: 40)
        .opacity(0.04)
        .rotationEffect(.degrees(logo5.rotation))
        .offset(x: logo5.x, y: logo5.y)
        .animation(
          .easeInOut(duration: logo5.duration)
            .repeatForever(autoreverses: true),
          value: logo5.x
        )
        .onAppear {
          logo5.startAnimation()
        }

      // Logo 6
      Image("BlueskyLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 48, height: 48)
        .opacity(0.06)
        .rotationEffect(.degrees(logo6.rotation))
        .offset(x: logo6.x, y: logo6.y)
        .animation(
          .easeInOut(duration: logo6.duration)
            .repeatForever(autoreverses: true),
          value: logo6.x
        )
        .onAppear {
          logo6.startAnimation()
        }

      // Logo 7
      Image("BlueskyLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 42, height: 42)
        .opacity(0.05)
        .rotationEffect(.degrees(logo7.rotation))
        .offset(x: logo7.x, y: logo7.y)
        .animation(
          .easeInOut(duration: logo7.duration)
            .repeatForever(autoreverses: true),
          value: logo7.x
        )
        .onAppear {
          logo7.startAnimation()
        }

      // Logo 8
      Image("BlueskyLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 52, height: 52)
        .opacity(0.07)
        .rotationEffect(.degrees(logo8.rotation))
        .offset(x: logo8.x, y: logo8.y)
        .animation(
          .easeInOut(duration: logo8.duration)
            .repeatForever(autoreverses: true),
          value: logo8.x
        )
        .onAppear {
          logo8.startAnimation()
        }
    }
  }
}

// MARK: - Logo State

struct LogoState {
  var x: CGFloat = 0
  var y: CGFloat = 0
  var rotation: Double = 0
  var duration: Double = 0

  mutating func startAnimation() {
    // Random starting positions - cover the entire screen
    x = CGFloat.random(in: -200...200)
    y = CGFloat.random(in: -400...400)

    // Random animation parameters - move across the entire screen
    let targetX = CGFloat.random(in: -200...200)
    let targetY = CGFloat.random(in: -400...400)
    duration = Double.random(in: 12...20)

    // Animate to target position with gentle rotation
    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
      x = targetX
      y = targetY
      rotation = Double.random(in: -45...45)
    }
  }
}

// MARK: - Preview

#Preview("Light Mode") {
  AuthView()
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
  AuthView()
    .preferredColorScheme(.dark)
}

#Preview("Sheet Presentation") {
  NavigationView {
    Text("Hello World")
  }
  .sheet(isPresented: .constant(true)) {
    AuthView()
  }
}
