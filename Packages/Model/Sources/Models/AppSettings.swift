import Foundation
import SwiftUI

// MARK: - App Settings Model
@Observable
public final class AppSettings {
  // MARK: - Display Settings
  public var useSystemTheme: Bool {
    didSet { UserDefaults.standard.set(useSystemTheme, forKey: "useSystemTheme") }
  }

  public var selectedAppIcon: AppIcon {
    didSet { UserDefaults.standard.set(selectedAppIcon.rawValue, forKey: "selectedAppIcon") }
  }

  public var selectedTheme: AppTheme {
    didSet { UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme") }
  }

  public var selectedColorTheme: ColorTheme {
    didSet { UserDefaults.standard.set(selectedColorTheme.rawValue, forKey: "selectedColorTheme") }
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

  // MARK: - Intelligence Settings
  public var aiSummariesEnabled: Bool {
    didSet { UserDefaults.standard.set(aiSummariesEnabled, forKey: "aiSummariesEnabled") }
  }

  // Device experimental gate for Apple Intelligence usage on physical devices
  public var aiDeviceExperimentalEnabled: Bool {
    didSet {
      UserDefaults.standard.set(aiDeviceExperimentalEnabled, forKey: "aiDeviceExperimentalEnabled")
    }
  }

  // MARK: - Media Settings
  public var imageQuality: ImageQuality {
    didSet { UserDefaults.standard.set(imageQuality.rawValue, forKey: "imageQuality") }
  }

  public var preloadImages: Bool {
    didSet { UserDefaults.standard.set(preloadImages, forKey: "preloadImages") }
  }

  // MARK: - Haptic Feedback Settings
  public var hapticFeedbackEnabled: Bool {
    didSet { UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled") }
  }

  // MARK: - Tab Bar Settings
  // Array of AppTab raw values representing the visible tabs in order
  public var tabBarTabsRaw: [String] {
    didSet { UserDefaults.standard.set(tabBarTabsRaw, forKey: "tabBarTabs") }
  }

  // MARK: - Initialization
  public init() {
    // Load saved settings or use defaults
    self.useSystemTheme = UserDefaults.standard.object(forKey: "useSystemTheme") as? Bool ?? true
    self.selectedAppIcon =
      AppIcon(rawValue: UserDefaults.standard.string(forKey: "selectedAppIcon") ?? "cloud")
      ?? .cloud
    self.selectedTheme =
      AppTheme(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? "system")
      ?? .system
    self.selectedColorTheme =
      ColorTheme(rawValue: UserDefaults.standard.string(forKey: "selectedColorTheme") ?? "bluesky")
      ?? .bluesky
    self.showTimestamps = UserDefaults.standard.object(forKey: "showTimestamps") as? Bool ?? true
    self.compactMode = UserDefaults.standard.object(forKey: "compactMode") as? Bool ?? false
    self.autoPlayVideos = UserDefaults.standard.object(forKey: "autoPlayVideos") as? Bool ?? true
    self.showSensitiveContent =
      UserDefaults.standard.object(forKey: "showSensitiveContent") as? Bool ?? false
    self.aiSummariesEnabled =
      UserDefaults.standard.object(forKey: "aiSummariesEnabled") as? Bool ?? false
    self.aiDeviceExperimentalEnabled =
      UserDefaults.standard.object(forKey: "aiDeviceExperimentalEnabled") as? Bool ?? false
    self.imageQuality =
      ImageQuality(rawValue: UserDefaults.standard.string(forKey: "imageQuality") ?? "high")
      ?? .high
    self.preloadImages = UserDefaults.standard.object(forKey: "preloadImages") as? Bool ?? true
    self.hapticFeedbackEnabled =
      UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true

    // Default tab order without Messages
    let defaultTabs = ["feed", "notification", "profile", "settings", "compose"]
    self.tabBarTabsRaw =
      UserDefaults.standard.array(forKey: "tabBarTabs") as? [String] ?? defaultTabs
  }

  // MARK: - Helper Methods
  private func updateNotificationSettings() {
    // This would integrate with UNUserNotificationCenter
    // For now, just a placeholder for future implementation
  }

  public func resetToDefaults() {
    useSystemTheme = true
    selectedAppIcon = .cloud
    selectedTheme = .system
    selectedColorTheme = .bluesky
    showTimestamps = true
    compactMode = false
    autoPlayVideos = true
    showSensitiveContent = false
    aiSummariesEnabled = false
    aiDeviceExperimentalEnabled = false
    imageQuality = .high
    preloadImages = true
    hapticFeedbackEnabled = true
    tabBarTabsRaw = ["feed", "notification", "profile", "settings", "compose"]
  }
}

// MARK: - Supporting Enums
public enum AppIcon: String, CaseIterable {
  case cloud = "AppIcon"
  case og = "AppIcon2"
  case blueprint = "AppIcon3"
  case butterfly = "AppIcon4"
  case rain = "AppIcon5"

  public var displayName: String {
    switch self {
    case .cloud: return "Cloud"
    case .og: return "OG"
    case .blueprint: return "Blueprint"
    case .butterfly: return "Butterfly"
    case .rain: return "Rain"
    }
  }

  public var previewImageName: String {
    switch self {
    case .cloud: return "cloud"
    case .og: return "OG"
    case .blueprint: return "Blueprint"
    case .butterfly: return "butterfly"
    case .rain: return "rain"
    }
  }

  public var iconName: String? {
    switch self {
    case .cloud: return nil  // nil means use the primary app icon
    case .og: return "AppIcon2"
    case .blueprint: return "AppIcon3"
    case .butterfly: return "AppIcon4"
    case .rain: return "AppIcon5"
    }
  }
}

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

public enum ColorTheme: String, CaseIterable {
  case bluesky = "bluesky"
  case sunset = "sunset"
  case forest = "forest"
  case ocean = "ocean"
  case lavender = "lavender"
  case fire = "fire"

  public var displayName: String {
    switch self {
    case .bluesky: return "Bluesky Blue"
    case .sunset: return "Sunset Orange"
    case .forest: return "Forest Green"
    case .ocean: return "Ocean Teal"
    case .lavender: return "Lavender Purple"
    case .fire: return "Fire Red"
    }
  }

  public var description: String {
    switch self {
    case .bluesky: return "Official Bluesky blue theme"
    case .sunset: return "Warm orange and red tones"
    case .forest: return "Natural green and brown tones"
    case .ocean: return "Cool blue and teal tones"
    case .lavender: return "Soft purple and pink tones"
    case .fire: return "Bold red and orange tones"
    }
  }

  public var icon: String {
    switch self {
    case .bluesky: return "paintbrush.fill"
    case .sunset: return "sunset.fill"
    case .forest: return "leaf.fill"
    case .ocean: return "drop.fill"
    case .lavender: return "sparkles"
    case .fire: return "flame.fill"
    }
  }
}
