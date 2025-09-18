import Foundation
import SwiftUI

@available(iOS 18.0, *)
@Observable
@MainActor
class LazyContentManager {
  var loadedContent: [String: Any] = [:]
  var loadingStates: [String: LoadingState] = [:]
  var contentPriorities: [String: ContentPriority] = [:]

  // Cache management
  var cacheManager = ContentCacheManager()
  var preloadManager = ContentPreloadManager()

  // Performance settings
  var maxConcurrentLoads = 5
  var currentLoadCount = 0
  var loadingQueue: [ContentLoadRequest] = []

  // Viewport tracking
  var visibleContentIds: Set<String> = []
  var nearVisibleContentIds: Set<String> = []

  init() {
    setupPerformanceMonitoring()
  }

  private func setupPerformanceMonitoring() {
    NotificationCenter.default.addObserver(
      forName: .optimizeGlassEffects,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.optimizeContentLoading()
    }
  }

  func loadContent<T>(
    id: String,
    priority: ContentPriority = .normal,
    loader: @escaping () async throws -> T
  ) async -> T? {
    // Check cache first
    if let cachedContent = cacheManager.getCachedContent(id: id) as? T {
      return cachedContent
    }

    // Check if already loading
    if loadingStates[id] == .loading {
      return await waitForExistingLoad(id: id)
    }

    // Start loading
    loadingStates[id] = .loading
    contentPriorities[id] = priority

    do {
      let content = try await loader()
      loadedContent[id] = content
      loadingStates[id] = .loaded

      // Cache the content
      cacheManager.cacheContent(id: id, content: content)

      return content
    } catch {
      loadingStates[id] = .failed(error)
      return nil
    }
  }

  private func waitForExistingLoad<T>(id: String) async -> T? {
    // Wait for existing load to complete
    while loadingStates[id] == .loading {
      try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms
    }

    return loadedContent[id] as? T
  }

  func preloadContent(ids: [String]) {
    preloadManager.schedulePreload(ids: ids, priority: .low)
  }

  func updateVisibleContent(ids: Set<String>) {
    visibleContentIds = ids

    // Update cache priorities
    cacheManager.updatePriorities(visibleIds: ids)

    // Schedule preloading for near-visible content
    scheduleNearVisiblePreload()
  }

  private func scheduleNearVisiblePreload() {
    let preloadIds = nearVisibleContentIds.subtracting(visibleContentIds)
    preloadManager.schedulePreload(ids: Array(preloadIds), priority: .low)
  }

  private func optimizeContentLoading() {
    // Reduce concurrent loads during performance issues
    maxConcurrentLoads = max(2, maxConcurrentLoads - 1)

    // Clear low-priority cache items
    cacheManager.clearLowPriorityItems()

    // Cancel low-priority loads
    cancelLowPriorityLoads()
  }

  private func cancelLowPriorityLoads() {
    loadingQueue.removeAll { request in
      request.priority == .low
    }
  }

  func clearCache() {
    cacheManager.clearAll()
    loadedContent.removeAll()
    loadingStates.removeAll()
  }
}

// MARK: - Content Cache Manager

@available(iOS 18.0, *)
@Observable
class ContentCacheManager {
  private var cache: [String: CachedItem] = [:]
  private var accessTimes: [String: Date] = [:]
  private var priorities: [String: ContentPriority] = [:]

  // Cache limits
  private let maxCacheSize: Int = 100 * 1024 * 1024  // 100MB
  private let maxItemCount: Int = 1000
  private var currentCacheSize: Int = 0

  func cacheContent<T>(id: String, content: T, priority: ContentPriority = .normal) {
    let item = CachedItem(
      id: id,
      content: content,
      size: estimateSize(of: content),
      timestamp: Date()
    )

    cache[id] = item
    accessTimes[id] = Date()
    priorities[id] = priority
    currentCacheSize += item.size

    // Cleanup if needed
    cleanupCacheIfNeeded()
  }

  func getCachedContent(id: String) -> Any? {
    guard let item = cache[id] else { return nil }

    // Update access time
    accessTimes[id] = Date()

    return item.content
  }

  func updatePriorities(visibleIds: Set<String>) {
    // Increase priority for visible content
    for id in visibleIds {
      priorities[id] = .high
    }

    // Decrease priority for non-visible content
    for id in cache.keys {
      if !visibleIds.contains(id) {
        priorities[id] = .low
      }
    }
  }

  func clearLowPriorityItems() {
    let lowPriorityIds = priorities.compactMap { key, priority in
      priority == .low ? key : nil
    }

    for id in lowPriorityIds {
      removeCachedItem(id: id)
    }
  }

  func clearAll() {
    cache.removeAll()
    accessTimes.removeAll()
    priorities.removeAll()
    currentCacheSize = 0
  }

  private func cleanupCacheIfNeeded() {
    guard currentCacheSize > maxCacheSize || cache.count > maxItemCount else { return }

    // Sort by access time and priority
    let sortedIds = cache.keys.sorted { id1, id2 in
      let priority1 = priorities[id1] ?? .normal
      let priority2 = priorities[id2] ?? .normal

      if priority1 != priority2 {
        return priority1.rawValue < priority2.rawValue
      }

      let time1 = accessTimes[id1] ?? Date.distantPast
      let time2 = accessTimes[id2] ?? Date.distantPast
      return time1 < time2
    }

    // Remove oldest, lowest priority items
    let itemsToRemove = sortedIds.prefix(cache.count / 4)
    for id in itemsToRemove {
      removeCachedItem(id: id)
    }
  }

