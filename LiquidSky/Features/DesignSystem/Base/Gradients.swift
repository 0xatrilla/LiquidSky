import SwiftUI

extension LinearGradient {
  @MainActor
  public static var blueskyGradient: LinearGradient {
    LinearGradient(
      colors: [.themePrimary, .themeSecondary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  @MainActor
  public static var blueskyGradientReversed: LinearGradient {
    LinearGradient(
      colors: [.themeSecondary, .themePrimary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  @MainActor
  public static var avatarBorder: LinearGradient {
    LinearGradient(
      colors: [.themePrimary, .themeSecondary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  @MainActor
  public static var avatarBorderReversed: LinearGradient {
    LinearGradient(
      colors: [.themeSecondary, .themePrimary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  @MainActor
  public static var feedBackground: LinearGradient {
    LinearGradient(
      colors: [.themePrimary.opacity(0.1), .themeSecondary.opacity(0.05)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  @MainActor
  public static var feedBackgroundReversed: LinearGradient {
    LinearGradient(
      colors: [.themeSecondary.opacity(0.1), .themePrimary.opacity(0.05)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}

extension ShapeStyle where Self == LinearGradient {
  public static var blueskyBlue: LinearGradient { .blueskyBlue }
  public static var blueBluesky: LinearGradient { .blueBluesky }
  public static var blueCyan: LinearGradient { .blueCyan }
  public static var blueskyBlueHorizontal: LinearGradient { .blueskyBlueHorizontal }
  public static var blueskyBlueAvatar: LinearGradient { .blueskyBlueAvatar }
}
