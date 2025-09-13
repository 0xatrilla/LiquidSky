import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
@Observable
@MainActor
class MemoryManagementSystem {
  var currentMemoryUsage: Double = 0.0
  var memoryWarningLevel: MemoryWarningLevel = .normal
  var isOptimizing = false

  // Memory pools
  var glassEffectPool = ObjectPool<GlassEffectState>(factory: {
    GlassEffectState(id: UUID().uuidString)
  })
  var viewPool = ObjectPool<ViewState>(factory: { ViewState(id: UUID().uuidString) })
  var imageCache = ImageMemoryCache()

  // Cleanup managers
  var automaticCleanup = AutomaticCleanupManager()
  var backgroundTaskManager = BackgroundTaskManager()

  // Memory thresholds (in MB)
  private let warningThreshold: Double = 500.0
  private let criticalThreshold: Double = 800.0
  private let maxMemoryUsage: Double = 1000.0

  // Monitoring
  private var memoryTimer: Timer?
  private var memoryHistory: [MemorySnapshot] = []

  init() {
    startMemoryMonitoring()
    setupMemoryWarningObserver()
  }

  deinit {
    Task { @MainActor [weak self] in
      await self?.stopMemoryMonitoring()
    }
  }

  private func startMemoryMonitoring() {
    memoryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      self?.updateMemoryMetrics()
    }
  }

  private func stopMemoryMonitoring() {
    memoryTimer?.invalidate()
    memoryTimer = nil
  }

  private func setupMemoryWarningObserver() {
    NotificationCenter.default.addObserver(
      forName: UIApplication.didReceiveMemoryWarningNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleMemoryWarning()
    }
  }

  private func updateMemoryMetrics() {
    currentMemoryUsage = getCurrentMemoryUsage()

    let snapshot = MemorySnapshot(
      timestamp: Date(),
      memoryUsage: currentMemoryUsage,
      glassEffectCount: glassEffectPool.activeCount,
      viewCount: viewPool.activeCount,
      imageCacheSize: imageCache.currentSize
    )

    memoryHistory.append(snapshot)

    // Keep only last 50 snapshots
    if memoryHistory.count > 50 {
      memoryHistory.removeFirst()
    }

    updateMemoryWarningLevel()

    if memoryWarningLevel != .normal {
      performMemoryOptimization()
    }
  }

  private func updateMemoryWarningLevel() {
    let previousLevel = memoryWarningLevel

    if currentMemoryUsage > criticalThreshold {
      memoryWarningLevel = .critical
    } else if currentMemoryUsage > warningThreshold {
      memoryWarningLevel = .warning
    } else {
      memoryWarningLevel = .normal
    }

    if memoryWarningLevel != previousLevel {
      NotificationCenter.default.post(
        name: .memoryWarningLevelChanged,
        object: nil,
        userInfo: [
          "level": memoryWarningLevel,
          "usage": currentMemoryUsage,
        ]
      )
    }
  }

  private func handleMemoryWarning() {
    memoryWarningLevel = .critical
    performAggressiveCleanup()
  }

  private func performMemoryOptimization() {
    guard !isOptimizing else { return }

    isOptimizing = true

    Task {
      await performCleanup(level: memoryWarningLevel)
      isOptimizing = false
    }
  }

  private func performAggressiveCleanup() {
    Task {
      await performCleanup(level: .critical)
    }
  }

  private func performCleanup(level: MemoryWarningLevel) async {
    switch level {
    case .normal:
      break

    case .warning:
      // Moderate cleanup
      imageCache.clearLowPriorityImages()
      glassEffectPool.releaseInactive()
      viewPool.releaseInactive()

    case .critical:
      // Aggressive cleanup
      imageCache.clearAll()
      glassEffectPool.releaseAll()
      viewPool.releaseAll()

      // Force garbage collection
      await forceGarbageCollection()
    }

    NotificationCenter.default.post(
      name: .memoryCleanupCompleted,
      object: nil,
      userInfo: ["level": level]
    )
  }

  private func forceGarbageCollection() async {
    // Trigger garbage collection by creating and releasing objects
    for _ in 0..<10 {
      autoreleasepool {
        _ = Array(0..<1000).map { _ in UUID() }
      }

      try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms
    }
  }

  private func getCurrentMemoryUsage() -> Double {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(
          mach_task_self_,
          task_flavor_t(MACH_TASK_BASIC_INFO),
          $0,
          &count)
      }
    }

    if kerr == KERN_SUCCESS {
      return Double(info.resident_size) / 1024.0 / 1024.0  // MB
    }

    return 0.0
  }

  func getMemoryMetrics() -> MemoryMetrics {
    MemoryMetrics(
      currentUsage: currentMemoryUsage,
      warningLevel: memoryWarningLevel,
      glassEffectCount: glassEffectPool.activeCount,
      viewCount: viewPool.activeCount,
      imageCacheSize: imageCache.currentSize,
      trend: getMemoryTrend()
    )
  }

  private func getMemoryTrend() -> MemoryTrend {
    guard memoryHistory.count >= 10 else { return .stable }

    let recent = Array(memoryHistory.suffix(10))
    let averageUsage = recent.map { $0.memoryUsage }.reduce(0, +) / Double(recent.count)
    let oldAverage =
      Array(memoryHistory.prefix(10)).map { $0.memoryUsage }.reduce(0, +)
      / Double(min(10, memoryHistory.count))

    let change = averageUsage - oldAverage

    if change > 50 {
      return .increasing
    } else if change < -50 {
      return .decreasing
    } else {
      return .stable
    }
  }
}

