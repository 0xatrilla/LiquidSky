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
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .task(id: filter) {
      #if DEBUG
      print("Filter changed to: \(filter)")
      #endif
      await loadFeedsForCurrentFilter()
    }
    .onAppear {
      checkForSearchNavigation()
    }
  }

  private var headerView: some View {
    FeedsListTitleView(
      filter: $filter
    )
    .onChange(of: currentUser.savedFeeds.count) {
      #if DEBUG
      print("Saved feeds count changed: \(currentUser.savedFeeds.count)")
      #endif
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
      #if DEBUG
      print("Fetching suggested feeds...")
      #endif
      let feeds = try await client.protoClient.getPopularFeedGenerators(matching: nil)
      #if DEBUG
      print("Suggested feeds API response: \(feeds)")
      print("Suggested feeds received: \(feeds.feeds.count)")
      #endif

      let feedItems = feeds.feeds.map { $0.feedItem }.filter { feed in
        !currentUser.savedFeeds.contains { $0.value == feed.uri }
      }

      #if DEBUG
      print("Filtered suggested feeds: \(feedItems.count)")
      print("Feed items: \(feedItems.map { $0.displayName })")
      #endif

      withAnimation {
        self.feeds = feedItems
      }
    } catch {
      #if DEBUG
      print("Error fetching suggested feeds: \(error)")
      #endif
      self.error = error
    }
  }

  private func fetchMyFeeds() async {
    do {
      #if DEBUG
      print("Fetching my feeds...")
      print("Saved feeds count: \(currentUser.savedFeeds.count)")
      print("Saved feeds URIs: \(currentUser.savedFeeds.map { $0.value })")
      #endif

      guard !currentUser.savedFeeds.isEmpty else {
        #if DEBUG
        print("No saved feeds to fetch")
        #endif
        withAnimation {
          self.feeds = []
        }
        return
      }

      let feeds = try await client.protoClient.getFeedGenerators(
        by: currentUser.savedFeeds.map { $0.value })
      #if DEBUG
      print("My feeds API response: \(feeds)")
      print("My feeds received: \(feeds.feeds.count)")
      #endif

      let feedItems = feeds.feeds.map { $0.feedItem }
      #if DEBUG
      print("Processed my feeds: \(feedItems.count)")
      print("Feed items: \(feedItems.map { $0.displayName })")
      #endif

      withAnimation {
        self.feeds = feedItems
      }
    } catch {
      #if DEBUG
      print("Error fetching my feeds: \(error)")
      #endif
      // Don't set error state for my feeds, just show empty state
      withAnimation {
        self.feeds = []
      }
    }
  }

  // MARK: - Search Navigation
  private func checkForSearchNavigation() {
    // This method is no longer needed since we're using sheet destinations
    // The search navigation is now handled directly in SearchView.swift
  }
}
