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
    
    public var selectedTheme: AppTheme {
        get { settings.selectedTheme }
        set { settings.selectedTheme = newValue }
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
    
    public var enablePushNotifications: Bool {
        get { settings.enablePushNotifications }
        set { settings.enablePushNotifications = newValue }
    }
    
    public var enableEmailNotifications: Bool {
        get { settings.enableEmailNotifications }
        set { settings.enableEmailNotifications = newValue }
    }
    
    public var allowMentions: Bool {
        get { settings.allowMentions }
        set { settings.allowMentions = newValue }
    }
    
    public var allowReplies: Bool {
        get { settings.allowReplies }
        set { settings.allowReplies = newValue }
    }
    
    public var allowQuotes: Bool {
        get { settings.allowQuotes }
        set { settings.allowQuotes = newValue }
    }
    
    public var defaultFeed: String {
        get { settings.defaultFeed }
        set { settings.defaultFeed = newValue }
    }
    
    public var showReposts: Bool {
        get { settings.showReposts }
        set { settings.showReposts = newValue }
    }
    
    public var showReplies: Bool {
        get { settings.showReplies }
        set { settings.showReplies = newValue }
    }
    
    public var imageQuality: ImageQuality {
        get { settings.imageQuality }
        set { settings.imageQuality = newValue }
    }
    
    public var preloadImages: Bool {
        get { settings.preloadImages }
        set { settings.preloadImages = newValue }
    }
}