// MARK: - Object Pool

@available(iPadOS 26.0, *)
class ObjectPool<T: AnyObject> {
  private var pool: [T] = []
  private var activeObjects: Set<ObjectIdentifier> = []
  private let maxPoolSize: Int
  private let createObject: () -> T

  var activeCount: Int { activeObjects.count }

  init(maxSize: Int = 50, factory: @escaping () -> T) {
    self.maxPoolSize = maxSize
    self.createObject = factory
  }

  func acquire() -> T {
    if let object = pool.popLast() {
      activeObjects.insert(ObjectIdentifier(object))
      return object
    } else {
      let object = createObject()
      activeObjects.insert(ObjectIdentifier(object))
      return object
    }
  }

  func release(_ object: T) {
    let identifier = ObjectIdentifier(object)
    activeObjects.remove(identifier)

    if pool.count < maxPoolSize {
      pool.append(object)
    }
  }

  func releaseInactive() {
    pool.removeAll()
  }

  func releaseAll() {
    pool.removeAll()
    activeObjects.removeAll()
  }
}

// MARK: - Image Memory Cache

@available(iPadOS 26.0, *)
@Observable
@MainActor
class ImageMemoryCache {
  private var cache: [String: CachedImage] = [:]
  private var accessTimes: [String: Date] = [:]
  private var priorities: [String: ContentPriority] = [:]

  private let maxCacheSize: Int = 50 * 1024 * 1024  // 50MB
  var currentSize: Int = 0

  func cacheImage(_ image: UIImage, forKey key: String, priority: ContentPriority = .normal) {
    let imageData = image.pngData() ?? Data()
    let cachedImage = CachedImage(
      image: image,
      size: imageData.count,
      timestamp: Date()
    )

    cache[key] = cachedImage
    accessTimes[key] = Date()
    priorities[key] = priority
    currentSize += cachedImage.size

    cleanupIfNeeded()
  }

  func getImage(forKey key: String) -> UIImage? {
    guard let cachedImage = cache[key] else { return nil }

    accessTimes[key] = Date()
    return cachedImage.image
  }

  func clearLowPriorityImages() {
    let lowPriorityKeys = priorities.compactMap { key, priority in
      priority == .low ? key : nil
    }

    for key in lowPriorityKeys {
      removeImage(forKey: key)
    }
  }

  func clearAll() {
    cache.removeAll()
    accessTimes.removeAll()
    priorities.removeAll()
    currentSize = 0
  }

  private func cleanupIfNeeded() {
    guard currentSize > maxCacheSize else { return }

    let sortedKeys = cache.keys.sorted { key1, key2 in
      let priority1 = priorities[key1] ?? .normal
      let priority2 = priorities[key2] ?? .normal

      if priority1 != priority2 {
        return priority1.rawValue < priority2.rawValue
      }

      let time1 = accessTimes[key1] ?? Date.distantPast
      let time2 = accessTimes[key2] ?? Date.distantPast
      return time1 < time2
    }

    let keysToRemove = sortedKeys.prefix(cache.count / 3)
    for key in keysToRemove {
      removeImage(forKey: key)
    }
  }

