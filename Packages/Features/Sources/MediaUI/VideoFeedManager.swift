import AVKit
import SwiftUI

@MainActor
public final class VideoFeedManager: ObservableObject {
  public static let shared = VideoFeedManager()

  @Published public var isAutoplayEnabled: Bool = true
  @Published public var isMutedByDefault: Bool = true
  @Published public var maxConcurrentVideos: Int = 2

  private var activePlayers: [String: AVPlayer] = [:]
  private var visibleVideos: Set<String> = []

  private init() {
    loadPreferences()
  }

  public func shouldAutoplayVideo(_ videoId: String) -> Bool {
    guard isAutoplayEnabled else { return false }
    guard activePlayers.count < maxConcurrentVideos else { return false }
    return visibleVideos.contains(videoId)
  }

  public func registerVideoAsVisible(_ videoId: String) {
    visibleVideos.insert(videoId)
  }

  public func unregisterVideoAsVisible(_ videoId: String) {
    visibleVideos.remove(videoId)
  }

  public func registerActivePlayer(_ player: AVPlayer, for videoId: String) {
    activePlayers[videoId] = player
  }

  public func unregisterActivePlayer(for videoId: String) {
    activePlayers.removeValue(forKey: videoId)
  }

  public func pauseAllVideos() {
    activePlayers.values.forEach { $0.pause() }
  }

  public func resumeAllVideos() {
    activePlayers.values.forEach { $0.play() }
  }

  public func cleanupInactivePlayers() {
    let inactiveVideos = Set(activePlayers.keys).subtracting(visibleVideos)
    inactiveVideos.forEach { videoId in
      if let player = activePlayers[videoId] {
        player.pause()
        activePlayers.removeValue(forKey: videoId)
      }
    }
  }

  private func loadPreferences() {
    isAutoplayEnabled = UserDefaults.standard.bool(forKey: "VideoFeedAutoplayEnabled")
    isMutedByDefault = UserDefaults.standard.bool(forKey: "VideoFeedMutedByDefault")
    maxConcurrentVideos = UserDefaults.standard.integer(forKey: "VideoFeedMaxConcurrent")

    if UserDefaults.standard.object(forKey: "VideoFeedAutoplayEnabled") == nil {
      isAutoplayEnabled = true
      UserDefaults.standard.set(true, forKey: "VideoFeedAutoplayEnabled")
    }

    if UserDefaults.standard.object(forKey: "VideoFeedMutedByDefault") == nil {
      isMutedByDefault = true
      UserDefaults.standard.set(true, forKey: "VideoFeedMutedByDefault")
    }

    if maxConcurrentVideos == 0 {
      maxConcurrentVideos = 2
      UserDefaults.standard.set(2, forKey: "VideoFeedMaxConcurrent")
    }
  }

  public func updateAutoplayEnabled(_ enabled: Bool) {
    isAutoplayEnabled = enabled
    UserDefaults.standard.set(enabled, forKey: "VideoFeedAutoplayEnabled")

    if !enabled {
      pauseAllVideos()
    }
  }

  public func updateMutedByDefault(_ muted: Bool) {
    isMutedByDefault = muted
    UserDefaults.standard.set(muted, forKey: "VideoFeedMutedByDefault")

    activePlayers.values.forEach { $0.isMuted = muted }
  }

  public func updateMaxConcurrentVideos(_ max: Int) {
    maxConcurrentVideos = max
    UserDefaults.standard.set(max, forKey: "VideoFeedMaxConcurrent")

    if activePlayers.count > max {
      let excessCount = activePlayers.count - max
      let playersToPause = Array(activePlayers.values.prefix(excessCount))
      playersToPause.forEach { $0.pause() }
    }
  }
}

private struct VideoFeedManagerKey: EnvironmentKey {
  static let defaultValue: VideoFeedManager? = nil
}

extension EnvironmentValues {
  public var videoFeedManager: VideoFeedManager {
    get {
      // Check if we have a stored value first
      if let stored = self[VideoFeedManagerKey.self] {
        return stored
      }
      // If no stored value, we need to handle this carefully
      // Since VideoFeedManager.shared is main actor-isolated, we'll return nil
      // and let the caller handle the main actor access
      fatalError("VideoFeedManager must be explicitly provided in the environment")
    }
    set {
      self[VideoFeedManagerKey.self] = newValue
    }
  }
}
