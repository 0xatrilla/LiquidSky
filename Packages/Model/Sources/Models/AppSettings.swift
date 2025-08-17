import Foundation
import SwiftUI

// MARK: - App Settings Model
@Observable
public final class AppSettings {
  // MARK: - Display Settings
  public var useSystemTheme: Bool {
    didSet { UserDefaults.standard.set(useSystemTheme, forKey: "useSystemTheme") }
  }

  public var selectedTheme: AppTheme {
    didSet { UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme") }
  }

  public var showTimestamps: Bool {
    didSet { UserDefaults.standard.set(showTimestamps, forKey: "showTimestamps") }
  }

  public var compactMode: Bool {
    didSet { UserDefaults.standard.set(compactMode, forKey: "compactMode") }
  }

  // MARK: - Content Settings
  public var autoPlayVideos: Bool {
    didSet { UserDefaults.standard.set(autoPlayVideos, forKey: "autoPlayVideos") }
  }

  public var showSensitiveContent: Bool {
    didSet { UserDefaults.standard.set(showSensitiveContent, forKey: "showSensitiveContent") }
  }

  // MARK: - Media Settings
  public var imageQuality: ImageQuality {
    didSet { UserDefaults.standard.set(imageQuality.rawValue, forKey: "imageQuality") }
  }

  public var preloadImages: Bool {
    didSet { UserDefaults.standard.set(preloadImages, forKey: "preloadImages") }
  }

  // MARK: - Initialization
  public init() {
    // Load saved settings or use defaults
    self.useSystemTheme = UserDefaults.standard.object(forKey: "useSystemTheme") as? Bool ?? true
    self.selectedTheme =
      AppTheme(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? "system")
      ?? .system
    self.showTimestamps = UserDefaults.standard.object(forKey: "showTimestamps") as? Bool ?? true
    self.compactMode = UserDefaults.standard.object(forKey: "compactMode") as? Bool ?? false
    self.autoPlayVideos = UserDefaults.standard.object(forKey: "autoPlayVideos") as? Bool ?? true
    self.showSensitiveContent =
      UserDefaults.standard.object(forKey: "showSensitiveContent") as? Bool ?? false
    self.imageQuality =
      ImageQuality(rawValue: UserDefaults.standard.string(forKey: "imageQuality") ?? "high")
      ?? .high
    self.preloadImages = UserDefaults.standard.object(forKey: "preloadImages") as? Bool ?? true
  }

  // MARK: - Helper Methods
  private func updateNotificationSettings() {
    // This would integrate with UNUserNotificationCenter
    // For now, just a placeholder for future implementation
  }

  public func resetToDefaults() {
    useSystemTheme = true
    selectedTheme = .system
    showTimestamps = true
    compactMode = false
    autoPlayVideos = true
    showSensitiveContent = false
    imageQuality = .high
    preloadImages = true
  }
}

// MARK: - Supporting Enums
public enum AppTheme: String, CaseIterable {
  case system = "system"
  case light = "light"
  case dark = "dark"

  public var displayName: String {
    switch self {
    case .system: return "System"
    case .light: return "Light"
    case .dark: return "Dark"
    }
  }

  public var icon: String {
    switch self {
    case .system: return "gear"
    case .light: return "sun.max.fill"
    case .dark: return "moon.fill"
    }
  }
}

public enum ImageQuality: String, CaseIterable {
  case low = "low"
  case medium = "medium"
  case high = "high"

  public var displayName: String {
    switch self {
    case .low: return "Low"
    case .medium: return "Medium"
    case .high: return "High"
    }
  }

  public var description: String {
    switch self {
    case .low: return "Faster loading, lower quality"
    case .medium: return "Balanced performance"
    case .high: return "Best quality, slower loading"
    }
  }
}
