import DesignSystem
import SwiftUI

/// Enhanced summary button for when there are 10+ new notifications
public struct EnhancedSummaryButtonView: View {
  let itemCount: Int
  let action: () -> Void

  @State private var isPressed = false

  public init(itemCount: Int, action: @escaping () -> Void) {
    self.itemCount = itemCount
    self.action = action
  }

  public var body: some View {
    Button(action: {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
        isPressed = true
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
          isPressed = false
        }
        action()
      }
    }) {
      HStack(spacing: 16) {
        // Icon with notification count
        ZStack {
          Circle()
            .fill(Color.blue.opacity(0.1))
            .frame(width: 48, height: 48)

          Image(systemName: "doc.text.magnifyingglass")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.blue)
        }

        VStack(alignment: .leading, spacing: 4) {
          Text("\(itemCount) new notifications")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)

          Text("Tap to see a quick summary")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()

        // Arrow indicator
        Image(systemName: "chevron.right")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.blue)
          .rotationEffect(.degrees(isPressed ? 90 : 0))
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 16)
              .stroke(Color.blue.opacity(0.2), lineWidth: 1)
          )
      )
      .scaleEffect(isPressed ? 0.95 : 1.0)
      .shadow(
        color: .black.opacity(0.05),
        radius: 8,
        x: 0,
        y: 2
      )
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  VStack(spacing: 20) {
    EnhancedSummaryButtonView(itemCount: 15) {
      print("Summary tapped")
    }

    EnhancedSummaryButtonView(itemCount: 42) {
      print("Summary tapped")
    }
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
