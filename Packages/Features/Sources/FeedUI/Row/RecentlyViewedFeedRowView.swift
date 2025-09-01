import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import NukeUI
import SwiftUI

struct RecentlyViewedFeedRowView: View {
  @Environment(AppRouter.self) var router

  let item: RecentFeedItem
  @Namespace private var namespace

  public init(item: RecentFeedItem) {
    self.item = item
  }

  public var body: some View {
    Button(action: {
      let feedItem = FeedItem(
        uri: item.uri,
        displayName: item.name,
        description: nil,
        avatarImageURL: item.avatarImageURL,
        creatorHandle: "",
        likesCount: 0,
        liked: false
      )
      router.navigateTo(.feed(feedItem))
    }) {
      HStack {
        LazyImage(url: item.avatarImageURL) { state in
          if let image = state.image {
            image
              .resizable()
              .scaledToFit()
              .frame(width: 32, height: 32)
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .shadow(color: .shadowPrimary.opacity(0.7), radius: 2)
          } else {
            Image(systemName: "antenna.radiowaves.left.and.right")
              .imageScale(.medium)
              .foregroundStyle(.white)
              .frame(width: 32, height: 32)
              .background(RoundedRectangle(cornerRadius: 8).fill(LinearGradient.blueskySubtle))
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .shadow(color: .shadowPrimary.opacity(0.7), radius: 2)
          }
        }

        Text(item.name)
          .font(.title3)
          .fontWeight(.bold)
          .foregroundStyle(
            .primary.shadow(
              .inner(
                color: .shadowSecondary.opacity(0.5),
                radius: 2, x: -1, y: -1)))
      }
    }
    .buttonStyle(PlainButtonStyle())
    .listRowSeparator(.hidden)
    .listRowInsets(.vertical, 0)
  }
}
