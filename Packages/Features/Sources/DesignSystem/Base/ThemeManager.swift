import SwiftUI
import Models

// MARK: - Theme Manager
@MainActor
@Observable
public final class ThemeManager {
    public static let shared = ThemeManager()
    
    public var currentTheme: AppTheme = .system {
        didSet {
            applyTheme(currentTheme)
        }
    }
    
    public var useSystemTheme: Bool = true {
        didSet {
            if useSystemTheme {
                currentTheme = .system
            }
        }
    }
    
    private init() {}
    
    public func applyTheme(_ theme: AppTheme) {
        switch theme {
        case .system:
            // Let the system handle it
            break
        case .light:
            setAppearance(.light)
        case .dark:
            setAppearance(.dark)
        }
    }
    
    private func setAppearance(_ appearance: ColorScheme?) {
        // This would typically integrate with the app's window management
        // For now, we'll just store the preference
        if let appearance = appearance {
            UserDefaults.standard.set(appearance == .dark ? "dark" : "light", forKey: "appearance")
        }
    }
    
    public func getCurrentColorScheme() -> ColorScheme? {
        if useSystemTheme {
            return nil // Let system decide
        }
        
        switch currentTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Theme Modifier
public struct ThemeModifier: ViewModifier {
    @State private var themeManager = ThemeManager.shared
    
    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.getCurrentColorScheme())
    }
}

extension View {
    public func withTheme() -> some View {
        modifier(ThemeModifier())
    }
}
