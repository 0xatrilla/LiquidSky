import DesignSystem
import Models
import SwiftUI

public struct CurrentAccountHeader: View {
  @Environment(AccountManager.self) private var accountManager
  @State private var showAccountSwitcher = false

  public init() {}

  public var body: some View {
    Button {
      showAccountSwitcher = true
    } label: {
      HStack(spacing: 16) {
        // Avatar
        ZStack {
          Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 60, height: 60)
            .overlay(
              Circle()
                .stroke(.white.opacity(0.2), lineWidth: 1)
            )

          if let currentAccount = accountManager.currentAccount,
            let avatarUrl = currentAccount.avatarUrl
          {
            AsyncImage(url: URL(string: avatarUrl)) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              Image(systemName: "person.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
          } else {
            Image(systemName: "person.circle.fill")
              .font(.system(size: 30))
              .foregroundColor(.white)
          }
        }

        // Account info
        VStack(alignment: .leading, spacing: 4) {
          if let currentAccount = accountManager.currentAccount {
            Text(currentAccount.displayName ?? currentAccount.handle)
              .font(.headline)
              .fontWeight(.semibold)
              .foregroundColor(.white)

            Text(currentAccount.handle)
              .font(.subheadline)
              .foregroundColor(.white.opacity(0.8))
          } else {
            Text("No Account")
              .font(.headline)
              .fontWeight(.semibold)
              .foregroundColor(.white)

            Text("Tap to sign in")
              .font(.subheadline)
              .foregroundColor(.white.opacity(0.8))
          }
        }

        Spacer()

        // Account switcher indicator
        HStack(spacing: 4) {
          Text("Switch")
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))

          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))
        }
      }
      .padding(.vertical, 20)
      .padding(.horizontal, 24)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(.white.opacity(0.2), lineWidth: 1)
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
    .sheet(isPresented: $showAccountSwitcher) {
      AccountSwitcherView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
  }
}
