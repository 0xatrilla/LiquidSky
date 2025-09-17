import AppRouter
import Client
import DesignSystem
import Models
import NukeUI
import SwiftUI
import User

public struct DiscoverFeedsListView: View {
    let onFeedSelected: (FeedItem) -> Void

    @Environment(BSkyClient.self) var client
    @Environment(CurrentUser.self) var currentUser
    @Environment(\.dismiss) var dismiss

    @State var feeds: [FeedItem] = []
    @State var filter: FeedsListFilter = .myFeeds
    @State var isLoading: Bool = false
    @State var error: Error?

    public init(onFeedSelected: @escaping (FeedItem) -> Void) {
        self.onFeedSelected = onFeedSelected
    }

    public var body: some View {
        NavigationStack {
            List {
                if let error {
                    errorSection
                }

                if isLoading {
                    loadingSection
                } else if feeds.isEmpty {
                    emptySection
                } else {
                    feedsSection
                }
            }
            .listStyle(.plain)
            .navigationTitle("Discover Feeds")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Filter", selection: $filter) {
                        Text("My Feeds").tag(FeedsListFilter.myFeeds)
                        Text("Suggested").tag(FeedsListFilter.suggested)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .task(id: filter) {
                await loadFeedsForCurrentFilter()
            }
        }
    }

    private var errorSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Unable to Load Feeds")
                        .font(.headline)
                }

                Text("There was an error loading the feeds. Please try again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Retry") {
                    Task {
                        await loadFeedsForCurrentFilter()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var loadingSection: some View {
        Section {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading feeds...")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
        }
    }

    private var emptySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: filter == .myFeeds ? "star.slash" : "magnifyingglass")
                        .foregroundStyle(.secondary)
                    Text(filter == .myFeeds ? "No Saved Feeds" : "No Suggested Feeds")
                        .font(.headline)
                }

                Text(
                    filter == .myFeeds
                        ? "You haven't saved any feeds yet. Try exploring suggested feeds!"
                        : "Unable to load suggested feeds. Please try again."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private var feedsSection: some View {
        Section {
            ForEach(feeds, id: \.uri) { feed in
                DiscoverFeedRowView(
                    feed: feed,
                    currentFilter: filter,
                    onFeedSelected: onFeedSelected
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onFeedSelected(feed)
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

    private func fetchSuggestedFeed() async {
        error = nil
        do {
            let feeds = try await client.protoClient.getPopularFeedGenerators(matching: nil)
            let feedItems = feeds.feeds.map { $0.feedItem }.filter { feed in
                !currentUser.savedFeeds.contains { $0.value == feed.uri }
            }

            withAnimation(.easeInOut(duration: 0.3)) {
                self.feeds = feedItems
            }
        } catch {
            self.error = error
        }
    }

    private func fetchMyFeeds() async {
        do {
            guard !currentUser.savedFeeds.isEmpty else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.feeds = []
                }
                return
            }

            let feeds = try await client.protoClient.getFeedGenerators(
                by: currentUser.savedFeeds.map { $0.value })
            let feedItems = feeds.feeds.map { $0.feedItem }

            withAnimation(.easeInOut(duration: 0.3)) {
                self.feeds = feedItems
            }
        } catch {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.feeds = []
            }
        }
    }
}

// MARK: - Discover Feed Row View
private struct DiscoverFeedRowView: View {
    let feed: FeedItem
    let currentFilter: FeedsListFilter
    let onFeedSelected: (FeedItem) -> Void
    @Environment(CurrentUser.self) var currentUser

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            FeedAvatarView(feed: feed)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(feed.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let description = feed.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Text("@\(feed.creatorHandle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: feed.liked ? "heart.fill" : "heart")
                            .foregroundStyle(feed.liked ? .red : .secondary)
                            .font(.caption)
                        Text("\(feed.likesCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .contextMenu {
            contextMenuContent
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        if currentFilter == .suggested {
            Button {
                pinFeed()
            } label: {
                Label("Save to My Feeds", systemImage: "pin")
            }

            Button {
                pinFeedToTabBar()
            } label: {
                Label("Pin to Tab Bar", systemImage: "square.stack.3d.up")
            }
        } else {
            Button(role: .destructive) {
                unpinFeed()
            } label: {
                Label("Remove from My Feeds", systemImage: "trash")
            }

            Button {
                pinFeedToTabBar()
            } label: {
                Label("Pin to Tab Bar", systemImage: "square.stack.3d.up")
            }
        }
    }

    private func pinFeedToTabBar() {
        let uri = feed.uri
        var uris = SettingsService.shared.pinnedFeedURIs
        if !uris.contains(uri) {
            uris.append(uri)
            SettingsService.shared.pinnedFeedURIs = uris
        }
        var names = SettingsService.shared.pinnedFeedNames
        names[uri] = feed.displayName
        SettingsService.shared.pinnedFeedNames = names
    }

    private func pinFeed() {
        Task {
            do {
                try await currentUser.pinFeed(
                    uri: feed.uri, displayName: feed.displayName)
            } catch {
                #if DEBUG
                    print("Failed to pin feed: \(error)")
                #endif
            }
        }
    }

    private func unpinFeed() {
        Task {
            do {
                try await currentUser.unpinFeed(
                    uri: feed.uri, displayName: feed.displayName)
            } catch {
                #if DEBUG
                    print("Failed to unpin feed: \(error)")
                #endif
            }
        }
    }
}

// MARK: - Feed Avatar View
private struct FeedAvatarView: View {
    let feed: FeedItem

    var body: some View {
        LazyImage(url: feed.avatarImageURL) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.7), .indigo.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
