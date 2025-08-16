import SwiftUI

// MARK: - Settings Section Header
public struct SettingsSectionHeader: View {
  let title: String
  let icon: String
  let color: Color

  public init(title: String, icon: String, color: Color = .blueskyPrimary) {
    self.title = title
    self.icon = icon
    self.color = color
  }

  public var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.white)
        .frame(width: 32, height: 32)
        .background(
          LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .glowingRoundedRectangle(cornerRadius: 8)

      Text(title)
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }
}

// MARK: - Settings Toggle Row
public struct SettingsToggleRow: View {
  let title: String
  let subtitle: String?
  let icon: String
  let iconColor: Color
  @Binding var isOn: Bool

  public init(
    title: String,
    subtitle: String? = nil,
    icon: String,
    iconColor: Color = .blue,
    isOn: Binding<Bool>
  ) {
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.iconColor = iconColor
    self._isOn = isOn
  }

  public var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(iconColor)
        .frame(width: 24, height: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        if let subtitle = subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Toggle("", isOn: $isOn)
        .labelsHidden()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(uiColor: .secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 16)
  }
}

// MARK: - Settings Navigation Row
public struct SettingsNavigationRow: View {
  let title: String
  let subtitle: String?
  let icon: String
  let iconColor: Color
  let action: () -> Void

  public init(
    title: String,
    subtitle: String? = nil,
    icon: String,
    iconColor: Color = .blue,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.iconColor = iconColor
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Image(systemName: icon)
          .font(.title3)
          .foregroundColor(iconColor)
          .frame(width: 24, height: 24)

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.primary)

          if let subtitle = subtitle {
            Text(subtitle)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color(uiColor: .secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .padding(.horizontal, 16)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Settings Picker Row
public struct SettingsPickerRow<T: Hashable>: View {
  let title: String
  let subtitle: String?
  let icon: String
  let iconColor: Color
  let selection: Binding<T>
  private let _selection: Binding<T>
  let options: [T]
  let optionTitle: (T) -> String

  public init(
    title: String,
    subtitle: String? = nil,
    icon: String,
    iconColor: Color = .blue,
    selection: Binding<T>,
    options: [T],
    optionTitle: @escaping (T) -> String
  ) {
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.iconColor = iconColor
    self.selection = selection
    self._selection = selection
    self.options = options
    self.optionTitle = optionTitle
  }

  public var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(iconColor)
        .frame(width: 24, height: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        if let subtitle = subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Picker("", selection: selection) {
        ForEach(options, id: \.self) { option in
          Text(optionTitle(option))
            .tag(option)
        }
      }
      .pickerStyle(MenuPickerStyle())
      .labelsHidden()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(uiColor: .secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 16)
  }
}

// MARK: - Settings Button Row
public struct SettingsButtonRow: View {
  let title: String
  let subtitle: String?
  let icon: String
  let iconColor: Color
  let buttonTitle: String
  let buttonColor: Color
  let action: () -> Void

  public init(
    title: String,
    subtitle: String? = nil,
    icon: String,
    iconColor: Color = .blue,
    buttonTitle: String,
    buttonColor: Color = .red,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.iconColor = iconColor
    self.buttonTitle = buttonTitle
    self.buttonColor = buttonColor
    self.action = action
  }

  public var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(iconColor)
        .frame(width: 24, height: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        if let subtitle = subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Button(action: action) {
        Text(buttonTitle)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(buttonColor)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(uiColor: .secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 16)
  }
}

// MARK: - Settings Info Row
public struct SettingsInfoRow: View {
  let title: String
  let subtitle: String?
  let icon: String
  let iconColor: Color
  let value: String

  public init(
    title: String,
    subtitle: String? = nil,
    icon: String,
    iconColor: Color = .blue,
    value: String
  ) {
    self.title = title
    self.subtitle = subtitle
    self.icon = icon
    self.iconColor = iconColor
    self.value = value
  }

  public var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(iconColor)
        .frame(width: 24, height: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        if let subtitle = subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Text(value)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(uiColor: .secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 16)
  }
}
