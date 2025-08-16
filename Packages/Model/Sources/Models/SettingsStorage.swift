import Foundation

// MARK: - Settings Storage Service
@MainActor
public final class SettingsStorage {
    public static let shared = SettingsStorage()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let useSystemTheme = "useSystemTheme"
        static let selectedTheme = "selectedTheme"
        static let showTimestamps = "showTimestamps"
        static let compactMode = "compactMode"
        static let autoPlayVideos = "autoPlayVideos"
        static let showSensitiveContent = "showSensitiveContent"
        static let enablePushNotifications = "enablePushNotifications"
        static let enableEmailNotifications = "enableEmailNotifications"
        static let allowMentions = "allowMentions"
        static let allowReplies = "allowReplies"
        static let allowQuotes = "allowQuotes"
        static let defaultFeed = "defaultFeed"
        static let showReposts = "showReposts"
        static let showReplies = "showReplies"
        static let imageQuality = "imageQuality"
        static let preloadImages = "preloadImages"
    }
    
    // MARK: - Default Values
    private enum Defaults {
        static let useSystemTheme = true
        static let selectedTheme = "system"
        static let showTimestamps = true
        static let compactMode = false
        static let autoPlayVideos = true
        static let showSensitiveContent = false
        static let enablePushNotifications = true
        static let enableEmailNotifications = false
        static let allowMentions = true
        static let allowReplies = true
        static let allowQuotes = true
        static let defaultFeed = "following"
        static let showReposts = true
        static let showReplies = true
        static let imageQuality = "high"
        static let preloadImages = true
    }
    
    // MARK: - Getters
    public func getUseSystemTheme() -> Bool {
        userDefaults.object(forKey: Keys.useSystemTheme) as? Bool ?? Defaults.useSystemTheme
    }
    
    public func getSelectedTheme() -> String {
        userDefaults.string(forKey: Keys.selectedTheme) ?? Defaults.selectedTheme
    }
    
    public func getShowTimestamps() -> Bool {
        userDefaults.object(forKey: Keys.showTimestamps) as? Bool ?? Defaults.showTimestamps
    }
    
    public func getCompactMode() -> Bool {
        userDefaults.object(forKey: Keys.compactMode) as? Bool ?? Defaults.compactMode
    }
    
    public func getAutoPlayVideos() -> Bool {
        userDefaults.object(forKey: Keys.autoPlayVideos) as? Bool ?? Defaults.autoPlayVideos
    }
    
    public func getShowSensitiveContent() -> Bool {
        userDefaults.object(forKey: Keys.showSensitiveContent) as? Bool ?? Defaults.showSensitiveContent
    }
    
    public func getEnablePushNotifications() -> Bool {
        userDefaults.object(forKey: Keys.enablePushNotifications) as? Bool ?? Defaults.enablePushNotifications
    }
    
    public func getEnableEmailNotifications() -> Bool {
        userDefaults.object(forKey: Keys.enableEmailNotifications) as? Bool ?? Defaults.enableEmailNotifications
    }
    
    public func getAllowMentions() -> Bool {
        userDefaults.object(forKey: Keys.allowMentions) as? Bool ?? Defaults.allowMentions
    }
    
    public func getAllowReplies() -> Bool {
        userDefaults.object(forKey: Keys.allowReplies) as? Bool ?? Defaults.allowReplies
    }
    
    public func getAllowQuotes() -> Bool {
        userDefaults.object(forKey: Keys.allowQuotes) as? Bool ?? Defaults.allowQuotes
    }
    
    public func getDefaultFeed() -> String {
        userDefaults.string(forKey: Keys.defaultFeed) ?? Defaults.defaultFeed
    }
    
    public func getShowReposts() -> Bool {
        userDefaults.object(forKey: Keys.showReposts) as? Bool ?? Defaults.showReposts
    }
    
    public func getShowReplies() -> Bool {
        userDefaults.object(forKey: Keys.showReplies) as? Bool ?? Defaults.showReplies
    }
    
    public func getImageQuality() -> String {
        userDefaults.string(forKey: Keys.imageQuality) ?? Defaults.imageQuality
    }
    
    public func getPreloadImages() -> Bool {
        userDefaults.object(forKey: Keys.preloadImages) as? Bool ?? Defaults.preloadImages
    }
    
    // MARK: - Setters
    public func setUseSystemTheme(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.useSystemTheme)
    }
    
    public func setSelectedTheme(_ value: String) {
        userDefaults.set(value, forKey: Keys.selectedTheme)
    }
    
    public func setShowTimestamps(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.showTimestamps)
    }
    
    public func setCompactMode(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.compactMode)
    }
    
    public func setAutoPlayVideos(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.autoPlayVideos)
    }
    
    public func setShowSensitiveContent(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.showSensitiveContent)
    }
    
    public func setEnablePushNotifications(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.enablePushNotifications)
    }
    
    public func setEnableEmailNotifications(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.enableEmailNotifications)
    }
    
    public func setAllowMentions(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.allowMentions)
    }
    
    public func setAllowReplies(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.allowReplies)
    }
    
    public func setAllowQuotes(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.allowQuotes)
    }
    
    public func setDefaultFeed(_ value: String) {
        userDefaults.set(value, forKey: Keys.defaultFeed)
    }
    
    public func setShowReposts(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.showReposts)
    }
    
    public func setShowReplies(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.showReplies)
    }
    
    public func setImageQuality(_ value: String) {
        userDefaults.set(value, forKey: Keys.imageQuality)
    }
    
    public func setPreloadImages(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.preloadImages)
    }
    
    // MARK: - Reset
    public func resetToDefaults() {
        setUseSystemTheme(Defaults.useSystemTheme)
        setSelectedTheme(Defaults.selectedTheme)
        setShowTimestamps(Defaults.showTimestamps)
        setCompactMode(Defaults.compactMode)
        setAutoPlayVideos(Defaults.autoPlayVideos)
        setShowSensitiveContent(Defaults.showSensitiveContent)
        setEnablePushNotifications(Defaults.enablePushNotifications)
        setEnableEmailNotifications(Defaults.enableEmailNotifications)
        setAllowMentions(Defaults.allowMentions)
        setAllowReplies(Defaults.allowReplies)
        setAllowQuotes(Defaults.allowQuotes)
        setDefaultFeed(Defaults.defaultFeed)
        setShowReposts(Defaults.showReposts)
        setShowReplies(Defaults.showReplies)
        setImageQuality(Defaults.imageQuality)
        setPreloadImages(Defaults.preloadImages)
    }
    
    // MARK: - Migration
    public func migrateIfNeeded() {
        // Check if we need to migrate from old settings format
        // This can be expanded as the app evolves
    }
}
