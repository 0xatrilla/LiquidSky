import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
struct GlassButton: View {
  let title: String
  let systemImage: String?
  let action: () -> Void
  let style: GlassButtonStyle
  let isEnabled: Bool

  enum GlassButtonStyle {
    case regular
    case prominent
    case tinted(Color)
    case interactive
  }

  init(
    _ title: String,
    systemImage: String? = nil,
    style: GlassButtonStyle = .regular,
    isEnabled: Bool = true,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.systemImage = systemImage
    self.style = style
    self.isEnabled = isEnabled
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if let systemImage = systemImage {
          Image(systemName: systemImage)
            .font(.subheadline.weight(.medium))
        }
        Text(title)
          .font(.subheadline.weight(.medium))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .buttonStyle(glassButtonStyle)
    .disabled(!isEnabled)
  }

  private var glassButtonStyle: some PrimitiveButtonStyle {
    switch style {
    case .regular:
      return GlassRegularButtonStyle()
    case .prominent:
      return GlassProminentButtonStyle()
    case .tinted(let color):
      return GlassTintedButtonStyle(tint: color)
    case .interactive:
      return GlassInteractiveButtonStyle()
    }
  }
}

@available(iPadOS 26.0, *)
struct GlassRegularButtonStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .glassEffect(.regular)
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.smooth(duration: 0.1), value: configuration.isPressed)
  }
}

@available(iPadOS 26.0, *)
struct GlassProminentButtonStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(.white)
      .background(.blue, in: RoundedRectangle(cornerRadius: 8))
      .glassEffect(.regular.tint(.blue).interactive())
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.smooth(duration: 0.1), value: configuration.isPressed)
  }
}

@available(iPadOS 26.0, *)
struct GlassTintedButtonStyle: PrimitiveButtonStyle {
  let tint: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .glassEffect(.regular.tint(tint).interactive())
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.smooth(duration: 0.1), value: configuration.isPressed)
  }
}

@available(iPadOS 26.0, *)
struct GlassInteractiveButtonStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .glassEffect(.regular.interactive())
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.smooth(duration: 0.1), value: configuration.isPressed)
  }
}

// MARK: - Glass Card Component

@available(iPadOS 26.0, *)
struct GlassCard<Content: View>: View {
  let content: Content
  let cornerRadius: CGFloat
  let padding: EdgeInsets
  let isInteractive: Bool

  init(
    cornerRadius: CGFloat = 12,
    padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
    isInteractive: Bool = false,
    @ViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.cornerRadius = cornerRadius
    self.padding = padding
    self.isInteractive = isInteractive
  }

  var body: some View {
    content
      .padding(padding)
      .glassEffect(
        isInteractive ? .regular.interactive() : .regular,
        in: .rect(cornerRadius: cornerRadius)
      )
  }
}

// MARK: - Glass Toolbar Component

@available(iPadOS 26.0, *)
struct GlassToolbar<Content: View>: View {
  let content: Content
  let placement: ToolbarItemPlacement

  init(
    placement: ToolbarItemPlacement = .topBarTrailing,
    @ViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.placement = placement
  }

  var body: some View {
    ToolbarItemGroup(placement: placement) {
      HStack(spacing: 12) {
        content
      }
      .padding(.horizontal, 8)
      .glassEffect(.regular.interactive(), in: .capsule)
    }
  }
}

// MARK: - Glass Navigation Item

@available(iPadOS 26.0, *)
struct GlassNavigationItem: View {
  let title: String
  let systemImage: String
  let isSelected: Bool
  let badgeCount: Int?
  let action: () -> Void

  @Environment(\.glassEffectManager) var glassEffectManager
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: systemImage)
          .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
          .foregroundStyle(isSelected ? .primary : .secondary)

        Text(title)
          .font(.subheadline.weight(isSelected ? .semibold : .regular))
          .foregroundStyle(isSelected ? .primary : .secondary)

        Spacer()

        if let badgeCount = badgeCount, badgeCount > 0 {
          Text("\(badgeCount)")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.red, in: Capsule())
            .glassEffect(.regular.tint(.red))
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(isSelected ? .blue.opacity(0.15) : .clear)
      )
    }
    .buttonStyle(.plain)
    .glassEffect(
      glassEffectManager.shouldUseSimplifiedEffects()
        ? .regular
        : .regular.interactive(),
      in: .rect(cornerRadius: 10)
    )
    .onHover { hovering in
      withAnimation(.smooth(duration: 0.2)) {
        isHovered = hovering
      }
    }
    .scaleEffect(isHovered ? 1.02 : 1.0)
    .animation(.smooth(duration: 0.2), value: isSelected)
  }
}

// MARK: - Glass Section Header

@available(iPadOS 26.0, *)
struct GlassSectionHeader: View {
  let title: String
  let subtitle: String?

  init(_ title: String, subtitle: String? = nil) {
    self.title = title
    self.subtitle = subtitle
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.headline.weight(.semibold))
        .foregroundStyle(.primary)

      if let subtitle = subtitle {
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .glassEffect(.regular, in: .rect(cornerRadius: 8))
  }
}

// MARK: - Glass Loading View

@available(iPadOS 26.0, *)
struct GlassLoadingView: View {
  let message: String
  @State private var isAnimating = false

  init(message: String = "Loading...") {
    self.message = message
  }

  var body: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)
        .rotationEffect(.degrees(isAnimating ? 360 : 0))
        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)

      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(24)
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    .onAppear {
      isAnimating = true
    }
  }
}

// MARK: - Glass Error View

@available(iPadOS 26.0, *)
struct GlassErrorView: View {
  let title: String
  let message: String
  let retryAction: (() -> Void)?

  init(
    title: String = "Something went wrong",
    message: String,
    retryAction: (() -> Void)? = nil
  ) {
    self.title = title
    self.message = message
    self.retryAction = retryAction
  }

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 32))
        .foregroundStyle(.orange)
        .glassEffect(.regular.tint(.orange))

      VStack(spacing: 8) {
        Text(title)
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        Text(message)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      if let retryAction = retryAction {
        GlassButton("Try Again", systemImage: "arrow.clockwise", style: .prominent) {
          retryAction()
        }
      }
    }
    .padding(24)
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
  }
}

// MARK: - Glass Search Bar

@available(iPadOS 26.0, *)
struct GlassSearchBar: View {
  @Binding var text: String
  let placeholder: String
  let onSearchButtonClicked: (() -> Void)?

  @FocusState private var isFocused: Bool

  init(
    text: Binding<String>,
    placeholder: String = "Search...",
    onSearchButtonClicked: (() -> Void)? = nil
  ) {
    self._text = text
    self.placeholder = placeholder
    self.onSearchButtonClicked = onSearchButtonClicked
  }

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.secondary)

      TextField(placeholder, text: $text)
        .textFieldStyle(.plain)
        .focused($isFocused)
        .onSubmit {
          onSearchButtonClicked?()
        }

      if !text.isEmpty {
        Button(action: { text = "" }) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive())
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .glassEffect(.regular.interactive(), in: .capsule)
    .animation(.smooth(duration: 0.2), value: text.isEmpty)
  }
}
