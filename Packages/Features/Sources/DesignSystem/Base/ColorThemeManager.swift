import SwiftUI
import Models

@MainActor
@Observable
public final class ColorThemeManager {
    public static let shared = ColorThemeManager()

    public var currentTheme: ColorTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedColorTheme")
            NotificationCenter.default.post(name: .colorThemeDidChange, object: currentTheme)
        }
    }

    private init() {
        self.currentTheme = ColorTheme(rawValue: UserDefaults.standard.string(forKey: "selectedColorTheme") ?? "bluesky") ?? .bluesky
    }

    // MARK: - Theme-aware color getters

    public var primaryColor: Color {
        Color.primary(for: currentTheme)
    }

    public var secondaryColor: Color {
        Color.secondary(for: currentTheme)
    }

    public var accentColor: Color {
        Color.accent(for: currentTheme)
    }

    // MARK: - Theme-aware gradient getters

    public var primaryGradient: LinearGradient {
        LinearGradient.primary(for: currentTheme)
    }

    public var accentGradient: LinearGradient {
        LinearGradient.accent(for: currentTheme)
    }

    public var subtleGradient: LinearGradient {
        LinearGradient.subtle(for: currentTheme)
    }

    public var themeGradient: LinearGradient {
        LinearGradient.themeGradient(for: currentTheme)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    public static let colorThemeDidChange = Notification.Name("colorThemeDidChange")
}


