import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
struct AccessibilitySettingsView: View {
  @Environment(\.dismiss) var dismiss
  @State private var accessibilityManager = AccessibilityManager()
  @State private var voiceOverSupport = VoiceOverSupport()
  @State private var dynamicTypeSupport = DynamicTypeSupport()
  @State private var visualAccessibilitySupport = VisualAccessibilitySupport()

  @State private var selectedTab: AccessibilityTab = .general

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Tab selector
        accessibilityTabSelector

        // Content based on selected tab
        TabView(selection: $selectedTab) {
          generalAccessibilitySettings
            .tag(AccessibilityTab.general)

          voiceOverSettings
            .tag(AccessibilityTab.voiceOver)

          visualSettings
            .tag(AccessibilityTab.visual)

          motionSettings
            .tag(AccessibilityTab.motion)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
      }
      .navigationTitle("Accessibility Settings")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  // MARK: - Tab Selector

  @ViewBuilder
  private var accessibilityTabSelector: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(AccessibilityTab.allCases, id: \.self) { tab in
          Button {
            withAnimation(.smooth(duration: 0.3)) {
              selectedTab = tab
            }
          } label: {
            tabButtonLabel(for: tab)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal)
    }
    .background(.ultraThinMaterial)
  }
  
  @ViewBuilder
  private func tabButtonLabel(for tab: AccessibilityTab) -> some View {
    VStack(spacing: 4) {
      Image(systemName: tab.icon)
        .font(.subheadline)

      Text(tab.title)
        .font(.caption.weight(.medium))
    }
    .foregroundStyle(selectedTab == tab ? .blue : .secondary)
    .frame(minWidth: 80)
    .padding(.vertical, 12)
    .padding(.horizontal, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
    )
  }

  // MARK: - General Accessibility Settings

  @ViewBuilder
  private var generalAccessibilitySettings: some View {
    Form {
      Section("Glass Effects") {
        Picker("Glass Effect Mode", selection: $accessibilityManager.glassEffectAccessibilityMode) {
          ForEach(GlassEffectAccessibilityMode.allCases, id: \.self) { mode in
            VStack(alignment: .leading, spacing: 2) {
              Text(mode.displayName)
                .font(.subheadline.weight(.medium))
              Text(mode.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .tag(mode)
          }
        }
        .pickerStyle(.navigationLink)

        Toggle("Detailed Descriptions", isOn: $accessibilityManager.detailedDescriptions)
        Toggle("Navigation Announcements", isOn: $accessibilityManager.navigationAnnouncements)
      }

      Section("Haptic Feedback") {
        Picker("Haptic Level", selection: $accessibilityManager.hapticFeedbackLevel) {
          ForEach(HapticFeedbackLevel.allCases, id: \.self) { level in
            Text(level.displayName)
              .tag(level)
          }
        }
        .pickerStyle(.segmented)
      }

      Section("System Settings") {
        AccessibilitySystemStatusRow(
          title: "VoiceOver",
          isEnabled: accessibilityManager.isVoiceOverEnabled,
          icon: "speaker.wave.3",
          description: "Screen reader for blind and low-vision users"
        )

        AccessibilitySystemStatusRow(
          title: "Switch Control",
          isEnabled: accessibilityManager.isSwitchControlEnabled,
          icon: "switch.2",
          description: "Control your device with switches"
        )

        AccessibilitySystemStatusRow(
          title: "Voice Control",
          isEnabled: accessibilityManager.isVoiceControlEnabled,
          icon: "mic",
          description: "Control your device with your voice"
        )
      }
    }
  }

  // MARK: - VoiceOver Settings

  @ViewBuilder
  private var voiceOverSettings: some View {
    Form {
      Section("VoiceOver Configuration") {
        Toggle("VoiceOver Enabled", isOn: $voiceOverSupport.isEnabled)
          .disabled(true)

        if voiceOverSupport.isEnabled {
          Picker("Verbosity Level", selection: $voiceOverSupport.verbosityLevel) {
            ForEach(VerbosityLevel.allCases, id: \.self) { level in
              Text(level.displayName)
                .tag(level)
            }
          }
          .pickerStyle(.segmented)

          Slider(
            value: $voiceOverSupport.speechRate,
            in: 0.1...1.0,
            step: 0.1
          ) {
            Text("Speech Rate")
          } minimumValueLabel: {
            Text("Slow")
              .font(.caption)
          } maximumValueLabel: {
            Text("Fast")
              .font(.caption)
          }
        }
      }

      Section("Navigation Support") {
        Toggle("Custom Rotors", isOn: .constant(!voiceOverSupport.customRotors.isEmpty))
          .disabled(true)

        Toggle("Landmark Navigation", isOn: .constant(!voiceOverSupport.landmarkElements.isEmpty))
          .disabled(true)

        if voiceOverSupport.isEnabled {
          VStack(alignment: .leading, spacing: 8) {
            Text("Available Rotors")
              .font(.subheadline.weight(.medium))

            ForEach(Array(voiceOverSupport.customRotors.enumerated()), id: \.offset) { index, rotor in
              HStack {
                Image(systemName: "rotate.3d")
                  .foregroundStyle(.blue)
                Text(rotor)
                  .font(.body)
                Spacer()
              }
              .padding(.vertical, 4)
            }
          }
        }
      }

      Section("Glass Effect Accessibility") {
        VStack(alignment: .leading, spacing: 12) {
          Text(
            "VoiceOver provides enhanced descriptions for glass effects, including transparency levels and interactive states."
          )
          .font(.body)
          .foregroundStyle(.secondary)

          if voiceOverSupport.isEnabled {
            HStack {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
              Text("Glass effects are fully accessible")
                .font(.body)
            }
          } else {
            HStack {
              Image(systemName: "info.circle")
                .foregroundStyle(.blue)
              Text("Enable VoiceOver in Settings to access glass effect descriptions")
                .font(.body)
            }
          }
        }
      }
    }
  }

  // MARK: - Visual Settings

  @ViewBuilder
  private var visualSettings: some View {
    Form {
      Section("High Contrast") {
        Toggle("High Contrast", isOn: $visualAccessibilitySupport.isHighContrastEnabled)
          .disabled(true)

        Picker("Contrast Level", selection: $visualAccessibilitySupport.contrastLevel) {
          ForEach(ContrastLevel.allCases, id: \.self) { level in
            VStack(alignment: .leading, spacing: 2) {
              Text(level.displayName)
                .font(.subheadline.weight(.medium))
              Text("Ratio: \(level.contrastRatio, specifier: "%.1f"):1")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .tag(level)
          }
        }
        .pickerStyle(.navigationLink)
      }

      Section("Transparency") {
        Toggle(
          "Reduce Transparency",
          isOn: $visualAccessibilitySupport.isReduceTransparencyEnabled
        )
        .disabled(true)

        if visualAccessibilitySupport.isReduceTransparencyEnabled {
          Picker("Transparency Level", selection: $visualAccessibilitySupport.transparencyLevel) {
            ForEach(TransparencyLevel.allCases, id: \.self) { level in
              Text(level.displayName)
                .tag(level)
            }
          }
          .pickerStyle(.segmented)
        }
      }

      Section("Visual Indicators") {
        Toggle("Button Shapes", isOn: .constant(visualAccessibilitySupport.isButtonShapesEnabled))
          .disabled(true)

        Toggle("On/Off Labels", isOn: .constant(visualAccessibilitySupport.isOnOffLabelsEnabled))
          .disabled(true)

        Toggle(
          "Differentiate Without Color",
          isOn: .constant(visualAccessibilitySupport.isDifferentiateWithoutColorEnabled)
        )
        .disabled(true)
      }

      Section("Dynamic Type") {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Current Size")
              .font(.subheadline.weight(.medium))
            Spacer()
            Text(dynamicTypeSupport.currentSizeCategory.displayName)
              .font(.body)
              .foregroundStyle(.secondary)
          }

          if dynamicTypeSupport.isAccessibilitySizeEnabled {
            HStack {
              Image(systemName: "textformat.size")
                .foregroundStyle(.blue)
              Text("Accessibility size enabled")
                .font(.body)
            }
          }
        }

        Toggle("Adaptive Layout", isOn: $dynamicTypeSupport.adaptiveLayoutEnabled)
      }
    }
  }

  // MARK: - Motion Settings

  @ViewBuilder
  private var motionSettings: some View {
    Form {
      Section("Motion Preferences") {
        Toggle("Reduce Motion", isOn: $visualAccessibilitySupport.isReduceMotionEnabled)
          .disabled(true)

        if visualAccessibilitySupport.isReduceMotionEnabled {
          Picker("Motion Level", selection: $visualAccessibilitySupport.motionLevel) {
            ForEach(MotionLevel.allCases, id: \.self) { level in
              Text(level.displayName)
                .tag(level)
            }
          }
          .pickerStyle(.segmented)

          Toggle(
            "Prefer Cross-Fade Transitions",
            isOn: $visualAccessibilitySupport.prefersCrossFadeTransitions)
        }
      }

      Section("Glass Effect Animations") {
        VStack(alignment: .leading, spacing: 12) {
          Text("Glass effects adapt to your motion preferences:")
            .font(.subheadline.weight(.medium))

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(
                systemName: visualAccessibilitySupport.isReduceMotionEnabled
                  ? "checkmark.circle.fill" : "circle"
              )
              .foregroundStyle(
                visualAccessibilitySupport.isReduceMotionEnabled ? .green : .secondary)
              Text("Simplified animations")
                .font(.body)
            }

            HStack {
              Image(
                systemName: visualAccessibilitySupport.prefersCrossFadeTransitions
                  ? "checkmark.circle.fill" : "circle"
              )
              .foregroundStyle(
                visualAccessibilitySupport.prefersCrossFadeTransitions ? .green : .secondary)
              Text("Cross-fade transitions")
                .font(.body)
            }

            HStack {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
              Text("Maintained functionality")
                .font(.body)
            }
          }
          .padding(.leading)
        }
      }

      Section("Performance Impact") {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Animation Performance")
              .font(.subheadline.weight(.medium))
            Spacer()
            Text(visualAccessibilitySupport.isReduceMotionEnabled ? "Optimized" : "Standard")
              .font(.body)
              .foregroundStyle(visualAccessibilitySupport.isReduceMotionEnabled ? .green : .blue)
          }

          Text(
            "Reduced motion settings improve battery life and reduce visual distraction while maintaining full app functionality."
          )
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }
    }
  }
}

