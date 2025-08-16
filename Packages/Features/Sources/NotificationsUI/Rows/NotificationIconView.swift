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
          .fill(Color(uiColor: .systemBackground))
          .overlay(
            Circle()
              .stroke(color, lineWidth: 2)
          )
      )
      .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
  }
}
