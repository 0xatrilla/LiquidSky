import AVKit
import Models
import SwiftUI
import UIKit

struct FullScreenVideoView: UIViewControllerRepresentable {
  let media: Media
  let namespace: Namespace.ID

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller = AVPlayerViewController()

    // Create player item and player
    let playerItem = AVPlayerItem(url: media.url)
    let player = AVPlayer(playerItem: playerItem)

    // Configure the controller
    controller.player = player
    controller.showsPlaybackControls = true
    controller.allowsPictureInPicturePlayback = true
    controller.canStartPictureInPictureAutomaticallyFromInline = true

    // Enable fullscreen controls
    controller.entersFullScreenWhenPlaybackBegins = false
    controller.exitsFullScreenWhenPlaybackEnds = false

    // Start playing automatically
    player.play()

    return controller
  }

  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    // No updates needed
  }
}

struct FullScreenVideoViewWrapper: View {
  let media: Media
  let namespace: Namespace.ID
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      FullScreenVideoView(media: media, namespace: namespace)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button {
              dismiss()
            } label: {
              Image(systemName: "xmark")
                .foregroundStyle(.primary)
            }
          }
        }
        .scrollContentBackground(.hidden)
    }
    .navigationTransition(.zoom(sourceID: "video", in: namespace))
  }
}
