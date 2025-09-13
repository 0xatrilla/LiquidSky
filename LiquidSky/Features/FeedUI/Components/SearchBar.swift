import SwiftUI

public struct SearchBar: View {
  @Binding var text: String
  let placeholder: String
  let onSearch: () -> Void
  let onClear: () -> Void

  @FocusState private var isFocused: Bool

  public init(
    text: Binding<String>,
    placeholder: String = "Search posts, users, and feeds...",
    onSearch: @escaping () -> Void = {},
    onClear: @escaping () -> Void = {}
  ) {
    self._text = text
    self.placeholder = placeholder
    self.onSearch = onSearch
    self.onClear = onClear
  }

  public var body: some View {
    HStack(spacing: 12) {
      // Search icon
      Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)
        .font(.system(size: 16, weight: .medium))

      // Search text field
      TextField(placeholder, text: $text)
        .textFieldStyle(PlainTextFieldStyle())
        .focused($isFocused)
        .onSubmit {
          onSearch()
        }

      // Clear button
      if !text.isEmpty {
        Button(action: {
          text = ""
          onClear()
        }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
            .font(.system(size: 16))
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(.systemGray6))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
    )
  }
}

#Preview {
  VStack(spacing: 20) {
    SearchBar(text: .constant(""))
    SearchBar(text: .constant("Search query"))
  }
  .padding()
}
