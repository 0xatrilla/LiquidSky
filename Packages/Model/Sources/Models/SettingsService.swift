import Foundation
import SwiftUI

// MARK: - Settings Service
@MainActor
@Observable
public final class SettingsService {
  public static let shared = SettingsService()

  public private(set) var settings: AppSettings

  private init() {
    self.settings = AppSettings()
  }

  public func refreshSettings() {
    self.settings = AppSettings()
  }

  public func resetAllSettings() {
    settings.resetToDefaults()
  }

  // MARK: - Convenience Accessors
  public var useSystemTheme: Bool {
    get { settings.useSystemTheme }
    set { settings.useSystemTheme = newValue }
  }

  public var selectedAppIcon: AppIcon {
    get { settings.selectedAppIcon }
    set { settings.selectedAppIcon = newValue }
  }

  public var selectedTheme: AppTheme {
    get { settings.selectedTheme }
    set { settings.selectedTheme = newValue }
  }

  public var selectedColorTheme: ColorTheme {
    get { settings.selectedColorTheme }
    set { settings.selectedColorTheme = newValue }
  }

  public var showTimestamps: Bool {
    get { settings.showTimestamps }
    set { settings.showTimestamps = newValue }
  }

  public var compactMode: Bool {
    get { settings.compactMode }
    set { settings.compactMode = newValue }
  }

  public var autoPlayVideos: Bool {
    get { settings.autoPlayVideos }
    set { settings.autoPlayVideos = newValue }
  }

  public var showSensitiveContent: Bool {
    get { settings.showSensitiveContent }
    set { settings.showSensitiveContent = newValue }
  }

  public var imageQuality: ImageQuality {
    get { settings.imageQuality }
    set { settings.imageQuality = newValue }
  }

  public var preloadImages: Bool {
    get { settings.preloadImages }
    set { settings.preloadImages = newValue }
  }

  public var hapticFeedbackEnabled: Bool {
    get { settings.hapticFeedbackEnabled }
    set {
      settings.hapticFeedbackEnabled = newValue
      // Note: HapticManager will be updated when the setting is accessed
    }
  }

  // MARK: - Tab Bar Settings
  public var tabBarTabsRaw: [String] {
    get { settings.tabBarTabsRaw }
    set { settings.tabBarTabsRaw = newValue }
  }

  public var aiSummariesEnabled: Bool {
    get { settings.aiSummariesEnabled }
    set { settings.aiSummariesEnabled = newValue }
  }

  public var aiDeviceExperimentalEnabled: Bool {
    get { settings.aiDeviceExperimentalEnabled }
    set { settings.aiDeviceExperimentalEnabled = newValue }
  }
}
