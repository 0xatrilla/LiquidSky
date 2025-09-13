import SwiftUI

/// A specialized glass card component for notifications with enhanced readability
public struct NotificationGlassCard<Content: View>: View {
  let content: Content
  let cornerRadius: CGFloat
  let backgroundColor: Color
  let borderColor: Color
  let borderWidth: CGFloat
  let shadowColor: Color
  let shadowRadius: CGFloat
  let shadowOffset: CGSize

  public init(
    cornerRadius: CGFloat = 16,
    backgroundColor: Color = .clear,
    borderColor: Color = .white.opacity(0.15),
    borderWidth: CGFloat = 0.5,
    shadowColor: Color = .black.opacity(0.08),
    shadowRadius: CGFloat = 12,
    shadowOffset: CGSize = CGSize(width: 0, height: 4),
    @ViewBuilder content: () -> Content
  ) {
    self.cornerRadius = cornerRadius
    self.backgroundColor = backgroundColor
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.shadowColor = shadowColor
    self.shadowRadius = shadowRadius
    self.shadowOffset = shadowOffset
    self.content = content()
  }

  public var body: some View {
    content
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(borderColor, lineWidth: borderWidth)
          )
      )
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(backgroundColor)
      )
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .shadow(
        color: shadowColor,
        radius: shadowRadius,
        x: shadowOffset.width,
        y: shadowOffset.height
      )
  }
}

/// A view modifier for notification glass cards
public struct NotificationGlassCardModifier: ViewModifier {
  let cornerRadius: CGFloat
  let backgroundColor: Color
  let borderColor: Color
  let borderWidth: CGFloat
  let shadowColor: Color
  let shadowRadius: CGFloat
  let shadowOffset: CGSize

  public init(
    cornerRadius: CGFloat = 16,
    backgroundColor: Color = .clear,
    borderColor: Color = .white.opacity(0.15),
    borderWidth: CGFloat = 0.5,
    shadowColor: Color = .black.opacity(0.08),
    shadowRadius: CGFloat = 12,
    shadowOffset: CGSize = CGSize(width: 0, height: 4)
  ) {
    self.cornerRadius = cornerRadius
    self.backgroundColor = backgroundColor
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.shadowColor = shadowColor
    self.shadowRadius = shadowRadius
    self.shadowOffset = shadowOffset
  }

  public func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(borderColor, lineWidth: borderWidth)
          )
      )
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(backgroundColor)
      )
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .shadow(
        color: shadowColor,
        radius: shadowRadius,
        x: shadowOffset.width,
        y: shadowOffset.height
      )
  }
}

/// Extension to add notification glass card modifier to any view
extension View {
  public func notificationGlassCard(
    cornerRadius: CGFloat = 16,
    backgroundColor: Color = .clear,
    borderColor: Color = .white.opacity(0.15),
    borderWidth: CGFloat = 0.5,
    shadowColor: Color = .black.opacity(0.08),
    shadowRadius: CGFloat = 12,
    shadowOffset: CGSize = CGSize(width: 0, height: 4)
  ) -> some View {
    modifier(
      NotificationGlassCardModifier(
        cornerRadius: cornerRadius,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        shadowColor: shadowColor,
        shadowRadius: shadowRadius,
        shadowOffset: shadowOffset
      ))
  }
}

#Preview {
  ZStack {
    // Background gradient
    LinearGradient(
      colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea()

    VStack(spacing: 20) {
      // Notification glass card example
      NotificationGlassCard {
        VStack(alignment: .leading, spacing: 16) {
          HStack(spacing: 12) {
            Circle()
              .fill(.blue)
              .frame(width: 44, height: 44)
              .overlay(
                Image(systemName: "person.fill")
                  .foregroundColor(.white)
              )

            VStack(alignment: .leading, spacing: 4) {
              Text("John Doe")
                .font(.subheadline)
                .fontWeight(.semibold)

              Text("liked your post")
                .font(.subheadline)
                .foregroundColor(.secondary)

              Text("2 hours ago")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
          }

          Text("This is a sample notification content that demonstrates the glass effect...")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(2)
            .padding(12)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
            )
        }
        .padding(16)
      }

      // Using the modifier
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 12) {
          Circle()
            .fill(.green)
            .frame(width: 44, height: 44)
            .overlay(
              Image(systemName: "star.fill")
                .foregroundColor(.white)
            )

          VStack(alignment: .leading, spacing: 4) {
            Text("Jane Smith")
              .font(.subheadline)
              .fontWeight(.semibold)

            Text("followed you")
              .font(.subheadline)
              .foregroundColor(.secondary)

            Text("1 hour ago")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()
        }
      }
      .padding(16)
      .notificationGlassCard()
    }
    .padding(20)
  }
}
