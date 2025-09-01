import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI
import User

extension EnvironmentValues {
  @Entry public var isQuote: Bool = false
  @Entry public var isFocused: Bool = false
  @Entry public var isThreadContext: Bool = false
}

public struct PostRowView: View {
  @Environment(\.isQuote) var isQuote
  @Environment(\.isFocused) var isFocused
  @Environment(\.isThreadContext) var isThreadContext
  @Environment(\.sizeCategory) var sizeCategory
  @Environment(SettingsService.self) var settingsService

  @Environment(PostContextProvider.self) var postDataControllerProvider
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @Environment(CurrentUser.self) var currentUser

  let post: PostItem
  @Namespace private var namespace
  @State private var parentPost: PostItem?

  public init(post: PostItem) {
    self.post = post
  }

  public var body: some View {
    HStack(alignment: .top, spacing: compactMode ? 6 : 8) {
      if !isQuote {
        VStack(spacing: 0) {
          avatarView
          threadLineView
        }
      }
      mainView
        .padding(.bottom, compactMode ? 12 : 18)
    }
    .environment(postDataControllerProvider.get(for: post, client: client))
    .listRowSeparator(.hidden)
    .listRowInsets(
      .init(top: 0, leading: compactMode ? 14 : 18, bottom: 0, trailing: compactMode ? 14 : 18)
    )
    .task {
      if post.isReplyTo, parentPost == nil {
        await loadParentPost()
      }
    }
  }

  private var compactMode: Bool {
    settingsService.compactMode
  }

  private var mainView: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Repost indicator - show who reposted this content
      if post.isReposted, let repostedBy = post.repostedBy {
        RepostIndicatorView(repostedBy: repostedBy)
      }

      authorView
      // If this post is a reply, show the parent inline above (only in thread context, not feed)
      if post.isReplyTo && isInThreadContext {
        if let parentPost {
          PostRowEmbedQuoteView(post: parentPost)
        }
      }

      // Show simple reply indicator in thread view only
      if post.isReplyTo && isInThreadContext, let toHandle = post.inReplyToHandle {
        Text("Replying to @\(toHandle)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      PostRowBodyView(
        post: post,
        onUsernameTap: { username in
          // Search for the user and navigate to their profile
          Task {
            await searchAndNavigateToUser(username: username)
          }
        })
      PostRowEmbedView(post: post)
      if !isQuote {
        PostRowActionsView(post: post)
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      router.navigateTo(.post(post))
    }
  }

  private var avatarView: some View {
    AsyncImage(url: post.author.avatarImageURL) { phase in
      switch phase {
      case .success(let image):
        image
          .resizable()
          .scaledToFit()
          .frame(width: isQuote ? 16 : 40, height: isQuote ? 16 : 40)
          .clipShape(Circle())
      default:
        Circle()
          .fill(.gray.opacity(0.2))
          .frame(width: isQuote ? 16 : 40, height: isQuote ? 16 : 40)
      }
    }
    .overlay {
      Circle()
        .stroke(
          post.hasReply ? LinearGradient.avatarBorderReversed : LinearGradient.avatarBorder,
          lineWidth: 1)
    }
    .shadow(color: .shadowPrimary.opacity(0.3), radius: 2)
    .onTapGesture {
      router.navigateTo(.profile(post.author))
    }
  }

