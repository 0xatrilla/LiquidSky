import SwiftUI

public struct SummaryButtonView: View {
  let itemCount: Int
  let onTap: () -> Void

  @State private var isPressed = false

  public init(itemCount: Int, onTap: @escaping () -> Void) {
    self.itemCount = itemCount
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        isPressed = true
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        isPressed = false
        onTap()
      }
    }) {
      HStack(spacing: 8) {
        Image(systemName: "sparkles")
          .font(.subheadline)
          .symbolRenderingMode(.multicolor)

        Text("AI Summary")
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text("(\(itemCount) new)")
          .font(.caption)
          .foregroundStyle(.secondary)

        Image(systemName: "chevron.up")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(.quaternary, lineWidth: 0.5)
          )
      )
      .scaleEffect(isPressed ? 0.95 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  SummaryButtonView(itemCount: 15) {
    print("Summary button tapped")
  }
  .preferredColorScheme(.dark)
}
