import Foundation
import SwiftUI

@available(iOS 18.0, *)
struct GestureAwareGlassButton: View {
  let title: String
  let systemImage: String?
  let action: () -> Void
  let style: GlassButton.GlassButtonStyle
  let isEnabled: Bool

  @Environment(\.gestureCoordinator) var gestureCoordinator
  @State private var isHovering = false
  @State private var hoverIntensity: CGFloat = 0
  @State private var isPencilHovering = false
  @State private var isPressed = false

  private let buttonId = UUID().uuidString

  init(
    _ title: String,
    systemImage: String? = nil,
    style: GlassButton.GlassButtonStyle = .regular,
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
    .buttonStyle(.plain)
    .disabled(!isEnabled)
    .scaleEffect(isPressed ? 0.95 : (isPencilHovering ? 1.05 : (isHovering ? 1.02 : 1.0)))
    .brightness(hoverIntensity * 0.1)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    .overlay {
      if isPencilHovering {
        RoundedRectangle(cornerRadius: 8)
          .stroke(.blue.opacity(hoverIntensity), lineWidth: 2)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(.blue.opacity(hoverIntensity), lineWidth: 2)
          )
      }
    }
    .enhancedHover(id: buttonId, glassEffect: true)
    .applePencilHover(id: buttonId) { hovering, location, intensity in
      withAnimation(.smooth(duration: 0.2)) {
        isPencilHovering = hovering
        hoverIntensity = intensity
      }
    }
    .onHover { hovering in
      withAnimation(.smooth(duration: 0.2)) {
        isHovering = hovering && !isPencilHovering
      }
    }
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          if !isPressed {
            withAnimation(.smooth(duration: 0.1)) {
              isPressed = true
            }
          }
        }
        .onEnded { _ in
          withAnimation(.smooth(duration: 0.1)) {
            isPressed = false
          }
        }
    )
    .keyboardNavigation(id: buttonId) { focused in
      // Handle keyboard focus
    } onKeyPress: { key in
      if key == .space || key == .return {
        action()
        return true
      }
      return false
    }
    .trackpadGestures(
      onRightClick: {
        // Show context menu or alternative action
      }
    )
  }

}

@available(iOS 18.0, *)
struct GestureAwareGlassCard<Content: View>: View {
  let content: Content
  let cornerRadius: CGFloat
  let padding: EdgeInsets
  let isInteractive: Bool
  let onTap: (() -> Void)?
  let onLongPress: (() -> Void)?

  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0
  @State private var dragOffset: CGSize = .zero
  @State private var scale: CGFloat = 1.0
  @State private var rotation: Angle = .zero

  private let cardId = UUID().uuidString

  init(
    cornerRadius: CGFloat = 12,
    padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
    isInteractive: Bool = false,
    onTap: (() -> Void)? = nil,
    onLongPress: (() -> Void)? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.cornerRadius = cornerRadius
    self.padding = padding
    self.isInteractive = isInteractive
    self.onTap = onTap
    self.onLongPress = onLongPress
  }

  var body: some View {
    content
      .padding(padding)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
      .scaleEffect(scale * (isPencilHovering ? 1.02 : (isHovering ? 1.01 : 1.0)))
      .rotationEffect(rotation)
      .offset(dragOffset)
      .brightness(hoverIntensity * 0.05)
      .overlay {
        if isPencilHovering {
          RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(.blue.opacity(hoverIntensity * 0.5), lineWidth: 1)
        }
      }
      .applePencilHover(id: cardId) { hovering, location, intensity in
        withAnimation(.smooth(duration: 0.3)) {
          isPencilHovering = hovering
          hoverIntensity = intensity
        }
      }
      .onHover { hovering in
        withAnimation(.smooth(duration: 0.2)) {
          isHovering = hovering && !isPencilHovering
        }
      }
      .onTapGesture {
        onTap?()
      }
      .onLongPressGesture {
        onLongPress?()
      }
      .multiTouchGestures(
        onPinch: { pinchScale in
          withAnimation(.interactiveSpring()) {
            scale = pinchScale
          }
        },
        onRotate: { rotationAngle in
          withAnimation(.interactiveSpring()) {
            rotation = rotationAngle
          }
        },
        onDrag: { value in
          if isInteractive {
            dragOffset = value.translation
          }
        }
      )
      .keyboardNavigation(id: cardId) { focused in
        // Handle keyboard focus for card
      }
  }
}

@available(iOS 18.0, *)
struct GestureAwareNavigationItem: View {
  let title: String
  let systemImage: String
  let isSelected: Bool
  let badgeCount: Int?
  let action: () -> Void

  @Environment(\.gestureCoordinator) var gestureCoordinator
  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0
  @State private var isFocused = false

