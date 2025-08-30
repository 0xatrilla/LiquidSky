import AppRouter
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
        }
      }
  }
}

extension View {
  public func withAppDestinations() -> some View {
    modifier(AppDestinations())
  }
}
