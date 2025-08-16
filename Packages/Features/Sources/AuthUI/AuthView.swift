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

  public init() {}

  public var body: some View {
    ZStack {
      // Beautiful animated background gradient
      backgroundGradient

      ScrollView {
        VStack(spacing: 32) {
          Spacer(minLength: 60)

          // App branding section
          brandingSection

          // Login card with modern glass morphism
          loginCard

          Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
      }
    }
    .ignoresSafeArea(.container, edges: .top)
    .preferredColorScheme(.dark)  // Force dark mode for better glass effect
  }

  // MARK: - Background Gradient

  @ViewBuilder
  private var backgroundGradient: some View {
    ZStack {
      // Primary gradient background
      LinearGradient(
        colors: [
          .blue.opacity(0.8),
          .blue.opacity(0.6),
          .cyan.opacity(0.4),
        ],
        startPoint: animateGradient ? .topLeading : .bottomTrailing,
        endPoint: animateGradient ? .bottomTrailing : .topLeading
      )
      .ignoresSafeArea()

      // Floating orbs for depth
      floatingOrbs
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
        animateGradient.toggle()
      }
    }
  }

  @ViewBuilder
  private var floatingOrbs: some View {
    ZStack {
      // Large orb
      Circle()
        .fill(.white.opacity(0.1))
        .frame(width: 200, height: 200)
        .blur(radius: 40)
        .offset(x: -100, y: -200)
        .scaleEffect(animateGradient ? 1.2 : 0.8)

      // Medium orb
      Circle()
        .fill(.blue.opacity(0.15))
        .frame(width: 150, height: 150)
        .blur(radius: 30)
        .offset(x: 120, y: 100)
        .scaleEffect(animateGradient ? 0.8 : 1.2)

      // Small orb
      Circle()
        .fill(.blue.opacity(0.2))
        .frame(width: 100, height: 100)
        .blur(radius: 20)
        .offset(x: -80, y: 150)
        .scaleEffect(animateGradient ? 1.1 : 0.9)
    }
    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateGradient)
  }

  // MARK: - Branding Section

  @ViewBuilder
  private var brandingSection: some View {
    VStack(spacing: 16) {
      // App icon/logo with enhanced glass effect
      ZStack {
        Circle()
          .fill(.white.opacity(0.2))
          .frame(width: 80, height: 80)
          .background(.ultraThinMaterial)
          .clipShape(Circle())
          .overlay(
            Circle()
              .stroke(.white.opacity(0.3), lineWidth: 1)
          )

        Image(systemName: "cloud.sun.fill")
          .font(.system(size: 36, weight: .medium))
          .foregroundStyle(.blue)
          .symbolEffect(.bounce, options: .repeating)
      }

      // App title
      VStack(spacing: 8) {
        Text("LiquidSky")
          .font(.system(size: 36, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
          .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

        Text("Connect to the decentralized web")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.white.opacity(0.8))
          .multilineTextAlignment(.center)
      }
    }
  }

  // MARK: - Login Card

  @ViewBuilder
  private var loginCard: some View {
    VStack(spacing: 24) {
      // Header
      VStack(spacing: 8) {
        Text("Welcome Back")
          .font(.system(size: 28, weight: .bold, design: .rounded))
          .foregroundStyle(.white)

        Text("Sign in to your Bluesky account")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.white.opacity(0.7))
      }

      // Form fields
      VStack(spacing: 20) {
        // Handle field
        inputField(
          icon: "at",
          placeholder: "john@bsky.social",
          text: $handle
        )

        // Password field with show/hide toggle
        passwordField
      }

      // Login button
      loginButton

      // Error message
      if let error {
        errorMessage(error)
      }

      // Help text
      helpText
    }
    .padding(32)
    .background(
      RoundedRectangle(cornerRadius: 24)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 24)
        .stroke(.white.opacity(0.2), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    .scaleEffect(inputFocused ? 1.02 : 1.0)
    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: inputFocused)
  }

  @ViewBuilder
  private func inputField(
    icon: String,
    placeholder: String,
    text: Binding<String>
  ) -> some View {
    HStack(spacing: 16) {
      // Icon
      Image(systemName: icon)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(.blue)
        .frame(width: 24)

      // Input field
      TextField(placeholder, text: text)
        .font(.system(size: 16, weight: .medium))
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
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(.white.opacity(0.1), lineWidth: 1)
    )
    .scaleEffect(inputFocused ? 1.02 : 1.0)
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: inputFocused)
  }

  @ViewBuilder
  private var passwordField: some View {
    HStack(spacing: 16) {
      // Icon
      Image(systemName: "lock.fill")
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(.blue)
        .frame(width: 24)

      // Password field
      Group {
        if showPassword {
          TextField("App Password", text: $appPassword)
        } else {
          SecureField("App Password", text: $appPassword)
        }
      }
      .font(.system(size: 16, weight: .medium))
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .foregroundStyle(.white)
      .onTapGesture {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
          inputFocused = true
        }
      }

      // Show/hide password toggle
      Button {
        withAnimation(.easeInOut(duration: 0.2)) {
          showPassword.toggle()
        }
        // Haptic feedback
        HapticManager.shared.impact(.light)
      } label: {
        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.white.opacity(0.6))
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(.white.opacity(0.1), lineWidth: 1)
    )
    .scaleEffect(inputFocused ? 1.02 : 1.0)
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: inputFocused)
  }

  @ViewBuilder
  private var loginButton: some View {
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
          Image(systemName: "arrow.right.circle.fill")
            .font(.system(size: 20, weight: .semibold))
        }

        Text(isLoading ? "Signing In..." : "Sign In to Bluesky")
          .font(.system(size: 18, weight: .semibold))
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 18)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(.blueskyBlue)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(.white.opacity(0.2), lineWidth: 1)
      )
    }
    .disabled(handle.isEmpty || appPassword.isEmpty || isLoading)
    .opacity(handle.isEmpty || appPassword.isEmpty ? 0.6 : 1.0)
    .scaleEffect(handle.isEmpty || appPassword.isEmpty ? 0.98 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: handle.isEmpty || appPassword.isEmpty)
    .onTapGesture {
      // Haptic feedback on button tap
      HapticManager.shared.impact(.medium)
    }
  }

  @ViewBuilder
  private func errorMessage(_ message: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.red)
        .font(.system(size: 16, weight: .medium))

      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.red)
        .multilineTextAlignment(.leading)

      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.red.opacity(0.1))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(.red.opacity(0.2), lineWidth: 1)
    )
    .transition(
      .asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .scale.combined(with: .opacity)
      ))
  }

  @ViewBuilder
  private var helpText: some View {
    VStack(spacing: 8) {
      Text("Need help?")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.white.opacity(0.7))

      HStack(spacing: 16) {
        Button("Create Account") {
          // TODO: Navigate to account creation
          HapticManager.shared.impact(.light)
        }
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.indigo)

        Button("Forgot Password?") {
          // TODO: Navigate to password reset
          HapticManager.shared.impact(.light)
        }
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.purple)
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
  @Previewable @State var auth: Auth = .init()

  return AuthView()
    .environment(auth)
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
  @Previewable @State var auth: Auth = .init()

  return AuthView()
    .environment(auth)
    .preferredColorScheme(.dark)
}

#Preview("Sheet Presentation") {
  @Previewable @State var auth: Auth = .init()

  return ScrollView {
    Text("Hello World")
  }
  .sheet(isPresented: .constant(true)) {
    AuthView()
      .environment(auth)
  }
}