  private func removeCachedItem(id: String) {
    if let item = cache[id] {
      currentCacheSize -= item.size
    }

    cache.removeValue(forKey: id)
    accessTimes.removeValue(forKey: id)
    priorities.removeValue(forKey: id)
  }

  private func estimateSize<T>(of content: T) -> Int {
    // Simplified size estimation
    if content is String {
      return (content as! String).utf8.count
    } else if content is Data {
      return (content as! Data).count
    } else if content is UIImage {
      return 1024 * 1024  // Estimate 1MB for images
    } else {
      return 1024  // Default 1KB estimate
    }
  }
}

// MARK: - Content Preload Manager

@available(iOS 18.0, *)
@Observable
class ContentPreloadManager {
  private var preloadQueue: [PreloadRequest] = []
  private var isPreloading = false
  private let maxPreloadConcurrency = 2

  func schedulePreload(ids: [String], priority: ContentPriority) {
    let requests = ids.map { id in
      PreloadRequest(id: id, priority: priority, timestamp: Date())
    }

    preloadQueue.append(contentsOf: requests)

    if !isPreloading {
      startPreloading()
    }
  }

  private func startPreloading() {
    isPreloading = true

    Task {
      while !preloadQueue.isEmpty {
        let batch = Array(preloadQueue.prefix(maxPreloadConcurrency))
        preloadQueue.removeFirst(min(maxPreloadConcurrency, preloadQueue.count))

        await withTaskGroup(of: Void.self) { group in
          for request in batch {
            group.addTask {
              await self.preloadContent(request: request)
            }
          }
        }
      }

      isPreloading = false
    }
  }

  private func preloadContent(request: PreloadRequest) async {
    // Simulate content preloading
    try? await Task.sleep(nanoseconds: 500_000_000)  // 500ms

    NotificationCenter.default.post(
      name: .contentPreloaded,
      object: nil,
      userInfo: ["contentId": request.id]
    )
  }
}

// MARK: - Lazy Content Column

@available(iOS 18.0, *)
struct LazyContentColumn<Content: View>: View {
  let content: Content
  let contentId: String
  let loadingPlaceholder: AnyView?

  @Environment(\.lazyContentManager) var contentManager
  @State private var isVisible = false
  @State private var loadingState: LoadingState = .notLoaded

  init(
    contentId: String,
    loadingPlaceholder: AnyView? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.contentId = contentId
    self.loadingPlaceholder = loadingPlaceholder
    self.content = content()
  }

  var body: some View {
    Group {
      switch loadingState {
      case .notLoaded, .loading:
        loadingPlaceholder ?? AnyView(defaultLoadingView)
      case .loaded:
        content
      case .failed:
        errorView
      }
    }
    .onAppear {
      isVisible = true
      contentManager.updateVisibleContent(ids: [contentId])
      loadContent()
    }
    .onDisappear {
      isVisible = false
    }
  }

  private var defaultLoadingView: some View {
    GestureAwareGlassCard(cornerRadius: 12, isInteractive: false) {
      VStack(spacing: 12) {
        ProgressView()
          .scaleEffect(1.2)

        Text("Loading...")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .padding(20)
    }
  }

  private var errorView: some View {
    GestureAwareGlassCard(cornerRadius: 12, isInteractive: true) {
      VStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle")
          .font(.title2)
          .foregroundStyle(.orange)

        Text("Failed to load content")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Button("Retry") {
          loadContent()
        }
        .buttonStyle(.borderedProminent)
      }
      .padding(20)
    }
  }

  private func loadContent() {
    loadingState = .loading

    Task {
      let result = await contentManager.loadContent(id: contentId) {
        // Simulate content loading
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        return "Loaded content for \(contentId)"
      }

      await MainActor.run {
        loadingState = result != nil ? .loaded : .failed(ContentLoadError.loadingFailed)
      }
    }
  }
}

// MARK: - Data Models

@available(iOS 18.0, *)
enum LoadingState: Equatable {
  case notLoaded
  case loading
  case loaded
  case failed(Error)

  static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
    switch (lhs, rhs) {
    case (.notLoaded, .notLoaded), (.loading, .loading), (.loaded, .loaded):
      return true
    case (.failed, .failed):
      return true
    default:
      return false
    }
  }
}

@available(iOS 18.0, *)
struct CachedItem {
  let id: String
  let content: Any
  let size: Int
  let timestamp: Date
}

@available(iOS 18.0, *)
struct ContentLoadRequest {
  let id: String
  let priority: ContentPriority
  let timestamp: Date
}

@available(iOS 18.0, *)
struct PreloadRequest {
  let id: String
  let priority: ContentPriority
  let timestamp: Date
}

@available(iOS 18.0, *)
enum ContentLoadError: Error, LocalizedError {
  case loadingFailed
  case networkError
  case cacheError

  var errorDescription: String? {
    switch self {
    case .loadingFailed: return "Failed to load content"
    case .networkError: return "Network error"
    case .cacheError: return "Cache error"
    }
  }
}

// MARK: - Environment Key

@available(iOS 18.0, *)
struct LazyContentManagerKey: EnvironmentKey {
  static let defaultValue = LazyContentManager()
}

@available(iOS 18.0, *)
extension EnvironmentValues {
  var lazyContentManager: LazyContentManager {
    get { self[LazyContentManagerKey.self] }
    set { self[LazyContentManagerKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let contentPreloaded = Notification.Name("contentPreloaded")
}
