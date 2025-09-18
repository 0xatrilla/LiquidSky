import Destinations
import Models
import SwiftUI

public struct PostRowBodyView: View {
  @Environment(\.isFocused) private var isFocused
  @Environment(SettingsService.self) private var settingsService

  let post: PostItem
  let onUsernameTap: ((String) -> Void)?
  let onHashtagTap: ((String) -> Void)?

  public init(
    post: PostItem,
    onUsernameTap: ((String) -> Void)? = nil,
    onHashtagTap: ((String) -> Void)? = nil
  ) {
    self.post = post
    self.onUsernameTap = onUsernameTap
    self.onHashtagTap = onHashtagTap
  }

  public var body: some View {
    ClickablePostText(
      text: post.content, compactMode: compactMode, isFocused: isFocused,
      onUsernameTap: onUsernameTap,
      onHashtagTap: onHashtagTap
    )
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
  let onUsernameTap: ((String) -> Void)?
  let onHashtagTap: ((String) -> Void)?

  var body: some View {
    let attributedString = createAttributedString(from: text)

    Text(attributedString)
      .font(compactMode ? .caption : .body)
      .lineLimit(compactMode ? 3 : nil)
      .textSelection(.enabled)
      .onTapGesture { location in
        handleTap(at: location, in: attributedString)
      }
  }

  private func createAttributedString(from text: String) -> AttributedString {
    var attributedString = AttributedString(text)

    // Find and style hashtags
    let hashtagPattern = #/#[a-zA-Z0-9_]+/#
    let hashtagMatches = text.matches(of: hashtagPattern)

    for match in hashtagMatches {
      if let attributedRange = attributedString.range(of: String(match.output)) {
        attributedString[attributedRange].foregroundColor = .blue
        attributedString[attributedRange].underlineStyle = .single
        // Add custom attribute to identify hashtags
        attributedString[attributedRange][HashtagAttribute.self] = String(match.output)
      }
    }

    // Find and style mentions
    let mentionPattern = #/@[a-zA-Z0-9_.]+/#
    let mentionMatches = text.matches(of: mentionPattern)

    for match in mentionMatches {
      if let attributedRange = attributedString.range(of: String(match.output)) {
        attributedString[attributedRange].foregroundColor = .blue
        attributedString[attributedRange].underlineStyle = .single
        // Add custom attribute to identify mentions
        attributedString[attributedRange][MentionAttribute.self] = String(match.output)
      }
    }

    // Find and style URLs
    let urlPattern = #/https?://[^\s]+/#
    let urlMatches = text.matches(of: urlPattern)

    for match in urlMatches {
      if let attributedRange = attributedString.range(of: String(match.output)) {
        attributedString[attributedRange].foregroundColor = .blue
        attributedString[attributedRange].underlineStyle = .single
        // Add custom attribute to identify URLs
        attributedString[attributedRange][URLAttribute.self] = String(match.output)
        if let link = URL(string: String(match.output)) {
          attributedString[attributedRange].link = link
        }
      }
    }

    return attributedString
  }

  private func handleTap(at location: CGPoint, in attributedString: AttributedString) {
    // For now, we'll use a simple approach: check if there are any mentions, hashtags, or URLs
    // and handle the first one found. This is a limitation of SwiftUI's current tap handling.
    // In a future update, we could implement more precise tap detection using UITextView.
    
    let hashtagPattern = #/#[a-zA-Z0-9_]+/#
    let mentionPattern = #/@[a-zA-Z0-9_.]+/#
    let urlPattern = #/https?://[^\s]+/#

    let hashtagMatches = text.matches(of: hashtagPattern)
    let mentionMatches = text.matches(of: mentionPattern)
    let urlMatches = text.matches(of: urlPattern)

    // If no interactive elements, do nothing (let parent handle the tap)
    guard !hashtagMatches.isEmpty || !mentionMatches.isEmpty || !urlMatches.isEmpty else { return }

    // Priority: mentions > hashtags > URLs
    if let firstMention = mentionMatches.first {
      let mention = String(firstMention.output)
      let username = String(mention.dropFirst())  // Remove @ symbol
      print("PostRowBodyView: Tapping mention: \(mention) -> \(username)")

      // Use the callback to handle username navigation
      onUsernameTap?(username)
      return
    }

    if let firstHashtag = hashtagMatches.first {
      let hashtag = String(firstHashtag.output)
      let hashtagWithoutHash = String(hashtag.dropFirst())
      onHashtagTap?(hashtagWithoutHash)
      return
    }

    if let firstURL = urlMatches.first {
      let url = String(firstURL.output)
      print("PostRowBodyView: Tapping URL: \(url)")
      // Open URL in Safari or handle appropriately
      if let url = URL(string: url) {
        UIApplication.shared.open(url)
      }
      return
    }
  }

}

// MARK: - Custom Attributes
struct HashtagAttribute: CodableAttributedStringKey {
  typealias Value = String
  static let name = "hashtag"
}

struct MentionAttribute: CodableAttributedStringKey {
  typealias Value = String
  static let name = "mention"
}

struct URLAttribute: CodableAttributedStringKey {
  typealias Value = String
  static let name = "url"
}
