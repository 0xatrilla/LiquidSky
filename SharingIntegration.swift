import Foundation
import SwiftUI
import UniformTypeIdentifiers

@available(iPadOS 26.0, *)
@Observable
@MainActor
class SharingManager {
  // Sharing state
  var isShareSheetPresented = false
  var currentShareItem: ShareableItem?
  var shareSheetConfiguration: ShareSheetConfiguration?

  // AirDrop state
  var isAirDropAvailable = false
  var nearbyDevices: [AirDropDevice] = []

  // Universal Clipboard
  var universalClipboardEnabled = true
  var clipboardHistory: [ClipboardItem] = []

  // Custom sharing options
  var customSharingOptions: [CustomSharingOption] = []

  init() {
    setupSharingIntegration()
    createCustomSharingOptions()
    setupUniversalClipboard()
  }

  private func setupSharingIntegration() {
    // Check AirDrop availability
    checkAirDropAvailability()

    // Setup sharing notifications
    NotificationCenter.default.addObserver(
      forName: .shareCompleted,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      // Extract data from notification to avoid data race
      let notificationName = notification.name

      Task { @MainActor in
        self?.handleShareCompletion(name: notificationName)
      }
    }
  }

  private func checkAirDropAvailability() {
    // In a real implementation, this would check for AirDrop availability
    isAirDropAvailable = true
  }

  private func createCustomSharingOptions() {
    customSharingOptions = [
      CustomSharingOption(
        id: "glass-screenshot",
        title: "Share with Glass Effects",
        subtitle: "Include liquid glass visual effects",
        systemImage: "sparkles.rectangle.stack",
        action: .glassScreenshot,
        glassEffectEnabled: true
      ),
      CustomSharingOption(
        id: "rich-preview",
        title: "Rich Preview",
        subtitle: "Share with enhanced metadata",
        systemImage: "doc.richtext",
        action: .richPreview,
        glassEffectEnabled: true
      ),
      CustomSharingOption(
        id: "universal-clipboard",
        title: "Copy to Universal Clipboard",
        subtitle: "Available on all your devices",
        systemImage: "doc.on.clipboard",
        action: .universalClipboard,
        glassEffectEnabled: false
      ),
      CustomSharingOption(
        id: "qr-code",
        title: "Generate QR Code",
        subtitle: "Create QR code for easy sharing",
        systemImage: "qrcode",
        action: .qrCode,
        glassEffectEnabled: true
      ),
    ]
  }

  private func setupUniversalClipboard() {
    // Monitor clipboard changes
    NotificationCenter.default.addObserver(
      forName: UIPasteboard.changedNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleClipboardChange()
    }
  }

  // MARK: - Sharing Methods

  func shareItem(_ item: ShareableItem, from sourceView: UIView? = nil) {
    currentShareItem = item

    // Create share sheet configuration
    shareSheetConfiguration = ShareSheetConfiguration(
      item: item,
      sourceView: sourceView,
      customOptions: getRelevantCustomOptions(for: item),
      glassEffectEnabled: true
    )

    // Present share sheet
    isShareSheetPresented = true

    // Track sharing event
    trackSharingEvent(item)
  }

  private func getRelevantCustomOptions(for item: ShareableItem) -> [CustomSharingOption] {
    switch item.type {
    case .post:
      return customSharingOptions.filter {
        ["glass-screenshot", "rich-preview", "universal-clipboard"].contains($0.id)
      }
    case .image:
      return customSharingOptions.filter {
        ["glass-screenshot", "universal-clipboard", "qr-code"].contains($0.id)
      }
    case .text:
      return customSharingOptions.filter { ["universal-clipboard", "qr-code"].contains($0.id) }
    case .url:
      return customSharingOptions.filter {
        ["rich-preview", "universal-clipboard", "qr-code"].contains($0.id)
      }
    case .profile:
      return customSharingOptions.filter { ["rich-preview", "qr-code"].contains($0.id) }
    }
  }

  func executeCustomSharingOption(_ option: CustomSharingOption, for item: ShareableItem) {
    switch option.action {
    case .glassScreenshot:
      shareWithGlassEffects(item)
    case .richPreview:
      shareWithRichPreview(item)
    case .universalClipboard:
      copyToUniversalClipboard(item)
    case .qrCode:
      generateAndShareQRCode(item)
    }

    // Provide haptic feedback
    if option.glassEffectEnabled {
      provideGlassEffectFeedback()
    }
  }

