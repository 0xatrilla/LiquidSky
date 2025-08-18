import Models
import SwiftUI
import UIKit

public struct AppIconPickerView: View {
  @Binding var selectedIcon: AppIcon
  @Environment(\.dismiss) private var dismiss

  public init(selectedIcon: Binding<AppIcon>) {
    self._selectedIcon = selectedIcon
  }

  public var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 8) {
            Text("Choose App Icon")
              .font(.title2)
              .fontWeight(.bold)

            Text("Select your preferred app icon")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.top, 16)

          // Icon Grid
          LazyVGrid(
            columns: [
              GridItem(.flexible()),
              GridItem(.flexible()),
            ], spacing: 20
          ) {
            ForEach(AppIcon.allCases, id: \.self) { icon in
              AppIconOptionView(
                icon: icon,
                isSelected: selectedIcon == icon
              ) {
                if icon != selectedIcon {
                  changeAppIcon(to: icon)
                }
              }
            }
          }
          .padding(.horizontal, 20)

          Spacer()
        }
      }
      .background(Color(.systemGroupedBackground))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }

  private func changeAppIcon(to icon: AppIcon) {
    guard UIApplication.shared.supportsAlternateIcons else {
      // Fallback for devices that don't support alternate icons
      selectedIcon = icon
      return
    }

    let iconName = icon.iconName

    UIApplication.shared.setAlternateIconName(iconName) { error in
      DispatchQueue.main.async {
        if let error = error {
          print("Error changing app icon: \(error)")
          // Still update the selection even if the change fails
          // The user can restart the app to see the change
        }
        selectedIcon = icon
      }
    }
  }
}

// MARK: - App Icon Option View
private struct AppIconOptionView: View {
  let icon: AppIcon
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 12) {
        // Icon Preview
        Image(icon.previewImageName)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 80, height: 80)
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .overlay(
            RoundedRectangle(cornerRadius: 16)
              .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
          )

        // Icon Name
        Text(icon.displayName)
          .font(.headline)
          .foregroundColor(.primary)

        // Selection Indicator
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            .foregroundColor(.blue)
        }
      }
      .padding(.vertical, 16)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.secondarySystemGroupedBackground))
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  AppIconPickerView(selectedIcon: .constant(.cloud))
}
