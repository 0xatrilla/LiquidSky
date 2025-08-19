import Auth
import DesignSystem
import Models
import SwiftUI

public struct ChangePasswordView: View {
  @Environment(Auth.self) private var auth
  @Environment(\.dismiss) private var dismiss

  @State private var currentPassword = ""
  @State private var newPassword = ""
  @State private var confirmPassword = ""
  @State private var showCurrentPassword = false
  @State private var showNewPassword = false
  @State private var showConfirmPassword = false
  @State private var isLoading = false
  @State private var error: String?
  @State private var success = false

  public init() {}

  public var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
              .font(.system(size: 48, weight: .medium))
              .foregroundStyle(.blue)

            Text("Change App Password")
              .font(.title2)
              .fontWeight(.bold)

            Text("Update your Bluesky app password to keep your account secure")
              .font(.body)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          .padding(.top, 20)

          // Form
          VStack(spacing: 20) {
            // Current Password
            passwordField(
              title: "Current App Password",
              placeholder: "Enter your current password",
              text: $currentPassword,
              showPassword: $showCurrentPassword,
              icon: "lock.fill",
              iconColor: .blue
            )

            // New Password
            passwordField(
              title: "New App Password",
              placeholder: "Enter your new password",
              text: $newPassword,
              showPassword: $showNewPassword,
              icon: "lock.rotation",
              iconColor: .green
            )

            // Confirm New Password
            passwordField(
              title: "Confirm New Password",
              placeholder: "Confirm your new password",
              text: $confirmPassword,
              showPassword: $showConfirmPassword,
              icon: "checkmark.shield.fill",
              iconColor: .purple
            )
          }
          .padding(.horizontal, 20)

          // Error Message
          if let error {
            errorMessage(error)
          }

          // Success Message
          if success {
            successMessage
          }

          // Action Buttons
          VStack(spacing: 16) {
            // Change Password Button
            Button {
              Task {
                await changePassword()
              }
            } label: {
              HStack {
                if isLoading {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                } else {
                  Image(systemName: "key.fill")
                    .font(.system(size: 16, weight: .medium))
                }
                Text("Change Password")
                  .font(.system(size: 16, weight: .semibold))
              }
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(
                canSubmit ? Color.blue : Color.gray
              )
              .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSubmit || isLoading)
            .buttonStyle(PlainButtonStyle())

            // Cancel Button
            Button("Cancel") {
              dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 20)

          Spacer(minLength: 40)
        }
      }
      .background(Color(uiColor: .systemGroupedBackground))
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(true)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }

  // MARK: - Computed Properties
  private var canSubmit: Bool {
    !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty
      && newPassword == confirmPassword && newPassword != currentPassword && newPassword.count >= 8
  }

  // MARK: - Password Field
  @ViewBuilder
  private func passwordField(
    title: String,
    placeholder: String,
    text: Binding<String>,
    showPassword: Binding<Bool>,
    icon: String,
    iconColor: Color
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.primary)

      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(iconColor)
          .frame(width: 20)

        Group {
          if showPassword.wrappedValue {
            TextField(placeholder, text: text)
          } else {
            SecureField(placeholder, text: text)
          }
        }
        .font(.system(size: 16, weight: .medium))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()

        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            showPassword.wrappedValue.toggle()
          }
        } label: {
          Image(systemName: showPassword.wrappedValue ? "eye.slash.fill" : "eye.fill")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(uiColor: .systemBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color(uiColor: .separator), lineWidth: 1)
      )
    }
  }

  // MARK: - Error Message
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

  // MARK: - Success Message
  @ViewBuilder
  private var successMessage: some View {
    HStack(spacing: 12) {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.green)
        .font(.system(size: 16, weight: .medium))

      Text("Password changed successfully!")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.green)
        .multilineTextAlignment(.leading)

      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.green.opacity(0.1))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(.green.opacity(0.2), lineWidth: 1)
    )
    .transition(
      .asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .scale.combined(with: .opacity)
      ))
  }

  // MARK: - Password Change Logic
  private func changePassword() async {
    isLoading = true
    error = nil

    do {
      try await auth.changeAppPassword(newPassword: newPassword)

      withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
        success = true
      }

      // Dismiss after a short delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        dismiss()
      }

    } catch {
      withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
        self.error = error.localizedDescription
      }
    }

    isLoading = false
  }
}

// MARK: - Preview
#Preview {
  ChangePasswordView()
    .environment(AccountManager())
    .environment(Auth(accountManager: AccountManager()))
}
