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
        // Try to handle mention tap first, then hashtag tap, then URL tap
        if !handleMentionTap(at: location) {
          if !handleHashtagTap(at: location) {
            handleURLTap(at: location)
          }
        }
      }
  }

  private func createAttributedString() -> AttributedString {
    var attributedString = AttributedString(text)

    // Find and style mentions (handles starting with @)
    let mentionPattern = try! NSRegularExpression(pattern: "@([a-zA-Z0-9._-]+)")
    let mentionRange = NSRange(location: 0, length: text.utf16.count)

    mentionPattern.enumerateMatches(in: text, range: mentionRange) { match, _, _ in
      guard let match = match else { return }

      // Capture group for the handle without @ (optional, not used yet)
      let nsHandleRange = match.range(at: 1)
      if let handleRange = Range(nsHandleRange, in: text) {
        _ = String(text[handleRange])
      }

      // Style the entire mention (@handle) using a safe conversion
      if let fullRange = Range(match.range, in: text),
        let attributedRange = Range(NSRange(fullRange, in: text), in: attributedString)
      {
        attributedString[attributedRange].foregroundColor = .themePrimary
        attributedString[attributedRange].underlineStyle = .single
      }
    }

    // Find and style hashtags
    let hashtagPattern = try! NSRegularExpression(pattern: "#([a-zA-Z0-9_]+)")
    let hashtagRange = NSRange(location: 0, length: text.utf16.count)

    hashtagPattern.enumerateMatches(in: text, range: hashtagRange) { match, _, _ in
      guard let match = match else { return }

      // Style the hashtag using a safe conversion
      if let fullRange = Range(match.range, in: text),
        let attributedRange = Range(NSRange(fullRange, in: text), in: attributedString)
      {
        attributedString[attributedRange].foregroundColor = .themePrimary
        attributedString[attributedRange].underlineStyle = .single
      }
    }

    // Find and style URLs
    let urlPattern = try! NSRegularExpression(pattern: "https?://[^\\s]+")
    let urlRange = NSRange(location: 0, length: text.utf16.count)

    urlPattern.enumerateMatches(in: text, range: urlRange) { match, _, _ in
      guard let match = match else { return }

      // Style the URL using a safe conversion
      if let fullRange = Range(match.range, in: text),
        let attributedRange = Range(NSRange(fullRange, in: text), in: attributedString)
      {
        attributedString[attributedRange].foregroundColor = .blue
        attributedString[attributedRange].underlineStyle = .single
      }
    }

    return attributedString
  }

  private func handleMentionTap(at location: CGPoint) -> Bool {
    // Find which mention was tapped
    let mentionPattern = try! NSRegularExpression(pattern: "@([a-zA-Z0-9._-]+)")
    let range = NSRange(location: 0, length: text.utf16.count)
    var foundMention = false

    mentionPattern.enumerateMatches(in: text, range: range) { match, _, _ in
      guard let match = match else { return }

      let nsRange = match.range(at: 1)  // Capture group for the handle without @
      if let handleRange = Range(nsRange, in: text) {
        let handle = String(text[handleRange])
        // For now, just print the handle - navigation will be implemented later
        print("Tapped on mention: @\(handle)")
        foundMention = true
      }

      // TODO: Implement navigation to profile when AppRouter is available
      // This will require:
      // 1. Adding AppRouter to the environment
      // 2. Creating a Profile object from the handle
      // 3. Calling router.navigateTo(.profile(profile))

      // Only handle the first mention for now
      return
    }

    return foundMention
  }

  private func handleHashtagTap(at location: CGPoint) -> Bool {
    // Find which hashtag was tapped
    let hashtagPattern = try! NSRegularExpression(pattern: "#([a-zA-Z0-9_]+)")
    let range = NSRange(location: 0, length: text.utf16.count)
    var foundHashtag = false

    hashtagPattern.enumerateMatches(in: text, range: range) { match, _, _ in
      guard let match = match else { return }

      let nsRange = match.range(at: 1)  // Capture group for the hashtag without #
      if let hashtagRange = Range(nsRange, in: text) {
        let hashtag = String(text[hashtagRange])
        // For now, just print the hashtag - navigation will be implemented later
        print("Tapped on hashtag: #\(hashtag)")
        foundHashtag = true
      }

      // TODO: Implement navigation to hashtag search when AppRouter is available
      // This will require:
      // 1. Adding AppRouter to the environment
      // 2. Calling router.navigateTo(.search(query: "#\(hashtag)"))

      // Only handle the first hashtag for now
      return
    }

    return foundHashtag
  }

  private func handleURLTap(at location: CGPoint) {
    // Find which URL was tapped
    let urlPattern = try! NSRegularExpression(pattern: "https?://[^\\s]+")
    let range = NSRange(location: 0, length: text.utf16.count)

    urlPattern.enumerateMatches(in: text, range: range) { match, _, _ in
      guard let match = match else { return }

      if let urlRange = Range(match.range, in: text) {
        let urlString = String(text[urlRange])
        if let url = URL(string: urlString) {
          // Open URL in Safari
          UIApplication.shared.open(url)
        }
      }

      // Only handle the first URL for now
      return
    }
  }
}
