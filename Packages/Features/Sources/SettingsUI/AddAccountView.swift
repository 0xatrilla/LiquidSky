import Auth
import DesignSystem
import Models
import SwiftUI

public struct AddAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Auth.self) private var auth

  @State private var handle = ""
  @State private var appPassword = ""
  @State private var isLoading = false
  @State private var errorMessage = ""
  @State private var showPassword = false

  public init() {}

  // Clear cached accounts only when there's a login conflict
  private func clearCachedAccountsIfNeeded() {
    // Only clear accounts if we're in a fresh login state (set by logout or explicit clearing)
    let isInFreshLoginState = UserDefaults.standard.bool(forKey: "Auth.isInFreshLoginState")

    if isInFreshLoginState {
      #if DEBUG
        print("AddAccountView: In fresh login state, clearing cached accounts to prevent conflicts")
      #endif

      // Clear the fresh login state flag
      UserDefaults.standard.removeObject(forKey: "Auth.isInFreshLoginState")

      // Force logout to clear all cached data
      Task {
        do {
          try await auth.logout()
        } catch {
          #if DEBUG
            print("AddAccountView: Error during logout: \(error)")
          #endif
        }
      }
    } else {
      #if DEBUG
        print("AddAccountView: Normal add account flow, not clearing cached accounts")
      #endif
    }
  }

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Header
        header

        // Form
        form

        // Login button
        loginButton

        Spacer(minLength: 60)
      }
      .padding(.horizontal, 24)
      .navigationTitle("Add Account")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        // Clear cached accounts only if needed (fresh login state)
        clearCachedAccountsIfNeeded()
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.primary)
        }
      }
    }
  }

  @ViewBuilder
  private var header: some View {
    VStack(spacing: 24) {
      Spacer(minLength: 60)

      // Icon
      ZStack {
        Circle()
          .fill(.secondary.opacity(0.1))
          .frame(width: 100, height: 100)

        Image(systemName: "person.badge.plus")
          .font(.system(size: 40))
          .foregroundColor(.primary)
      }

      // Title
      VStack(spacing: 8) {
        Text("Add New Account")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        Text("Sign in with your Bluesky credentials")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
    }
  }

  @ViewBuilder
  private var form: some View {
    VStack(spacing: 20) {
      // Handle field
      VStack(alignment: .leading, spacing: 8) {
        Text("Handle")
          .font(.headline)
          .foregroundColor(.primary)

        TextField("yourhandle.bsky.social", text: $handle)
          .textFieldStyle(.plain)
          .padding(.vertical, 16)
          .padding(.horizontal, 20)

          .foregroundColor(.primary)
          .autocapitalization(.none)
          .autocorrectionDisabled()
      }

      // App Password field
      VStack(alignment: .leading, spacing: 8) {
        Text("App Password")
          .font(.headline)
          .foregroundColor(.primary)

        HStack {
          if showPassword {
            TextField("Enter your app password", text: $appPassword)
              .textFieldStyle(.plain)
          } else {
            SecureField("Enter your app password", text: $appPassword)
          }

          Button {
            showPassword.toggle()
          } label: {
            Image(systemName: showPassword ? "eye.slash" : "eye")
              .foregroundColor(.secondary)
          }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)

        .foregroundColor(.primary)
        .autocapitalization(.none)
        .autocorrectionDisabled()
      }

      // Error message
      if !errorMessage.isEmpty {
        Text(errorMessage)
          .font(.caption)
          .foregroundColor(.red)
          .padding(.horizontal, 20)
      }
    }
    .padding(.top, 32)
  }

  @ViewBuilder
  private var loginButton: some View {
    Button {
      Task {
        await addAccount()
      }
    } label: {
      HStack {
        if isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .primary))
            .scaleEffect(0.8)
        } else {
          Image(systemName: "plus.circle.fill")
            .font(.title2)
        }

        Text(isLoading ? "Adding Account..." : "Add Account")
          .font(.headline)
      }
      .foregroundColor(.primary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 18)

    }
    .disabled(isLoading || handle.isEmpty || appPassword.isEmpty)
    .padding(.top, 32)
  }

  private func addAccount() async {
    guard !handle.isEmpty && !appPassword.isEmpty else { return }

    isLoading = true
    errorMessage = ""

    // Clean the handle - remove domain suffix if present
    let cleanHandle = handle.replacingOccurrences(of: ".bsky.social", with: "")
      .replacingOccurrences(of: ".bsky.app", with: "")
      .replacingOccurrences(of: ".bsky.network", with: "")

    do {
      print(
        "AddAccountView: Attempting to add account with handle: '\(cleanHandle)' (original: '\(handle)')"
      )
      let _ = try await auth.addAccount(handle: cleanHandle, appPassword: appPassword)
      dismiss()
    } catch {
      print("AddAccountView: Error adding account: \(error)")

      // Check if this is a login conflict error
      if error.localizedDescription.contains("already exists")
        || (error as? AuthError) == .accountAlreadyExists
      {
        #if DEBUG
          print("AddAccountView: Login conflict detected, setting fresh login state")
        #endif

        // Set fresh login state to clear cached accounts on next attempt
        UserDefaults.standard.set(true, forKey: "Auth.isInFreshLoginState")

        errorMessage = "Login conflict detected. Please try again."
      } else if let authError = error as? AuthError {
        switch authError {
        case .accountAlreadyExists:
          errorMessage = "An account with this handle already exists"
        case .authenticationFailed:
          errorMessage = "Authentication failed. Please check your handle and app password."
        case .invalidCredentials:
          errorMessage = "Invalid handle or app password. Please verify your credentials."
        default:
          errorMessage = "Failed to add account: \(authError.localizedDescription)"
        }
      } else {
        errorMessage = "Failed to add account: \(error.localizedDescription)"
      }
    }

    isLoading = false
  }
}