  private let itemId = UUID().uuidString

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
            .background(.ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.red.opacity(0.3), lineWidth: 1))
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
      )
    }
    .buttonStyle(.plain)
    .scaleEffect(isPencilHovering ? 1.03 : (isHovering ? 1.01 : 1.0))
    .brightness(hoverIntensity * 0.1)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    .overlay {
      if isPencilHovering {
        RoundedRectangle(cornerRadius: 10)
          .stroke(.blue.opacity(hoverIntensity), lineWidth: 2)
          .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
          .overlay(RoundedRectangle(cornerRadius: 10).stroke(.blue.opacity(0.3), lineWidth: 1))
      }

      if isFocused {
        RoundedRectangle(cornerRadius: 10)
          .stroke(.primary, lineWidth: 2)
      }
    }
    .applePencilHover(id: itemId) { hovering, location, intensity in
      withAnimation(.smooth(duration: 0.2)) {
        isPencilHovering = hovering
        hoverIntensity = intensity
      }
    }
    .onHover { hovering in
      withAnimation(.smooth(duration: 0.2)) {
        isHovering = hovering && !isPencilHovering
      }
    }
    .keyboardNavigation(id: itemId) { focused in
      withAnimation(.smooth(duration: 0.2)) {
        isFocused = focused
      }
    } onKeyPress: { key in
      if key == .space || key == .return {
        action()
        return true
      }
      return false
    }
    .trackpadGestures(
      onRightClick: {
        // Show context menu for navigation item
      }
    )
    .animation(.smooth(duration: 0.2), value: isSelected)
  }
}

@available(iOS 18.0, *)
struct GestureAwareSearchBar: View {
  @Binding var text: String
  let placeholder: String
  let onSearchButtonClicked: (() -> Void)?

  @FocusState private var isFocused: Bool
  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0

  private let searchId = UUID().uuidString

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
        .background(.ultraThinMaterial)
        .enhancedHover(id: "\(searchId)-clear")
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(.ultraThinMaterial, in: Capsule())
    .background(.ultraThinMaterial, in: Capsule())
    .scaleEffect(isPencilHovering ? 1.02 : (isHovering ? 1.01 : 1.0))
    .brightness(hoverIntensity * 0.1)
    .overlay {
      if isPencilHovering {
        Capsule()
          .stroke(.blue.opacity(hoverIntensity), lineWidth: 2)
          .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
          .overlay(RoundedRectangle(cornerRadius: 10).stroke(.blue.opacity(0.3), lineWidth: 1))
      }

      if isFocused {
        Capsule()
          .stroke(.blue, lineWidth: 2)
      }
    }
    .applePencilHover(id: searchId) { hovering, location, intensity in
      withAnimation(.smooth(duration: 0.2)) {
        isPencilHovering = hovering
        hoverIntensity = intensity
      }
    }
    .onHover { hovering in
      withAnimation(.smooth(duration: 0.2)) {
        isHovering = hovering && !isPencilHovering
      }
    }
    .keyboardNavigation(id: searchId) { focused in
      isFocused = focused
    }
    .animation(.smooth(duration: 0.2), value: text.isEmpty)
  }
}

@available(iOS 18.0, *)
struct GestureAwareMediaView: View {
  let imageURL: URL?
  let aspectRatio: CGFloat?
  let onTap: (() -> Void)?

  @State private var scale: CGFloat = 1.0
  @State private var rotation: Angle = .zero
  @State private var dragOffset: CGSize = .zero
  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0

  private let mediaId = UUID().uuidString

  var body: some View {
    AsyncImage(url: imageURL) { image in
      image
        .resizable()
        .aspectRatio(aspectRatio, contentMode: .fit)
    } placeholder: {
      RoundedRectangle(cornerRadius: 12)
        .fill(.ultraThinMaterial)
        .overlay {
          Image(systemName: "photo")
            .font(.title)
            .foregroundStyle(.secondary)
        }
    }
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .scaleEffect(scale * (isPencilHovering ? 1.02 : (isHovering ? 1.01 : 1.0)))
    .rotationEffect(rotation)
    .offset(dragOffset)
    .brightness(hoverIntensity * 0.05)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    .overlay {
      if isPencilHovering {
        RoundedRectangle(cornerRadius: 12)
          .stroke(.blue.opacity(hoverIntensity * 0.5), lineWidth: 2)
          .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
          .overlay(RoundedRectangle(cornerRadius: 10).stroke(.blue.opacity(0.3), lineWidth: 1))
      }
    }
    .applePencilHover(id: mediaId) { hovering, location, intensity in
      withAnimation(.smooth(duration: 0.3)) {
        isPencilHovering = hovering
        hoverIntensity = intensity
      }
    }
    .onHover { hovering in
      withAnimation(.smooth(duration: 0.2)) {
        isHovering = hovering && !isPencilHovering
      }
    }
    .onTapGesture {
      onTap?()
    }
    .multiTouchGestures(
      onPinch: { pinchScale in
        withAnimation(.interactiveSpring()) {
          scale = max(0.5, min(3.0, pinchScale))
        }
      },
      onRotate: { rotationAngle in
        withAnimation(.interactiveSpring()) {
          rotation = rotationAngle
        }
      },
      onDrag: { value in
        dragOffset = value.translation
      }
    )
    .keyboardNavigation(id: mediaId) { focused in
      // Handle keyboard focus for media
    } onKeyPress: { key in
      switch key {
      case .space, .return:
        onTap?()
        return true
      case .escape:
        // Reset transformations
        withAnimation(.smooth(duration: 0.3)) {
          scale = 1.0
          rotation = .zero
          dragOffset = .zero
        }
        return true
      default:
        return false
      }
    }
  }
}
