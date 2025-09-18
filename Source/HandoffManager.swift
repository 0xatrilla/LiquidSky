import CoreSpotlight
import Foundation
import SwiftUI

@available(iOS 18.0, *)
@Observable
class HandoffManager {
  // Handoff state
  var isHandoffEnabled = true
  var currentUserActivity: NSUserActivity?
  var handoffIndicatorVisible = false

  // Activity types
  private let activityTypes = HandoffActivityType.allCases.map { $0.rawValue }

  // State restoration
  var restorationData: [String: Any] = [:]
  var pendingRestoration: HandoffRestoration?

  // Cross-device synchronization
  var syncManager: CrossDeviceSyncManager

  init() {
    self.syncManager = CrossDeviceSyncManager()
    setupHandoffSupport()
  }

  private func setupHandoffSupport() {
    // Register supported activity types
    registerActivityTypes()

    // Setup restoration handling
    setupRestorationHandling()

    // Start sync manager
    syncManager.delegate = self
    syncManager.startSynchronization()
  }

  private func registerActivityTypes() {
    // In a real app, these would be registered in Info.plist
    // NSUserActivityTypes array
  }

  private func setupRestorationHandling() {
    NotificationCenter.default.addObserver(
      forName: UIApplication.willResignActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.saveCurrentState()
    }

    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleAppActivation()
    }
  }

  // MARK: - User Activity Management

  func createUserActivity(for type: HandoffActivityType, with data: [String: Any]) -> NSUserActivity
  {
    let activity = NSUserActivity(activityType: type.rawValue)

    activity.title = type.displayTitle
    activity.userInfo = data
    activity.isEligibleForHandoff = true
    activity.isEligibleForSearch = type.isSearchable
    activity.isEligibleForPublicIndexing = false

    // Add glass effect specific metadata
    var glassEffectData: [String: Any] = [:]
    glassEffectData["glassEffectEnabled"] = true
    glassEffectData["liquidGlassVersion"] = "1.0"
    glassEffectData["timestamp"] = Date().timeIntervalSince1970

    activity.addUserInfoEntries(from: glassEffectData)

    // Set content attributes for search
    if type.isSearchable {
      let attributes = CSSearchableItemAttributeSet(itemContentType: type.contentType)
      attributes.title = type.displayTitle
      attributes.contentDescription = type.description
      activity.contentAttributeSet = attributes
    }

    currentUserActivity = activity
    return activity
  }

  func updateCurrentActivity(with data: [String: Any]) {
    guard let activity = currentUserActivity else { return }

    var updatedUserInfo = activity.userInfo ?? [:]
    updatedUserInfo.merge(data) { _, new in new }
    updatedUserInfo["lastUpdated"] = Date().timeIntervalSince1970

    activity.userInfo = updatedUserInfo
    activity.needsSave = true
  }

  func invalidateCurrentActivity() {
    currentUserActivity?.invalidate()
    currentUserActivity = nil
  }

  // MARK: - State Management

  func saveCurrentState() {
    guard isHandoffEnabled else { return }

    // Collect current app state
    let state: [String: Any] = [
      "selectedTab": getCurrentSelectedTab(),
      "navigationPath": getCurrentNavigationPath(),
      "contentState": getCurrentContentState(),
      "glassEffectState": getCurrentGlassEffectState(),
      "timestamp": Date().timeIntervalSince1970,
    ]

    restorationData = state

    // Create or update user activity
    let activity = createUserActivity(for: .browsing, with: state)
    activity.becomeCurrent()

    // Sync with other devices
    syncManager.syncState(state)
  }

  private func getCurrentSelectedTab() -> String {
    // In a real implementation, this would get the current tab from navigation state
    return "feed"
  }

  private func getCurrentNavigationPath() -> [String] {
    // In a real implementation, this would get the current navigation path
    return []
  }

  private func getCurrentContentState() -> [String: Any] {
    // In a real implementation, this would get the current content state
    return [:]
  }

  private func getCurrentGlassEffectState() -> [String: Any] {
    return [
      "effectsEnabled": true,
      "interactiveMode": true,
      "performanceMode": "standard",
    ]
  }

  // MARK: - State Restoration

  func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
    guard let activityType = HandoffActivityType(rawValue: userActivity.activityType),
      let userInfo = userActivity.userInfo
    else {
      return false
    }

    let restoration = HandoffRestoration(
      activityType: activityType,
      userInfo: userInfo as? [String: Any] ?? [:],
      timestamp: Date()
    )

    pendingRestoration = restoration

    // Show handoff indicator
    showHandoffIndicator()

    // Perform restoration
    return performStateRestoration(restoration)
  }

  private func performStateRestoration(_ restoration: HandoffRestoration) -> Bool {
    switch restoration.activityType {
    case .browsing:
      return restoreBrowsingState(restoration.userInfo)
    case .reading:
      return restoreReadingState(restoration.userInfo)
    case .composing:
      return restoreComposingState(restoration.userInfo)
    case .searching:
      return restoreSearchingState(restoration.userInfo)
    }
  }

  private func restoreBrowsingState(_ userInfo: [String: Any]) -> Bool {
    guard let selectedTab = userInfo["selectedTab"] as? String else { return false }

    // Restore navigation state
    NotificationCenter.default.post(
      name: .handoffRestoreNavigation,
      object: nil,
      userInfo: ["selectedTab": selectedTab]
    )

    // Restore glass effect state
    if let glassEffectState = userInfo["glassEffectState"] as? [String: Any] {
      NotificationCenter.default.post(
        name: .handoffRestoreGlassEffects,
        object: nil,
        userInfo: glassEffectState
      )
    }

    return true
  }

  private func restoreReadingState(_ userInfo: [String: Any]) -> Bool {
    guard let postId = userInfo["postId"] as? String else { return false }

    NotificationCenter.default.post(
      name: .handoffRestoreReading,
      object: nil,
      userInfo: ["postId": postId]
    )

    return true
  }

  private func restoreComposingState(_ userInfo: [String: Any]) -> Bool {
    guard let draftText = userInfo["draftText"] as? String else { return false }

    NotificationCenter.default.post(
      name: .handoffRestoreComposing,
      object: nil,
      userInfo: ["draftText": draftText]
    )

    return true
  }

  private func restoreSearchingState(_ userInfo: [String: Any]) -> Bool {
    guard let searchQuery = userInfo["searchQuery"] as? String else { return false }

    NotificationCenter.default.post(
      name: .handoffRestoreSearch,
      object: nil,
      userInfo: ["searchQuery": searchQuery]
    )

    return true
  }

  private func handleAppActivation() {
    // Check for pending restoration
    if let restoration = pendingRestoration {
      performStateRestoration(restoration)
      pendingRestoration = nil
    }
  }

  // MARK: - UI Indicators

  private func showHandoffIndicator() {
    withAnimation(.smooth(duration: 0.3)) {
      handoffIndicatorVisible = true
    }

    // Auto-hide after 3 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      withAnimation(.smooth(duration: 0.3)) {
        self.handoffIndicatorVisible = false
      }
    }
  }

  // MARK: - Content Synchronization

  func syncContent(_ content: SyncableContent) {
    syncManager.syncContent(content)
  }

  func requestContentSync(for contentId: String) {
    syncManager.requestSync(for: contentId)
  }
}

