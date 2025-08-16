import ATProtoKit
import AppRouter
import DesignSystem
import Destinations
import MediaUI
import Models
import SwiftUI

struct PostRowVideosView: View {
  @Environment(\.isQuote) var isQuote
  @Environment(AppRouter.self) var router

  @Namespace private var namespace

  let quoteMaxSize: CGFloat = 100
  let videos: AppBskyLexicon.Embed.VideoDefinition.View

  @State private var firstVideoSize: CGSize?
  @State private var shouldRotate = true

  var body: some View {
    ZStack(alignment: .topLeading) {
      makeVideoView(video: videos, index: 0)
        .frame(maxWidth: isQuote ? quoteMaxSize : nil)
        .rotationEffect(
          .degrees(shouldRotate ? 0 : 0),
          anchor: .bottomTrailing
        )
    }
    .padding(.bottom, !isQuote ? 7 : 0)
    .onTapGesture {
      withAnimation(.easeInOut(duration: 0.1)) {
        shouldRotate = false
      } completion: {
        router.presentedSheet = .fullScreenVideo(
          media: videos.media,
          namespace: namespace
        )
      }
    }
    .onChange(of: router.presentedSheet) {
      if router.presentedSheet == nil {
        withAnimation(.bouncy) {
          shouldRotate = true
        }
      }
    }
  }

  @ViewBuilder
  private func makeVideoView(video: AppBskyLexicon.Embed.VideoDefinition.View, index: Int)
    -> some View
  {
    let width: CGFloat = CGFloat(video.aspectRatio?.width ?? 16)
    let height: CGFloat = CGFloat(video.aspectRatio?.height ?? 9)
    GeometryReader { geometry in
      let displayWidth = isQuote ? quoteMaxSize : min(geometry.size.width, width * 20)
      let displayHeight = isQuote ? quoteMaxSize : displayWidth / (width / height)
      let finalWidth = firstVideoSize?.width ?? displayWidth
      let finalHeight = firstVideoSize?.height ?? displayHeight

      MediaView(
        media: video.media,
        isQuote: isQuote,
        namespace: namespace,
        onFullScreenRequest: {
          router.presentedSheet = .fullScreenVideo(
            media: video.media,
            namespace: namespace
          )
        }
      )
      .frame(width: finalWidth, height: finalHeight)
      .onAppear {
        if index == 0 {
          self.firstVideoSize = CGSize(width: displayWidth, height: displayHeight)
        }
      }
    }
    .aspectRatio(
      isQuote ? 1 : (firstVideoSize?.width ?? width) / (firstVideoSize?.height ?? height),
      contentMode: .fit)
  }
}
