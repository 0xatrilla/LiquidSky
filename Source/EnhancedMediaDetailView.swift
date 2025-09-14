import Foundation
import SwiftUI

@available(iOS 18.0, *)
struct EnhancedMediaDetailView: View {
  let mediaId: String
  @Environment(\.detailColumnManager) var detailManager
  @Environment(\.glassEffectManager) var glassEffectManager
  @State private var showingShareSheet = false
  @State private var showingFullScreen = false
  @State private var zoomScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastOffset: CGSize = .zero
  @GestureState private var magnification: CGFloat = 1.0
  @Namespace private var mediaNamespace

  var body: some View {
    GlassEffectContainer(spacing: 16.0) {
      if detailManager.mediaDetailState.isLoading {
        mediaLoadingView
      } else if let mediaItem = detailManager.mediaDetailState.mediaItem {
        VStack(spacing: 0) {
          // Media viewer
          mediaViewerSection(mediaItem)

          // Media controls
          mediaControlsSection(mediaItem)
        }
      } else {
        mediaNotFoundView
      }
    }
    .navigationTitle("Media")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        mediaToolbarButtons
      }
    }
    .sheet(isPresented: $showingShareSheet) {
      MediaShareSheet(mediaItem: detailManager.mediaDetailState.mediaItem)
    }
    .fullScreenCover(isPresented: $showingFullScreen) {
      FullScreenMediaViewer(
        mediaItem: detailManager.mediaDetailState.mediaItem,
        isPresented: $showingFullScreen
      )
    }
    .onAppear {
      Task {
        let detailItem = DetailItem(id: mediaId, type: .media, title: "Media")
        await detailManager.loadDetailContent(for: detailItem)
      }
    }
  }

  // MARK: - Media Viewer Section

  @ViewBuilder
  private func mediaViewerSection(_ mediaItem: MediaDetailData) -> some View {
    GeometryReader { geometry in
      GestureAwareGlassCard(
        cornerRadius: 20,
        isInteractive: true
      ) {
        ZStack {
          // Media content
          mediaContentView(mediaItem, geometry: geometry)

          // Zoom controls overlay
          VStack {
            HStack {
              Spacer()

              zoomControlsOverlay
            }
            .padding()

            Spacer()
          }
        }
      }
    }
    .aspectRatio(mediaItem.aspectRatio ?? 16 / 9, contentMode: .fit)
    .glassEffectID("media-viewer-\(mediaItem.id)", in: mediaNamespace)
  }

  @ViewBuilder
  private func mediaContentView(_ mediaItem: MediaDetailData, geometry: GeometryProxy) -> some View
  {
    Group {
      switch mediaItem.type {
      case .image:
        imageViewer(mediaItem, geometry: geometry)
      case .video:
        videoViewer(mediaItem, geometry: geometry)
      case .gif:
        gifViewer(mediaItem, geometry: geometry)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }

  @ViewBuilder
  private func imageViewer(_ mediaItem: MediaDetailData, geometry: GeometryProxy) -> some View {
    AsyncImage(url: URL(string: mediaItem.url)) { image in
      image
        .resizable()
        .aspectRatio(contentMode: .fit)
        .scaleEffect(zoomScale * magnification)
        .offset(offset)
        .gesture(
          SimultaneousGesture(
            // Zoom gesture
            MagnificationGesture()
              .updating($magnification) { value, state, _ in
                state = value
              }
              .onEnded { value in
                withAnimation(.smooth(duration: 0.3)) {
                  zoomScale *= value
                  zoomScale = max(0.5, min(zoomScale, 5.0))
                }
              },

            // Pan gesture
            DragGesture()
              .onChanged { value in
                offset = CGSize(
                  width: lastOffset.width + value.translation.width,
                  height: lastOffset.height + value.translation.height
                )
              }
              .onEnded { _ in
                lastOffset = offset
              }
          )
        )
        .onTapGesture(count: 2) {
          withAnimation(.smooth(duration: 0.3)) {
            if zoomScale > 1.0 {
              zoomScale = 1.0
              offset = .zero
              lastOffset = .zero
            } else {
              zoomScale = 2.0
            }
          }
        }
    } placeholder: {
      Rectangle()
        .fill(.quaternary)
        .overlay {
          VStack(spacing: 12) {
            ProgressView()
              .scaleEffect(1.2)

            Text("Loading image...")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
    }
  }

  @ViewBuilder
  private func videoViewer(_ mediaItem: MediaDetailData, geometry: GeometryProxy) -> some View {
    // Video player would be implemented here
    Rectangle()
      .fill(.black)
      .overlay {
        VStack(spacing: 16) {
          Image(systemName: "play.circle.fill")
            .font(.system(size: 60))
            .foregroundStyle(.white)

          Text("Video Player")
            .font(.headline)
            .foregroundStyle(.white)

          Text("Video playback would be implemented here")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
        }
      }
  }

  @ViewBuilder
  private func gifViewer(_ mediaItem: MediaDetailData, geometry: GeometryProxy) -> some View {
    // GIF viewer would be implemented here
    AsyncImage(url: URL(string: mediaItem.url)) { image in
      image
        .resizable()
        .aspectRatio(contentMode: .fit)
    } placeholder: {
      Rectangle()
        .fill(.quaternary)
        .overlay {
          VStack(spacing: 12) {
            ProgressView()
              .scaleEffect(1.2)

            Text("Loading GIF...")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
    }
  }

  // MARK: - Zoom Controls Overlay

  @ViewBuilder
  private var zoomControlsOverlay: some View {
    VStack(spacing: 8) {
      Button {
        withAnimation(.smooth(duration: 0.3)) {
          zoomScale = min(zoomScale * 1.5, 5.0)
        }
      } label: {
        Image(systemName: "plus.magnifyingglass")
          .font(.subheadline)
          .foregroundStyle(.white)
          .padding(8)
          .background(.black.opacity(0.6), in: Circle())
      }
      .buttonStyle(.plain)
      .background {
        if #available(iOS 26.0, *) {
          Circle()
            .glassEffect(.regular.interactive(), in: .circle)
        }
      }

      Button {
        withAnimation(.smooth(duration: 0.3)) {
          zoomScale = max(zoomScale / 1.5, 0.5)
        }
      } label: {
        Image(systemName: "minus.magnifyingglass")
          .font(.subheadline)
          .foregroundStyle(.white)
          .padding(8)
          .background(.black.opacity(0.6), in: Circle())
      }
      .buttonStyle(.plain)
      .background {
        if #available(iOS 26.0, *) {
          Circle()
            .glassEffect(.regular.interactive(), in: .circle)
        }
      }

      Button {
        withAnimation(.smooth(duration: 0.3)) {
          zoomScale = 1.0
          offset = .zero
          lastOffset = .zero
        }
      } label: {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
          .font(.subheadline)
          .foregroundStyle(.white)
          .padding(8)
          .background(.black.opacity(0.6), in: Circle())
      }
      .buttonStyle(.plain)
      .background {
        if #available(iOS 26.0, *) {
          Circle()
            .glassEffect(.regular.interactive(), in: .circle)
        }
      }
    }
    .opacity(zoomScale > 1.0 ? 1.0 : 0.6)
  }

  // MARK: - Media Controls Section

  @ViewBuilder
  private func mediaControlsSection(_ mediaItem: MediaDetailData) -> some View {
    GestureAwareGlassCard(
      cornerRadius: 16,
      isInteractive: true
    ) {
      VStack(spacing: 16) {
        // Media info
        mediaInfoSection(mediaItem)

        // Action buttons
        mediaActionButtons(mediaItem)
      }
      .padding(16)
    }
    .glassEffectID("media-controls-\(mediaItem.id)", in: mediaNamespace)
  }

  @ViewBuilder
  private func mediaInfoSection(_ mediaItem: MediaDetailData) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Media Details")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        Spacer()

        Text(mediaItem.type.displayName)
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.quaternary, in: Capsule())
      }

      if let altText = mediaItem.altText {
        Text(altText)
          .font(.body)
          .foregroundStyle(.secondary)
      }

      if let width = mediaItem.width, let height = mediaItem.height {
        Text("\(width) × \(height)")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    }
  }

  @ViewBuilder
  private func mediaActionButtons(_ mediaItem: MediaDetailData) -> some View {
    HStack(spacing: 16) {
      // Full screen button
      MediaActionButton(
        title: "Full Screen",
        systemImage: "arrow.up.left.and.arrow.down.right",
        color: .blue
      ) {
        showingFullScreen = true
      }

      // Share button
      MediaActionButton(
        title: "Share",
        systemImage: "square.and.arrow.up",
        color: .green
      ) {
        showingShareSheet = true
      }

      // Download button
      MediaActionButton(
        title: "Save",
        systemImage: "square.and.arrow.down",
        color: .purple
      ) {
        // Handle download
      }

      Spacer()
    }
  }

  // MARK: - Loading and Error States

  @ViewBuilder
  private var mediaLoadingView: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)

      Text("Loading media...")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background {
      if #available(iOS 26.0, *) {
        RoundedRectangle(cornerRadius: 20)
          .glassEffect(.regular, in: .rect(cornerRadius: 20))
      }
    }
  }

  @ViewBuilder
  private var mediaNotFoundView: some View {
    ContentUnavailableView(
      "Media not found",
      systemImage: "photo.badge.exclamationmark",
      description: Text("This media may have been deleted or is no longer available")
    )
    .background {
      if #available(iOS 26.0, *) {
        RoundedRectangle(cornerRadius: 20)
          .glassEffect(.regular, in: .rect(cornerRadius: 20))
      }
    }
  }

  // MARK: - Toolbar

  @ViewBuilder
  private var mediaToolbarButtons: some View {
    Button {
      showingShareSheet = true
    } label: {
      Image(systemName: "square.and.arrow.up")
        .font(.subheadline)
    }
    .background {
      if #available(iOS 26.0, *) {
        Rectangle()
          .glassEffect(.regular.interactive())
      }
    }

    Button {
      // Handle more options
    } label: {
      Image(systemName: "ellipsis.circle")
        .font(.subheadline)
    }
    .background {
      if #available(iOS 26.0, *) {
        Rectangle()
          .glassEffect(.regular.interactive())
      }
    }
  }
}

