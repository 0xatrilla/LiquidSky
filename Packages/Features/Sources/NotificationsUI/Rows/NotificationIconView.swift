import SwiftUI

struct NotificationIconView: View {
  let icon: String
  let color: Color

  var body: some View {
    Image(systemName: icon)
      .font(.caption)
      .fontWeight(.semibold)
      .foregroundStyle(color)
      .frame(width: 20, height: 20)
      .background(
        Circle()
          .fill(.ultraThinMaterial)
          .overlay(
            Circle()
              .stroke(color.opacity(0.8), lineWidth: 1.5)
          )
      )
      .background(
        Circle()
          .fill(color.opacity(0.1))
          .blur(radius: 4)
      )
      .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)
  }
}
