import ATProtoKit
import Foundation
import Client

@Observable
public final class ReportingService: Sendable {
  private let client: BSkyClient
  
  public init(client: BSkyClient) {
    self.client = client
  }
  
  // MARK: - Report Operations
  
  /// Report a post to Bluesky
  public func reportPost(uri: String, cid: String, reason: String) async throws {
    // TODO: Implement proper reporting using ATProtoKit
    // For now, this is a placeholder implementation
    #if DEBUG
    print("ReportingService: Would report post \(uri) for reason: \(reason)")
    #endif
  }
  
  /// Report a user to Bluesky
  public func reportUser(did: String, reason: String) async throws {
    // TODO: Implement proper reporting using ATProtoKit
    // For now, this is a placeholder implementation
    #if DEBUG
    print("ReportingService: Would report user \(did) for reason: \(reason)")
    #endif
  }
  
  // MARK: - Helper Methods
  
  private func mapToBlueskyReason(_ reason: String) -> String {
    switch reason.lowercased() {
    case "spam":
      return "com.atproto.moderation.defs#reasonSpam"
    case "harassment":
      return "com.atproto.moderation.defs#reasonHarassment"
    case "hate speech":
      return "com.atproto.moderation.defs#reasonRude"
    case "violence":
      return "com.atproto.moderation.defs#reasonViolence"
    case "inappropriate content":
      return "com.atproto.moderation.defs#reasonSexual"
    case "misinformation":
      return "com.atproto.moderation.defs#reasonMisleading"
    case "other":
      return "com.atproto.moderation.defs#reasonOther"
    default:
      return "com.atproto.moderation.defs#reasonOther"
    }
  }
}

// MARK: - Error Types

public enum ReportingError: Error, LocalizedError {
  case noSession
  case reportFailed(Error)
  
  public var errorDescription: String? {
    switch self {
    case .noSession:
      return "No active session found"
    case .reportFailed(let error):
      return "Failed to submit report: \(error.localizedDescription)"
    }
  }
}