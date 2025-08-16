import DesignSystem
import Foundation
import Models
import Nuke
import NukeUI
import SwiftUI

public struct FullScreenMediaView: View {
  @Environment(\.dismiss) private var dismiss

  let images: [Media]
  let preloadedImage: URL?
  let namespace: Namespace.ID

  @State private var isFirstImageLoaded: Bool = false
  @State private var isSaved: Bool = false
  @State private var scrollPosition: Media?
  @State private var isAltVisible: Bool = false

  @GestureState private var zoom = 1.0

  public init(images: [Media], preloadedImage: URL?, namespace: Namespace.ID) {
    self.images = images
    self.preloadedImage = preloadedImage
    self.namespace = namespace
  }

  var firstImageURL: URL? {
    if let preloadedImage, !isFirstImageLoaded {
      return preloadedImage
    }
    return images.first?.url
  }

  public var body: some View {
    NavigationStack {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack {
          ForEach(images.indices, id: \.self) { index in
            let media = images[index]

            if media.mediaType == .image {
              makeImageView(media: media, index: index)
            } else {
              makeVideoView(media: media, index: index)
            }
          }
        }
        .scrollTargetLayout()
      }
      .scrollPosition(id: $scrollPosition)
      .toolbar {
        leadingToolbar
        trailingToolbar
      }
      .scrollContentBackground(.hidden)
      .scrollTargetBehavior(.viewAligned)
      .task {
        scrollPosition = images.first
        if let firstMedia = images.first, firstMedia.mediaType == .image {
          do {
            let data = try await ImagePipeline.shared.data(for: .init(url: firstMedia.url))
            if !data.0.isEmpty {
              self.isFirstImageLoaded = true
            }
          } catch {}
        }
      }
    }
    .navigationTransition(.zoom(sourceID: images[0].id, in: namespace))
  }

  // MARK: - Image View

  private func makeImageView(media: Media, index: Int) -> some View {
    LazyImage(
      request: .init(
        url: index == 0 ? firstImageURL : media.url,
        priority: .veryHigh)
    ) { state in
      if let image = state.image {
        image
          .resizable()
          .scaledToFill()
          .aspectRatio(contentMode: .fit)
          .scaleEffect(zoom)
          .gesture(
            MagnifyGesture()
              .updating($zoom) { value, gestureState, transaction in
                gestureState = value.magnification
              }
          )
      } else {
        RoundedRectangle(cornerRadius: 8)
          .fill(.thinMaterial)
      }
    }
    .containerRelativeFrame([.horizontal, .vertical])
    .id(media)
  }

  // MARK: - Video View

  private func makeVideoView(media: Media, index: Int) -> some View {
    VideoPlayerView(media: media, isFullScreen: true)
      .containerRelativeFrame([.horizontal, .vertical])
      .id(media)
  }

  private var leadingToolbar: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark")
          .foregroundStyle(.blue)
      }
    }
  }

  private var trailingToolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .navigationBarTrailing) {
      saveButton
      shareButton
    }
  }

  private var saveButton: some View {
    Button {
      Task {
        do {
          guard let media = scrollPosition else { return }

          if media.mediaType == .image {
            // Save image
            let data = try await ImagePipeline.shared.data(for: .init(url: media.url))
            if !data.0.isEmpty, let image = UIImage(data: data.0) {
              UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
              withAnimation {
                isSaved = true
              }
              DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                  isSaved = false
                }
              }
            }
          } else {
            // Save video - this would require downloading the video file
            // For now, just show a message
            print("Video saving not yet implemented")
          }
        } catch {}
      }
    } label: {
      Image(systemName: isSaved ? "checkmark" : "arrow.down.circle")
        .foregroundStyle(.blue)
    }
  }

  @ViewBuilder
  private var shareButton: some View {
    if let media = scrollPosition {
      ShareLink(item: media.url) {
        Image(systemName: "square.and.arrow.up")
          .foregroundStyle(.blue)
      }
    }
  }
}
