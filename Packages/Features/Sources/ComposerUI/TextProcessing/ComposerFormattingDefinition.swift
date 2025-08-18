import SwiftUI

/// The formatting definition for composer text
struct ComposerFormattingDefinition: AttributedTextFormattingDefinition {
  typealias Scope = AttributeScopes.ComposerAttributes
  
  var body: some AttributedTextFormattingDefinition<Scope> {
    PatternColorConstraint()
    URLUnderlineConstraint()
  }
}

/// Constraint that applies colors based on text patterns
struct PatternColorConstraint: AttributedTextValueConstraint {
  typealias Scope = AttributeScopes.ComposerAttributes
  typealias AttributeKey = AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute
  
  nonisolated func constrain(_ container: inout Attributes) {
    if let pattern = container.textPattern {
      // Get the current theme from UserDefaults and apply the appropriate color
      let currentTheme = UserDefaults.standard.string(forKey: "selectedColorTheme") ?? "bluesky"
      container.foregroundColor = pattern.color(for: currentTheme)
    }
  }
}

/// Constraint that applies underlines to URLs
struct URLUnderlineConstraint: AttributedTextValueConstraint {
  typealias Scope = AttributeScopes.ComposerAttributes
  typealias AttributeKey = AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute
  
  nonisolated func constrain(_ container: inout Attributes) {
    if let pattern = container.textPattern, pattern == .url {
      container.underlineStyle = .single
    }
  }
}