import SwiftUI

/// Enhanced notification icon view with modern design
public struct EnhancedNotificationIconView: View {
  let icon: String
  let color: Color

  @State private var isAnimating = false

  public init(icon: String, color: Color) {
    self.icon = icon
    self.color = color
  }

  public var body: some View {
    ZStack {
      // Background circle with subtle glow
      Circle()
        .fill(.white)
        .frame(width: 20, height: 20)
        .shadow(
          color: color.opacity(0.3),
          radius: 4,
          x: 0,
          y: 2
        )

      // Icon with enhanced styling
      Image(systemName: icon)
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(color)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(
          .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true),
          value: isAnimating
        )
    }
    .onAppear {
      isAnimating = true
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    HStack(spacing: 16) {
      EnhancedNotificationIconView(icon: "heart.fill", color: .red)
      EnhancedNotificationIconView(icon: "arrow.2.squarepath", color: .green)
      EnhancedNotificationIconView(icon: "message.fill", color: .blue)
      EnhancedNotificationIconView(icon: "person.fill.badge.plus", color: .purple)
    }

    HStack(spacing: 16) {
      EnhancedNotificationIconView(icon: "quote.bubble.fill", color: .orange)
      EnhancedNotificationIconView(icon: "at", color: .pink)
      EnhancedNotificationIconView(icon: "bell.fill", color: .yellow)
      EnhancedNotificationIconView(icon: "star.fill", color: .indigo)
    }
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
