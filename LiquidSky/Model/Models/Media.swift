import ATProtoKit
import AVFoundation
import Foundation

public enum MediaType {
  case image
  case video
}

public struct Media: Identifiable, Hashable {
  public var id: URL { url }
  public let url: URL
  public let alt: String?
  public let mediaType: MediaType
  public let aspectRatio: AspectRatio?
  public let thumbnailURL: URL?
  public let videoPlaylistURI: String?
  public let videoCID: String?

  // For images
  public init(url: URL, alt: String?, aspectRatio: AspectRatio? = nil) {
    self.url = url
    self.alt = alt?.isEmpty == true ? nil : alt
    self.mediaType = .image
    self.aspectRatio = aspectRatio
    self.thumbnailURL = nil
    self.videoPlaylistURI = nil
    self.videoCID = nil
  }

  // For videos
  public init(
    url: URL,
    alt: String?,
    aspectRatio: AspectRatio?,
    thumbnailURL: URL?,
    videoPlaylistURI: String?,
    videoCID: String?
  ) {
    self.url = url
    self.alt = alt?.isEmpty == true ? nil : alt
    self.mediaType = .video
    self.aspectRatio = aspectRatio
    self.thumbnailURL = thumbnailURL
    self.videoPlaylistURI = videoPlaylistURI
    self.videoCID = videoCID
  }
}

public struct AspectRatio: Hashable {
  public let width: Int
  public let height: Int

  public init(width: Int, height: Int) {
    self.width = width
    self.height = height
  }

  public var ratio: CGFloat {
    CGFloat(width) / CGFloat(height)
  }
}

// MARK: - ATProtoKit Extensions

extension AppBskyLexicon.Embed.ImagesDefinition.ViewImage {
  public var media: Media {
    Media(
      url: fullSizeImageURL,
      alt: altText,
      aspectRatio: aspectRatio.map { AspectRatio(width: $0.width, height: $0.height) }
    )
  }
}

extension AppBskyLexicon.Embed.VideoDefinition.View {
  public var media: Media {
    Media(
      url: constructVideoStreamURL(from: playlistURI, cid: cid),
      alt: altText,
      aspectRatio: aspectRatio.map { AspectRatio(width: $0.width, height: $0.height) },
      thumbnailURL: thumbnailImageURL.flatMap { URL(string: $0) },
      videoPlaylistURI: playlistURI,
      videoCID: cid
    )
  }

  private func constructVideoStreamURL(from playlistURI: String?, cid: String) -> URL {
    // If we have a playlist URI, use it directly as it contains the actual video stream URL
    if let playlistURI = playlistURI, let url = URL(string: playlistURI) {
      return url
    }

    // Fallback: try to construct a video URL using the CID
    // This is a fallback and may not work for all videos
    if let url = URL(string: "https://bsky.social/xrpc/com.atproto.sync.getBlob?cid=\(cid)") {
      return url
    }

    // Final fallback to a placeholder URL
    return URL(string: "https://bsky.app")!
  }
}
