import Auth
import DesignSystem
import Models
import SwiftUI

public struct AccountSwitcherView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(AccountManager.self) private var accountManager
  @Environment(Auth.self) private var auth

  @State private var showAddAccount = false
  @State private var isLoading = false

  public init() {}

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Header with current account
        currentAccountHeader

        // Account list
        accountList

        // Add account button
        addAccountButton

        Spacer(minLength: 60)
      }
      .padding(.horizontal, 24)
      .navigationTitle("Accounts")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .foregroundColor(.primary)
        }
      }
      .sheet(isPresented: $showAddAccount) {
        AddAccountView()
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.visible)
      }
    }
  }

  @ViewBuilder
  private var currentAccountHeader: some View {
    VStack(spacing: 24) {
      Spacer(minLength: 40)

      if let currentAccount = accountManager.currentAccount {
        // Current account display
        VStack(spacing: 16) {
          // Avatar
          ZStack {
            Circle()
              .fill(.secondary.opacity(0.1))
              .frame(width: 80, height: 80)

            if let avatarUrl = currentAccount.avatarUrl {
              AsyncImage(url: URL(string: avatarUrl)) { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
              } placeholder: {
                Image(systemName: "person.circle.fill")
                  .font(.system(size: 40))
                  .foregroundColor(.primary)
              }
              .frame(width: 60, height: 60)
              .clipShape(Circle())
            } else {
              Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.primary)
            }
          }

          // Account info
          VStack(spacing: 8) {
            Text(currentAccount.displayName ?? currentAccount.handle)
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.primary)

            Text(currentAccount.handle)
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
      }
    }
  }

  @ViewBuilder
  private var accountList: some View {
    VStack(spacing: 16) {
      ForEach(accountManager.accounts.filter { $0.id != accountManager.currentAccount?.id }) {
        account in
        AccountRowView(account: account) {
          Task {
            isLoading = true
            do {
              try await auth.switchAccount(to: account.id)
              dismiss()
            } catch {
              print("Failed to switch account: \(error)")
            }
            isLoading = false
          }
        }
      }
    }
  }

  @ViewBuilder
  private var addAccountButton: some View {
    Button {
      showAddAccount = true
    } label: {
      HStack {
        Image(systemName: "plus.circle.fill")
          .font(.title2)
        Text("Add Account")
          .font(.headline)
      }
      .foregroundColor(.primary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
    }
    .disabled(isLoading)
    .padding(.top, 32)
  }
}

// MARK: - Account Row Component
private struct AccountRowView: View {
  let account: Account
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 16) {
        // Avatar
        ZStack {
          Circle()
            .fill(.secondary.opacity(0.1))
            .frame(width: 50, height: 50)

          if let avatarUrl = account.avatarUrl {
            AsyncImage(url: URL(string: avatarUrl)) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              Image(systemName: "person.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.primary)
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
          } else {
            Image(systemName: "person.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(.primary)
          }
        }

        // Account info
        VStack(alignment: .leading, spacing: 4) {
          Text(account.displayName ?? account.handle)
            .font(.headline)
            .foregroundColor(.primary)

          Text(account.handle)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(.vertical, 16)
      .padding(.horizontal, 20)
    }
  }
}
