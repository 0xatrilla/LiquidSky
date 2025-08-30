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
  private var isInFreshLoginState = false

  public func logout() async throws {
    #if DEBUG
      print("Auth: Starting logout process")
    #endif

    try await configuration?.deleteSession()
    configuration = nil
    currentAccountId = nil

    #if DEBUG
      print("Auth: Clearing all accounts from AccountManager")
    #endif

    // Mark all accounts as inactive and clear them to allow fresh login
    accountManager.clearAllAccounts()

    #if DEBUG
      print("Auth: Resetting Auth class internal state")
    #endif

    // Set fresh login state to ignore any existing accounts
    isInFreshLoginState = true

    // Reset the Auth class internal state to allow fresh login
    resetInternalState()

    #if DEBUG
      print("Auth: Logout complete, set fresh login state, yielding nil configuration")
    #endif

    configurationContinuation.yield(nil)
  }

  private func resetInternalState() {
    // Create a completely new keychain to avoid any session remnants
    self.ATProtoKeychain = AppleSecureKeychain(identifier: UUID())

    // Reset the configuration to ensure no old session data remains
    self.configuration = ATProtocolConfiguration(keychainProtocol: self.ATProtoKeychain)

    #if DEBUG
      print("Auth: Internal state reset, new keychain and configuration created")
      print("Auth: After reset - accounts count: \(accountManager.accounts.count)")
      print("Auth: After reset - account handles: \(accountManager.accounts.map { $0.handle })")
    #endif
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
      #if DEBUG
        print("Auth: Found active account: \(activeAccount.handle)")
      #endif
      self.currentAccountId = activeAccountId
      self.ATProtoKeychain = AppleSecureKeychain(identifier: activeAccount.keychainIdentifier)
      #if DEBUG
        print("Auth: Initialized with existing account: \(activeAccount.handle)")
      #endif
    } else if let firstAccount = accountManager.accounts.first {
      // Fallback to first account if no active account set
      #if DEBUG
        print("Auth: No active account, using first available account: \(firstAccount.handle)")
      #endif
      self.currentAccountId = firstAccount.id
      self.ATProtoKeychain = AppleSecureKeychain(identifier: firstAccount.keychainIdentifier)
    } else {
      // No accounts - will show auth screen
      #if DEBUG
        print("Auth: No accounts found, creating new keychain")
      #endif
      self.ATProtoKeychain = AppleSecureKeychain(identifier: UUID())
    }

    // Initialize configuration with the keychain
    self.configuration = ATProtocolConfiguration(keychainProtocol: self.ATProtoKeychain)

    // Note: Session restoration is orchestrated by the app on startup to avoid duplicate work.
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
    #if DEBUG
      print("Auth: Starting addAccount for handle: \(handle)")
    #endif

    #if DEBUG
      print("Auth: Checking if account with handle \(handle) already exists")
      print("Auth: Current accounts count: \(accountManager.accounts.count)")
      print("Auth: Account handles: \(accountManager.accounts.map { $0.handle })")
      print("Auth: Current configuration: \(configuration != nil ? "exists" : "nil")")
      print("Auth: Current account ID: \(currentAccountId?.uuidString ?? "nil")")
      print("Auth: Is in fresh login state: \(isInFreshLoginState)")
    #endif

    // If we're in fresh login state (after logout), ignore any existing accounts
    if isInFreshLoginState {
      #if DEBUG
        print("Auth: In fresh login state, clearing any existing accounts and proceeding")
      #endif
      // Clear any existing accounts and reset state
      accountManager.clearAllAccounts()
      currentAccountId = nil
      isInFreshLoginState = false
    } else {
      // Check if account already exists and is active (normal flow)
      if let existingAccount = accountManager.accounts.first(where: { $0.handle == handle }) {
        if existingAccount.isActive {
          #if DEBUG
            print("Auth: Active account with handle \(handle) already exists")
          #endif
          throw AuthError.accountAlreadyExists
        } else {
          #if DEBUG
            print("Auth: Found inactive account with handle \(handle), will reactivate it")
          #endif
          // Remove the inactive account so we can create a fresh one
          accountManager.removeAccount(existingAccount.id)
        }
      } else {
        #if DEBUG
          print("Auth: No existing account found with handle \(handle)")
        #endif
      }
    }

    // Create new keychain for this account
    let newAccountId = UUID()
    let newAccountKeychain = AppleSecureKeychain(identifier: newAccountId)
    let configuration = ATProtocolConfiguration(keychainProtocol: newAccountKeychain)

    #if DEBUG
      print("Auth: Created new keychain with identifier: \(newAccountId)")
    #endif

    // Authenticate with the new account
    do {
      #if DEBUG
        print("Auth: Attempting authentication...")
      #endif
      try await configuration.authenticate(with: handle, password: appPassword)
      #if DEBUG
        print("Auth: Authentication successful")
      #endif
    } catch {
      #if DEBUG
        print("Auth: Authentication failed with error: \(error)")
      #endif
      throw AuthError.invalidCredentials
    }

    // Get user session to extract profile info
    #if DEBUG
      print("Auth: Creating ATProtoKit client...")
    #endif
    let protoClient = await ATProtoKit(sessionConfiguration: configuration)

    #if DEBUG
      print("Auth: Attempting to get user session...")
    #endif
    guard let session = try await protoClient.getUserSession() else {
      #if DEBUG
        print("Auth: Failed to get user session - session is nil")
      #endif
      throw AuthError.authenticationFailed
    }
    #if DEBUG
      print("Auth: Got user session for handle: \(session.handle), DID: \(session.sessionDID)")
    #endif

    // Fetch full profile data including avatar and display name
    var displayName: String?
    var avatarUrl: String?

    do {
      #if DEBUG
        print("Auth: Fetching profile data for \(session.handle)")
      #endif
      let profileData = try await protoClient.getProfile(for: session.sessionDID)
      displayName = profileData.displayName
      avatarUrl = profileData.avatarImageURL?.absoluteString
      #if DEBUG
        print(
          "Auth: Successfully fetched profile - displayName: \(displayName ?? "nil"), avatarUrl: \(avatarUrl ?? "nil")"
        )
      #endif
    } catch {
      #if DEBUG
        print("Auth: Failed to fetch profile data: \(error)")
      #endif
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

    #if DEBUG
      print("Auth: Created account object for \(session.handle)")
    #endif

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
      #if DEBUG
        print("Auth: Attempting to restore existing session...")
      #endif

      // Determine target account: prefer active, else fall back to first stored
      var targetAccountId: UUID?
      if let activeId = accountManager.activeAccountId {
        targetAccountId = activeId
      } else if let firstAccount = accountManager.accounts.first {
        #if DEBUG
          print(
            "Auth: No active account found, falling back to first stored account: \(firstAccount.handle)"
          )
        #endif
        // Mark it active for consistency across app components
        try? await accountManager.switchToAccount(firstAccount.id)
        targetAccountId = firstAccount.id
      } else {
        #if DEBUG
          print("Auth: No accounts available, cannot restore session")
        #endif
        return
      }

      // Get the target account
      guard let activeAccount = accountManager.accounts.first(where: { $0.id == targetAccountId })
      else {
        #if DEBUG
          print("Auth: Active account not found in account list")
        #endif
        return
      }

      #if DEBUG
        print("Auth: Attempting to restore session for account: \(activeAccount.handle)")
      #endif

      // Create keychain for the active account
      let accountKeychain = AppleSecureKeychain(identifier: activeAccount.keychainIdentifier)
      let configuration = ATProtocolConfiguration(keychainProtocol: accountKeychain)

      // Try to refresh the session without requiring user input
      try await configuration.refreshSession()

      #if DEBUG
        print("Auth: Successfully restored existing session for \(activeAccount.handle)")
      #endif

      // Update our state
      self.ATProtoKeychain = accountKeychain
      self.configuration = configuration
      self.currentAccountId = targetAccountId

      // Trigger the authentication flow
      configurationContinuation.yield(configuration)
    } catch {
      #if DEBUG
        print("Auth: Failed to restore existing session: \(error)")
      #endif
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
      #if DEBUG
        print("Auth refresh failed: \(error)")
      #endif
      // Handle no session token gracefully
      #if DEBUG
        print("No session token found, user needs to authenticate")
      #endif
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
