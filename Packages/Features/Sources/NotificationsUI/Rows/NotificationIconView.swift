import SwiftUI

struct NotificationIconView: View {
  let icon: String
  let color: Color

  var body: some View {
    Image(systemName: icon)
      .font(.caption)
      .fontWeight(.semibold)
      .foregroundStyle(color)
      .frame(width: 16, height: 16)
      .background(
        Circle()
          .fill(.white)
          .overlay(
            Circle()
              .stroke(color, lineWidth: 1)
          )
      )
      .shadow(color: .shadowPrimary.opacity(0.3), radius: 2)
  }
}
