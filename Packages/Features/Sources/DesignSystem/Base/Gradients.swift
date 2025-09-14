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
  public static var blueskyBlue: LinearGradient { 
    LinearGradient(
      colors: [.blue, .cyan],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
  public static var blueBluesky: LinearGradient { 
    LinearGradient(
      colors: [.blue, .blue.opacity(0.8)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
  public static var blueCyan: LinearGradient { 
    LinearGradient(
      colors: [.blue, .cyan],
      startPoint: .top,
      endPoint: .bottom
    )
  }
  public static var blueskyBlueHorizontal: LinearGradient { 
    LinearGradient(
      colors: [.blue, .cyan],
      startPoint: .leading,
      endPoint: .trailing
    )
  }
  public static var blueskyBlueAvatar: LinearGradient { 
    LinearGradient(
      colors: [.blue, .cyan],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