// MARK: - Supporting Views

@available(iPadOS 26.0, *)
struct AccessibilitySystemStatusRow: View {
  let title: String
  let isEnabled: Bool
  let icon: String
  let description: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundStyle(isEnabled ? .green : .secondary)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline.weight(.medium))

        Text(description)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text(isEnabled ? "Enabled" : "Disabled")
        .font(.caption.weight(.medium))
        .foregroundStyle(isEnabled ? .green : .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(isEnabled ? .green.opacity(0.1) : .secondary.opacity(0.1))
        )
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Accessibility Tab Enum

@available(iPadOS 26.0, *)
enum AccessibilityTab: String, CaseIterable {
  case general = "general"
  case voiceOver = "voiceOver"
  case visual = "visual"
  case motion = "motion"

  var title: String {
    switch self {
    case .general: return "General"
    case .voiceOver: return "VoiceOver"
    case .visual: return "Visual"
    case .motion: return "Motion"
    }
  }

  var icon: String {
    switch self {
    case .general: return "accessibility"
    case .voiceOver: return "speaker.wave.3"
    case .visual: return "eye"
    case .motion: return "motion.up.down"
    }
  }
}

// MARK: - ContentSizeCategory Extension

@available(iPadOS 26.0, *)
extension ContentSizeCategory {
  var displayName: String {
    switch self {
    case .extraSmall: return "Extra Small"
    case .small: return "Small"
    case .medium: return "Medium"
    case .large: return "Large"
    case .extraLarge: return "Extra Large"
    case .extraExtraLarge: return "Extra Extra Large"
    case .extraExtraExtraLarge: return "Extra Extra Extra Large"
    case .accessibilityMedium: return "Accessibility Medium"
    case .accessibilityLarge: return "Accessibility Large"
    case .accessibilityExtraLarge: return "Accessibility Extra Large"
    case .accessibilityExtraExtraLarge: return "Accessibility Extra Extra Large"
    case .accessibilityExtraExtraExtraLarge: return "Accessibility Extra Extra Extra Large"
    @unknown default: return "Unknown"
    }
  }
}