  // MARK: - Custom Sharing Actions

  private func shareWithGlassEffects(_ item: ShareableItem) {
    // Create a version of the content with glass effects rendered
    let glassEffectItem = createGlassEffectVersion(item)

    // Share the enhanced version
    shareStandardItem(glassEffectItem)

    NotificationCenter.default.post(
      name: .glassEffectShareCompleted,
      object: nil,
      userInfo: ["item": item]
    )
  }

  private func shareWithRichPreview(_ item: ShareableItem) {
    // Create rich metadata
    let richMetadata = createRichMetadata(for: item)

    // Create enhanced shareable item
    let enhancedItem = ShareableItem(
      id: item.id,
      type: item.type,
      content: item.content,
      metadata: richMetadata,
      glassEffectData: item.glassEffectData
    )

    shareStandardItem(enhancedItem)
  }

  private func copyToUniversalClipboard(_ item: ShareableItem) {
    let clipboardItem = ClipboardItem(
      id: UUID().uuidString,
      content: item.content,
      type: item.type,
      timestamp: Date(),
      isUniversal: true
    )

    // Add to clipboard history
    clipboardHistory.insert(clipboardItem, at: 0)

    // Keep only last 10 items
    if clipboardHistory.count > 10 {
      clipboardHistory = Array(clipboardHistory.prefix(10))
    }

    // Copy to system clipboard
    copyToSystemClipboard(item)

    // Sync with Universal Clipboard (in a real implementation)
    syncWithUniversalClipboard(clipboardItem)

    NotificationCenter.default.post(
      name: .universalClipboardUpdated,
      object: nil,
      userInfo: ["item": clipboardItem]
    )
  }

  private func generateAndShareQRCode(_ item: ShareableItem) {
    // Generate QR code for the item
    let qrCodeData = generateQRCode(for: item)

    let qrCodeItem = ShareableItem(
      id: UUID().uuidString,
      type: .image,
      content: qrCodeData,
      metadata: ShareMetadata(
        title: "QR Code",
        description: "QR code for \(item.metadata?.title ?? "content")",
        thumbnailData: qrCodeData
      ),
      glassEffectData: nil
    )

    shareStandardItem(qrCodeItem)
  }

  // MARK: - AirDrop Integration

  func shareViaAirDrop(_ item: ShareableItem) {
    guard isAirDropAvailable else { return }

    // Create AirDrop-optimized version
    let airDropItem = createAirDropVersion(item)

    // Present AirDrop interface
    presentAirDropInterface(with: airDropItem)
  }

  private func createAirDropVersion(_ item: ShareableItem) -> ShareableItem {
    // Optimize for AirDrop transfer
    var optimizedContent = item.content

    // Add AirDrop-specific metadata
    let airDropMetadata = ShareMetadata(
      title: item.metadata?.title ?? "Shared from LiquidSky",
      description: item.metadata?.description,
      thumbnailData: item.metadata?.thumbnailData,
      sourceApp: "LiquidSky",
      glassEffectVersion: "1.0"
    )

    return ShareableItem(
      id: item.id,
      type: item.type,
      content: optimizedContent,
      metadata: airDropMetadata,
      glassEffectData: item.glassEffectData
    )
  }

  private func presentAirDropInterface(with item: ShareableItem) {
    // In a real implementation, this would present the AirDrop interface
    NotificationCenter.default.post(
      name: .airDropPresented,
      object: nil,
      userInfo: ["item": item]
    )
  }

  // MARK: - Helper Methods

  private func createGlassEffectVersion(_ item: ShareableItem) -> ShareableItem {
    // In a real implementation, this would render the content with glass effects
    return item
  }

  private func createRichMetadata(for item: ShareableItem) -> ShareMetadata {
    return ShareMetadata(
      title: item.metadata?.title ?? "Shared from LiquidSky",
      description: item.metadata?.description ?? "Content shared with Liquid Glass effects",
      thumbnailData: item.metadata?.thumbnailData,
      sourceApp: "LiquidSky",
      glassEffectVersion: "1.0",
      shareTimestamp: Date()
    )
  }

  private func shareStandardItem(_ item: ShareableItem) {
    // Convert to system shareable format
    let activityItems = convertToActivityItems(item)

    // Present system share sheet
    NotificationCenter.default.post(
      name: .presentSystemShareSheet,
      object: nil,
      userInfo: ["activityItems": activityItems]
    )
  }

