import SwiftUI

/// A custom large title header component that follows iOS design principles
public struct LargeTitleHeader: View {
  let title: String
  let subtitle: String?
  let icon: String?
  let iconColor: Color?
  let backgroundColor: Color
  let borderColor: Color

  public init(
    title: String,
    subtitle: String? = nil,
    icon: String? = nil,
    iconColor: Color? = nil,
    backgroundColor: Color = .clear,
    borderColor: Color = .white.opacity(0.1)
  ) {
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.iconColor = iconColor
    self.backgroundColor = backgroundColor
    self.borderColor = borderColor
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 16) {
        // Icon if provided
        if let icon = icon {
          Image(systemName: icon)
            .font(.system(size: 32, weight: .medium))
            .foregroundStyle(iconColor ?? .blue)
            .frame(width: 48, height: 48)
            .background(
              Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                  Circle()
                    .stroke(borderColor, lineWidth: 0.5)
                )
            )
        }

        VStack(alignment: .leading, spacing: 6) {
          // Main title with iOS large title styling
          Text(title)
            .font(.system(size: 34, weight: .bold, design: .default))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .minimumScaleFactor(0.8)

          // Subtitle if provided
          if let subtitle = subtitle {
            Text(subtitle)
              .font(.system(size: 17, weight: .regular, design: .default))
              .foregroundStyle(.secondary)
              .lineLimit(2)
              .minimumScaleFactor(0.9)
          }
        }

        Spacer()
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .background(
      NotificationGlassCard(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        shadowColor: .black.opacity(0.04),
        shadowRadius: 8,
        shadowOffset: CGSize(width: 0, height: 2)
      ) {
        HStack(alignment: .top, spacing: 16) {
          // Icon if provided
          if let icon = icon {
            Image(systemName: icon)
              .font(.system(size: 32, weight: .medium))
              .foregroundStyle(iconColor ?? .blue)
              .frame(width: 48, height: 48)
              .background(
                Circle()
                  .fill(.ultraThinMaterial)
                  .overlay(
                    Circle()
                      .stroke(borderColor, lineWidth: 0.5)
                  )
              )
          }

          VStack(alignment: .leading, spacing: 6) {
            // Main title with iOS large title styling
            Text(title)
              .font(.system(size: 34, weight: .bold, design: .default))
              .foregroundStyle(.primary)
              .lineLimit(2)
              .minimumScaleFactor(0.8)

            // Subtitle if provided
            if let subtitle = subtitle {
              Text(subtitle)
                .font(.system(size: 17, weight: .regular, design: .default))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
            }
          }

          Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
      }
    )
  }
}

/// A view modifier for large title headers
public struct LargeTitleHeaderModifier: ViewModifier {
  let title: String
  let subtitle: String?
  let icon: String?
  let iconColor: Color?
  let backgroundColor: Color
  let borderColor: Color

  public init(
    title: String,
    subtitle: String? = nil,
    icon: String? = nil,
    iconColor: Color? = nil,
    backgroundColor: Color = .clear,
    borderColor: Color = .white.opacity(0.1)
  ) {
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.iconColor = iconColor
    self.backgroundColor = backgroundColor
    self.borderColor = borderColor
  }

  public func body(content: Content) -> some View {
    VStack(spacing: 0) {
      LargeTitleHeader(
        title: title,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor,
        backgroundColor: backgroundColor,
        borderColor: borderColor
      )
      .padding(.horizontal, 16)

      content
    }
  }
}

/// Extension to add large title header modifier to any view
extension View {
  public func largeTitleHeader(
    title: String,
    subtitle: String? = nil,
    icon: String? = nil,
    iconColor: Color? = nil,
    backgroundColor: Color = .clear,
    borderColor: Color = .white.opacity(0.1)
  ) -> some View {
    modifier(
      LargeTitleHeaderModifier(
        title: title,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor,
        backgroundColor: backgroundColor,
        borderColor: borderColor
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
      // Large title header with icon
      LargeTitleHeader(
        title: "Notifications",
        subtitle: "Stay updated with your latest activity",
        icon: "bell.fill",
        iconColor: .blue
      )

      // Large title header without icon
      LargeTitleHeader(
        title: "Settings",
        subtitle: "Customize your app experience"
      )

      // Using the modifier
      VStack {
        Text("Content goes here")
          .padding()
      }
      .largeTitleHeader(
        title: "Profile",
        subtitle: "Manage your account",
        icon: "person.circle.fill",
        iconColor: .green
      )
    }
    .padding(20)
  }
}
