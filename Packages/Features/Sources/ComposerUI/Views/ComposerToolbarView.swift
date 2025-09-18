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
  
  // Advanced AI features
  @State private var showingAIFeatures = false
  @State private var selectedAIFeature: AIFeature = .compose
  @State private var tone: ReplyTone = .friendly
  @State private var includeEmojis = true
  @State private var translationTargetLanguage: String = "en"
  @State private var isTranslating = false
  @State private var translationError: String?

  var body: some ToolbarContent {
    ToolbarItem(placement: .keyboard) {
      PhotosPicker(selection: $selectedPhotos, matching: .images) {
        Image(systemName: "photo")
          .foregroundColor(.blue)
      }
      .onChange(of: selectedPhotos) { _, newValue in
        // TODO: Handle selected photos
        #if DEBUG
          print("Selected photos: \(newValue.count)")
        #endif
      }
    }

    ToolbarItem(placement: .keyboard) {
      PhotosPicker(selection: $selectedVideos, matching: .videos) {
        Image(systemName: "film")
          .foregroundColor(.blue)
      }
      .onChange(of: selectedVideos) { _, newValue in
        // TODO: Handle selected videos
        #if DEBUG
          print("Selected videos: \(newValue.count)")
        #endif
      }
    }

    ToolbarItem(placement: .keyboard) {
      Button {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
          showCamera = true
        } else {
          #if DEBUG
            print("Camera not available on this device")
          #endif
        }
      } label: {
        Image(systemName: "camera")
          .foregroundColor(.blue)
      }
      .sheet(isPresented: $showCamera) {
        CameraView { image in
          // TODO: Handle captured image
          #if DEBUG
            print("Captured image")
          #endif
        }
      }
    }

    if #available(iOS 26.0, *) {
      ToolbarSpacer(placement: .keyboard)
    }

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

    // Advanced AI Features (only available on iOS 26+ with FoundationModels)
    if aiComposeAvailable() {
      ToolbarItem(placement: .keyboard) {
        Button {
          showingAIFeatures = true
        } label: {
          Image(systemName: "sparkles")
            .symbolRenderingMode(.multicolor)
        }
        .sheet(isPresented: $showingAIFeatures) {
          AdvancedAIFeaturesSheet(
            selectedFeature: $selectedAIFeature,
            tone: $tone,
            includeEmojis: $includeEmojis,
            translationTargetLanguage: $translationTargetLanguage,
            isGenerating: $isAIGenerating,
            isTranslating: $isTranslating,
            errorMessage: $aiError,
            translationError: $translationError,
            onCancel: { showingAIFeatures = false },
            onCompose: { Task { await composeWithAI() } },
            onTranslate: { Task { await translateText() } },
            onImprove: { Task { await improveText() } },
            onSummarize: { Task { await summarizeText() } }
          )
        }
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
    // Show AI on iOS 26+ when FoundationModels is available.
    // We removed user/device gates, so this returns true purely based on OS capability.
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) { return true } else { return false }
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
    let needsNewline = !current.isEmpty
    let newlineCost = needsNewline ? 1 : 0

    // Remaining character budget up to Bluesky's 300 character limit
    let remaining = max(0, 300 - current.count - newlineCost)

    if remaining == 0 {
      // No room to append anything
      #if DEBUG
        print("AI Compose: No remaining characters to append.")
      #endif
      aiError = "Post length limit reached (300 characters)."
      return
    }

    // Truncate AI output to fit remaining budget
    let clipped = String(generated.prefix(remaining))
    let combined = needsNewline ? current + "\n" + clipped : clipped
    text = AttributedString(combined)
  }

  private func composeWithAI() async {
    guard aiComposeAvailable() else {
      aiError = "Apple Intelligence not available. Enable AI in Settings or use a supported device (iOS 26.0+)."
      return
    }

    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        isAIGenerating = true
        defer { isAIGenerating = false }

        let userPrompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let instructions = userPrompt.isEmpty ? "Write a brief, engaging social post about today's highlights." : userPrompt

        let systemPrompt = buildComposeSystemPrompt()
        let session = LanguageModelSession { systemPrompt }
        
        do {
          let response = try await session.respond(to: instructions)
          let generated = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
          await MainActor.run {
            appendToComposer(generated)
            dismissAIPrompt()
          }
        } catch {
          await MainActor.run {
            aiError = "Failed to generate text. Please try again."
          }
        }
      }
    #endif
  }
  
  private func translateText() async {
    guard aiComposeAvailable() else {
      translationError = "Apple Intelligence not available for translation."
      return
    }
    
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        isTranslating = true
        defer { isTranslating = false }
        
        let currentText = String(text.characters)
        guard !currentText.isEmpty else {
          translationError = "No text to translate."
          return
        }
        
        let systemPrompt = """
        You are a professional translator. Translate the given text to \(translationTargetLanguage).
        Maintain the original tone and meaning.
        Return only the translated text, no explanations.
        """
        
        let session = LanguageModelSession { systemPrompt }
        
        do {
          let response = try await session.respond(to: currentText)
          let translated = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
          await MainActor.run {
            text = AttributedString(translated)
            translationError = nil
          }
        } catch {
          await MainActor.run {
            translationError = "Translation failed. Please try again."
          }
        }
      }
    #endif
  }
  
  private func improveText() async {
    guard aiComposeAvailable() else {
      aiError = "Apple Intelligence not available for text improvement."
      return
    }
    
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        isAIGenerating = true
        defer { isAIGenerating = false }
        
        let currentText = String(text.characters)
        guard !currentText.isEmpty else {
          aiError = "No text to improve."
          return
        }
        
        let systemPrompt = """
        Improve the following social media post for clarity, engagement, and impact.
        Keep it under 300 characters and maintain the original meaning.
        Make it more engaging and professional.
        Return only the improved text.
        """
        
        let session = LanguageModelSession { systemPrompt }
        
        do {
          let response = try await session.respond(to: currentText)
          let improved = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
          await MainActor.run {
            text = AttributedString(improved)
            aiError = nil
          }
        } catch {
          await MainActor.run {
            aiError = "Text improvement failed. Please try again."
          }
        }
      }
    #endif
  }
  
  private func summarizeText() async {
    guard aiComposeAvailable() else {
      aiError = "Apple Intelligence not available for summarization."
      return
    }
    
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        isAIGenerating = true
        defer { isAIGenerating = false }
        
        let currentText = String(text.characters)
        guard !currentText.isEmpty else {
          aiError = "No text to summarize."
          return
        }
        
        let systemPrompt = """
        Summarize the following text into a concise social media post.
        Keep it under 300 characters and maintain the key points.
        Make it engaging and clear.
        Return only the summarized text.
        """
        
        let session = LanguageModelSession { systemPrompt }
        
        do {
          let response = try await session.respond(to: currentText)
          let summarized = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
          await MainActor.run {
            text = AttributedString(summarized)
            aiError = nil
          }
        } catch {
          await MainActor.run {
            aiError = "Summarization failed. Please try again."
          }
        }
      }
    #endif
  }
  
  private func buildComposeSystemPrompt() -> String {
    let toneDescription = tone.description
    let emojiInstruction = includeEmojis ? "Use appropriate emojis sparingly." : "Do not use emojis."
    
    return """
    You are an assistant that writes short, engaging social media posts for Bluesky.
    Constraints:
    - Keep under 300 characters
    - Tone: \(toneDescription)
    - \(emojiInstruction)
    - Clear, engaging content
    - Output plain text only suitable to paste directly as a post
    """
  }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
  let onImageCaptured: (UIImage) -> Void

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = .camera
    picker.allowsEditing = false
    picker.cameraCaptureMode = .photo
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
      } else {
        #if DEBUG
          print("Failed to get image from camera")
        #endif
      }
      picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true)
    }
  }
}
