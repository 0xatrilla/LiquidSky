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
      print("Initializing ATProtoKit...")
      self.protoClient = await ATProtoKit(sessionConfiguration: configuration)
      print("ATProtoKit initialized successfully")
      self.blueskyClient = ATProtoBluesky(atProtoKitInstance: protoClient)
      print("ATProtoBluesky initialized successfully")
    } catch {
      print("BSkyClient initialization failed: \(error)")
      throw error
    }
  }
}

extension ATProtoKit: @unchecked @retroactive Sendable {}
extension ATProtoBluesky: @unchecked @retroactive Sendable {}
