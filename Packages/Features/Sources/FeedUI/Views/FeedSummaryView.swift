import SwiftUI
import Models

public struct FeedSummaryView: View {
    let summary: String
    let feedName: String
    let postCount: Int
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    
    private var isAIPowered: Bool {
        summary.contains("AI-Powered") || summary.contains("Apple Intelligence")
    }
    
    public init(summary: String, feedName: String, postCount: Int, onDismiss: @escaping () -> Void) {
        self.summary = summary
        self.feedName = feedName
        self.postCount = postCount
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Hero Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: isAIPowered ? "sparkles" : "doc.text.magnifyingglass")
                                        .font(.title2)
                                        .foregroundStyle(isAIPowered ? .purple : .blue)
                                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                                    
                                    Text("Feed Summary")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                }
                                
                                if isAIPowered {
                                    HStack(spacing: 4) {
                                        Image(systemName: "brain.head.profile")
                                            .font(.caption)
                                            .foregroundStyle(.purple)
                                        Text("Powered by Apple Intelligence")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.purple)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.purple.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                            
                            Spacer()
                            
                            Button("Done") {
                                onDismiss()
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.blue)
                            .clipShape(Capsule())
                        }
                        
                        // Stats Card
                        HStack(spacing: 16) {
                            StatCard(
                                icon: "person.2.fill",
                                title: "Feed",
                                value: feedName,
                                color: .green
                            )
                            
                            StatCard(
                                icon: "clock.fill",
                                title: "Period",
                                value: "12 hours",
                                color: .orange
                            )
                            
                            StatCard(
                                icon: "bubble.left.and.bubble.right.fill",
                                title: "Posts",
                                value: "\(postCount)",
                                color: .blue
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(.systemBackground),
                                Color(.systemGray6).opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Summary Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(cleanSummaryText(summary))
                            .font(.body)
                            .lineSpacing(6)
                            .textSelection(.enabled)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        
                        // Footer
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.secondary)
                            
                            Text(getFooterText())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("Generated \(Date().formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            isAnimating = isAIPowered
        }
    }
    
    private func cleanSummaryText(_ text: String) -> String {
        // Remove markdown headers and clean up formatting
        return text
            .replacingOccurrences(of: "**AI-Powered Feed Summary - Last 12 Hours**", with: "")
            .replacingOccurrences(of: "**Feed Summary - Last 12 Hours**", with: "")
            .replacingOccurrences(of: "*Summary generated using Apple Intelligence*", with: "")
            .replacingOccurrences(of: "*Basic summary generated.*", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func getFooterText() -> String {
        if isAIPowered {
            return "AI-generated insights from your feed activity"
        } else {
            return "Structured summary of recent feed activity"
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

#Preview {
    FeedSummaryView(
        summary: "The main discussions today centered around AI development and SwiftUI updates. Several developers shared their experiences with the new iOS 18 features, particularly focusing on the enhanced navigation APIs. There was also significant conversation about sustainable coding practices and the importance of code reviews in maintaining quality.",
        feedName: "Tech News",
        postCount: 23,
        onDismiss: {}
    )
}
