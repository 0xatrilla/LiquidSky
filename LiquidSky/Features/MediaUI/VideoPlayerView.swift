import SwiftUI
import AVKit
import Models

@MainActor
public struct VideoPlayerView: View {
  let media: Media
  let isFullScreen: Bool
  
  @State private var isLoading: Bool = true
  @State private var hasError: Bool = false
  @State private var errorMessage: String = ""
  
  public init(media: Media, isFullScreen: Bool = false) {
    self.media = media
    self.isFullScreen = isFullScreen
  }
  
  public var body: some View {
    ZStack {
      if !hasError {
        AVPlayerViewControllerRepresentable(media: media)
          .onAppear {
            isLoading = false
          }
      } else if isLoading {
        loadingView
      } else {
        errorView
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
    
    // Check if media has a valid URL
    guard !media.url.absoluteString.isEmpty else {
      hasError = true
      errorMessage = "Video URL not available"
      isLoading = false
      return
    }
    
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
}

// MARK: - AVPlayerViewControllerRepresentable

struct AVPlayerViewControllerRepresentable: UIViewControllerRepresentable {
  let media: Media
  
  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let playerViewController = AVPlayerViewController()
    
    // Configure the player view controller
    playerViewController.showsPlaybackControls = true
    
    // Create and configure the player
    let url = media.url
    let playerItem = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: playerItem)
    
    // Configure player for better performance
    player.automaticallyWaitsToMinimizeStalling = true
    player.volume = 1.0
    
    // Set the player
    playerViewController.player = player
    
    // Start playing automatically
    player.play()
    
    // Add player item observer for completion
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { _ in
      player.seek(to: .zero)
      player.play()
    }
    
    return playerViewController
  }
  
  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    // Update if needed
  }
}