// MARK: - Media Action Button

@available(iOS 18.0, *)
struct MediaActionButton: View {
  let title: String
  let systemImage: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 6) {
        Image(systemName: systemImage)
          .font(.title3)
          .foregroundStyle(color)

        Text(title)
          .font(.caption.weight(.medium))
          .foregroundStyle(.primary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .stroke(color.opacity(0.3), lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
    .background {
      if #available(iOS 26.0, *) {
        RoundedRectangle(cornerRadius: 12)
          .glassEffect(.regular.tint(color).interactive(), in: .rect(cornerRadius: 12))
      }
    }
  }
}

// MARK: - Full Screen Media Viewer

@available(iOS 18.0, *)
struct FullScreenMediaViewer: View {
  let mediaItem: MediaDetailData?
  @Binding var isPresented: Bool
  @State private var zoomScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastOffset: CGSize = .zero
  @GestureState private var magnification: CGFloat = 1.0

  var body: some View {
    ZStack {
      // Background
      Color.black
        .ignoresSafeArea()

      if let mediaItem = mediaItem {
        // Media content
        AsyncImage(url: URL(string: mediaItem.url)) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(zoomScale * magnification)
            .offset(offset)
            .gesture(
              SimultaneousGesture(
                // Zoom gesture
                MagnificationGesture()
                  .updating($magnification) { value, state, _ in
                    state = value
                  }
                  .onEnded { value in
                    withAnimation(.smooth(duration: 0.3)) {
                      zoomScale *= value
                      zoomScale = max(0.5, min(zoomScale, 5.0))
                    }
                  },

                // Pan gesture
                DragGesture()
                  .onChanged { value in
                    offset = CGSize(
                      width: lastOffset.width + value.translation.width,
                      height: lastOffset.height + value.translation.height
                    )
                  }
                  .onEnded { _ in
                    lastOffset = offset
                  }
              )
            )
            .onTapGesture(count: 2) {
              withAnimation(.smooth(duration: 0.3)) {
                if zoomScale > 1.0 {
                  zoomScale = 1.0
                  offset = .zero
                  lastOffset = .zero
                } else {
                  zoomScale = 2.0
                }
              }
            }
        } placeholder: {
          ProgressView()
            .scaleEffect(2.0)
            .tint(.white)
        }
      }

      // Close button
      VStack {
        HStack {
          Spacer()

          Button {
            isPresented = false
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundStyle(.white)
              .background(.black.opacity(0.6), in: Circle())
          }
          .buttonStyle(.plain)
          .padding()
        }

        Spacer()
      }
    }
    .onTapGesture {
      if zoomScale <= 1.0 {
        isPresented = false
      }
    }
  }
}

