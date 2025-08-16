import SwiftUI

extension LinearGradient {
  public static let blueskyBlue = LinearGradient(
    colors: [.blueskyBackground, .blue],
    startPoint: .top,
    endPoint: .bottom
  )

  public static let blueBluesky = LinearGradient(
    colors: [.blue, .blueskyBackground],
    startPoint: .top,
    endPoint: .bottom
  )

  public static let blueCyan = LinearGradient(
    colors: [.blue, .cyan],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  public static let blueskyBlueHorizontal = LinearGradient(
    colors: [.blueskyBackground, .blue],
    startPoint: .leading,
    endPoint: .trailing
  )

  public static let blueskyBlueAvatar = LinearGradient(
    colors: [.blue, .blueskyBackground],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  public static func avatarBorder(hasReply: Bool) -> LinearGradient {
    LinearGradient(
      colors: hasReply
        ? [.blue, .blueskyBackground]
        : [.shadowPrimary.opacity(0.5), .blueskyBackground.opacity(0.5)],
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
