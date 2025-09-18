import SwiftUI
import Models

struct SemanticSearchResultCard: View {
  let result: SemanticSearchResult
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 8) {
        // Header with type and relevance
        HStack {
          Image(systemName: result.type.icon)
            .foregroundColor(result.type.color)
            .font(.caption)
          
          Text(result.type.title)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
          
          Spacer()
          
          Text("\(Int(result.relevanceScore * 100))%")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        
        // Content preview
        Text(result.matchedContent)
          .font(.subheadline)
          .lineLimit(3)
          .multilineTextAlignment(.leading)
          .foregroundColor(.primary)
        
        // Explanation
        if !result.explanation.isEmpty {
          Text(result.explanation)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
        
        // Relevance indicator
        HStack {
          ForEach(0..<5) { index in
            Circle()
              .fill(index < Int(result.relevanceScore * 5) ? Color.blue : Color.gray.opacity(0.3))
              .frame(width: 4, height: 4)
          }
          
          Spacer()
        }
      }
      .padding(12)
      .frame(width: 200, alignment: .leading)
      .background(Color(.systemBackground))
      .cornerRadius(12)
      .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

extension SemanticSearchResult.ResultType {
  var icon: String {
    switch self {
    case .post:
      return "bubble.left"
    case .user:
      return "person.circle"
    case .topic:
      return "tag"
    }
  }
  
  var title: String {
    switch self {
    case .post:
      return "Post"
    case .user:
      return "User"
    case .topic:
      return "Topic"
    }
  }
  
  var color: Color {
    switch self {
    case .post:
      return .blue
    case .user:
      return .green
    case .topic:
      return .orange
    }
  }
}

#Preview {
  HStack {
    SemanticSearchResultCard(
      result: SemanticSearchResult(
        type: .post,
        post: nil,
        user: nil,
        relevanceScore: 0.85,
        explanation: "Contains keywords about AI and technology",
        matchedContent: "This is a great post about artificial intelligence and machine learning..."
      ),
      onTap: { }
    )
    
    SemanticSearchResultCard(
      result: SemanticSearchResult(
        type: .user,
        post: nil,
        user: nil,
        relevanceScore: 0.92,
        explanation: "Expert in AI and technology",
        matchedContent: "AI Researcher @johndoe - Expert in machine learning and neural networks"
      ),
      onTap: { }
    )
  }
  .padding()
  .background(Color(.systemGray6))
}
