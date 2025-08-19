import Foundation

public struct Account: Identifiable, Codable, Equatable {
  public let id: UUID
  public let handle: String
  public var did: String
  public var displayName: String?
  public var avatarUrl: String?
  public var keychainIdentifier: UUID
  public var isActive: Bool

  public init(
    id: UUID = UUID(),
    handle: String,
    did: String,
    displayName: String?,
    avatarUrl: String?,
    keychainIdentifier: UUID,
    isActive: Bool = false
  ) {
    self.id = id
    self.handle = handle
    self.did = did
    self.displayName = displayName
    self.avatarUrl = avatarUrl
    self.keychainIdentifier = keychainIdentifier
    self.isActive = isActive
  }
}
