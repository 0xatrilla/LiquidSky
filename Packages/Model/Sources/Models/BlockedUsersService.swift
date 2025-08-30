import Foundation

@MainActor
@Observable
public final class BlockedUsersService {
  public static let shared = BlockedUsersService()

  private let blockedUsersKey = "localBlockedUsers"
  private let mutedUsersKey = "localMutedUsers"

  public var blockedUsers: [BlockedUser] = []
  public var mutedUsers: [MutedUser] = []

  private init() {
    loadBlockedUsers()
    loadMutedUsers()
  }

  // MARK: - Blocked Users

  public func blockUser(did: String, handle: String) {
    let blockedUser = BlockedUser(did: did, handle: handle, timestamp: Date())

    if !blockedUsers.contains(where: { $0.did == did }) {
      blockedUsers.append(blockedUser)
      saveBlockedUsers()
    }
  }

  public func unblockUser(did: String) {
    blockedUsers.removeAll { $0.did == did }
    saveBlockedUsers()
  }

  public func isUserBlocked(did: String) -> Bool {
    return blockedUsers.contains { $0.did == did }
  }

  public func isUserBlocked(handle: String) -> Bool {
    return blockedUsers.contains { $0.handle == handle }
  }

  private func loadBlockedUsers() {
    let defaults = UserDefaults.standard
    if let data = defaults.data(forKey: blockedUsersKey),
      let users = try? JSONDecoder().decode([BlockedUser].self, from: data)
    {
      blockedUsers = users
    }
  }

  private func saveBlockedUsers() {
    let defaults = UserDefaults.standard
    if let data = try? JSONEncoder().encode(blockedUsers) {
      defaults.set(data, forKey: blockedUsersKey)
    }
  }

  // MARK: - Muted Users

  public func muteUser(did: String, handle: String) {
    let mutedUser = MutedUser(did: did, handle: handle, timestamp: Date())

    if !mutedUsers.contains(where: { $0.did == did }) {
      mutedUsers.append(mutedUser)
      saveMutedUsers()
    }
  }

  public func unmuteUser(did: String) {
    mutedUsers.removeAll { $0.did == did }
    saveMutedUsers()
  }

  public func isUserMuted(did: String) -> Bool {
    return mutedUsers.contains { $0.did == did }
  }

  public func isUserMuted(handle: String) -> Bool {
    return mutedUsers.contains { $0.handle == handle }
  }

  private func loadMutedUsers() {
    let defaults = UserDefaults.standard
    if let data = defaults.data(forKey: mutedUsersKey),
      let users = try? JSONDecoder().decode([MutedUser].self, from: data)
    {
      mutedUsers = users
    }
  }

  private func saveMutedUsers() {
    let defaults = UserDefaults.standard
    if let data = try? JSONEncoder().encode(mutedUsers) {
      defaults.set(data, forKey: mutedUsersKey)
    }
  }

  // MARK: - Filtering

  public func shouldHidePost(from user: Profile) -> Bool {
    return isUserBlocked(did: user.did) || isUserMuted(did: user.did)
  }

  public func shouldHidePost(from did: String) -> Bool {
    return isUserBlocked(did: did) || isUserMuted(did: did)
  }
}

// MARK: - Models

public struct BlockedUser: Codable, Identifiable {
  public var id = UUID()
  public let did: String
  public let handle: String
  public let timestamp: Date

  public init(did: String, handle: String, timestamp: Date) {
    self.did = did
    self.handle = handle
    self.timestamp = timestamp
  }
}

public struct MutedUser: Codable, Identifiable {
  public var id = UUID()
  public let did: String
  public let handle: String
  public let timestamp: Date

  public init(did: String, handle: String, timestamp: Date) {
    self.did = did
    self.handle = handle
    self.timestamp = timestamp
  }
}