// MARK: - Missing Type Definitions

@available(iPadOS 26.0, *)
enum VerbosityLevel: CaseIterable {
  case minimal, standard, detailed
  
  var displayName: String {
    switch self {
    case .minimal: return "Minimal"
    case .standard: return "Standard"
    case .detailed: return "Detailed"
    }
  }
}

@available(iPadOS 26.0, *)
enum ContrastLevel: CaseIterable {
  case normal, high, maximum
  
  var displayName: String {
    switch self {
    case .normal: return "Normal"
    case .high: return "High"
    case .maximum: return "Maximum"
    }
  }
  
  var contrastRatio: Double {
    switch self {
    case .normal: return 4.5
    case .high: return 7.0
    case .maximum: return 21.0
    }
  }
}

@available(iPadOS 26.0, *)
enum TransparencyLevel: CaseIterable {
  case normal, reduced, maximum
  
  var displayName: String {
    switch self {
    case .normal: return "Normal"
    case .reduced: return "Reduced"
    case .maximum: return "Maximum"
    }
  }
}

@available(iPadOS 26.0, *)
enum MotionLevel: CaseIterable {
  case normal, reduced, disabled
  
  var displayName: String {
    switch self {
    case .normal: return "Normal"
    case .reduced: return "Reduced"
    case .disabled: return "Disabled"
    }
  }
}