  private var authorView: some View {
    HStack(alignment: isQuote ? .center : .firstTextBaseline) {
      if isQuote {
        avatarView
      }
      Text(post.author.displayName ?? "")
        .font(.callout)
        .foregroundStyle(.primary)
        .fontWeight(.semibold)
        + Text("  @\(post.author.handle)")
        .font(.footnote)
        .foregroundStyle(.tertiary)
      Spacer()
      if settingsService.showTimestamps {
        Text(post.indexAtFormatted)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .lineLimit(1)
    .onTapGesture {
      router.navigateTo(.profile(post.author))
    }
  }

  @ViewBuilder
  private var threadLineView: some View {
    // Only show thread lines when we're actually viewing a thread, not in a feed view
    // In a feed view, posts are individual and not connected, so no thread lines should appear
    if isInThreadContext && post.isReplyTo {
      Rectangle()
        .fill(LinearGradient.themeGradient)
        .frame(width: 2)
        .frame(maxHeight: .infinity)
        .padding(.top, -20)  // Start well above the avatar to connect with parent post above
        .padding(.bottom, 8)  // Extend to connect with next post
    }
  }

  // Determine if we're in a thread context (viewing replies to a specific post)
  // vs. a feed context (viewing individual posts from different users)
  private var isInThreadContext: Bool {
    // Explicitly provided by parent views (e.g., PostDetailView)
    // Ensures thread lines render for all replies within a thread view
    return isThreadContext
  }

  // Fetch the immediate parent of this post for inline display in feed
  private func loadParentPost() async {
    do {
      let thread = try await client.protoClient.getPostThread(from: post.uri)
      switch thread.thread {
      case .threadViewPost(let threadViewPost):
        if let parent = threadViewPost.parent {
          switch parent {
          case .threadViewPost(let parentPostView):
            self.parentPost = parentPostView.post.postItem
          default:
            break
          }
        }
      default:
        break
      }
    } catch {
      // Silently ignore; parent will just not render
    }
  }

  // Search for a user by username and navigate to their profile
  @MainActor
  private func searchAndNavigateToUser(username: String) async {
    do {
      // Search for the user by their handle
      let searchResults = try await client.protoClient.searchActors(matching: username, limit: 1)

      if let firstActor = searchResults.actors.first {
        // Create a proper Profile object with the real DID
        let profile = Profile(
          did: firstActor.actorDID,
          handle: firstActor.actorHandle,
          displayName: firstActor.displayName,
          avatarImageURL: firstActor.avatarImageURL,
          description: firstActor.description,
          followersCount: 0,
          followingCount: 0,
          postsCount: 0,
          isFollowing: firstActor.viewer?.followingURI != nil,
          isFollowedBy: firstActor.viewer?.followedByURI != nil,
          isBlocked: firstActor.viewer?.isBlocked == true,
          isBlocking: firstActor.viewer?.blockingURI != nil,
          isMuted: firstActor.viewer?.isMuted == true
        )

        print("PostRowView: Found profile for \(username), navigating to profile")
        router.navigateTo(.profile(profile))
      } else {
        print("PostRowView: No profile found for username: \(username)")
        // Could show an error message or fallback behavior here
      }
    } catch {
      print("PostRowView: Error searching for user \(username): \(error)")
      // Could show an error message or fallback behavior here
    }
  }

}

// #Preview {
//   NavigationStack {
//     List {
//       PostRowView(
//         post: .init(
//           uri: "",
//           cid: "",
//           indexedAt: Date(),
//           author: .init(
//             did: "",
//             handle: "dimillian",
//             displayName: "Thomas Ricouard",
//             avatarImageURL: nil),
//           content: "Just some content",
//           replyCount: 10,
//           repostCount: 150,
//           likeCount: 38,
//           likeURI: nil,
//           repostURI: nil,
//           // embed: nil,
//           replyRef: nil))
//       PostRowView(
//         post: .init(
//           uri: "",
//           cid: "",
//           indexedAt: Date(),
//           author: .init(
//             did: "",
//             handle: "dimillian",
//             displayName: "Thomas Ricouard",
//             avatarImageURL: nil),
//           content: "Just some content",
//           replyCount: 10,
//           repostCount: 150,
//           likeCount: 38,
//           likeURI: nil,
//           repostURI: nil,
//           // embed: nil,
//           replyRef: nil))
//       PostRowEmbedQuoteView(
//         post: .init(
//           uri: "",
//           cid: "",
//           indexedAt: Date(),
//           author: .init(
//             did: "",
//             handle: "dimillian",
//             displayName: "Thomas Ricouard",
//             avatarImageURL: nil),
//           content: "Just some content",
//           replyCount: 10,
//           repostCount: 150,
//           likeCount: 38,
//           likeURI: "",
//           repostURI: "",
//           // embed: nil,
//           replyRef: nil))
//     }
//     .listStyle(.plain)
//     .environment(AppRouter(initialTab: .feed))
//     .environment(PostContextProvider())
//     .environment(PostFilterService.shared)
//   }
// }
