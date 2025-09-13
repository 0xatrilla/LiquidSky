import Foundation

@Observable
public final class AccountManager {
  private let userDefaults = UserDefaults.standard
  private let accountsKey = "accounts"
  private let activeAccountIdKey = "activeAccountId"

  public private(set) var accounts: [Account] = []
  public private(set) var activeAccountId: UUID?

  public init() {
    loadAccounts()
  }

  public func addAccount(_ account: Account) {
    #if DEBUG
      print("AccountManager: Adding account with handle: \(account.handle)")
      print("AccountManager: Current accounts count: \(accounts.count)")
    #endif

    // Check if account with same handle already exists
    if let existingAccount = accounts.first(where: { $0.handle == account.handle }) {
      #if DEBUG
        print(
          "AccountManager: Found existing account with handle: \(existingAccount.handle), updating instead of creating duplicate"
        )
      #endif

      // Create a new account with the same ID but updated information
      let updatedAccount = Account(
        id: existingAccount.id,
        handle: existingAccount.handle,
        did: account.did,
        displayName: account.displayName,
        avatarUrl: account.avatarUrl,
        keychainIdentifier: account.keychainIdentifier,
        isActive: true
      )

      // Deactivate all other accounts
      accounts = accounts.map { existingAccount in
        var updatedAccount = existingAccount
        updatedAccount.isActive = false
        return updatedAccount
      }

      // Replace the existing account
      if let index = accounts.firstIndex(where: { $0.id == existingAccount.id }) {
        accounts[index] = updatedAccount
      }

      activeAccountId = updatedAccount.id
    } else {
      #if DEBUG
        print("AccountManager: No existing account found, creating new one")
      #endif

      // Deactivate all other accounts
      accounts = accounts.map { existingAccount in
        var updatedAccount = existingAccount
        updatedAccount.isActive = false
        return updatedAccount
      }

      // Add new account as active
      var newAccount = account
      newAccount.isActive = true
      accounts.append(newAccount)
      activeAccountId = newAccount.id
    }

    #if DEBUG
      print("AccountManager: Final accounts count: \(accounts.count)")
      print("AccountManager: Account handles: \(accounts.map { $0.handle })")
    #endif

    saveAccounts()
  }

  public func removeAccount(_ accountId: UUID) {
    accounts.removeAll { $0.id == accountId }

    // If we removed the active account, activate the first remaining one
    if activeAccountId == accountId {
      if let firstAccount = accounts.first {
        activeAccountId = firstAccount.id
        accounts = accounts.map { account in
          var updatedAccount = account
          updatedAccount.isActive = account.id == firstAccount.id
          return updatedAccount
        }
      } else {
        activeAccountId = nil
      }
    }

    saveAccounts()
  }

  public func switchToAccount(_ accountId: UUID) async throws {
    guard let account = accounts.first(where: { $0.id == accountId }) else {
      throw AccountError.accountNotFound
    }

    // Update active account
    accounts = accounts.map { existingAccount in
      var updatedAccount = existingAccount
      updatedAccount.isActive = existingAccount.id == accountId
      return updatedAccount
    }

    activeAccountId = accountId
    saveAccounts()
  }

  public func loadAccounts() {
    #if DEBUG
      print("AccountManager: Loading accounts from UserDefaults")
      print(
        "AccountManager: Call stack: \(Thread.callStackSymbols.prefix(3).map { $0.components(separatedBy: " ").last ?? "unknown" })"
      )
    #endif

    if let data = userDefaults.data(forKey: accountsKey),
      let decodedAccounts = try? JSONDecoder().decode([Account].self, from: data)
    {
      accounts = decodedAccounts
      #if DEBUG
        print("AccountManager: Loaded \(accounts.count) accounts from UserDefaults")
        print("AccountManager: Account handles: \(accounts.map { $0.handle })")
      #endif
    } else {
      #if DEBUG
        print("AccountManager: No accounts found in UserDefaults")
      #endif
    }

    if let activeIdString = userDefaults.string(forKey: activeAccountIdKey),
      let activeId = UUID(uuidString: activeIdString)
    {
      activeAccountId = activeId
      #if DEBUG
        print("AccountManager: Active account ID: \(activeId)")
      #endif
    } else {
      #if DEBUG
        print("AccountManager: No active account ID found")
      #endif
    }
  }

  public func saveAccounts() {
    if let encoded = try? JSONEncoder().encode(accounts) {
      userDefaults.set(encoded, forKey: accountsKey)
    }

    if let activeId = activeAccountId {
      userDefaults.set(activeId.uuidString, forKey: activeAccountIdKey)
    } else {
      userDefaults.removeObject(forKey: activeAccountIdKey)
    }
  }

  public var currentAccount: Account? {
    accounts.first { $0.id == activeAccountId }
  }

  // Debug method to clear all accounts
  public func clearAllAccounts() {
    #if DEBUG
      print("AccountManager: Clearing all accounts")
      print("AccountManager: Before clearing - accounts count: \(accounts.count)")
      print("AccountManager: Before clearing - account handles: \(accounts.map { $0.handle })")
      print(
        "AccountManager: Before clearing - active account ID: \(activeAccountId?.uuidString ?? "nil")"
      )
    #endif

    accounts.removeAll()
    activeAccountId = nil
    userDefaults.removeObject(forKey: accountsKey)
    userDefaults.removeObject(forKey: activeAccountIdKey)

    #if DEBUG
      print("AccountManager: After clearing - accounts count: \(accounts.count)")
      print(
        "AccountManager: After clearing - active account ID: \(activeAccountId?.uuidString ?? "nil")"
      )
      print("AccountManager: All accounts cleared from memory and UserDefaults")
    #endif
  }
}

public enum AccountError: Error, LocalizedError {
  case accountNotFound

  public var errorDescription: String? {
    switch self {
    case .accountNotFound:
      return "Account not found"
    }
  }
}
