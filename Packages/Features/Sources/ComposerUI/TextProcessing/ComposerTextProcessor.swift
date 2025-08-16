import Foundation
import SwiftUI

/// Processes text to identify and mark patterns (hashtags, mentions, URLs)
struct ComposerTextProcessor {
  private let combinedRegex: Regex<AnyRegexOutput>

  init() {
    // Build regex from the patterns defined in ComposerTextPattern
    let patterns = ComposerTextPattern.allCases.map { $0.pattern }
    // Add patterns for in-progress typing
    let inProgressPatterns = ["#$", "@$"]  // Just # or @ being typed

    let combinedPattern = (patterns + inProgressPatterns).joined(separator: "|")
    self.combinedRegex = try! Regex(combinedPattern)
  }

  /// Process text to apply pattern attributes
  func processText(_ text: inout AttributedString) {
    // Create a completely fresh AttributedString from the plain text
    // This ensures we don't inherit any fragmented runs from TextEditor
    let plainString = String(text.characters)
    var freshText = AttributedString(plainString)

    // Find and apply all pattern matches
    for match in plainString.matches(of: combinedRegex) {
      let matchedText = String(plainString[match.range])

      // Skip empty matches
      guard !matchedText.isEmpty else { continue }

      // Determine which pattern type this is
      guard let pattern = ComposerTextPattern.allCases.first(where: { $0.matches(matchedText) })
      else {
        continue
      }

      // Convert String range to AttributedString indices
      guard let matchStart = AttributedString.Index(match.range.lowerBound, within: freshText),
        let matchEnd = AttributedString.Index(match.range.upperBound, within: freshText)
      else {
        continue
      }

      // Apply the pattern attribute to the fresh text
      freshText[matchStart..<matchEnd][TextPatternAttribute.self] = pattern
    }

    // Replace the entire text with our fresh version
    text = freshText
  }

  // MARK: - Autocomplete Detection

  /// Detects if autocomplete should be shown and what type
  func detectAutocompleteContext(from text: String) -> AutocompleteContext? {
    guard !text.isEmpty else { return nil }

    // Check for @mention autocomplete at the end of text
    if let mentionMatch = text.range(of: "@\\w*$", options: .regularExpression) {
      let query = String(text[mentionMatch])
      let startIndex = text.distance(from: text.startIndex, to: mentionMatch.lowerBound)
      return AutocompleteContext(
        type: .mention,
        query: query,
        startIndex: startIndex,
        endIndex: text.count
      )
    }

    // Check for #hashtag autocomplete at the end of text
    if let hashtagMatch = text.range(of: "#\\w*$", options: .regularExpression) {
      let query = String(text[hashtagMatch])
      let startIndex = text.distance(from: text.startIndex, to: hashtagMatch.lowerBound)
      return AutocompleteContext(
        type: .hashtag,
        query: query,
        startIndex: startIndex,
        endIndex: text.count
      )
    }

    return nil
  }
}

// MARK: - Autocomplete Context

public struct AutocompleteContext {
  public let type: AutocompleteType
  public let query: String
  public let startIndex: Int
  public let endIndex: Int

  public init(type: AutocompleteType, query: String, startIndex: Int, endIndex: Int) {
    self.type = type
    self.query = query
    self.startIndex = startIndex
    self.endIndex = endIndex
  }

  /// Returns the query without the @ or # symbol
  public var cleanQuery: String {
    String(query.dropFirst())
  }

  /// Returns true if the query is just the symbol (e.g., just "@" or "#")
  public var isJustSymbol: Bool {
    cleanQuery.isEmpty
  }
}

public enum AutocompleteType {
  case mention
  case hashtag
}
