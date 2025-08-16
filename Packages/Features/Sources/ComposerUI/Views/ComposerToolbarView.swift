import Client
import DesignSystem
import Models
import PhotosUI
import SwiftUI

struct ComposerToolbarView: ToolbarContent {
  @Binding var text: AttributedString
  @Binding var sendState: ComposerSendState
  
  @Environment(PostFilterService.self) private var postFilterService

  @State private var selectedPhotos: [PhotosPickerItem] = []
  @State private var selectedVideos: [PhotosPickerItem] = []
  @State private var showCamera = false

  var body: some ToolbarContent {
    ToolbarItem(placement: .keyboard) {
      PhotosPicker(selection: $selectedPhotos, matching: .images) {
        Image(systemName: "photo")
          .foregroundStyle(.blue)
      }
      .onChange(of: selectedPhotos) { _, newValue in
        // TODO: Handle selected photos
        print("Selected photos: \(newValue.count)")
      }
    }

    ToolbarItem(placement: .keyboard) {
      PhotosPicker(selection: $selectedVideos, matching: .videos) {
        Image(systemName: "film")
          .foregroundStyle(.blue)
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
          .foregroundStyle(.blue)
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
          .foregroundStyle(postFilterService.canMentionUser("") ? .blue : .gray)
      }
      .disabled(!postFilterService.canMentionUser(""))
    }

    ToolbarItem(placement: .keyboard) {
      Button {
        insertText("#")
      } label: {
        Image(systemName: "tag")
          .foregroundStyle(.blue)
      }
    }

    ToolbarItem(placement: .keyboard) {
      let text = String(text.characters)
      Text("\(300 - text.count)")
        .foregroundStyle(text.count > 250 ? .red : .blue)
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
