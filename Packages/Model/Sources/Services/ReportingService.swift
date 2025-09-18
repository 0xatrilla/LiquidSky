import ATProtoKit
import Foundation

@Observable
public final class ReportingService: Sendable {
  private let client: BSkyClient
  
  public init(client: BSkyClient) {
    self.client = client
  }
  
  // MARK: - Report Operations
  
  /// Report a post to Bluesky
  public func reportPost(uri: String, cid: String, reason: String) async throws {
    do {
      // Get the current user's session
      guard let session = try await client.protoClient.getUserSession() else {
        throw ReportingError.noSession
      }
      
      // Map UI reason to Bluesky's internal reason
      let blueskyReason = mapToBlueskyReason(reason)
      
      // Create the report record
      let reportRecord = ComAtprotoLexicon.Moderation.CreateReportRequest(
        reasonType: blueskyReason,
        subject: ComAtprotoLexicon.Moderation.CreateReportRequest.Subject(
          recordURI: uri,
          cid: cid
        ),
        reason: reason
      )
      
      // Submit the report using XRPC
      let response = try await client.protoClient.createRecord(
        repositoryDID: session.sessionDID,
        collection: "com.atproto.moderation.report",
        record: reportRecord
      )
      
      #if DEBUG
      print("ReportingService: Successfully reported post \(uri) for reason: \(reason)")
      print("ReportingService: Response: \(response)")
      #endif
      
    } catch {
      #if DEBUG
      print("ReportingService: Failed to report post: \(error)")
      #endif
      throw ReportingError.failedToReport(error.localizedDescription)
    }
  }
  
  /// Report a user to Bluesky
  public func reportUser(did: String, reason: String) async throws {
    do {
      // Get the current user's session
      guard let session = try await client.protoClient.getUserSession() else {
        throw ReportingError.noSession
      }
      
      // Map UI reason to Bluesky's internal reason
      let blueskyReason = mapToBlueskyReason(reason)
      
      // Create the report record
      let reportRecord = ComAtprotoLexicon.Moderation.CreateReportRequest(
        reasonType: blueskyReason,
        subject: ComAtprotoLexicon.Moderation.CreateReportRequest.Subject(
          actorDID: did
        ),
        reason: reason
      )
      
      // Submit the report using XRPC
      let response = try await client.protoClient.createRecord(
        repositoryDID: session.sessionDID,
        collection: "com.atproto.moderation.report",
        record: reportRecord
      )
      
      #if DEBUG
      print("ReportingService: Successfully reported user \(did) for reason: \(reason)")
      print("ReportingService: Response: \(response)")
      #endif
      
    } catch {
      #if DEBUG
      print("ReportingService: Failed to report user: \(error)")
      #endif
      throw ReportingError.failedToReport(error.localizedDescription)
    }
  }
  
  // MARK: - Helper Methods
  
  private func mapToBlueskyReason(_ uiReason: String) -> String {
    switch uiReason {
    case "Spam":
      return "com.atproto.moderation.defs#reasonSpam"
    case "Harassment or bullying":
      return "com.atproto.moderation.defs#reasonHarassment"
    case "False information":
      return "com.atproto.moderation.defs#reasonMisleading"
    case "Violence or threats":
      return "com.atproto.moderation.defs#reasonViolence"
    case "Inappropriate content":
      return "com.atproto.moderation.defs#reasonSexual"
    case "Other":
      return "com.atproto.moderation.defs#reasonOther"
    default:
      return "com.atproto.moderation.defs#reasonOther"
    }
  }
}

// MARK: - Error Types

public enum ReportingError: Error, LocalizedError {
  case noSession
  case failedToReport(String)
  
  public var errorDescription: String? {
    switch self {
    case .noSession:
      return "No valid session found"
    case .failedToReport(let message):
      return "Failed to submit report: \(message)"
    }
  }
}
