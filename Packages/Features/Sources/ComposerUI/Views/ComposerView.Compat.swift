import Models
import SwiftUI

// Unified public composer type that switches implementation by OS version.
public struct ComposerView: View {
  let mode: ComposerMode

  public init(mode: ComposerMode) { self.mode = mode }

  public var body: some View {
    if #available(iOS 26.0, *) {
      ModernComposerInnerView(mode: mode)
    } else {
      LegacyComposerView(mode: mode)
    }
  }
}
