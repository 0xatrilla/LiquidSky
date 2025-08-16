import Models
import NukeUI
import SwiftUI

public struct MediaView: View {
  let media: Media
  let isQuote: Bool
  let namespace: Namespace.ID
  
  @Environment(ImageQualityService.self) private var imageQualityService

  public init(media: Media, isQuote: Bool = false, namespace: Namespace.ID) {
    self.media = media
    self.isQuote = isQuote
    self.namespace = namespace
  }

  public var body: some View {
    Group {
      switch media.mediaType {
      case .image:
        imageView
      case .video:
        videoView
      }
    }
    .aspectRatio(media.aspectRatio?.ratio ?? 16 / 9, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(
          LinearGradient(
            colors: [.shadowPrimary.opacity(0.3), .blue.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing),
          lineWidth: 1)
    )
    .shadow(color: .blue.opacity(0.3), radius: 3)
  }

  // MARK: - Image View

  private var imageView: some View {
    LazyImage(url: media.url, options: imageQualityService.getImageLoadingOptions()) { state in
      if let image = state.image {
        image
          .resizable()
          .scaledToFill()
          .aspectRatio(contentMode: .fit)
      } else {
        RoundedRectangle(cornerRadius: 8)
          .fill(.thinMaterial)
          .overlay(
            Image(systemName: "photo")
              .font(.title)
              .foregroundColor(.secondary)
          )
      }
    }
    .matchedTransitionSource(id: media.id, in: namespace)
    .onAppear {
      if imageQualityService.shouldPreloadImages() {
        preloadImage()
      }
    }
  }
  
  private func preloadImage() {
    // Preload the image using the quality service configuration
    let options = imageQualityService.getImageLoadingOptions()
    ImagePipeline.shared.loadImage(with: media.url, options: options) { _ in }
  }

  // MARK: - Video View

  private var videoView: some View {
    InlineVideoPlayerView(
      media: media,
      isQuote: isQuote,
      namespace: namespace
    )
  }
}
