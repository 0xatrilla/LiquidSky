@preconcurrency import ATProtoKit
import AppRouter
import Client
import DesignSystem
import Models
import SwiftUI
import User

public struct FeedsListView: View {
  @Environment(BSkyClient.self) var client
  @Environment(CurrentUser.self) var currentUser

  @State var feeds: [FeedItem] = []
  @State var filter: FeedsListFilter = .suggested
  @State var isLoading: Bool = false

  @State var isRecentFeedExpanded: Bool = true

  @State var error: Error?

  public init() {
  }

  public var body: some View {
    List {
      headerView
        .padding(.bottom, 16)
      if let error {
        FeedsListErrorView(error: error) {
          await fetchSuggestedFeed()
        }
      }
      FeedsListRecentSection(isRecentFeedExpanded: $isRecentFeedExpanded)
      feedsSection
    }
    .screenContainer()
    .scrollDismissesKeyboard(.immediately)
    // Enable proper scroll behavior and tab bar collapse
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .task(id: filter) {
      print("Filter changed to: \(filter)")
      await loadFeedsForCurrentFilter()
    }
    .onAppear {
      // No initialization needed for local filtering
    }
  }

  private var headerView: some View {
    FeedsListTitleView(
      filter: $filter
    )
    .onChange(of: currentUser.savedFeeds.count) {
      print("Saved feeds count changed: \(currentUser.savedFeeds.count)")
      switch filter {
      case .suggested:
        feeds = feeds.filter { feed in
          !currentUser.savedFeeds.contains { $0.value == feed.uri }
        }
      case .myFeeds:
        Task { await fetchMyFeeds() }
      }
    }
    .listRowSeparator(.hidden)
  }

  private var feedsSection: some View {
    Section {
      if isLoading {
        HStack {
          ProgressView()
            .scaleEffect(0.8)
          Text("Loading feeds...")
            .font(.body)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
      } else if feeds.isEmpty {
        VStack(spacing: 16) {
          Image(
            systemName: filter == .myFeeds
              ? "person.crop.rectangle.stack" : "sparkles.rectangle.stack"
          )
          .font(.system(size: 48))
          .foregroundStyle(.secondary)

          Text(filter == .myFeeds ? "No Saved Feeds" : "No Suggested Feeds")
            .font(.title2)
            .fontWeight(.semibold)

          Text(
            filter == .myFeeds
              ? "You haven\'t saved any feeds yet. Try exploring suggested feeds!"
              : "Unable to load suggested feeds. Please try again."
          )
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
      } else {
        ForEach(feeds, id: \.uri) { feed in
          FeedRowView(feed: feed)
        }
      }
    }
  }

  private func loadFeedsForCurrentFilter() async {
    isLoading = true
    defer { isLoading = false }

    switch filter {
    case .suggested:
      await fetchSuggestedFeed()
    case .myFeeds:
      await fetchMyFeeds()
    }
  }
}

// MARK: - Network
extension FeedsListView {
  private func fetchSuggestedFeed() async {
    error = nil
    do {
      print("Fetching suggested feeds...")
      let feeds = try await client.protoClient.getPopularFeedGenerators(matching: nil)
      print("Suggested feeds API response: \(feeds)")
      print("Suggested feeds received: \(feeds.feeds.count)")

      let feedItems = feeds.feeds.map { $0.feedItem }.filter { feed in
        !currentUser.savedFeeds.contains { $0.value == feed.uri }
      }

      print("Filtered suggested feeds: \(feedItems.count)")
      print("Feed items: \(feedItems.map { $0.displayName })")

      withAnimation {
        self.feeds = feedItems
      }
    } catch {
      print("Error fetching suggested feeds: \(error)")
      self.error = error
    }
  }

  private func fetchMyFeeds() async {
    do {
      print("Fetching my feeds...")
      print("Saved feeds count: \(currentUser.savedFeeds.count)")
      print("Saved feeds URIs: \(currentUser.savedFeeds.map { $0.value })")

      guard !currentUser.savedFeeds.isEmpty else {
        print("No saved feeds to fetch")
        withAnimation {
          self.feeds = []
        }
        return
      }

      let feeds = try await client.protoClient.getFeedGenerators(
        by: currentUser.savedFeeds.map { $0.value })
      print("My feeds API response: \(feeds)")
      print("My feeds received: \(feeds.feeds.count)")

      let feedItems = feeds.feeds.map { $0.feedItem }
      print("Processed my feeds: \(feedItems.count)")
      print("Feed items: \(feedItems.map { $0.displayName })")

      withAnimation {
        self.feeds = feedItems
      }
    } catch {
      print("Error fetching my feeds: \(error)")
      // Don't set error state for my feeds, just show empty state
      withAnimation {
        self.feeds = []
      }
    }
  }
}
