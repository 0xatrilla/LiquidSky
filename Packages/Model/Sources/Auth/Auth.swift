import ATProtoKit
import Foundation
@preconcurrency import KeychainSwift
import Models
import SwiftUI

@Observable
public final class Auth: @unchecked Sendable {
  let keychain = KeychainSwift()
  private let accountManager: AccountManager

  public private(set) var configuration: ATProtocolConfiguration?
  public private(set) var currentAccountId: UUID?

  private let configurationContinuation: AsyncStream<ATProtocolConfiguration?>.Continuation
  public let configurationUpdates: AsyncStream<ATProtocolConfiguration?>

  private var ATProtoKeychain: AppleSecureKeychain

  public func logout() async throws {
    try await configuration?.deleteSession()
    configuration = nil
    configurationContinuation.yield(nil)
  }

  public init(accountManager: AccountManager) {
    self.accountManager = accountManager

    // Initialize AsyncStream properties first
    var continuation: AsyncStream<ATProtocolConfiguration?>.Continuation!
    self.configurationUpdates = AsyncStream { cont in
      continuation = cont
    }
    self.configurationContinuation = continuation

    // Initialize with active account or create new keychain
    if let activeAccountId = accountManager.activeAccountId,
      let activeAccount = accountManager.accounts.first(where: { $0.id == activeAccountId })
    {
      print("Auth: Found active account: \(activeAccount.handle)")
      self.currentAccountId = activeAccountId
      self.ATProtoKeychain = AppleSecureKeychain(identifier: activeAccount.keychainIdentifier)
      print("Auth: Initialized with existing account: \(activeAccount.handle)")
    } else if let firstAccount = accountManager.accounts.first {
      // Fallback to first account if no active account set
      print("Auth: No active account, using first available account: \(firstAccount.handle)")
      self.currentAccountId = firstAccount.id
      self.ATProtoKeychain = AppleSecureKeychain(identifier: firstAccount.keychainIdentifier)
    } else {
      // No accounts - will show auth screen
      print("Auth: No accounts found, creating new keychain")
      self.ATProtoKeychain = AppleSecureKeychain(identifier: UUID())
    }

    // Initialize configuration with the keychain
    self.configuration = ATProtocolConfiguration(keychainProtocol: self.ATProtoKeychain)

    // Try to restore existing session on initialization
    Task {
      await restoreSession()
    }
  }

  public func switchAccount(to accountId: UUID) async throws {
    guard let account = accountManager.accounts.first(where: { $0.id == accountId }) else {
      throw AccountError.accountNotFound
    }

    // Load different keychain for the account using the stored keychain identifier
    let accountKeychain = AppleSecureKeychain(identifier: account.keychainIdentifier)
    let configuration = ATProtocolConfiguration(keychainProtocol: accountKeychain)

    // Try to refresh the session for this account
    try await configuration.refreshSession()

    self.ATProtoKeychain = accountKeychain
    self.configuration = configuration
    self.currentAccountId = accountId

    // Update account manager
    try await accountManager.switchToAccount(accountId)

    // This triggers the EXISTING reactive flow!
    configurationContinuation.yield(configuration)
  }

  public func addAccount(handle: String, appPassword: String) async throws -> Account {
    print("Auth: Starting addAccount for handle: \(handle)")

    // Check if account already exists
    if accountManager.accounts.contains(where: { $0.handle == handle }) {
      print("Auth: Account with handle \(handle) already exists")
      throw AuthError.accountAlreadyExists
    }

    // Create new keychain for this account
    let newAccountId = UUID()
    let newAccountKeychain = AppleSecureKeychain(identifier: newAccountId)
    let configuration = ATProtocolConfiguration(keychainProtocol: newAccountKeychain)

    print("Auth: Created new keychain with identifier: \(newAccountId)")

    // Authenticate with the new account
    do {
      print("Auth: Attempting authentication...")
      try await configuration.authenticate(with: handle, password: appPassword)
      print("Auth: Authentication successful")
    } catch {
      print("Auth: Authentication failed with error: \(error)")
      throw AuthError.invalidCredentials
    }

    // Get user session to extract profile info
    print("Auth: Creating ATProtoKit client...")
    let protoClient = await ATProtoKit(sessionConfiguration: configuration)

    print("Auth: Attempting to get user session...")
    guard let session = try await protoClient.getUserSession() else {
      print("Auth: Failed to get user session - session is nil")
      throw AuthError.authenticationFailed
    }
    print("Auth: Got user session for handle: \(session.handle), DID: \(session.sessionDID)")

    // Fetch full profile data including avatar and display name
    var displayName: String?
    var avatarUrl: String?

    do {
      print("Auth: Fetching profile data for \(session.handle)")
      let profileData = try await protoClient.getProfile(for: session.sessionDID)
      displayName = profileData.displayName
      avatarUrl = profileData.avatarImageURL?.absoluteString
      print(
        "Auth: Successfully fetched profile - displayName: \(displayName ?? "nil"), avatarUrl: \(avatarUrl ?? "nil")"
      )
    } catch {
      print("Auth: Failed to fetch profile data: \(error)")
      // Continue with nil values if profile fetch fails
    }

    // Create account object with profile data
    let account = Account(
      handle: session.handle,
      did: session.sessionDID,
      displayName: displayName,
      avatarUrl: avatarUrl,
      keychainIdentifier: newAccountId
    )

    print("Auth: Created account object for \(session.handle)")

    // Add to account manager (this sets it as active)
    accountManager.addAccount(account)

    // Update the current configuration, account ID, and keychain
    self.configuration = configuration
    self.currentAccountId = account.id
    self.ATProtoKeychain = newAccountKeychain

    // Yield the configuration to trigger the authentication flow
    configurationContinuation.yield(configuration)

    return account
  }