// MARK: - Cross-Device Sync Manager

@available(iOS 18.0, *)
class CrossDeviceSyncManager {
  weak var delegate: CrossDeviceSyncDelegate?

  private var syncQueue = DispatchQueue(label: "com.liquidsky.sync", qos: .utility)
  private var pendingSyncs: [String: SyncableContent] = [:]

  func startSynchronization() {
    // In a real implementation, this would setup CloudKit or other sync mechanism
  }

  func syncState(_ state: [String: Any]) {
    syncQueue.async {
      // Implement state synchronization
      self.delegate?.didSyncState(state)
    }
  }

  func syncContent(_ content: SyncableContent) {
    syncQueue.async {
      self.pendingSyncs[content.id] = content
      // Implement content synchronization
      self.delegate?.didSyncContent(content)
    }
  }

  func requestSync(for contentId: String) {
    syncQueue.async {
      // Implement sync request
      if let content = self.pendingSyncs[contentId] {
        self.delegate?.didReceiveSyncRequest(for: content)
      }
    }
  }
}

// MARK: - Data Models

@available(iOS 18.0, *)
enum HandoffActivityType: String, CaseIterable {
  case browsing = "com.liquidsky.browsing"
  case reading = "com.liquidsky.reading"
  case composing = "com.liquidsky.composing"
  case searching = "com.liquidsky.searching"

  var displayTitle: String {
    switch self {
    case .browsing: return "Browsing Feed"
    case .reading: return "Reading Post"
    case .composing: return "Composing Post"
    case .searching: return "Searching"
    }
  }

  var description: String {
    switch self {
    case .browsing: return "Browse your social media feed with Liquid Glass effects"
    case .reading: return "Read a post with enhanced glass interface"
    case .composing: return "Compose a new post with glass effects"
    case .searching: return "Search content with glass interface"
    }
  }

