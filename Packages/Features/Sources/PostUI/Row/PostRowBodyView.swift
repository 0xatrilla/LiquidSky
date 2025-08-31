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
        handleTap(at: location)
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

  private func handleTap(at location: CGPoint) {
    // Find hashtags in the text and navigate to the first one
    // This is a simplified approach that will work reliably
    let hashtagPattern = #/#[a-zA-Z0-9_]+/#
    let hashtagMatches = text.matches(of: hashtagPattern)
    
    if let firstMatch = hashtagMatches.first {
      let hashtag = String(firstMatch.output)
      let hashtagWithoutHash = String(hashtag.dropFirst())
      router.navigateTo(.hashtag(hashtagWithoutHash))
    }
  }
}

// MARK: - Custom Attribute for Hashtags
struct HashtagAttribute: CodableAttributedStringKey {
  typealias Value = String
  static let name = "hashtag"
}