  private func convertToActivityItems(_ item: ShareableItem) -> [Any] {
    var items: [Any] = []

    switch item.type {
    case .text:
      if let text = item.content as? String {
        items.append(text)
      }
    case .url:
      if let urlString = item.content as? String,
        let url = URL(string: urlString)
      {
        items.append(url)
      }
    case .image:
      if let imageData = item.content as? Data,
        let image = UIImage(data: imageData)
      {
        items.append(image)
      }
    case .post, .profile:
      // Convert to text representation
      if let textContent = extractTextContent(from: item) {
        items.append(textContent)
      }
    }

    return items
  }

  private func extractTextContent(from item: ShareableItem) -> String? {
    // Extract text representation of complex items
    return item.metadata?.title ?? "Shared from LiquidSky"
  }

  private func copyToSystemClipboard(_ item: ShareableItem) {
    let pasteboard = UIPasteboard.general

    switch item.type {
    case .text:
      if let text = item.content as? String {
        pasteboard.string = text
      }
    case .url:
      if let urlString = item.content as? String,
        let url = URL(string: urlString)
      {
        pasteboard.url = url
      }
    case .image:
      if let imageData = item.content as? Data,
        let image = UIImage(data: imageData)
      {
        pasteboard.image = image
      }
    case .post, .profile:
      if let textContent = extractTextContent(from: item) {
        pasteboard.string = textContent
      }
    }
  }

  private func syncWithUniversalClipboard(_ item: ClipboardItem) {
    // In a real implementation, this would sync with iCloud
    // for Universal Clipboard functionality
  }

  private func generateQRCode(for item: ShareableItem) -> Data {
    // In a real implementation, this would generate an actual QR code
    return Data()
  }

  private func provideGlassEffectFeedback() {
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred(intensity: 0.6)
  }

  private func trackSharingEvent(_ item: ShareableItem) {
    // Track sharing analytics
    NotificationCenter.default.post(
      name: .sharingEventTracked,
      object: nil,
      userInfo: [
        "itemType": item.type,
        "timestamp": Date(),
      ]
    )
  }

  @MainActor
  private func handleShareCompletion(name: Notification.Name) {
    // Handle share completion
    isShareSheetPresented = false
    currentShareItem = nil
    shareSheetConfiguration = nil
  }

  private func handleClipboardChange() {
    // Handle clipboard changes for Universal Clipboard
    guard universalClipboardEnabled else { return }

    let pasteboard = UIPasteboard.general

    if let string = pasteboard.string {
      let clipboardItem = ClipboardItem(
        id: UUID().uuidString,
        content: string,
        type: .text,
        timestamp: Date(),
        isUniversal: false
      )

      clipboardHistory.insert(clipboardItem, at: 0)
    }
  }
}

// MARK: - Data Models

@available(iPadOS 26.0, *)
struct ShareableItem {
  let id: String
  let type: ShareableItemType
  let content: Any
  let metadata: ShareMetadata?
  let glassEffectData: GlassEffectData?
}

@available(iPadOS 26.0, *)
enum ShareableItemType {
  case text, url, image, post, profile
}

@available(iPadOS 26.0, *)
struct ShareMetadata {
  let title: String?
  let description: String?
  let thumbnailData: Data?
  let sourceApp: String?
  let glassEffectVersion: String?
  let shareTimestamp: Date?

  init(
    title: String? = nil,
    description: String? = nil,
    thumbnailData: Data? = nil,
    sourceApp: String? = nil,
    glassEffectVersion: String? = nil,
    shareTimestamp: Date? = nil
  ) {
    self.title = title
    self.description = description
    self.thumbnailData = thumbnailData
    self.sourceApp = sourceApp
    self.glassEffectVersion = glassEffectVersion
    self.shareTimestamp = shareTimestamp
  }
}

@available(iPadOS 26.0, *)
struct GlassEffectData {
  let effectType: String
  let parameters: [String: Any]
  let renderingData: Data?
}

@available(iPadOS 26.0, *)
struct ShareSheetConfiguration {
  let item: ShareableItem
  let sourceView: UIView?
  let customOptions: [CustomSharingOption]
  let glassEffectEnabled: Bool
}

