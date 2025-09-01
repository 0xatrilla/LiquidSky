import AppRouter
import Models
import SwiftUI

public enum ComposerDestinationMode: Hashable {
  case newPost
  case reply(PostItem)
}

public enum SheetDestination: SheetType, Hashable, Identifiable {
  public var id: Int { self.hashValue }

  case auth
  case feedsList
  case fullScreenMedia(
    images: [Media],
    preloadedImage: URL?,
    namespace: Namespace.ID)
  case fullScreenProfilePicture(
    imageURL: URL,
    namespace: Namespace.ID)
  case fullScreenVideo(
    media: Media,
    namespace: Namespace.ID)
  case composer(mode: ComposerDestinationMode)
  case profile(Profile)
  case feed(FeedItem)
  case post(PostItem)
  case translate(post: PostItem)
  case followingList(profile: Profile)
  case followersList(profile: Profile)
}
