import Models
import SwiftUI

public struct PostRowBodyView: View {
  @Environment(\.isFocused) private var isFocused
  @Environment(SettingsService.self) private var settingsService

  let post: PostItem

  public init(post: PostItem) {
    self.post = post
  }

  public var body: some View {
    Text(post.content)
      .font(compactMode ? (isFocused ? .system(size: UIFontMetrics.default.scaledValue(for: 18)) : .callout) : (isFocused ? .system(size: UIFontMetrics.default.scaledValue(for: 20)) : .body))
      .lineSpacing(compactMode ? 2 : 4)
  }
  
  private var compactMode: Bool {
    settingsService.compactMode
  }
}
