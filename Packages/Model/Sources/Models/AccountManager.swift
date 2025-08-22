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
    print("AccountManager: Adding account with handle: \(account.handle)")
    print("AccountManager: Current accounts count: \(accounts.count)")

    // Check if account with same handle already exists
    if let existingAccount = accounts.first(where: { $0.handle == account.handle }) {
      print(
        "AccountManager: Found existing account with handle: \(existingAccount.handle), updating instead of creating duplicate"
      )

      // Update existing account instead of creating duplicate
      var updatedAccount = existingAccount
      updatedAccount.isActive = true
      updatedAccount.did = account.did
      updatedAccount.displayName = account.displayName
      updatedAccount.avatarUrl = account.avatarUrl
      updatedAccount.keychainIdentifier = account.keychainIdentifier

      // Deactivate all other accounts
      accounts = accounts.map { existingAccount in
        var updatedAccount = existingAccount
        updatedAccount.isActive = false
        return updatedAccount
      }

      // Update the existing account
      if let index = accounts.firstIndex(where: { $0.id == existingAccount.id }) {
        accounts[index] = updatedAccount
      }

      activeAccountId = updatedAccount.id
    } else {
      print("AccountManager: No existing account found, creating new one")

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

    print("AccountManager: Final accounts count: \(accounts.count)")
    print("AccountManager: Account handles: \(accounts.map { $0.handle })")

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
    print("AccountManager: Loading accounts from UserDefaults")

    if let data = userDefaults.data(forKey: accountsKey),
      let decodedAccounts = try? JSONDecoder().decode([Account].self, from: data)
    {
      accounts = decodedAccounts
      print("AccountManager: Loaded \(accounts.count) accounts from UserDefaults")
      print("AccountManager: Account handles: \(accounts.map { $0.handle })")
    } else {
      print("AccountManager: No accounts found in UserDefaults")
    }

    if let activeIdString = userDefaults.string(forKey: activeAccountIdKey),
      let activeId = UUID(uuidString: activeIdString)
    {
      activeAccountId = activeId
      print("AccountManager: Active account ID: \(activeId)")
    } else {
      print("AccountManager: No active account ID found")
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
    print("AccountManager: Clearing all accounts")
    accounts.removeAll()
    activeAccountId = nil
    userDefaults.removeObject(forKey: accountsKey)
    userDefaults.removeObject(forKey: activeAccountIdKey)
    print("AccountManager: All accounts cleared from memory and UserDefaults")
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
