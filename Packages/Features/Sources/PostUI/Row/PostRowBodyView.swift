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
    ClickablePostText(text: post.content, compactMode: compactMode, isFocused: isFocused)
  }

  private var compactMode: Bool {
    settingsService.compactMode
  }
}

// MARK: - Clickable Post Text Component
struct ClickablePostText: View {
  let text: String
  let compactMode: Bool
  let isFocused: Bool

  var body: some View {
    let attributedText = createAttributedString()

    Text(attributedText)
      .font(
        compactMode
          ? (isFocused ? .system(size: 18) : .callout)
          : (isFocused ? .system(size: 20) : .body)
      )
      .lineLimit(compactMode ? 3 : nil)
      .onTapGesture { location in
        handleMentionTap(at: location)
      }
  }

  private func createAttributedString() -> AttributedString {
    var attributedString = AttributedString(text)

    // Find and style mentions (handles starting with @)
    let mentionPattern = try! NSRegularExpression(pattern: "@([a-zA-Z0-9._-]+)")
    let range = NSRange(location: 0, length: text.utf16.count)

    mentionPattern.enumerateMatches(in: text, range: range) { match, _, _ in
      guard let match = match else { return }

      // Capture group for the handle without @ (optional, not used yet)
      let nsHandleRange = match.range(at: 1)
      if let handleRange = Range(nsHandleRange, in: text) {
        _ = String(text[handleRange])
      }

      // Style the entire mention (@handle) using a safe conversion
      if let fullRange = Range(match.range, in: text),
         let attributedRange = Range(NSRange(fullRange, in: text), in: attributedString) {
        attributedString[attributedRange].foregroundColor = .themePrimary
        attributedString[attributedRange].underlineStyle = .single
      }
    }

    return attributedString
  }

  private func handleMentionTap(at location: CGPoint) {
    // Find which mention was tapped
    let mentionPattern = try! NSRegularExpression(pattern: "@([a-zA-Z0-9._-]+)")
    let range = NSRange(location: 0, length: text.utf16.count)

    mentionPattern.enumerateMatches(in: text, range: range) { match, _, _ in
      guard let match = match else { return }

      let nsRange = match.range(at: 1)  // Capture group for the handle without @
      if let handleRange = Range(nsRange, in: text) {
        let handle = String(text[handleRange])
        // For now, just print the handle - navigation will be implemented later
        print("Tapped on mention: @\(handle)")
      }

      // TODO: Implement navigation to profile when AppRouter is available
      // This will require:
      // 1. Adding AppRouter to the environment
      // 2. Creating a Profile object from the handle
      // 3. Calling router.navigateTo(.profile(profile))

      // Only handle the first mention for now
    }
  }
}
