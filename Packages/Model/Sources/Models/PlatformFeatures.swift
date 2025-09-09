import Foundation
import SwiftUI

/// Central place to gate new OS-specific capabilities and visual treatments.
public enum PlatformFeatures {
  /// Whether the "liquid glass" visuals and other iOS 26 design affordances are available.
  public static var supportsLiquidDesign: Bool {
    if #available(iOS 26.0, *) { return true } else { return false }
  }

  /// Whether Apple Intelligence/Foundation Models UI/branding should be shown.
  public static var supportsAppleIntelligenceBranding: Bool {
    if #available(iOS 26.0, *) { return true } else { return false }
  }
}
