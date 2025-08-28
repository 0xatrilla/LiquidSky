import CloudKit
import Foundation
import SwiftUI

@Observable
class CloudKitSyncService {
  static let shared = CloudKitSyncService()

  private let container = CKContainer(identifier: "iCloud.Liquidsky")
  private let privateDatabase: CKDatabase
  private let publicDatabase: CKDatabase

  var isSignedInToiCloud = false
  var syncStatus: SyncStatus = .idle
  var lastSyncDate: Date?
  var errorMessage: String?

  enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed
  }

  private init() {
    self.privateDatabase = container.privateCloudDatabase
    self.publicDatabase = container.publicCloudDatabase

    checkiCloudStatus()
    setupNotificationObservers()
  }

  private func checkiCloudStatus() {
    container.accountStatus { [weak self] status, error in
      DispatchQueue.main.async {
        self?.isSignedInToiCloud = status == .available
        if status != .available {
          self?.errorMessage = "iCloud not available: \(status?.description ?? "Unknown")"
        }
      }
    }
  }

  private func setupNotificationObservers() {
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.CKAccountChanged,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.checkiCloudStatus()
    }
  }

  // MARK: - User Preferences Sync

  func syncUserPreferences(_ preferences: [String: Any]) async {
    guard isSignedInToiCloud else {
      await MainActor.run {
        syncStatus = .failed
        errorMessage = "iCloud not available"
      }
      return
    }

    await MainActor.run {
      syncStatus = .syncing
    }

    do {
      let record = CKRecord(recordType: "UserPreferences")
      record["userId"] = getCurrentUserId()
      record["preferences"] = preferences
      record["lastModified"] = Date()

      try await privateDatabase.save(record)

      await MainActor.run {
        syncStatus = .completed
        lastSyncDate = Date()
        errorMessage = nil
      }

      print("CloudKitSyncService: User preferences synced successfully")
    } catch {
      await MainActor.run {
        syncStatus = .failed
        errorMessage = error.localizedDescription
      }
      print("CloudKitSyncService: Failed to sync user preferences: \(error)")
    }
  }

  func fetchUserPreferences() async -> [String: Any]? {
    guard isSignedInToiCloud else { return nil }

    do {
      let predicate = NSPredicate(format: "userId == %@", getCurrentUserId())
      let query = CKQuery(recordType: "UserPreferences", predicate: predicate)
      query.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]

      let result = try await privateDatabase.records(matching: query)
      let records = result.matchResults.compactMap { try? $0.1.get() }

      guard let record = records.first else { return nil }

      return record["preferences"] as? [String: Any]
    } catch {
      print("CloudKitSyncService: Failed to fetch user preferences: \(error)")
      return nil
    }
  }

  // MARK: - Feed Subscriptions Sync

  func syncFeedSubscriptions(_ feeds: [String]) async {
    guard isSignedInToiCloud else { return }

    do {
      let record = CKRecord(recordType: "FeedSubscriptions")
      record["userId"] = getCurrentUserId()
      record["feeds"] = feeds
      record["lastModified"] = Date()

      try await privateDatabase.save(record)
      print("CloudKitSyncService: Feed subscriptions synced successfully")
    } catch {
      print("CloudKitSyncService: Failed to sync feed subscriptions: \(error)")
    }
  }

  func fetchFeedSubscriptions() async -> [String]? {
    guard isSignedInToiCloud else { return nil }

    do {
      let predicate = NSPredicate(format: "userId == %@", getCurrentUserId())
      let query = CKQuery(recordType: "FeedSubscriptions", predicate: predicate)

      let result = try await privateDatabase.records(matching: query)
      let records = result.matchResults.compactMap { try? $0.1.get() }

      guard let record = records.first else { return nil }

      return record["feeds"] as? [String]
    } catch {
      print("CloudKitSyncService: Failed to fetch feed subscriptions: \(error)")
      return nil
    }
  }

  // MARK: - User Block List Sync

  func syncBlockList(_ blockedUsers: [String]) async {
    guard isSignedInToiCloud else { return }

    do {
      let record = CKRecord(recordType: "BlockList")
      record["userId"] = getCurrentUserId()
      record["blockedUsers"] = blockedUsers
      record["lastModified"] = Date()

      try await privateDatabase.save(record)
      print("CloudKitSyncService: Block list synced successfully")
    } catch {
      print("CloudKitSyncService: Failed to sync block list: \(error)")
    }
  }

  func fetchBlockList() async -> [String]? {
    guard isSignedInToiCloud else { return nil }

    do {
      let predicate = NSPredicate(format: "userId == %@", getCurrentUserId())
      let query = CKQuery(recordType: "BlockList", predicate: predicate)

      let result = try await privateDatabase.records(matching: query)
      let records = result.matchResults.compactMap { try? $0.1.get() }

      guard let record = records.first else { return nil }

      return record["blockedUsers"] as? [String]
    } catch {
      print("CloudKitSyncService: Failed to fetch block list: \(error)")
      return nil
    }
  }

  // MARK: - Utility Methods

  private func getCurrentUserId() -> String {
    // Use a unique identifier for the current user
    // This could be the Bluesky DID or a generated UUID
    return UserDefaults.standard.string(forKey: "currentUserId") ?? UUID().uuidString
  }

  func setCurrentUserId(_ userId: String) {
    UserDefaults.standard.set(userId, forKey: "currentUserId")
  }

  func performFullSync() async {
    await MainActor.run {
      syncStatus = .syncing
    }

    // Sync all user data
    let preferences = UserDefaults.standard.dictionaryRepresentation()
    await syncUserPreferences(preferences)

    // TODO: Sync other data types as needed

    await MainActor.run {
      syncStatus = .completed
      lastSyncDate = Date()
    }
  }

  func resetSync() {
    lastSyncDate = nil
    syncStatus = .idle
    errorMessage = nil
  }
}

// MARK: - CloudKit Record Types
extension CKRecord.RecordType {
  static let userPreferences = "UserPreferences"
  static let feedSubscriptions = "FeedSubscriptions"
  static let blockList = "BlockList"
}
