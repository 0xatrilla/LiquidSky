import Client
import DesignSystem
import Models
import PhotosUI
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ComposerToolbarView: ToolbarContent {
  @Binding var text: AttributedString
  @Binding var sendState: ComposerSendState

  @Environment(PostFilterService.self) private var postFilterService

  @State private var selectedPhotos: [PhotosPickerItem] = []
  @State private var selectedVideos: [PhotosPickerItem] = []
  @State private var showCamera = false
  @State private var showingAIPrompt = false
  @State private var aiPrompt: String = ""
  @State private var isAIGenerating = false
  @State private var aiError: String?

  var body: some ToolbarContent {
    ToolbarItem(placement: .keyboard) {
      PhotosPicker(selection: $selectedPhotos, matching: .images) {
        Image(systemName: "photo")
          .foregroundColor(.blue)
      }
      .onChange(of: selectedPhotos) { _, newValue in
        // TODO: Handle selected photos
        print("Selected photos: \(newValue.count)")
      }
    }

    ToolbarItem(placement: .keyboard) {
      PhotosPicker(selection: $selectedVideos, matching: .videos) {
        Image(systemName: "film")
          .foregroundColor(.blue)
      }
      .onChange(of: selectedVideos) { _, newValue in
        // TODO: Handle selected videos
        print("Selected videos: \(newValue.count)")
      }
    }

    ToolbarItem(placement: .keyboard) {
      Button {
        showCamera = true
      } label: {
        Image(systemName: "camera")
          .foregroundColor(.blue)
      }
      .sheet(isPresented: $showCamera) {
        CameraView { image in
          // TODO: Handle captured image
          print("Captured image")
        }
      }
    }

    ToolbarSpacer(placement: .keyboard)

    ToolbarItem(placement: .keyboard) {
      Button {
        insertText("@")
      } label: {
        Image(systemName: "at")
          .foregroundColor(postFilterService.canMentionUser("") ? .blue : .gray)
      }
      .disabled(!postFilterService.canMentionUser(""))
    }

    ToolbarItem(placement: .keyboard) {
      Button {
        insertText("#")
      } label: {
        Image(systemName: "tag")
          .foregroundColor(.blue)
      }
    }

    // AI Compose
    ToolbarItem(placement: .keyboard) {
      Button {
        showingAIPrompt = true
      } label: {
        Image(systemName: "sparkles")
          .symbolRenderingMode(.multicolor)
      }
      .disabled(!aiComposeAvailable())
      .sheet(isPresented: $showingAIPrompt) {
        AIPromptSheet(
          prompt: $aiPrompt,
          isGenerating: $isAIGenerating,
          errorMessage: $aiError,
          onCancel: { showingAIPrompt = false },
          onGenerate: { Task { await composeWithAI() } }
        )
      }
    }

    ToolbarItem(placement: .keyboard) {
      let text = String(text.characters)
      Text("\(300 - text.count)")
        .foregroundColor(text.count > 250 ? .red : .blue)
        .font(.subheadline)
        .contentTransition(.numericText(value: Double(text.count)))
        .monospacedDigit()
        .lineLimit(1)
        .animation(.smooth, value: text.count)
    }
  }

  // MARK: - Helper Methods

  private func insertText(_ string: String) {
    let currentText = String(text.characters)
    let newText = currentText + string
    text = AttributedString(newText)
  }

  // MARK: - AI Compose Helpers

  private func aiComposeAvailable() -> Bool {
    let aiEnabledByUser = SettingsService.shared.aiSummariesEnabled
    #if targetEnvironment(simulator)
    let aiGatedOK = aiEnabledByUser
    #else
    let aiGatedOK = aiEnabledByUser && SettingsService.shared.aiDeviceExperimentalEnabled
    #endif
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      return aiGatedOK
    } else {
      return false
    }
    #else
    return false
    #endif
  }

  private func dismissAIPrompt() {
    showingAIPrompt = false
    aiPrompt = ""
    isAIGenerating = false
    aiError = nil
  }

  private func appendToComposer(_ generated: String) {
    let current = String(text.characters)
    let combined = current.isEmpty ? generated : current + "\n" + generated
    text = AttributedString(combined)
  }

  private func composeWithAI() async {
    guard aiComposeAvailable() else {
      aiError = "Apple Intelligence not available. Enable AI in Settings or use a supported device (iOS 26+)."
      return
    }

    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      isAIGenerating = true
      defer { isAIGenerating = false }

      let userPrompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
      let instructions = userPrompt.isEmpty ? "Write a brief, engaging social post about today's highlights." : userPrompt

      let systemPrompt = """
      You are an assistant that writes short, engaging social media posts for Bluesky.
      Constraints:
      - Keep under 300 characters
      - Clear, friendly tone; avoid hashtags unless requested
      - No emojis unless explicitly asked
      - Output plain text only suitable to paste directly as a post
      """

      let session = LanguageModelSession { systemPrompt }
      do {
        #if DEBUG
        print("AI Compose: Requesting response for prompt: \(instructions)")
        #endif
        let response = try await session.respond(to: instructions)
        let generated = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        await MainActor.run {
          appendToComposer(generated)
          dismissAIPrompt()
        }
      } catch {
        #if DEBUG
        print("AI Compose: Error: \(error)")
        #endif
        await MainActor.run {
          aiError = "Failed to generate text. Please try again."
        }
      }
    }
    #endif
  }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
  let onImageCaptured: (UIImage) -> Void

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = .camera
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(onImageCaptured: onImageCaptured)
  }

  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let onImageCaptured: (UIImage) -> Void

    init(onImageCaptured: @escaping (UIImage) -> Void) {
      self.onImageCaptured = onImageCaptured
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let image = info[.originalImage] as? UIImage {
        onImageCaptured(image)
      }
      picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true)
    }
  }
}
