import SwiftUI
import Models

// MARK: - Theme-Aware Color Extensions

extension Color {
    /// Get the current theme's primary color
    @MainActor
    public static var themePrimary: Color {
        ColorThemeManager.shared.primaryColor
    }

    /// Get the current theme's secondary color
    @MainActor
    public static var themeSecondary: Color {
        ColorThemeManager.shared.secondaryColor
    }

    /// Get the current theme's accent color
    @MainActor
    public static var themeAccent: Color {
        ColorThemeManager.shared.accentColor
    }
}

// MARK: - Theme-Aware Gradient Extensions

extension LinearGradient {
    /// Get the current theme's primary gradient
    @MainActor
    public static var themePrimary: LinearGradient {
        ColorThemeManager.shared.primaryGradient
    }

    /// Get the current theme's accent gradient
    @MainActor
    public static var themeAccent: LinearGradient {
        ColorThemeManager.shared.accentGradient
    }

    /// Get the current theme's subtle gradient
    @MainActor
    public static var themeSubtle: LinearGradient {
        ColorThemeManager.shared.subtleGradient
    }

    /// Get the current theme's main gradient (alias for primary)
    @MainActor
    public static var themeGradient: LinearGradient {
        ColorThemeManager.shared.themeGradient
    }
}

// MARK: - View Modifier for Theme Changes

struct ThemeAwareViewModifier: ViewModifier {
    @State private var colorThemeManager = ColorThemeManager.shared

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .colorThemeDidChange)) { _ in
                // Force view update when theme changes
                colorThemeManager = ColorThemeManager.shared
            }
    }
}

extension View {
    /// Make a view automatically update when the color theme changes
    public func themeAware() -> some View {
        modifier(ThemeAwareViewModifier())
    }
}
