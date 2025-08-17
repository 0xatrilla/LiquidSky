import Client
import SwiftUI

struct ComposerTextEditorView: View {
  @Binding var text: AttributedString
  @Binding var selection: AttributedTextSelection
  @Environment(BSkyClient.self) private var client

  let sendState: ComposerSendState
  @FocusState private var isFocused: Bool

  @State private var isPlaceholder = true
  // @State private var processor = ComposerTextProcessor() // Removed text processor
  // @State private var autocompleteService: ComposerAutocompleteService?
  // @State private var autocompleteContext: AutocompleteContext?
  // @State private var showAutocomplete = false

  var body: some View {
    ZStack(alignment: .topLeading) {
      VStack(spacing: 0) {
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
            // setupAutocompleteService() // Removed autocomplete setup
          }
          .onChange(of: text, initial: true) { oldValue, newValue in
            isPlaceholder = newValue.characters.isEmpty
            // processor.processText(&text) // Removed text processing
            // checkForAutocomplete() // Removed autocomplete check
          }

        if isPlaceholder {
          Text("What's on your mind?")
            .font(.system(size: 20))
            .foregroundStyle(.secondary)
            .padding()
            .padding(.top, 6)
            .padding(.leading, 8)
        }

        // Autocomplete overlay
        // if showAutocomplete, let context = autocompleteContext, // Removed autocomplete overlay
        //   let autocompleteService = autocompleteService
        // {
        //   ComposerAutocompleteView(
        //     autocompleteService: autocompleteService,
        //     onUserSelected: { user in
        //       insertAutocompleteSuggestion(user.handle, context: context)
        //     },
        //     onHashtagSelected: { hashtag in
        //       insertAutocompleteSuggestion(hashtag.tag, context: context)
        //     }
        //   )
        //   .padding(.horizontal)
        //   .padding(.bottom)
        //   .transition(.move(edge: .bottom).combined(with: .opacity))
        // }
      }
    }
  }

  // MARK: - Autocomplete Setup

  // private func setupAutocompleteService() { // Removed autocomplete setup function
  //   autocompleteService = ComposerAutocompleteService(client: client)
  // }

  // private func checkForAutocomplete() { // Removed autocomplete check function
  //   guard let autocompleteService = autocompleteService else { return }

  //   let plainText = String(text.characters)

  //   // Check if the text ends with @ or # followed by some text
  //   if let context = processor.detectAutocompleteContext(from: plainText) {
  //     autocompleteContext = context

  //     // Only show autocomplete if we have a query (not just the symbol)
  //     if !context.isJustSymbol {
  //       showAutocomplete = true

  //       // Trigger search based on context type
  //       Task {
  //         switch context.type {
  //         case .mention:
  //           await autocompleteService.searchUsers(query: context.cleanQuery)
  //         case .hashtag:
  //           await autocompleteService.searchHashtags(query: context.cleanQuery)
  //         }
  //       }
  //     } else {
  //       showAutocomplete = false
  //       autocompleteService.clearSuggestions()
  //     }
  //   } else {
  //     showAutocomplete = false
  //     autocompleteService.clearSuggestions()
  //   }
  // }

  // private func insertAutocompleteSuggestion(_ suggestion: String, context: AutocompleteContext) { // Removed autocomplete insertion function
  //   let plainText = String(text.characters)

  //   // Replace the @query or #query with the selected suggestion
  //   let beforeQuery = String(plainText.prefix(context.startIndex))
  //   let afterQuery = String(
  //     plainText.suffix(from: plainText.index(plainText.startIndex, offsetBy: context.endIndex)))

  //   let newText = beforeQuery + (context.type == .mention ? "@" : "#") + suggestion + afterQuery

  //   // Update the text
  //   text = AttributedString(newText)

  //   // Hide autocomplete
  //   showAutocomplete = false
  //   autocompleteService?.clearSuggestions()

  //   // Set focus back to text editor
  //   isFocused = true
  // }
}
