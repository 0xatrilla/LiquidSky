import Models
import SwiftUI

@available(iOS 26.0, *)
public struct SmartRepliesToolbar: View {
    @Binding var text: AttributedString
    @Binding var selection: AttributedTextSelection
    @State private var isExpanded = false
    @State private var suggestions: [ReplySuggestion] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    let post: PostItem?
    let onInsertSuggestion: (String) -> Void
    
    public init(
        text: Binding<AttributedString>,
        selection: Binding<AttributedTextSelection>,
        post: PostItem?,
        onInsertSuggestion: @escaping (String) -> Void
    ) {
        self._text = text
        self._selection = selection
        self.post = post
        self.onInsertSuggestion = onInsertSuggestion
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Collapse/Expand Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                
                if isExpanded && suggestions.isEmpty && post != nil {
                    Task {
                        await loadSuggestions()
                    }
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.up" : "sparkles")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(isExpanded ? "Hide Smart Replies" : "Smart Replies")
                        .font(.system(size: 14, weight: .medium))
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Smart Replies Content
            if isExpanded {
                VStack(spacing: 0) {
                    if isLoading {
                        loadingView
                    } else if let error = error {
                        errorView(error)
                    } else if suggestions.isEmpty {
                        emptyView
                    } else {
                        suggestionsView
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Generating smart replies...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }
    
    private func errorView(_ error: Error) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
            Text("Failed to load suggestions")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Retry") {
                Task {
                    await loadSuggestions()
                }
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var emptyView: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.secondary)
            Text("No smart replies available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }
    
    private var suggestionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(suggestions) { suggestion in
                    SmartReplySuggestionCard(
                        suggestion: suggestion,
                        onTap: {
                            insertSuggestion(suggestion.text)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions
    
    private func loadSuggestions() async {
        guard let post = post else { return }
        
        isLoading = true
        error = nil
        
        do {
            let context = ReplyContext(
                type: .thread,
                description: "Reply to post by @\(post.author.handle)"
            )
            
            suggestions = await SmartReplyService.shared.generateReplySuggestions(
                for: post,
                context: context
            )
            
            // Simulate potential error for demonstration
            if suggestions.isEmpty {
                throw NSError(domain: "SmartReplies", code: 1, userInfo: [NSLocalizedDescriptionKey: "No suggestions generated"])
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func insertSuggestion(_ suggestionText: String) {
        onInsertSuggestion(suggestionText)
        
        // Collapse the toolbar after selection
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
}

// MARK: - Smart Reply Suggestion Card

@available(iOS 26.0, *)
private struct SmartReplySuggestionCard: View {
    let suggestion: ReplySuggestion
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                HStack {
                    Text(suggestion.tone.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: 200, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {
            // Long press action if needed
        }
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    VStack {
        SmartRepliesToolbar(
            text: .constant(AttributedString("")),
            selection: .constant(AttributedTextSelection()),
            post: nil,
            onInsertSuggestion: { _ in }
        )
        
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
