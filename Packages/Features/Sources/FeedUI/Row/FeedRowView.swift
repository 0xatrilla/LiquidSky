import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import NukeUI
import SwiftUI
import User

struct FeedRowView: View {
  let feed: FeedItem
  @Namespace private var namespace
  @Environment(AppRouter.self) var router
  @Environment(CurrentUser.self) var currentUser
  @State private var showingPinAlert = false

  var body: some View {
    Button(action: {
      HapticManager.shared.impact(.light)
      router.navigateTo(.feed(feed))
    }) {
      VStack(alignment: .leading, spacing: 12) {
        headerView
        if let description = feed.description {
          Text(description)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        Text("By @\(feed.creatorHandle)")
          .font(.callout)
          .foregroundStyle(.tertiary)
      }
      .padding(.vertical, 12)
      .contentShape(Rectangle())  // Make entire area tappable
    }
    .buttonStyle(PlainButtonStyle())  // Remove default button styling
    .listRowSeparator(.hidden)
    .onLongPressGesture {
      showingPinAlert = true
    }
    .alert("Pin Feed", isPresented: $showingPinAlert) {
      Button("Pin to My Feeds") {
        pinFeed()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Add '\(feed.displayName)' to your pinned feeds?")
    }
  }

  private func pinFeed() {
    let feedToPin = feed
    Task {
      do {
        try await currentUser.pinFeed(uri: feedToPin.uri, displayName: feedToPin.displayName)
      } catch {
        #if DEBUG
          print("Failed to pin feed: \(error)")
        #endif
      }
    }
  }

  @ViewBuilder
  var headerView: some View {
    HStack {
      LazyImage(url: feed.avatarImageURL) { state in
        if let image = state.image {
          image
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .shadowPrimary.opacity(0.7), radius: 2)
        } else {
          Image(systemName: "antenna.radiowaves.left.and.right")
            .imageScale(.medium)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(RoundedRectangle(cornerRadius: 8).fill(LinearGradient.blueskySubtle))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .shadowPrimary.opacity(0.7), radius: 2)
        }
      }

      VStack(alignment: .leading) {
        Text(feed.displayName)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundStyle(
            .primary.shadow(
              .inner(
                color: .shadowSecondary.opacity(0.5),
                radius: 2, x: -1, y: -1)))
        likeView
      }
    }
  }

  @ViewBuilder
  var likeView: some View {
    HStack(spacing: 2) {
      Image(systemName: feed.liked ? "heart.fill" : "heart")
        .foregroundStyle(
          LinearGradient(
            colors: [.indigo.opacity(0.4), .red],
            startPoint: .top,
            endPoint: .bottom
          )
          .shadow(.inner(color: .red, radius: 3))
        )
        .shadow(color: .red, radius: 1)
      Text("\(feed.likesCount) likes")
        .font(.callout)
        .foregroundStyle(.secondary)

    }
  }
}

#Preview {
  NavigationStack {
    List {
      FeedRowView(
        feed: FeedItem(
          uri: "",
          displayName: "Preview Feed",
          description: "This is a sample feed",
          avatarImageURL: nil,
          creatorHandle: "dimillian.app",
          likesCount: 50,
          liked: false
        )
      )
      FeedRowView(
        feed: FeedItem(
          uri: "",
          displayName: "Preview Feed",
          description: "This is a sample feed",
          avatarImageURL: nil,
          creatorHandle: "dimillian.app",
          likesCount: 50,
          liked: true
        )
      )
    }
    .listStyle(.plain)
  }
}