// MARK: - Media Share Sheet

@available(iOS 18.0, *)
struct MediaShareSheet: View {
  let mediaItem: MediaDetailData?
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        if let mediaItem = mediaItem {
          // Media preview
          AsyncImage(url: URL(string: mediaItem.url)) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
          } placeholder: {
            Rectangle()
              .fill(.quaternary)
              .overlay {
                ProgressView()
              }
          }
          .frame(height: 200)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .background {
            if #available(iOS 26.0, *) {
              RoundedRectangle(cornerRadius: 12)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
            }
          }

          // Share options
          VStack(spacing: 12) {
            ShareOptionButton(
              title: "Copy Link",
              systemImage: "link",
              color: .blue
            ) {
              // Handle copy link
              dismiss()
            }

            ShareOptionButton(
              title: "Save to Photos",
              systemImage: "photo.badge.plus",
              color: .green
            ) {
              // Handle save to photos
              dismiss()
            }

            ShareOptionButton(
              title: "Share via AirDrop",
              systemImage: "airplayaudio",
              color: .orange
            ) {
              // Handle AirDrop
              dismiss()
            }
          }
        }

        Spacer()
      }
      .padding()
      .navigationTitle("Share Media")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
    .background {
      if #available(iOS 26.0, *) {
        RoundedRectangle(cornerRadius: 16)
          .glassEffect(.regular, in: .rect(cornerRadius: 16))
      }
    }
  }
}

// MARK: - Share Option Button

@available(iOS 18.0, *)
struct ShareOptionButton: View {
  let title: String
  let systemImage: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Image(systemName: systemImage)
          .font(.title3)
          .foregroundStyle(color)
          .frame(width: 24, height: 24)

        Text(title)
          .font(.body.weight(.medium))
          .foregroundStyle(.primary)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .background {
        if #available(iOS 26.0, *) {
          RoundedRectangle(cornerRadius: 12)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        }
      }
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Extensions

@available(iOS 18.0, *)
extension MediaDetailData.MediaType {
  var displayName: String {
    switch self {
    case .image: return "Image"
    case .video: return "Video"
    case .gif: return "GIF"
    }
  }
}
