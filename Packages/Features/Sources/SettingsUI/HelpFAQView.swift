import SwiftUI
import DesignSystem

public struct HelpFAQView: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HeaderView(title: "Help & FAQ", showBack: true)
                        .padding(.horizontal, 16)
                    
                    // FAQ Items
                    VStack(spacing: 16) {
                        FAQItem(
                            question: "How do I change my password?",
                            answer: "Go to Settings → Account → Change Password. You'll need to enter your current password and then your new password twice."
                        )
                        
                        FAQItem(
                            question: "How do I customize my feed?",
                            answer: "Go to Settings → Feed to choose your default feed and control what content is displayed."
                        )
                        
                        FAQItem(
                            question: "How do I manage notifications?",
                            answer: "Go to Settings → Content to control push notifications and email updates."
                        )
                        
                        FAQItem(
                            question: "How do I change the app theme?",
                            answer: "Go to Settings → Display → App Theme to choose between light, dark, or system themes."
                        )
                        
                        FAQItem(
                            question: "How do I report a bug?",
                            answer: "Go to Settings → Support → Report a Bug to submit an issue report."
                        )
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - FAQ Item
private struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HelpFAQView()
}