  private func removeImage(forKey key: String) {
    if let cachedImage = cache[key] {
      currentSize -= cachedImage.size
    }

    cache.removeValue(forKey: key)
    accessTimes.removeValue(forKey: key)
    priorities.removeValue(forKey: key)
  }
}

// MARK: - Automatic Cleanup Manager

@available(iPadOS 26.0, *)
@MainActor
class AutomaticCleanupManager {
  private var cleanupTimer: Timer?
  private let cleanupInterval: TimeInterval = 30.0  // 30 seconds

  init() {
    startAutomaticCleanup()
  }

  deinit {
    Task { @MainActor [weak self] in
      await self?.stopAutomaticCleanup()
    }
  }

  private func startAutomaticCleanup() {
    cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { _ in
      self.performRoutineCleanup()
    }
  }

  private func stopAutomaticCleanup() {
    cleanupTimer?.invalidate()
    cleanupTimer = nil
  }

  private func performRoutineCleanup() {
    NotificationCenter.default.post(
      name: .performRoutineCleanup,
      object: nil
    )
  }
}

// MARK: - Background Task Manager

@available(iPadOS 26.0, *)
@MainActor
class BackgroundTaskManager {
  private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid

  func startBackgroundTask() {
    backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
      self?.endBackgroundTask()
    }
  }

  func endBackgroundTask() {
    if backgroundTaskId != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTaskId)
      backgroundTaskId = .invalid
    }
  }

  func performBackgroundCleanup() {
    startBackgroundTask()

    Task {
      // Perform cleanup operations
      await performCleanupOperations()
      endBackgroundTask()
    }
  }

  private func performCleanupOperations() async {
    // Simulate cleanup operations
    try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
  }
}

// MARK: - Data Models

@available(iPadOS 26.0, *)
enum MemoryWarningLevel: Int, CaseIterable {
  case normal = 0
  case warning = 1
  case critical = 2

  var displayName: String {
    switch self {
    case .normal: return "Normal"
    case .warning: return "Warning"
    case .critical: return "Critical"
    }
  }

  var color: Color {
    switch self {
    case .normal: return .green
    case .warning: return .orange
    case .critical: return .red
    }
  }
}

@available(iPadOS 26.0, *)
enum MemoryTrend {
  case increasing
  case stable
  case decreasing

  var color: Color {
    switch self {
    case .increasing: return .red
    case .stable: return .blue
    case .decreasing: return .green
    }
  }

  var icon: String {
    switch self {
    case .increasing: return "arrow.up.circle.fill"
    case .stable: return "minus.circle.fill"
    case .decreasing: return "arrow.down.circle.fill"
    }
  }
}

@available(iPadOS 26.0, *)
struct MemoryMetrics {
  let currentUsage: Double
  let warningLevel: MemoryWarningLevel
  let glassEffectCount: Int
  let viewCount: Int
  let imageCacheSize: Int
  let trend: MemoryTrend
}

@available(iPadOS 26.0, *)
struct MemorySnapshot {
  let timestamp: Date
  let memoryUsage: Double
  let glassEffectCount: Int
  let viewCount: Int
  let imageCacheSize: Int
}

@available(iPadOS 26.0, *)
struct CachedImage {
  let image: UIImage
  let size: Int
  let timestamp: Date
}

@available(iPadOS 26.0, *)
class GlassEffectState {
  let id: String
  var isActive: Bool = false
  var lastUsed: Date = Date()

  init(id: String, isActive: Bool = false, lastUsed: Date = Date()) {
    self.id = id
    self.isActive = isActive
    self.lastUsed = lastUsed
  }
}

@available(iPadOS 26.0, *)
class ViewState {
  let id: String
  var isVisible: Bool = false
  var lastAccessed: Date = Date()

  init(id: String, isVisible: Bool = false, lastAccessed: Date = Date()) {
    self.id = id
    self.isVisible = isVisible
    self.lastAccessed = lastAccessed
  }
}

// MARK: - Environment Key

@available(iPadOS 26.0, *)
struct MemoryManagementSystemKey: EnvironmentKey {
  static let defaultValue = MemoryManagementSystem()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var memoryManagementSystem: MemoryManagementSystem {
    get { self[MemoryManagementSystemKey.self] }
    set { self[MemoryManagementSystemKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let memoryWarningLevelChanged = Notification.Name("memoryWarningLevelChanged")
  static let memoryCleanupCompleted = Notification.Name("memoryCleanupCompleted")
  static let performRoutineCleanup = Notification.Name("performRoutineCleanup")
}
