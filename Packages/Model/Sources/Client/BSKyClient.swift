@preconcurrency import ATProtoKit
import SwiftUI

@Observable
public final class BSkyClient: Sendable {
  public let configuration: ATProtocolConfiguration
  public let protoClient: ATProtoKit
  public let blueskyClient: ATProtoBluesky

  public init(configuration: ATProtocolConfiguration) async throws {
    self.configuration = configuration
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
  }
}

