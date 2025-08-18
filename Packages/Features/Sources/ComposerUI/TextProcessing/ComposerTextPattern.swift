import Foundation
import SwiftUI

// Custom attribute keys for text patterns
struct TextPatternAttribute: CodableAttributedStringKey {
  typealias Value = ComposerTextPattern

  static let name = "LiquidSky.TextPatternAttribute"
  static let inheritedByAddedText: Bool = false
  static let invalidationConditions: Set<AttributedString.AttributeInvalidationCondition>? = [
    .textChanged
  ]
}

extension AttributeScopes {
  struct ComposerAttributes: AttributeScope {
    let textPattern: TextPatternAttribute
    let foregroundColor: AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute
    let underlineStyle: AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute
  }
}

extension AttributeDynamicLookup {
  subscript<T: AttributedStringKey>(
    dynamicMember keyPath: KeyPath<AttributeScopes.ComposerAttributes, T>
  ) -> T {
    return self[T.self]
  }
}

/// Text patterns that can be applied to composer text
enum ComposerTextPattern: String, CaseIterable, Codable {
  case mention = "mention"
  case url = "url"
  case hashtag = "hashtag"
  
  /// Get the color for a specific theme
  func color(for theme: String) -> Color {
    switch self {
    case .mention:
      return .blue // Fallback color for now
    case .url:
      return .blue // Fallback color for now
    case .hashtag:
      return .blue // Fallback color for now
    }
  }
  
  /// Get the color for the current theme (for backward compatibility)
  var color: Color {
    let currentTheme = UserDefaults.standard.string(forKey: "selectedColorTheme") ?? "bluesky"
    return color(for: currentTheme)
  }
  
  /// Get the regex pattern for matching
  var pattern: String {
    switch self {
    case .hashtag:
      return "#\\w+"
    case .mention:
      return "@[\\w.-]+"
    case .url:
      return "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)"
    }
  }
  
  /// Check if text matches this pattern
  func matches(_ text: String) -> Bool {
    switch self {
    case .hashtag:
      return text.hasPrefix("#")
    case .mention:
      return text.hasPrefix("@")
    case .url:
      return text.lowercased().hasPrefix("http")
    }
  }
}
