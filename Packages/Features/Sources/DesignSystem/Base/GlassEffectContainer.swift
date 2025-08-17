import SwiftUI

/// A container that applies a modern glass morphism effect
public struct GlassEffectContainer<Content: View>: View {
  let content: Content
  let blurRadius: CGFloat
  let cornerRadius: CGFloat
  let backgroundColor: Color
  let borderColor: Color
  let borderWidth: CGFloat

  public init(
    blurRadius: CGFloat = 20,
    cornerRadius: CGFloat = 16,
    backgroundColor: Color = .white.opacity(0.1),
    borderColor: Color = .white.opacity(0.2),
    borderWidth: CGFloat = 1,
    @ViewBuilder content: () -> Content
  ) {
    self.blurRadius = blurRadius
    self.cornerRadius = cornerRadius
    self.backgroundColor = backgroundColor
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.content = content()
  }

  public var body: some View {
    content
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(backgroundColor)
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(borderColor, lineWidth: borderWidth)
          )
      )
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(.ultraThinMaterial)
          .blur(radius: blurRadius)
      )
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
  }
}

/// A view modifier that applies glass morphism effects
public struct GlassEffectModifier: ViewModifier {
  let blurRadius: CGFloat
  let cornerRadius: CGFloat
  let backgroundColor: Color
  let borderColor: Color
  let borderWidth: CGFloat

  public init(
    blurRadius: CGFloat = 20,
    cornerRadius: CGFloat = 16,
    backgroundColor: Color = .white.opacity(0.1),
    borderColor: Color = .white.opacity(0.2),
    borderWidth: CGFloat = 1
  ) {
    self.blurRadius = blurRadius
    self.cornerRadius = cornerRadius
    self.backgroundColor = backgroundColor
    self.borderColor = borderColor
    self.borderWidth = borderWidth
  }

  public func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(backgroundColor)
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(borderColor, lineWidth: borderWidth)
          )
      )
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(.ultraThinMaterial)
          .blur(radius: blurRadius)
      )
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
  }
}

/// Extension to add glass effect modifier to any view
extension View {
  public func glassEffect(
    blurRadius: CGFloat = 20,
    cornerRadius: CGFloat = 16,
    backgroundColor: Color = .white.opacity(0.1),
    borderColor: Color = .white.opacity(0.2),
    borderWidth: CGFloat = 1
  ) -> some View {
    modifier(
      GlassEffectModifier(
        blurRadius: blurRadius,
        cornerRadius: cornerRadius,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderWidth: borderWidth
      ))
  }

  public func glassEffect(in shape: some Shape) -> some View {
    self
      .background(.ultraThinMaterial)
      .clipShape(shape)
  }
}

#Preview {
  ZStack {
    // Background gradient
    LinearGradient(
      colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea()

    VStack(spacing: 20) {
      // Glass container example
      GlassEffectContainer {
        VStack(spacing: 12) {
          Image(systemName: "bell.fill")
            .font(.title)
            .foregroundColor(.blue)

          Text("Glass Container")
            .font(.headline)
            .foregroundColor(.primary)

          Text("Modern glass morphism effect")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(20)
      }

      // Glass effect modifier example
      VStack(spacing: 12) {
        Image(systemName: "star.fill")
          .font(.title)
          .foregroundColor(.yellow)

        Text("Glass Modifier")
          .font(.headline)
          .foregroundColor(.primary)

        Text("Applied with view modifier")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(20)
      .glassEffect()
    }
  }
}