@available(iPadOS 26.0, *)
struct CustomSharingOption: Identifiable {
  let id: String
  let title: String
  let subtitle: String
  let systemImage: String
  let action: SharingAction
  let glassEffectEnabled: Bool
}

@available(iPadOS 26.0, *)
enum SharingAction {
  case glassScreenshot, richPreview, universalClipboard, qrCode
}

@available(iPadOS 26.0, *)
struct AirDropDevice {
  let id: String
  let name: String
  let deviceType: String
  let isAvailable: Bool
}

@available(iPadOS 26.0, *)
struct ClipboardItem: Identifiable {
  let id: String
  let content: Any
  let type: ShareableItemType
  let timestamp: Date
  let isUniversal: Bool
}

// MARK: - Sharing UI Components

@available(iPadOS 26.0, *)
struct GlassShareSheet: View {
  let configuration: ShareSheetConfiguration
  @Environment(\.sharingManager) var sharingManager
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        // Item preview
        shareItemPreview

        // Custom sharing options
        customSharingOptions

        // Standard sharing
        standardSharingButton
      }
      .padding()
      .navigationTitle("Share")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }

  @ViewBuilder
  private var shareItemPreview: some View {
    GestureAwareGlassCard(cornerRadius: 12, isInteractive: false) {
      VStack(alignment: .leading, spacing: 8) {
        if let title = configuration.item.metadata?.title {
          Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
        }

        if let description = configuration.item.metadata?.description {
          Text(description)
            .font(.body)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }

        HStack {
          Image(systemName: iconForItemType(configuration.item.type))
            .foregroundStyle(.blue)

          Text(configuration.item.type.displayName)
            .font(.caption)
            .foregroundStyle(.secondary)

          Spacer()
        }
      }
      .padding()
    }
  }

  @ViewBuilder
  private var customSharingOptions: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
      ForEach(configuration.customOptions) { option in
        Button {
          sharingManager.executeCustomSharingOption(option, for: configuration.item)
          dismiss()
        } label: {
          VStack(spacing: 8) {
            Image(systemName: option.systemImage)
              .font(.title2)
              .foregroundStyle(.blue)

            Text(option.title)
              .font(.caption.weight(.medium))
              .foregroundStyle(.primary)
              .multilineTextAlignment(.center)

            Text(option.subtitle)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity, minHeight: 80)
          .padding(12)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  private var standardSharingButton: some View {
    Button {
      // Use standard iOS sharing
      let activityVC = UIActivityViewController(
        activityItems: [configuration.item.metadata?.title ?? "Shared Item"],
        applicationActivities: nil
      )
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = windowScene.windows.first,
        let rootVC = window.rootViewController
      {
        rootVC.present(activityVC, animated: true)
      }
      dismiss()
    } label: {
      HStack {
        Image(systemName: "square.and.arrow.up")
        Text("More Sharing Options")
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(.blue, in: RoundedRectangle(cornerRadius: 12))
      .foregroundStyle(.white)
    }
    .background(.blue.opacity(0.1), in: Circle())
    .overlay(Circle().stroke(.blue.opacity(0.3), lineWidth: 1))
  }

  private func iconForItemType(_ type: ShareableItemType) -> String {
    switch type {
    case .text: return "text.alignleft"
    case .url: return "link"
    case .image: return "photo"
    case .post: return "bubble.left"
    case .profile: return "person.circle"
    }
  }
}

@available(iPadOS 26.0, *)
extension ShareableItemType {
  var displayName: String {
    switch self {
    case .text: return "Text"
    case .url: return "Link"
    case .image: return "Image"
    case .post: return "Post"
    case .profile: return "Profile"
    }
  }
}

// MARK: - Environment Key

@available(iPadOS 26.0, *)
struct SharingManagerKey: EnvironmentKey {
  static let defaultValue = SharingManager()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var sharingManager: SharingManager {
    get { self[SharingManagerKey.self] }
    set { self[SharingManagerKey.self] = newValue }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let shareCompleted = Notification.Name("shareCompleted")
  static let glassEffectShareCompleted = Notification.Name("glassEffectShareCompleted")
  static let universalClipboardUpdated = Notification.Name("universalClipboardUpdated")
  static let airDropPresented = Notification.Name("airDropPresented")
  static let presentSystemShareSheet = Notification.Name("presentSystemShareSheet")
  static let sharingEventTracked = Notification.Name("sharingEventTracked")
}
