import AppRouter
import Destinations
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
  @Environment(AppRouter.self) private var router

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
      }
    }

    // Find and style URLs
    let urlPattern = #/https?://[^\s]+/#
    let urlMatches = text.matches(of: urlPattern)

    for match in urlMatches {
      if let attributedRange = attributedString.range(of: String(match.output)) {
        attributedString[attributedRange].foregroundColor = .blue
        attributedString[attributedRange].underlineStyle = .single
      }
    }

    return attributedString
  }

  private func handleTap(at location: CGPoint, in attributedString: AttributedString) {
    // Check if the tap is on a hashtag by examining the text layout
    // For now, we'll use a simpler approach that checks if there are hashtags
    // and only navigates if the tap is likely on one
    let hashtagPattern = #/#[a-zA-Z0-9_]+/#
    let hashtagMatches = text.matches(of: hashtagPattern)
    
    // If no hashtags, do nothing (let parent handle the tap)
    guard !hashtagMatches.isEmpty else { return }
    
    // For now, we'll use a simple heuristic: if there are hashtags and the tap is
    // in the text area, we'll assume it's on a hashtag. This is a limitation of
    // SwiftUI's current tap handling, but it's better than the current broken behavior.
    // In a future update, we could implement more precise tap detection using UITextView.
    
    // Extract the hashtag that was tapped (for now, just use the first one)
    // This is a temporary solution until we can implement proper tap coordinate detection
    if let firstMatch = hashtagMatches.first {
      let hashtag = String(firstMatch.output)
      let hashtagWithoutHash = String(hashtag.dropFirst())
      print("PostRowBodyView: Tapping hashtag: \(hashtag) -> \(hashtagWithoutHash)")
      router.navigateTo(.hashtag(hashtagWithoutHash))
      print("PostRowBodyView: Navigation called for hashtag: \(hashtagWithoutHash)")
    }
  }
}

// MARK: - Custom Attribute for Hashtags
struct HashtagAttribute: CodableAttributedStringKey {
  typealias Value = String
  static let name = "hashtag"
}
