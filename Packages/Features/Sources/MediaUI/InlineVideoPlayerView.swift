import AVKit
import Models
import SwiftUI

@MainActor
public struct InlineVideoPlayerView: View {
  let media: Media
  let isQuote: Bool
  let namespace: Namespace.ID

  @State private var player: AVPlayer?
  @State private var isLoading: Bool = true
  @State private var hasError: Bool = false
  @State private var isPlaying: Bool = false
  @State private var showControls: Bool = false
  @State private var progress: Double = 0.0
  @State private var duration: Double = 0.0
  @State private var currentTime: Double = 0.0
  @State private var isMuted: Bool = true
  @State private var shouldAutoplay: Bool = false

  // Performance optimization: only create player when needed
  @State private var hasAppeared: Bool = false

  @Environment(\.videoFeedManager) private var videoFeedManager

  public init(media: Media, isQuote: Bool = false, namespace: Namespace.ID) {
    self.media = media
    self.isQuote = isQuote
    self.namespace = namespace
  }

  public var body: some View {
    ZStack {
      if let player = player, !hasError {
        videoPlayerView(player: player)
      } else if isLoading {
        loadingView
      } else if hasError {
        errorView
      } else {
        placeholderView
      }

      // Overlay controls
      if showControls && !isQuote {
        videoControlsOverlay
      }

      // Video indicator badge
      videoIndicatorBadge
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
    .onAppear {
      if !hasAppeared {
        hasAppeared = true
        setupVideo()
      }
      videoFeedManager.registerVideoAsVisible(media.id)
    }
    .onDisappear {
      videoFeedManager.unregisterVideoAsVisible(media.id)
      cleanupVideo()
    }
    .onTapGesture {
      if !isQuote {
        withAnimation(.easeInOut(duration: 0.2)) {
          showControls.toggle()
        }
      }
    }
  }

  // MARK: - Video Player View

  @ViewBuilder
  private func videoPlayerView(player: AVPlayer) -> some View {
    VideoPlayer(player: player)
      .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
        handleVideoEnd()
      }
      .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemTimeJumped)) { _ in
        updateProgress()
      }
  }

  // MARK: - Controls Overlay

  @ViewBuilder
  private var videoControlsOverlay: some View {
    VStack {
      // Top controls
      HStack {
        Spacer()

        Button(action: toggleMute) {
          Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            .font(.title2)
            .foregroundColor(.white)
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 12)

      Spacer()

      // Center play/pause button
      Button(action: togglePlayPause) {
        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
          .font(.system(size: 48))
          .foregroundColor(.white)
          .background(
            Circle()
              .fill(.ultraThinMaterial)
              .scaleEffect(1.2)
          )
      }

      Spacer()

      // Bottom progress bar
      VStack(spacing: 8) {
        // Progress slider
        Slider(
          value: Binding(
            get: { progress },
            set: { newValue in
              seekTo(newValue)
            }
          ), in: 0...1
        )
        .accentColor(.blue)

        // Time labels
        HStack {
          Text(formatTime(currentTime))
            .font(.caption)
            .foregroundColor(.white)

          Spacer()

          Text(formatTime(duration))
            .font(.caption)
            .foregroundColor(.white)
        }
      }
      .padding(.horizontal, 12)
      .padding(.bottom, 12)
      .background(.ultraThinMaterial)
    }
    .background(
      LinearGradient(
        colors: [.clear, .black.opacity(0.3), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }

  // MARK: - Video Indicator Badge

  @ViewBuilder
  private var videoIndicatorBadge: some View {
    HStack {
      Image(systemName: "video")
        .font(.caption)
        .foregroundColor(.white)

      Text("VIDEO")
        .font(.caption2)
        .fontWeight(.bold)
        .foregroundColor(.white)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      Capsule()
        .fill(.black.opacity(0.7))
    )
    .padding(8)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  // MARK: - Loading View

  private var loadingView: some View {
    VStack(spacing: 12) {
      ProgressView()
        .scaleEffect(1.2)
        .tint(.blue)

      Text("Loading video...")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.ultraThinMaterial)
  }

  // MARK: - Error View

  private var errorView: some View {
    VStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle")
        .font(.title)
        .foregroundColor(.orange)

      Text("Video Error")
        .font(.caption)
        .foregroundColor(.primary)

      Button("Retry") {
        setupVideo()
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.ultraThinMaterial)
  }

  // MARK: - Placeholder View

  private var placeholderView: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(.ultraThinMaterial)
      .overlay(
        VStack(spacing: 8) {
          Image(systemName: "video")
            .font(.title)
            .foregroundColor(.secondary)

          Text("Video")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      )
  }

  // MARK: - Setup & Cleanup

  private func setupVideo() {
    isLoading = true
    hasError = false

    // Create player item
    let playerItem = AVPlayerItem(url: media.url)
    player = AVPlayer(playerItem: playerItem)

    // Configure player for inline playback
    player?.isMuted = videoFeedManager.isMutedByDefault
    player?.automaticallyWaitsToMinimizeStalling = true

    // Register with video feed manager
    if let player = player {
      videoFeedManager.registerActivePlayer(player, for: media.id)
    }

    // Add time observer for progress updates
    let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    let timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
      time in
      updateProgress()
    }

    // Add player item observers
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { _ in
      handleVideoEnd()
    }

    // Get video duration
    playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
      DispatchQueue.main.async {
        self.duration = playerItem.asset.duration.seconds
        self.isLoading = false

        // Check if we should autoplay based on feed manager
        if self.videoFeedManager.shouldAutoplayVideo(self.media.id) {
          self.shouldAutoplay = true
          self.player?.play()
          self.isPlaying = true
        }
      }
    }
  }

  private func cleanupVideo() {
    if let player = player {
      videoFeedManager.unregisterActivePlayer(for: media.id)
    }
    player?.pause()
    player = nil
    isLoading = false
    isPlaying = false
    progress = 0.0
    currentTime = 0.0
  }

  // MARK: - Control Actions

  private func togglePlayPause() {
    if isPlaying {
      player?.pause()
      isPlaying = false
    } else {
      player?.play()
      isPlaying = true
    }
  }

  private func toggleMute() {
    isMuted.toggle()
    player?.isMuted = isMuted
  }

  private func seekTo(_ progress: Double) {
    let time = CMTime(seconds: progress * duration, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    player?.seek(to: time)
  }

  private func updateProgress() {
    guard let player = player else { return }

    let currentTime = player.currentTime().seconds
    let duration = player.currentItem?.duration.seconds ?? 0

    if duration > 0 {
      self.currentTime = currentTime
      self.progress = currentTime / duration
    }
  }

  private func handleVideoEnd() {
    player?.seek(to: .zero)
    if shouldAutoplay {
      player?.play()
    } else {
      isPlaying = false
    }
  }

  // MARK: - Utility

  private func formatTime(_ time: Double) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
}
