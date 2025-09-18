import SwiftUI
import Models

struct ReplySuggestionsSheet: View {
  let suggestions: [ReplySuggestion]
  let isLoading: Bool
  let error: String?
  let onSelectSuggestion: (ReplySuggestion) -> Void
  let onDismiss: () -> Void
  
  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        if isLoading {
          loadingView
        } else if let error = error {
          errorView(error)
        } else if suggestions.isEmpty {
          emptyView
        } else {
          suggestionsList
        }
      }
      .navigationTitle("Reply Suggestions")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            onDismiss()
          }
        }
      }
    }
  }
  
  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)
      
      Text("Generating suggestions...")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  private func errorView(_ error: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundColor(.orange)
      
      Text("Unable to generate suggestions")
        .font(.headline)
      
      Text(error)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      
      Button("Try Again") {
        // This would need to be passed as a callback
        onDismiss()
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  private var emptyView: some View {
    VStack(spacing: 16) {
      Image(systemName: "bubble.left.and.bubble.right")
        .font(.system(size: 48))
        .foregroundColor(.secondary)
      
      Text("No suggestions available")
        .font(.headline)
      
      Text("Try writing your own reply or check back later.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  private var suggestionsList: some View {
    List {
      ForEach(suggestions) { suggestion in
        ReplySuggestionRow(
          suggestion: suggestion,
          onSelect: { onSelectSuggestion(suggestion) }
        )
      }
    }
    .listStyle(PlainListStyle())
  }
}

struct ReplySuggestionRow: View {
  let suggestion: ReplySuggestion
  let onSelect: () -> Void
  
  var body: some View {
    Button(action: onSelect) {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(suggestion.text)
            .font(.body)
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
          
          Spacer()
          
          Image(systemName: "arrow.up.left")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        
        HStack {
          Text(suggestion.tone.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(toneColor.opacity(0.2))
            .foregroundColor(toneColor)
            .cornerRadius(8)
          
          Spacer()
        }
      }
      .padding(.vertical, 4)
    }
    .buttonStyle(PlainButtonStyle())
  }
  
  private var toneColor: Color {
    switch suggestion.tone {
    case .friendly, .supportive, .celebratory:
      return .green
    case .professional:
      return .blue
    case .casual, .thoughtful:
      return .orange
    case .curious, .grateful:
      return .purple
    }
  }
}

#Preview {
  ReplySuggestionsSheet(
    suggestions: [
      ReplySuggestion(text: "Great point! I totally agree with this perspective.", tone: .supportive),
      ReplySuggestion(text: "Thanks for sharing this - it's really helpful!", tone: .grateful),
      ReplySuggestion(text: "I hadn't thought about it that way before. Could you elaborate?", tone: .curious),
      ReplySuggestion(text: "This is exactly what I needed to hear today! 🙌", tone: .celebratory)
    ],
    isLoading: false,
    error: nil,
    onSelectSuggestion: { _ in },
    onDismiss: { }
  )
}
