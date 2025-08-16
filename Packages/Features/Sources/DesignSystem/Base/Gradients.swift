import SwiftUI

extension LinearGradient {
  public static var blueskyGradient: LinearGradient {
    LinearGradient(
      colors: [.blueskyPrimary, .blueskySecondary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  public static var blueskyGradientReversed: LinearGradient {
    LinearGradient(
      colors: [.blueskySecondary, .blueskyPrimary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  public static var avatarBorder: LinearGradient {
    LinearGradient(
      colors: [.blueskyPrimary, .blueskySecondary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  public static var avatarBorderReversed: LinearGradient {
    LinearGradient(
      colors: [.blueskySecondary, .blueskyPrimary],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  public static var feedBackground: LinearGradient {
    LinearGradient(
      colors: [.blueskyPrimary.opacity(0.1), .blueskySecondary.opacity(0.05)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  public static var feedBackgroundReversed: LinearGradient {
    LinearGradient(
      colors: [.blueskySecondary.opacity(0.1), .blueskyPrimary.opacity(0.05)],
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
