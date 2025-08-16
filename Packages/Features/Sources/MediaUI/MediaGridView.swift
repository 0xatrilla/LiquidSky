import SwiftUI
import NukeUI
import Models

public struct MediaGridView: View {
  let media: [Media]
  let maxItems: Int
  
  public init(media: [Media], maxItems: Int = 4) {
    self.media = media
    self.maxItems = maxItems
  }
  
  public var body: some View {
    let displayMedia = Array(media.prefix(maxItems))
    
    switch displayMedia.count {
    case 1:
      singleMediaView(displayMedia[0])
    case 2:
      twoMediaView(displayMedia[0], displayMedia[1])
    case 3:
      threeMediaView(displayMedia[0], displayMedia[1], displayMedia[2])
    case 4...:
      fourMediaView(displayMedia[0], displayMedia[1], displayMedia[2], displayMedia[3])
    default:
      EmptyView()
    }
  }
  
  // MARK: - Single Media
  
  private func singleMediaView(_ media: Media) -> some View {
    MediaView(media: media, isQuote: false, namespace: Namespace().wrappedValue)
      .aspectRatio(media.aspectRatio?.ratio ?? 16/9, contentMode: .fit)
  }
  
  // MARK: - Two Media
  
  private func twoMediaView(_ media1: Media, _ media2: Media) -> some View {
    HStack(spacing: 4) {
      MediaView(media: media1, isQuote: false, namespace: Namespace().wrappedValue)
        .aspectRatio(media1.aspectRatio?.ratio ?? 1, contentMode: .fill)
      
      MediaView(media: media2, isQuote: false, namespace: Namespace().wrappedValue)
        .aspectRatio(media2.aspectRatio?.ratio ?? 1, contentMode: .fill)
    }
  }
  
  // MARK: - Three Media
  
  private func threeMediaView(_ media1: Media, _ media2: Media, _ media3: Media) -> some View {
    VStack(spacing: 4) {
      MediaView(media: media1, isQuote: false, namespace: Namespace().wrappedValue)
        .aspectRatio(media1.aspectRatio?.ratio ?? 16/9, contentMode: .fill)
      
      HStack(spacing: 4) {
        MediaView(media: media2, isQuote: false, namespace: Namespace().wrappedValue)
          .aspectRatio(media2.aspectRatio?.ratio ?? 1, contentMode: .fill)
        
        MediaView(media: media3, isQuote: false, namespace: Namespace().wrappedValue)
          .aspectRatio(media3.aspectRatio?.ratio ?? 1, contentMode: .fill)
      }
    }
  }
  
  // MARK: - Four Media
  
  private func fourMediaView(_ media1: Media, _ media2: Media, _ media3: Media, _ media4: Media) -> some View {
    VStack(spacing: 4) {
      HStack(spacing: 4) {
        MediaView(media: media1, isQuote: false, namespace: Namespace().wrappedValue)
          .aspectRatio(media1.aspectRatio?.ratio ?? 1, contentMode: .fill)
        
        MediaView(media: media2, isQuote: false, namespace: Namespace().wrappedValue)
          .aspectRatio(media2.aspectRatio?.ratio ?? 1, contentMode: .fill)
      }
      
      HStack(spacing: 4) {
        MediaView(media: media3, isQuote: false, namespace: Namespace().wrappedValue)
          .aspectRatio(media3.aspectRatio?.ratio ?? 1, contentMode: .fill)
        
        MediaView(media: media4, isQuote: false, namespace: Namespace().wrappedValue)
          .aspectRatio(media4.aspectRatio?.ratio ?? 1, contentMode: .fill)
      }
    }
  }
}
