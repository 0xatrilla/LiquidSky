@preconcurrency import ATProtoKit
import SwiftUI

@Observable
public final class BSkyClient: Sendable {
  public let configuration: ATProtocolConfiguration
  public let protoClient: ATProtoKit
  public let blueskyClient: ATProtoBluesky

  public init(configuration: ATProtocolConfiguration) async throws {
    self.configuration = configuration
    do {
      #if DEBUG
      print("Initializing ATProtoKit...")
      #endif
      self.protoClient = await ATProtoKit(sessionConfiguration: configuration)
      #if DEBUG
      print("ATProtoKit initialized successfully")
      #endif
      self.blueskyClient = ATProtoBluesky(atProtoKitInstance: protoClient)
      #if DEBUG
      print("ATProtoBluesky initialized successfully")
      #endif
    } catch {
      #if DEBUG
      print("BSkyClient initialization failed: \(error)")
      #endif
      throw error
    }
  }
}

extension ATProtoKit: @unchecked @retroactive Sendable {}
extension ATProtoBluesky: @unchecked @retroactive Sendable {}
