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

  // Legacy - keeping for backward compatibility but marking as deprecated
  @available(*, deprecated, message: "Use blueskyPrimary instead")
  public static var blueskyBackground: Color {
    blueskyPrimary
  }
}

// Bluesky-themed gradients
extension LinearGradient {
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
}
