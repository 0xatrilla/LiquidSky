import DesignSystem
import SwiftUI

/// Enhanced load more button for pagination
public struct EnhancedLoadMoreButton: View {
  let action: () -> Void

  @State private var isLoading = false

  public init(action: @escaping () -> Void) {
    self.action = action
  }

  public var body: some View {
    Button(action: {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
        isLoading = true
      }

      action()

      // Reset loading state after a delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
          isLoading = false
        }
      }
    }) {
      HStack(spacing: 12) {
        if isLoading {
          ProgressView()
            .scaleEffect(0.8)
            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
        } else {
          Image(systemName: "arrow.down.circle")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.blue)
        }

        Text(isLoading ? "Loading..." : "Load More")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.blue)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.blue.opacity(0.2), lineWidth: 1)
          )
      )
      .shadow(
        color: .black.opacity(0.05),
        radius: 4,
        x: 0,
        y: 1
      )
    }
    .buttonStyle(.plain)
    .disabled(isLoading)
  }
}

#Preview {
  VStack(spacing: 20) {
    EnhancedLoadMoreButton {
      print("Load more tapped")
    }

    EnhancedLoadMoreButton {
      print("Load more tapped")
    }
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
