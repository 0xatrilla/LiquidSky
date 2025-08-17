import ATProtoKit
import Foundation
@preconcurrency import KeychainSwift
import SwiftUI

@Observable
public final class Auth: @unchecked Sendable {
  let keychain = KeychainSwift()

  public private(set) var configuration: ATProtocolConfiguration?

  private let configurationContinuation: AsyncStream<ATProtocolConfiguration?>.Continuation
  public let configurationUpdates: AsyncStream<ATProtocolConfiguration?>

  private let ATProtoKeychain: AppleSecureKeychain

  public func logout() async throws {
    try await configuration?.deleteSession()
    configuration = nil
    configurationContinuation.yield(nil)
  }

  public init() {
    do {
      if let uuid = keychain.get("session_uuid") {
        self.ATProtoKeychain = AppleSecureKeychain(identifier: .init(uuidString: uuid) ?? UUID())
      } else {
        let newUUID = UUID().uuidString
        keychain.set(newUUID, forKey: "session_uuid")
        self.ATProtoKeychain = AppleSecureKeychain(identifier: .init(uuidString: newUUID) ?? UUID())
      }

      var continuation: AsyncStream<ATProtocolConfiguration?>.Continuation!
      self.configurationUpdates = AsyncStream { cont in
        continuation = cont
      }
      self.configurationContinuation = continuation
    } catch {
      print("Auth initialization failed: \(error)")
      // Fallback to safe defaults
      self.ATProtoKeychain = AppleSecureKeychain(identifier: UUID())
      var continuation: AsyncStream<ATProtocolConfiguration?>.Continuation!
      self.configurationUpdates = AsyncStream { cont in
        continuation = cont
      }
      self.configurationContinuation = continuation
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

  public var errorDescription: String? {
    switch self {
    case .noActiveSession:
      return "No active session found. Please sign in again."
    }
  }

}

extension UserSession: @retroactive Equatable {
  public static func == (lhs: UserSession, rhs: UserSession) -> Bool {
    lhs.sessionDID == rhs.sessionDID
  }
}
