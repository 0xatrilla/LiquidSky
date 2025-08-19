import ATProtoKit
import Auth
import Client
import DesignSystem
import Models
import SwiftUI

public struct AuthView: View {
  @Environment(Auth.self) private var auth
  @Environment(\.colorScheme) private var colorScheme

  @State private var handle: String = ""
  @State private var appPassword: String = ""
  @State private var error: String? = nil
  @State private var isLoading = false
  @State private var animateGradient = false
  @State private var showPassword = false
  @State private var inputFocused = false
  @State private var hasAppeared = false

  public init() {}

  public var body: some View {
    ZStack {
      // Enhanced animated background with iOS 26 design
      backgroundGradient

      ScrollView {
        VStack(spacing: 40) {
          Spacer(minLength: 80)

          // Enhanced branding section with iOS 26 styling
          brandingSection

          // Modern login card with enhanced glass morphism
          loginCard

          Spacer(minLength: 60)
        }
        .padding(.horizontal, 28)
      }
    }
    .ignoresSafeArea(.container, edges: .top)
    .preferredColorScheme(.dark)  // Force dark mode for better glass effect
    .onAppear {
      print("AuthView: onAppear called - starting initialization")
      hasAppeared = true
      withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
        animateGradient = true
      }
    }
    .onDisappear {
      print("AuthView: onDisappear called")
      hasAppeared = false
    }
  }

  // MARK: - Enhanced Background Gradient

  @ViewBuilder
  private var backgroundGradient: some View {
    ZStack {
      // iOS 26 enhanced gradient background
      LinearGradient(
        colors: [
          Color.blueskyPrimary.opacity(0.9),
          Color.blueskySecondary.opacity(0.7),
          Color.blueskyAccent.opacity(0.5),
        ],
        startPoint: animateGradient ? .topLeading : .bottomTrailing,
        endPoint: animateGradient ? .bottomTrailing : .topLeading
      )
      .ignoresSafeArea()

      // Enhanced floating orbs with iOS 26 blur effects
      floatingOrbs

      // Subtle noise texture for depth
      noiseTexture
    }
  }

  @ViewBuilder
  private var floatingOrbs: some View {
    ZStack {
      // Large primary orb
      Circle()
        .fill(.white.opacity(0.08))
        .frame(width: 240, height: 240)
        .blur(radius: 50)
        .offset(x: -120, y: -240)
        .scaleEffect(animateGradient ? 1.3 : 0.7)

      // Medium secondary orb
      Circle()
        .fill(Color.blueskySecondary.opacity(0.12))
        .frame(width: 180, height: 180)
        .blur(radius: 40)
        .offset(x: 140, y: 120)
        .scaleEffect(animateGradient ? 0.7 : 1.3)

      // Small accent orb
      Circle()
        .fill(Color.blueskyAccent.opacity(0.15))
        .frame(width: 120, height: 120)
        .blur(radius: 30)
        .offset(x: -100, y: 180)
        .scaleEffect(animateGradient ? 1.2 : 0.8)

      // Micro orbs for detail
      ForEach(0..<6, id: \.self) { index in
        Circle()
          .fill(.white.opacity(0.06))
          .frame(width: 20 + CGFloat(index * 10), height: 20 + CGFloat(index * 10))
          .blur(radius: 15)
          .offset(
            x: CGFloat.random(in: -150...150),
            y: CGFloat.random(in: -300...300)
          )
          .scaleEffect(animateGradient ? 1.1 : 0.9)
      }
    }
    .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateGradient)
  }

  @ViewBuilder
  private var noiseTexture: some View {
    Rectangle()
      .fill(.white.opacity(0.02))
      .blendMode(.overlay)
      .ignoresSafeArea()
  }

  // MARK: - Enhanced Branding Section

  @ViewBuilder
  private var brandingSection: some View {
    VStack(spacing: 24) {
      // Enhanced app icon with iOS 26 glass effect
      ZStack {
        // Outer glow ring
        Circle()
          .fill(.white.opacity(0.1))
          .frame(width: 100, height: 100)
          .blur(radius: 20)

        // Main glass container
        Circle()
          .fill(.white.opacity(0.15))
          .frame(width: 88, height: 88)
          .background(.ultraThinMaterial)
          .clipShape(Circle())
          .overlay(
            Circle()
              .stroke(.white.opacity(0.25), lineWidth: 1.5)
          )
          .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

        // Icon with enhanced styling
        Image(systemName: "cloud.sun.fill")
          .font(.system(size: 40, weight: .medium, design: .rounded))
          .foregroundStyle(
            LinearGradient(
              colors: [.white, Color.blueskySecondary],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .symbolEffect(.bounce, options: .repeating)
      }

      // Enhanced app title with iOS 26 typography
      VStack(spacing: 12) {
        Text("LiquidSky")
          .font(.system(size: 42, weight: .heavy, design: .rounded))
          .foregroundStyle(
            LinearGradient(
              colors: [.white, .white.opacity(0.9)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 3)

        Text("Connect to the decentralized web")
          .font(.system(size: 18, weight: .medium, design: .default))
          .foregroundStyle(.white.opacity(0.85))
          .multilineTextAlignment(.center)
          .lineLimit(2)
      }
    }
  }

  // MARK: - Enhanced Login Card

  @ViewBuilder
  private var loginCard: some View {
    VStack(spacing: 32) {
      // Enhanced header with iOS 26 typography
      VStack(spacing: 12) {
        Text("Welcome Back")
          .font(.system(size: 32, weight: .bold, design: .rounded))
          .foregroundStyle(.white)

        Text("Sign in to your Bluesky account")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.white.opacity(0.8))
      }

      // Enhanced form fields with iOS 26 styling
      VStack(spacing: 24) {
        // Enhanced handle field
        enhancedInputField(
          icon: "at",
          placeholder: "john@bsky.social",
          text: $handle
        )

        // Enhanced password field
        enhancedPasswordField
      }

      // Enhanced login button
      enhancedLoginButton

      // Enhanced error message
      if let error {
        enhancedErrorMessage(error)
      }

      // Enhanced help text
      enhancedHelpText
    }
    .padding(36)
    .background(
      RoundedRectangle(cornerRadius: 28)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 28)
            .stroke(.white.opacity(0.15), lineWidth: 1.5)
        )
    )
    .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
    .scaleEffect(inputFocused ? 1.02 : 1.0)
    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: inputFocused)
  }

  @ViewBuilder
  private func enhancedInputField(
    icon: String,
    placeholder: String,
    text: Binding<String>
  ) -> some View {
    HStack(spacing: 18) {
      // Enhanced icon with iOS 26 styling
      Image(systemName: icon)
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(
          LinearGradient(
            colors: [Color.blueskySecondary, Color.blueskyPrimary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 28)

      // Enhanced input field
      TextField(placeholder, text: text)
        .font(.system(size: 18, weight: .medium))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .foregroundStyle(.white)
        .onTapGesture {
          withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            inputFocused = true
          }
        }

      Spacer()
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 20)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(.white.opacity(0.12), lineWidth: 1.5)
        )
    )
    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    .scaleEffect(inputFocused ? 1.02 : 1.0)
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: inputFocused)
  }

  @ViewBuilder
  private var enhancedPasswordField: some View {
    HStack(spacing: 18) {
      // Enhanced lock icon
      Image(systemName: "lock.fill")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(
          LinearGradient(
            colors: [Color.blueskySecondary, Color.blueskyPrimary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 28)

      // Enhanced password field
      Group {
        if showPassword {
          TextField("App Password", text: $appPassword)
            .font(.system(size: 18, weight: .medium))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(.white)
        } else {
          SecureField("App Password", text: $appPassword)
            .font(.system(size: 18, weight: .medium))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(.white)
        }
      }
      .onTapGesture {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
          inputFocused = true
        }
      }

      // Enhanced show/hide password toggle
      Button {
        withAnimation(.easeInOut(duration: 0.3)) {
          showPassword.toggle()
        }
        // Enhanced haptic feedback
        HapticManager.shared.impact(.light)
      } label: {
        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(.white.opacity(0.7))
          .frame(width: 28, height: 28)
          .background(
            Circle()
              .fill(.white.opacity(0.1))
          )
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 20)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(.ultraThinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(.white.opacity(0.12), lineWidth: 1.5)
        )
    )
    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    .scaleEffect(inputFocused ? 1.02 : 1.0)
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: inputFocused)
  }

  @ViewBuilder
  private var enhancedLoginButton: some View {
    Button {
      Task {
        await performLogin()
      }
    } label: {
      HStack(spacing: 16) {
        if isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(0.9)
        } else {
          Image(systemName: "arrow.right.circle.fill")
            .font(.system(size: 24, weight: .semibold))
        }

        Text(isLoading ? "Signing In..." : "Sign In to Bluesky")
          .font(.system(size: 20, weight: .semibold))
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 22)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(
            LinearGradient(
              colors: [Color.blueskyPrimary, Color.blueskySecondary],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(.white.opacity(0.25), lineWidth: 1.5)
          )
      )
      .shadow(color: Color.blueskyPrimary.opacity(0.4), radius: 15, x: 0, y: 8)
    }
    .disabled(handle.isEmpty || appPassword.isEmpty || isLoading)
    .opacity(handle.isEmpty || appPassword.isEmpty ? 0.6 : 1.0)
    .scaleEffect(handle.isEmpty || appPassword.isEmpty ? 0.98 : 1.0)
    .animation(.easeInOut(duration: 0.3), value: handle.isEmpty || appPassword.isEmpty)
    .onTapGesture {
      // Enhanced haptic feedback on button tap
      if hasAppeared {
        HapticManager.shared.impact(.medium)
      }
    }
  }

  @ViewBuilder
  private func enhancedErrorMessage(_ message: String) -> some View {
    HStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.red)
        .font(.system(size: 18, weight: .semibold))

      Text(message)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.red)
        .multilineTextAlignment(.leading)

      Spacer()
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.red.opacity(0.15))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(.red.opacity(0.3), lineWidth: 1.5)
        )
    )
    .shadow(color: .red.opacity(0.2), radius: 10, x: 0, y: 5)
    .transition(
      .asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .scale.combined(with: .opacity)
      ))
  }

  @ViewBuilder
  private var enhancedHelpText: some View {
    VStack(spacing: 16) {
      Text("Need help?")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.white.opacity(0.8))

      HStack(spacing: 24) {
        Button("Create Account") {
          // TODO: Navigate to account creation
          if hasAppeared {
            HapticManager.shared.impact(.light)
          }
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(
          LinearGradient(
            colors: [Color.lavenderSecondary, Color.lavenderPrimary],
            startPoint: .leading,
            endPoint: .trailing
          )
        )

        Button("Forgot Password?") {
          // TODO: Navigate to password reset
          if hasAppeared {
            HapticManager.shared.impact(.light)
          }
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(
          LinearGradient(
            colors: [Color.sunsetSecondary, Color.sunsetPrimary],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
      }
    }
  }

  // MARK: - Login Logic

  private func performLogin() async {
    isLoading = true
    error = nil

    do {
      try await auth.authenticate(handle: handle, appPassword: appPassword)
    } catch {
      withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
        self.error = error.localizedDescription
      }
    }

    isLoading = false
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
  ScrollView {
    Text("Hello World")
  }
  .sheet(isPresented: .constant(true)) {
    AuthView()
  }
}
