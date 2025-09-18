import Client
import Models
import SwiftUI

@available(iOS 26.0, *)
struct ComposerTextEditorView: View {
  @Binding var text: AttributedString
  @Binding var selection: AttributedTextSelection
  @Environment(BSkyClient.self) private var client

  let sendState: ComposerSendState
  let post: PostItem? // Add post parameter for smart replies
  @FocusState private var isFocused: Bool

  @State private var isPlaceholder = true
  @State private var processor = ComposerTextProcessor()
  @State private var autocompleteService: ComposerAutocompleteService?
  @State private var autocompleteContext: AutocompleteContext?
  @State private var showAutocomplete = false

  var body: some View {
    ZStack(alignment: .topLeading) {
      VStack(spacing: 0) {
        ZStack(alignment: .topLeading) {
          TextEditor(text: $text, selection: $selection)
            .textInputFormattingControlVisibility(.hidden, for: .all)
            .font(.system(size: 20))
            .frame(maxWidth: .infinity)
            .padding()
            .focused($isFocused)
            .textEditorStyle(.plain)
            .disabled(sendState == .loading)
            .attributedTextFormattingDefinition(ComposerFormattingDefinition())
            .onAppear {
              isFocused = true
              setupAutocompleteService()
            }
            .onChange(of: text, initial: true) { oldValue, newValue in
              isPlaceholder = newValue.characters.isEmpty
              processor.processText(&text)
              checkForAutocomplete()
            }

          if isPlaceholder {
            Text("What's on your mind?")
              .font(.system(size: 20))
              .foregroundStyle(.secondary)
              .padding()
              .padding(.top, 8)
              .allowsHitTesting(false)
          }
        }

        // Autocomplete overlay
        if showAutocomplete, let context = autocompleteContext,
          let autocompleteService = autocompleteService
        {
          ComposerAutocompleteView(
            autocompleteService: autocompleteService,
            onUserSelected: { user in
              insertAutocompleteSuggestion(user.handle, context: context)
            },
            onHashtagSelected: { hashtag in
              insertAutocompleteSuggestion(hashtag.tag, context: context)
            }
          )
          .padding(.horizontal)
          .padding(.bottom)
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        
        // Original Post Context (only show for replies)
        if let post = post {
          ComposerPostContextView(post: post)
        }
      }
    }
  }

  // MARK: - Autocomplete Setup

  private func setupAutocompleteService() {
    autocompleteService = ComposerAutocompleteService(client: client)
  }

  private func checkForAutocomplete() {
    guard let autocompleteService = autocompleteService else { return }

    let plainText = String(text.characters)

    // Check if the text ends with @ or # followed by some text
    if let context = processor.detectAutocompleteContext(from: plainText) {
      // Update the context to get the latest query
      autocompleteContext = context
      showAutocomplete = true

      // Always trigger search to get updated suggestions
      Task {
        switch context.type {
        case .mention:
          // For mentions, search with the current query (even if empty)
          await autocompleteService.searchUsers(query: context.cleanQuery)
        case .hashtag:
          // For hashtags, search with the current query (even if empty)
          await autocompleteService.searchHashtags(query: context.cleanQuery)
        }
      }
    } else {
      // No autocomplete context found, hide suggestions
      showAutocomplete = false
      autocompleteService.clearSuggestions()
    }
  }

  private func insertAutocompleteSuggestion(_ suggestion: String, context: AutocompleteContext) {
    let plainText = String(text.characters)

    // Replace the @query or #query with the selected suggestion
    let beforeQuery = String(plainText.prefix(context.startIndex))
    let afterQuery = String(
      plainText.suffix(from: plainText.index(plainText.startIndex, offsetBy: context.endIndex)))

    let newText =
      beforeQuery + (context.type == .mention ? "@" : "#") + suggestion + " " + afterQuery

    // Update the text
    text = AttributedString(newText)

    // Hide autocomplete
    showAutocomplete = false
    autocompleteService?.clearSuggestions()

    // Set focus back to text editor
    isFocused = true
  }
}