// MARK: - Data Model Classes

@available(iPadOS 26.0, *)
@Observable
@MainActor
class VoiceOverSupport {
  var isEnabled: Bool = false
  var verbosityLevel: VerbosityLevel = .standard
  var speechRate: Double = 0.5
  var customRotors: [String] = []
  var landmarkElements: [String] = []
}

@available(iPadOS 26.0, *)
@Observable
@MainActor
class DynamicTypeSupport {
  var adaptiveLayoutEnabled: Bool = true
  var preferredSizeCategory: ContentSizeCategory = .large
  var currentSizeCategory: ContentSizeCategory = .large
  var isAccessibilitySizeEnabled: Bool = false
}

@available(iPadOS 26.0, *)
@Observable
@MainActor
class VisualAccessibilitySupport {
  var isHighContrastEnabled: Bool = false
  var contrastLevel: ContrastLevel = .normal
  var transparencyLevel: TransparencyLevel = .normal
  var isReduceMotionEnabled: Bool = false
  var motionLevel: MotionLevel = .normal
  var isReduceTransparencyEnabled: Bool = false
  var prefersCrossFadeTransitions: Bool = false
  var isButtonShapesEnabled: Bool = false
  var isOnOffLabelsEnabled: Bool = false
  var isDifferentiateWithoutColorEnabled: Bool = false
}

// Note: GlassEffectAccessibilityMode is defined in AccessibilityManager.swift
