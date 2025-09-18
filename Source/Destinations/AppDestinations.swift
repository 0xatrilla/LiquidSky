import AppRouter
import BookmarksUI
import Destinations
import FeedUI
import Models
import NotificationsUI
import PostUI
import ProfileUI
import SwiftUI

public struct AppDestinations: ViewModifier {
  public func body(content: Content) -> some View {
    content
      .navigationDestination(for: RouterDestination.self) { destination in
        switch destination {
        case .feed(let feedItem):
          let _ = {
            #if DEBUG
              print("AppDestinations: Navigating to feed: \(feedItem.displayName)")
              print("AppDestinations: Feed URI: \(feedItem.uri)")
            #endif
          }()
          PostsFeedView(feedItem: feedItem)
        case .post(let post):
          PostDetailView(post: post)
        case .timeline:
          PostsTimelineView()
        case .profile(let profile):
          ProfileView(profile: profile, isCurrentUser: false)
        case .profilePosts(let profile, let filter):
          PostsProfileView(profile: profile, filter: filter)
            .environment(PostFilterService.shared)
        case .profileLikes(let profile):
          PostsLikesView(profile: profile)
        case .hashtag(let hashtag):
          HashtagFeedView(hashtag: hashtag)
        case .bookmarks:
          BookmarksListView()
        }
      }
  }
}

extension View {
  public func withAppDestinations() -> some View {
    modifier(AppDestinations())
  }
}
