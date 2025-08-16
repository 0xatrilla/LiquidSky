import SwiftUI

@MainActor
public final class HapticManager: Sendable {
  public static let shared = HapticManager()

  private init() {}

  public func impact(_ style: ImpactStyle) {
    // Mock implementation - can be replaced with proper haptic feedback later
    #if os(iOS)
      // For now, just log the impact style
      print("Haptic impact: \(style)")
    #endif
  }

  public func notification(_ type: NotificationType) {
    // Mock implementation - can be replaced with proper haptic feedback later
    #if os(iOS)
      print("Haptic notification: \(type)")
    #endif
  }

  public func selection() {
    // Mock implementation - can be replaced with proper haptic feedback later
    #if os(iOS)
      print("Haptic selection")
    #endif
  }
}

// MARK: - Haptic Feedback Types
public enum ImpactStyle: String, CaseIterable {
  case light, medium, heavy, soft, rigid
}

public enum NotificationType: String, CaseIterable {
  case success, warning, error
}
