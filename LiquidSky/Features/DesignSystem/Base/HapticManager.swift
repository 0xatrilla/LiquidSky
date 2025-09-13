import SwiftUI

#if os(iOS)
import UIKit
#endif

@MainActor
public final class HapticManager: Sendable {
  public static let shared = HapticManager()

  @Published public var isEnabled: Bool = true

  private init() {
    // Load haptic feedback preference
    isEnabled = UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true
  }

  public func impact(_ style: ImpactStyle) {
    guard isEnabled else { return }

    #if os(iOS)
      let impactFeedbackGenerator: UIImpactFeedbackGenerator

      switch style {
      case .light:
        impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
      case .medium:
        impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
      case .heavy:
        impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
      case .soft:
        impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
      case .rigid:
        impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
      }

      impactFeedbackGenerator.prepare()
      impactFeedbackGenerator.impactOccurred()
    #endif
  }

  public func notification(_ type: NotificationType) {
    guard isEnabled else { return }

    #if os(iOS)
      let notificationFeedbackGenerator: UINotificationFeedbackGenerator

      switch type {
      case .success:
        notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.notificationOccurred(.success)
      case .warning:
        notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.notificationOccurred(.warning)
      case .error:
        notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.notificationOccurred(.error)
      }
    #endif
  }

  public func selection() {
    guard isEnabled else { return }

    #if os(iOS)
      let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
      selectionFeedbackGenerator.prepare()
      selectionFeedbackGenerator.selectionChanged()
    #endif
  }

  public func toggleHapticFeedback() {
    isEnabled.toggle()
    UserDefaults.standard.set(isEnabled, forKey: "hapticFeedbackEnabled")
  }
}

// MARK: - Haptic Feedback Types
public enum ImpactStyle: String, CaseIterable {
  case light, medium, heavy, soft, rigid
}

public enum NotificationType: String, CaseIterable {
  case success, warning, error
}