  public func removeAccount(_ accountId: UUID) async throws {
    // Don't allow removing the current account if it's the only one
    if accountManager.accounts.count == 1 {
      throw AuthError.cannotRemoveLastAccount
    }

    // If removing current account, switch to another first
    if accountId == currentAccountId {
      let remainingAccounts = accountManager.accounts.filter { $0.id != accountId }
      if let nextAccount = remainingAccounts.first {
        try await switchAccount(to: nextAccount.id)
      }
    }

    // Remove from account manager
    accountManager.removeAccount(accountId)
  }

  /// Attempts to restore an existing session from stored credentials
  public func restoreSession() async {
    do {
      print("Auth: Attempting to restore existing session...")

      // Determine target account: prefer active, else fall back to first stored
      var targetAccountId: UUID?
      if let activeId = accountManager.activeAccountId {
        targetAccountId = activeId
      } else if let firstAccount = accountManager.accounts.first {
        print("Auth: No active account found, falling back to first stored account: \(firstAccount.handle)")
        // Mark it active for consistency across app components
        try? await accountManager.switchToAccount(firstAccount.id)
        targetAccountId = firstAccount.id
      } else {
        print("Auth: No accounts available, cannot restore session")
        return
      }

      // Get the target account
      guard let activeAccount = accountManager.accounts.first(where: { $0.id == targetAccountId })
      else {
        print("Auth: Active account not found in account list")
        return
      }

      print("Auth: Attempting to restore session for account: \(activeAccount.handle)")

      // Create keychain for the active account
      let accountKeychain = AppleSecureKeychain(identifier: activeAccount.keychainIdentifier)
      let configuration = ATProtocolConfiguration(keychainProtocol: accountKeychain)

      // Try to refresh the session without requiring user input
      try await configuration.refreshSession()

      print("Auth: Successfully restored existing session for \(activeAccount.handle)")

      // Update our state
      self.ATProtoKeychain = accountKeychain
      self.configuration = configuration
      self.currentAccountId = targetAccountId

      // Trigger the authentication flow
      configurationContinuation.yield(configuration)
    } catch {
      print("Auth: Failed to restore existing session: \(error)")
      // Session restoration failed, user will need to authenticate
      self.configuration = nil
      configurationContinuation.yield(nil)
    }
  }

  public func authenticate(handle: String, appPassword: String) async throws {
    let configuration = ATProtocolConfiguration(keychainProtocol: ATProtoKeychain)
    try await configuration.authenticate(with: handle, password: appPassword)
    self.configuration = configuration
    configurationContinuation.yield(configuration)
  }

  public func refresh() async {
    do {
      let configuration = ATProtocolConfiguration(keychainProtocol: ATProtoKeychain)
      try await configuration.refreshSession()
      self.configuration = configuration
      configurationContinuation.yield(configuration)
    } catch {
      print("Auth refresh failed: \(error)")
      // Handle no session token gracefully
      print("No session token found, user needs to authenticate")
      // Don't crash, just set to unauthenticated
      self.configuration = nil
      configurationContinuation.yield(nil)
    }
  }

  public func changeAppPassword(newPassword: String) async throws {
    guard let configuration = configuration else {
      throw AuthError.noActiveSession
    }

    // Get the current handle from the session
    let protoClient = await ATProtoKit(sessionConfiguration: configuration)
    guard let session = try await protoClient.getUserSession() else {
      throw AuthError.noActiveSession
    }

    // Re-authenticate with the new password
    try await configuration.authenticate(with: session.handle, password: newPassword)

    // Update the configuration
    self.configuration = configuration
    configurationContinuation.yield(configuration)
  }
}

// MARK: - Auth Errors
public enum AuthError: LocalizedError {
  case noActiveSession
  case authenticationFailed
  case cannotRemoveLastAccount
  case accountAlreadyExists
  case invalidCredentials

  public var errorDescription: String? {
    switch self {
    case .noActiveSession:
      return "No active session found. Please sign in again."
    case .authenticationFailed:
      return "Failed to authenticate with the provided credentials."
    case .cannotRemoveLastAccount:
      return "Cannot remove the last account. Please add a new one first."
    case .accountAlreadyExists:
      return "An account with this handle already exists."
    case .invalidCredentials:
      return "Invalid handle or app password. Please check your credentials and try again."
    }
  }

}

extension UserSession: @retroactive Equatable {
  public static func == (lhs: UserSession, rhs: UserSession) -> Bool {
    lhs.sessionDID == rhs.sessionDID
  }
}
