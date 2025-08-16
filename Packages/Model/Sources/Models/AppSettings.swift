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
    
    public var enablePushNotifications: Bool {
        didSet { 
            UserDefaults.standard.set(enablePushNotifications, forKey: "enablePushNotifications")
            updateNotificationSettings()
        }
    }
    
    public var enableEmailNotifications: Bool {
        didSet { UserDefaults.standard.set(enableEmailNotifications, forKey: "enableEmailNotifications") }
    }
    
    // MARK: - Privacy Settings
    public var allowMentions: Bool {
        didSet { UserDefaults.standard.set(allowMentions, forKey: "allowMentions") }
    }
    
    public var allowReplies: Bool {
        didSet { UserDefaults.standard.set(allowReplies, forKey: "allowReplies") }
    }
    
    public var allowQuotes: Bool {
        didSet { UserDefaults.standard.set(allowQuotes, forKey: "allowQuotes") }
    }
    
    // MARK: - Feed Settings
    public var defaultFeed: String {
        didSet { UserDefaults.standard.set(defaultFeed, forKey: "defaultFeed") }
    }
    
    public var showReposts: Bool {
        didSet { UserDefaults.standard.set(showReposts, forKey: "showReposts") }
    }
    
    public var showReplies: Bool {
        didSet { UserDefaults.standard.set(showReplies, forKey: "showReplies") }
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
        self.selectedTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? "system") ?? .system
        self.showTimestamps = UserDefaults.standard.object(forKey: "showTimestamps") as? Bool ?? true
        self.compactMode = UserDefaults.standard.object(forKey: "compactMode") as? Bool ?? false
        self.autoPlayVideos = UserDefaults.standard.object(forKey: "autoPlayVideos") as? Bool ?? true
        self.showSensitiveContent = UserDefaults.standard.object(forKey: "showSensitiveContent") as? Bool ?? false
        self.enablePushNotifications = UserDefaults.standard.object(forKey: "enablePushNotifications") as? Bool ?? true
        self.enableEmailNotifications = UserDefaults.standard.object(forKey: "enableEmailNotifications") as? Bool ?? false
        self.allowMentions = UserDefaults.standard.object(forKey: "allowMentions") as? Bool ?? true
        self.allowReplies = UserDefaults.standard.object(forKey: "allowReplies") as? Bool ?? true
        self.allowQuotes = UserDefaults.standard.object(forKey: "allowQuotes") as? Bool ?? true
        self.defaultFeed = UserDefaults.standard.string(forKey: "defaultFeed") ?? "following"
        self.showReposts = UserDefaults.standard.object(forKey: "showReposts") as? Bool ?? true
        self.showReplies = UserDefaults.standard.object(forKey: "showReplies") as? Bool ?? true
        self.imageQuality = ImageQuality(rawValue: UserDefaults.standard.string(forKey: "imageQuality") ?? "high") ?? .high
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
        enablePushNotifications = true
        enableEmailNotifications = false
        allowMentions = true
        allowReplies = true
        allowQuotes = true
        defaultFeed = "following"
        showReposts = true
        showReplies = true
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
