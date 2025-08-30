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
    let attributedString = createAttributedString(from: text)
    
    Text(attributedString)
      .font(compactMode ? .caption : .body)
      .lineLimit(compactMode ? 3 : nil)
      .textSelection(.enabled)
  }
  
  private func createAttributedString(from text: String) -> AttributedString {
    var attributedString = AttributedString(text)
    
    // Find and style hashtags
    let hashtagPattern = #/#[a-zA-Z0-9_]+/#
    let hashtagMatches = text.matches(of: hashtagPattern)
    
    for match in hashtagMatches {
      let range = match.range
      if let attributedRange = attributedString.range(of: String(match.output)) {
        attributedString[attributedRange].foregroundColor = .blue
        attributedString[attributedRange].underlineStyle = .single
      }
    }
    
    // Find and style mentions
    let mentionPattern = #/@[a-zA-Z0-9_.]+/#
    let mentionMatches = text.matches(of: mentionPattern)
    
    for match in mentionMatches {
      let range = match.range
      if let attributedRange = attributedString.range(of: String(match.output)) {
        attributedString[attributedRange].foregroundColor = .blue
        attributedString[attributedRange].underlineStyle = .single
      }
    }
    
    // Find and style URLs
    let urlPattern = #/https?://[^\s]+/#
    let urlMatches = text.matches(of: urlPattern)
    
    for match in urlMatches {
      let range = match.range
      if let attributedRange = attributedString.range(of: String(match.output)) {
        attributedString[attributedRange].foregroundColor = .blue
        attributedString[attributedRange].underlineStyle = .single
      }
    }
    
    return attributedString
  }
}