  var isSearchable: Bool {
    switch self {
    case .browsing, .searching: return true
    case .reading, .composing: return false
    }
  }

  var contentType: String {
    return "com.liquidsky.activity"
  }
}

@available(iOS 18.0, *)
struct HandoffRestoration {
  let activityType: HandoffActivityType
  let userInfo: [String: Any]
  let timestamp: Date
}

@available(iOS 18.0, *)
struct SyncableContent {
  let id: String
  let type: ContentType
  let data: [String: Any]
  let timestamp: Date

  enum ContentType {
    case post, draft, bookmark, preference
  }
}

@available(iOS 18.0, *)
protocol CrossDeviceSyncDelegate: AnyObject {
  func didSyncState(_ state: [String: Any])
  func didSyncContent(_ content: SyncableContent)
  func didReceiveSyncRequest(for content: SyncableContent)
}

// MARK: - CrossDeviceSyncDelegate Implementation

@available(iOS 18.0, *)
extension HandoffManager: CrossDeviceSyncDelegate {
  func didSyncState(_ state: [String: Any]) {
    DispatchQueue.main.async {
      NotificationCenter.default.post(
        name: .handoffStateSynced,
        object: nil,
        userInfo: state
      )
    }
  }

  func didSyncContent(_ content: SyncableContent) {
    DispatchQueue.main.async {
      NotificationCenter.default.post(
        name: .handoffContentSynced,
        object: nil,
        userInfo: ["content": content]
      )
    }
  }

  func didReceiveSyncRequest(for content: SyncableContent) {
    DispatchQueue.main.async {
      NotificationCenter.default.post(
        name: .handoffSyncRequested,
        object: nil,
        userInfo: ["content": content]
      )
    }
  }
}

// MARK: - Handoff Indicator View

@available(iOS 18.0, *)
struct HandoffIndicatorView: View {
  @Environment(\.handoffManager) var handoffManager

  var body: some View {
    if handoffManager.handoffIndicatorVisible {
      HStack(spacing: 8) {
        Image(systemName: "arrow.triangle.2.circlepath")
          .font(.caption)
          .foregroundStyle(.blue)

        Text("Continuing from another device")
          .font(.caption.weight(.medium))
          .foregroundStyle(.primary)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(.ultraThinMaterial, in: Capsule())
      .transition(.move(edge: .top).combined(with: .opacity))
    }
  }
}

// MARK: - Environment Key

@available(iOS 18.0, *)
struct HandoffManagerKey: EnvironmentKey {
  static let defaultValue = HandoffManager()
}

@available(iOS 18.0, *)
extension EnvironmentValues {
  var handoffManager: HandoffManager {
    get { self[HandoffManagerKey.self] }
    set { self[HandoffManagerKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let handoffRestoreNavigation = Notification.Name("handoffRestoreNavigation")
  static let handoffRestoreGlassEffects = Notification.Name("handoffRestoreGlassEffects")
  static let handoffRestoreReading = Notification.Name("handoffRestoreReading")
  static let handoffRestoreComposing = Notification.Name("handoffRestoreComposing")
  static let handoffRestoreSearch = Notification.Name("handoffRestoreSearch")
  static let handoffStateSynced = Notification.Name("handoffStateSynced")
  static let handoffContentSynced = Notification.Name("handoffContentSynced")
  static let handoffSyncRequested = Notification.Name("handoffSyncRequested")
}

// MARK: - Core Spotlight Support

@available(iOS 18.0, *)
extension HandoffManager {
  func indexContentForSpotlight(_ content: SyncableContent) {
    let attributeSet = CSSearchableItemAttributeSet(itemContentType: "com.liquidsky.content")

    switch content.type {
    case .post:
      attributeSet.title = content.data["title"] as? String ?? "Post"
      attributeSet.contentDescription = content.data["content"] as? String
    case .draft:
      attributeSet.title = "Draft: \(content.data["title"] as? String ?? "Untitled")"
      attributeSet.contentDescription = content.data["content"] as? String
    case .bookmark:
      attributeSet.title = "Bookmark: \(content.data["title"] as? String ?? "Untitled")"
    case .preference:
      attributeSet.title = "Settings"
    }

    attributeSet.keywords = ["LiquidSky", "Glass", "Social"]

    let item = CSSearchableItem(
      uniqueIdentifier: content.id,
      domainIdentifier: "com.liquidsky.content",
      attributeSet: attributeSet
    )

    CSSearchableIndex.default().indexSearchableItems([item]) { error in
      if let error = error {
        print("Spotlight indexing error: \(error)")
      }
    }
  }
}
