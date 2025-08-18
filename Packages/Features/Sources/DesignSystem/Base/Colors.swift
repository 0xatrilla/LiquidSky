import Models
import SwiftUI

extension Color {
  public static var shadowPrimary: Color {
    Color("shadowPrimary", bundle: .module)
  }

  public static var shadowSecondary: Color {
    Color("shadowSecondary", bundle: .module)
  }

  // Bluesky official colors
  public static var blueskyPrimary: Color {
    Color(red: 0.0, green: 0.443, blue: 1.0)  // #0071FF - Official Bluesky blue
  }

  public static var blueskySecondary: Color {
    Color(red: 0.0, green: 0.588, blue: 1.0)  // #0096FF - Lighter blue variant
  }

  public static var blueskyAccent: Color {
    Color(red: 0.0, green: 0.325, blue: 0.8)  // #0053CC - Darker blue variant
  }

  // Sunset theme colors
  public static var sunsetPrimary: Color {
    Color(red: 1.0, green: 0.4, blue: 0.2)  // #FF6633 - Warm orange
  }

  public static var sunsetSecondary: Color {
    Color(red: 1.0, green: 0.6, blue: 0.3)  // #FF994D - Lighter orange
  }

  public static var sunsetAccent: Color {
    Color(red: 0.8, green: 0.3, blue: 0.1)  // #CC4D1A - Darker orange
  }

  // Forest theme colors
  public static var forestPrimary: Color {
    Color(red: 0.2, green: 0.6, blue: 0.3)  // #33994D - Natural green
  }

  public static var forestSecondary: Color {
    Color(red: 0.4, green: 0.7, blue: 0.4)  // #66B366 - Lighter green
  }

  public static var forestAccent: Color {
    Color(red: 0.1, green: 0.4, blue: 0.2)  // #1A661A - Darker green
  }

  // Ocean theme colors
  public static var oceanPrimary: Color {
    Color(red: 0.0, green: 0.6, blue: 0.7)  // #0099B3 - Ocean teal
  }

  public static var oceanSecondary: Color {
    Color(red: 0.2, green: 0.7, blue: 0.8)  // #33B3CC - Lighter teal
  }

  public static var oceanAccent: Color {
    Color(red: 0.0, green: 0.4, blue: 0.5)  // #006666 - Darker teal
  }

  // Lavender theme colors
  public static var lavenderPrimary: Color {
    Color(red: 0.6, green: 0.4, blue: 0.8)  // #9966CC - Soft purple
  }

  public static var lavenderSecondary: Color {
    Color(red: 0.7, green: 0.5, blue: 0.9)  // #B366E6 - Lighter purple
  }

  public static var lavenderAccent: Color {
    Color(red: 0.4, green: 0.2, blue: 0.6)  // #663399 - Darker purple
  }

  // Fire theme colors
  public static var firePrimary: Color {
    Color(red: 0.9, green: 0.2, blue: 0.1)  // #E6331A - Bold red
  }

  public static var fireSecondary: Color {
    Color(red: 1.0, green: 0.4, blue: 0.3)  // #FF664D - Lighter red
  }

  public static var fireAccent: Color {
    Color(red: 0.7, green: 0.1, blue: 0.0)  // #B31A00 - Darker red
  }

  // Legacy - keeping for backward compatibility but marking as deprecated
  @available(*, deprecated, message: "Use blueskyPrimary instead")
  public static var blueskyBackground: Color {
    blueskyPrimary
  }

  // Theme-aware color getters
  public static func primary(for theme: ColorTheme) -> Color {
    switch theme {
    case .bluesky: return .blueskyPrimary
    case .sunset: return .sunsetPrimary
    case .forest: return .forestPrimary
    case .ocean: return .oceanPrimary
    case .lavender: return .lavenderPrimary
    case .fire: return .firePrimary
    }
  }

  public static func secondary(for theme: ColorTheme) -> Color {
    switch theme {
    case .bluesky: return .blueskySecondary
    case .sunset: return .sunsetSecondary
    case .forest: return .forestSecondary
    case .ocean: return .oceanSecondary
    case .lavender: return .lavenderSecondary
    case .fire: return .fireSecondary
    }
  }

  public static func accent(for theme: ColorTheme) -> Color {
    switch theme {
    case .bluesky: return .blueskyAccent
    case .sunset: return .sunsetAccent
    case .forest: return .forestAccent
    case .ocean: return .oceanAccent
    case .lavender: return .lavenderAccent
    case .fire: return .fireAccent
    }
  }
}

// Theme-aware gradients
extension LinearGradient {
  // Bluesky-themed gradients (default)
  public static var blueskyPrimary: LinearGradient {
    LinearGradient(
      colors: [.blueskyPrimary, .blueskySecondary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  public static var blueskyAccent: LinearGradient {
    LinearGradient(
      colors: [.blueskySecondary, .blueskyPrimary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  public static var blueskySubtle: LinearGradient {
    LinearGradient(
      colors: [.blueskyPrimary.opacity(0.8), .blueskySecondary.opacity(0.6)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  // Theme-aware gradient getters
  public static func primary(for theme: ColorTheme) -> LinearGradient {
    switch theme {
    case .bluesky:
      return LinearGradient(
        colors: [.blueskyPrimary, .blueskySecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .sunset:
      return LinearGradient(
        colors: [.sunsetPrimary, .sunsetSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .forest:
      return LinearGradient(
        colors: [.forestPrimary, .forestSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .ocean:
      return LinearGradient(
        colors: [.oceanPrimary, .oceanSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .lavender:
      return LinearGradient(
        colors: [.lavenderPrimary, .lavenderSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .fire:
      return LinearGradient(
        colors: [.firePrimary, .fireSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  public static func accent(for theme: ColorTheme) -> LinearGradient {
    switch theme {
    case .bluesky:
      return LinearGradient(
        colors: [.blueskySecondary, .blueskyPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .sunset:
      return LinearGradient(
        colors: [.sunsetSecondary, .sunsetPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .forest:
      return LinearGradient(
        colors: [.forestSecondary, .forestPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .ocean:
      return LinearGradient(
        colors: [.oceanSecondary, .oceanPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .lavender:
      return LinearGradient(
        colors: [.lavenderSecondary, .lavenderPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .fire:
      return LinearGradient(
        colors: [.fireSecondary, .firePrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  public static func subtle(for theme: ColorTheme) -> LinearGradient {
    switch theme {
    case .bluesky:
      return LinearGradient(
        colors: [.blueskyPrimary.opacity(0.8), .blueskySecondary.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .sunset:
      return LinearGradient(
        colors: [.sunsetPrimary.opacity(0.8), .sunsetSecondary.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .forest:
      return LinearGradient(
        colors: [.forestPrimary.opacity(0.8), .forestSecondary.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .ocean:
      return LinearGradient(
        colors: [.oceanPrimary.opacity(0.8), .oceanSecondary.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .lavender:
      return LinearGradient(
        colors: [.lavenderPrimary.opacity(0.8), .lavenderSecondary.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .fire:
      return LinearGradient(
        colors: [.firePrimary.opacity(0.8), .fireSecondary.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  // Theme-aware gradient getter for commonly used gradients
  public static func themeGradient(for theme: ColorTheme) -> LinearGradient {
    return primary(for: theme)
  }
}
