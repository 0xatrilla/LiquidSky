import SwiftUI
import AVKit
import Models

@MainActor
public struct VideoPlayerView: View {
  let media: Media
  let isFullScreen: Bool
  
  @State private var player: AVPlayer?
  @State private var isLoading: Bool = true
  @State private var hasError: Bool = false
  @State private var errorMessage: String = ""
  
  public init(media: Media, isFullScreen: Bool = false) {
    self.media = media
    self.isFullScreen = isFullScreen
  }
  
  public var body: some View {
    ZStack {
      if let player = player, !hasError {
        VideoPlayer(player: player)
          .aspectRatio(media.aspectRatio?.ratio ?? 16/9, contentMode: .fit)
          .onAppear {
            player.play()
          }
          .onDisappear {
            player.pause()
          }
      } else if isLoading {
        loadingView
      } else if hasError {
        errorView
      } else {
        placeholderView
      }
    }
    .onAppear {
      setupVideo()
    }
  }
  
  // MARK: - Setup
  
  private func setupVideo() {
    isLoading = true
    hasError = false
    errorMessage = ""
    
    // Debug: Print the video URL being used
    print("VideoPlayerView: Attempting to play video with URL: \(media.url)")
    print("VideoPlayerView: Video CID: \(media.videoCID ?? "nil")")
    print("VideoPlayerView: Video Playlist URI: \(media.videoPlaylistURI ?? "nil")")
    
    // Use the media URL directly - AVPlayer will handle various video formats
    let playerItem = AVPlayerItem(url: media.url)
    player = AVPlayer(playerItem: playerItem)
    
    // Add player item observer for completion
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { _ in
      Task { @MainActor in
        player?.seek(to: .zero)
        player?.play()
      }
    }
    
    // Start playing automatically
    player?.play()
    
    // Mark as loaded after a short delay to allow for any immediate errors
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      if !self.hasError {
        self.isLoading = false
      }
    }
  }
  
  // MARK: - Views
  
  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.5)
      
      Text("Loading video...")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemGray6))
  }
  
  private var errorView: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.largeTitle)
        .foregroundColor(.orange)
      
      Text("Video Error")
        .font(.headline)
        .foregroundColor(.primary)
      
      Text(errorMessage)
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      
      Button("Retry") {
        setupVideo()
      }
      .buttonStyle(.bordered)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemGray6))
  }
  
  private var placeholderView: some View {
    VStack(spacing: 16) {
      Image(systemName: "video")
        .font(.largeTitle)
        .foregroundColor(.secondary)
      
      Text("Video not available")
        .font(.headline)
        .foregroundColor(.primary)
      
      Text("This video cannot be played at the moment")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemGray6))
  }
}
