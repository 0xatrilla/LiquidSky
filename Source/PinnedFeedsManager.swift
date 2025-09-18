import Foundation
import Models
import SwiftUI

@available(iOS 26.0, *)
@Observable
class PinnedFeedsManager {
  var pinnedFeeds: [PinnedFeed] = []
  var isLoading = false
  var error: Error?

  private let settingsService = SettingsService.shared

  init() {
    loadPinnedFeeds()
  }

  func loadPinnedFeeds() {
    isLoading = true
    error = nil

    // Convert existing pinned feed URIs to PinnedFeed objects
    pinnedFeeds = settingsService.pinnedFeedURIs.compactMap { uri in
      PinnedFeed(
        id: uri,
        uri: uri,
        displayName: settingsService.pinnedFeedNames[uri] ?? "Feed",
        description: nil,
        avatarImageURL: nil,
        creatorHandle: "",
        isPinned: true,
        order: settingsService.pinnedFeedURIs.firstIndex(of: uri) ?? 0
      )
    }.sorted { $0.order < $1.order }

    isLoading = false
  }

  func pinFeed(_ feed: FeedItem) {
    guard !isPinned(feed.uri) else { return }

    let pinnedFeed = PinnedFeed(
      id: feed.uri,
      uri: feed.uri,
      displayName: feed.displayName,
      description: feed.description,
      avatarImageURL: feed.avatarImageURL,
      creatorHandle: feed.creatorHandle,
      isPinned: true,
      order: pinnedFeeds.count
    )

    withAnimation(.smooth(duration: 0.3)) {
      pinnedFeeds.append(pinnedFeed)

      // Update settings service
      settingsService.pinnedFeedURIs.append(feed.uri)
      settingsService.pinnedFeedNames[feed.uri] = feed.displayName
    }
  }

  func unpinFeed(_ feedURI: String) {
    withAnimation(.smooth(duration: 0.3)) {
      pinnedFeeds.removeAll { $0.uri == feedURI }

      // Update settings service
      if let index = settingsService.pinnedFeedURIs.firstIndex(of: feedURI) {
        settingsService.pinnedFeedURIs.remove(at: index)
      }
      settingsService.pinnedFeedNames.removeValue(forKey: feedURI)

      // Reorder remaining feeds
      reorderFeeds()
    }
  }

  func renameFeed(_ feedURI: String, to newName: String) {
    if let index = pinnedFeeds.firstIndex(where: { $0.uri == feedURI }) {
      withAnimation(.smooth(duration: 0.2)) {
        pinnedFeeds[index].displayName = newName
        settingsService.pinnedFeedNames[feedURI] = newName
      }
    }
  }

  func moveFeed(from sourceIndex: Int, to destinationIndex: Int) {
    guard sourceIndex != destinationIndex,
      sourceIndex < pinnedFeeds.count,
      destinationIndex < pinnedFeeds.count
    else { return }

    withAnimation(.smooth(duration: 0.3)) {
      let feed = pinnedFeeds.remove(at: sourceIndex)
      pinnedFeeds.insert(feed, at: destinationIndex)

      // Update order values
      reorderFeeds()

      // Update settings service
      let reorderedURIs = pinnedFeeds.map { $0.uri }
      settingsService.pinnedFeedURIs = reorderedURIs
    }
  }

  func isPinned(_ feedURI: String) -> Bool {
    pinnedFeeds.contains { $0.uri == feedURI }
  }

  private func reorderFeeds() {
    for (index, _) in pinnedFeeds.enumerated() {
      pinnedFeeds[index].order = index
    }
  }
}

@available(iOS 26.0, *)
struct PinnedFeed: Identifiable, Hashable {
  let id: String
  let uri: String
  var displayName: String
  let description: String?
  let avatarImageURL: URL?
  let creatorHandle: String
  var isPinned: Bool
  var order: Int

  static func == (lhs: PinnedFeed, rhs: PinnedFeed) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - Pinned Feeds Section View

@available(iOS 26.0, *)
struct PinnedFeedsSection: View {
  @Environment(\.pinnedFeedsManager) var pinnedFeedsManager
  @Environment(\.focusManager) var focusManager
  @State private var showingFeedPicker = false
  @State private var editingFeed: PinnedFeed?
  @State private var newFeedName = ""

  var body: some View {
    if !pinnedFeedsManager.pinnedFeeds.isEmpty || pinnedFeedsManager.isLoading {
      Section {
        if pinnedFeedsManager.isLoading {
          loadingView
        } else {
          pinnedFeedsList
        }

        addFeedButton
      } header: {
        pinnedFeedsHeader
      }
    }
  }

  // MARK: - Pinned Feeds List

  @ViewBuilder
  private var pinnedFeedsList: some View {
    ForEach(Array(pinnedFeedsManager.pinnedFeeds.enumerated()), id: \.element) { index, feed in
      PinnedFeedRow(
        feed: feed,
        isSelected: isSelected(feed),
        isFocused: isFocused(at: index),
        onSelect: {
          selectFeed(feed)
        },
        onEdit: {
          editFeed(feed)
        },
        onDelete: {
          pinnedFeedsManager.unpinFeed(feed.uri)
        }
      )
      .tag(feed.uri)
    }
    .onMove(perform: moveFeed)
  }

  // MARK: - Loading View

  @ViewBuilder
  private var loadingView: some View {
    HStack {
      ProgressView()
        .scaleEffect(0.8)
      Text("Loading feeds...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 8)
        .fill(.ultraThinMaterial)
    }
  }

  // MARK: - Header

  @ViewBuilder
  private var pinnedFeedsHeader: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text("Pinned Feeds")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)
        
        Text("\(pinnedFeedsManager.pinnedFeeds.count) feeds")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button(action: { showingFeedPicker = true }) {
        Image(systemName: "plus.circle.fill")
          .font(.subheadline)
          .foregroundStyle(.blue)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Add Feed Button

  @ViewBuilder
  private var addFeedButton: some View {
    Button(action: { showingFeedPicker = true }) {
      HStack {
        Image(systemName: "plus")
          .font(.subheadline.weight(.medium))
        Text("Add Feed")
          .font(.subheadline.weight(.medium))
        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
    .background {
      RoundedRectangle(cornerRadius: 10)
        .fill(.ultraThinMaterial)
    }
    .sheet(isPresented: $showingFeedPicker) {
      FeedPickerSheet()
    }
    .sheet(item: $editingFeed) { feed in
      EditFeedSheet(feed: feed, newName: $newFeedName)
    }
  }

  // MARK: - Helper Methods

  private func isSelected(_ feed: PinnedFeed) -> Bool {
    // Selection state simplified for iPad
    return false
  }

  private func isFocused(at index: Int) -> Bool {
    let adjustedIndex = 5 + index // 5 main items: feed, notifications, search, profile, settings
    return focusManager.focusedColumn == .sidebar && focusManager.focusedItemIndex == adjustedIndex
  }

  private func selectFeed(_ feed: PinnedFeed) {
    // Feed selection simplified for iPad
    // Navigation handled by TabView
  }

  private func editFeed(_ feed: PinnedFeed) {
    editingFeed = feed
    newFeedName = feed.displayName
  }

  private func moveFeed(from source: IndexSet, to destination: Int) {
    guard let sourceIndex = source.first else { return }
    pinnedFeedsManager.moveFeed(from: sourceIndex, to: destination)
  }
}

// MARK: - Pinned Feed Row

@available(iOS 26.0, *)
struct PinnedFeedRow: View {
  let feed: PinnedFeed
  let isSelected: Bool
  let isFocused: Bool
  let onSelect: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0

  private let rowId = UUID().uuidString

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 12) {
        // Feed avatar or icon
        AsyncImage(url: feed.avatarImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(.blue.gradient)
            .overlay {
              Image(systemName: "dot.radiowaves.left.and.right")
                .foregroundStyle(.white)
                .font(.caption)
            }
        }
        .frame(width: 20, height: 20)
        .clipShape(Circle())

        // Feed info
        VStack(alignment: .leading, spacing: 2) {
          Text(feed.displayName)
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? .primary : .secondary)
            .lineLimit(1)

          if !feed.creatorHandle.isEmpty {
            Text("by @\(feed.creatorHandle)")
              .font(.caption2)
              .foregroundStyle(.tertiary)
              .lineLimit(1)
          }
        }

        Spacer()

        // Reorder handle (visible on hover)
        if isHovering || isPencilHovering {
          Image(systemName: "line.3.horizontal")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(backgroundView)
    }
    .buttonStyle(.plain)
    .scaleEffect(scaleEffect)
    .brightness(hoverIntensity * 0.1)
    .overlay(focusOverlay)
    .contextMenu {
      contextMenuContent
    }
    .applePencilHover(id: rowId) { hovering, location, intensity in
      withAnimation(.smooth(duration: 0.2)) {
        isPencilHovering = hovering
        hoverIntensity = intensity
      }
    }
    .onHover { hovering in
      withAnimation(.smooth(duration: 0.2)) {
        isHovering = hovering && !isPencilHovering
      }
    }
    .animation(.smooth(duration: 0.2), value: isSelected)
  }

  // MARK: - Computed Properties

  private var scaleEffect: CGFloat {
    if isPencilHovering {
      return 1.02
    } else if isHovering {
      return 1.01
    } else {
      return 1.0
    }
  }

  @ViewBuilder
  private var backgroundView: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(backgroundFill)

      RoundedRectangle(cornerRadius: 8)
        .fill(.ultraThinMaterial)
    }
  }

  private var backgroundFill: Color {
    if isSelected {
      return .blue.opacity(0.15)
    } else if isPencilHovering || isHovering {
      return .primary.opacity(0.05)
    } else {
      return .clear
    }
  }

  @ViewBuilder
  private var focusOverlay: some View {
    if isFocused {
      ZStack {
      RoundedRectangle(cornerRadius: 8)
        .stroke(.blue, lineWidth: 2)

      RoundedRectangle(cornerRadius: 8)
        .fill(.ultraThinMaterial)
    }
    }

    if isPencilHovering {
      ZStack {
      RoundedRectangle(cornerRadius: 8)
        .stroke(.blue.opacity(hoverIntensity), lineWidth: 1)

      RoundedRectangle(cornerRadius: 8)
        .fill(.ultraThinMaterial)
    }
    }
  }

  @ViewBuilder
  private var contextMenuContent: some View {
    Button("Rename", systemImage: "pencil") {
      onEdit()
    }

    Button("Move Up", systemImage: "arrow.up") {
      // Handle move up
    }

    Button("Move Down", systemImage: "arrow.down") {
      // Handle move down
    }

    Divider()

    Button("Unpin", systemImage: "pin.slash", role: .destructive) {
      onDelete()
    }
  }
}

// MARK: - Feed Picker Sheet

@available(iOS 26.0, *)
struct FeedPickerSheet: View {
  @Environment(\.dismiss) var dismiss
  @Environment(\.pinnedFeedsManager) var pinnedFeedsManager
  @State private var searchText = ""
  @State private var availableFeeds: [FeedItem] = []

  var body: some View {
    NavigationView {
      VStack {
        GestureAwareSearchBar(text: $searchText, placeholder: "Search feeds...")
          .padding()

        List(filteredFeeds, id: \.uri) { feed in
          FeedPickerRow(feed: feed) {
            pinnedFeedsManager.pinFeed(feed)
            dismiss()
          }
        }
      }
      .navigationTitle("Add Feed")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
    }
    .task {
      await loadAvailableFeeds()
    }
  }

  private var filteredFeeds: [FeedItem] {
    if searchText.isEmpty {
      return availableFeeds.filter { !pinnedFeedsManager.isPinned($0.uri) }
    } else {
      return availableFeeds.filter { feed in
        !pinnedFeedsManager.isPinned(feed.uri)
          && (feed.displayName.localizedCaseInsensitiveContains(searchText)
            || feed.creatorHandle.localizedCaseInsensitiveContains(searchText))
      }
    }
  }

  private func loadAvailableFeeds() async {
    // Mock feed data - in real app, this would fetch from API
    availableFeeds = [
      FeedItem(
        uri: "at://did:plc:example1/app.bsky.feed.generator/discover",
        displayName: "Discover",
        description: "Popular posts from across the network",
        avatarImageURL: nil,
        creatorHandle: "bsky.app",
        likesCount: 1250,
        liked: false
      ),
      FeedItem(
        uri: "at://did:plc:example2/app.bsky.feed.generator/tech",
        displayName: "Tech News",
        description: "Latest technology and programming discussions",
        avatarImageURL: nil,
        creatorHandle: "tech.bsky.social",
        likesCount: 890,
        liked: false
      ),
    ]
  }
}

// MARK: - Feed Picker Row

@available(iOS 26.0, *)
struct FeedPickerRow: View {
  let feed: FeedItem
  let onSelect: () -> Void

  var body: some View {
    GestureAwareGlassCard(cornerRadius: 8, isInteractive: true, onTap: onSelect) {
      HStack(spacing: 12) {
        AsyncImage(url: feed.avatarImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(.blue.gradient)
            .overlay {
              Image(systemName: "square.stack")
                .foregroundStyle(.white)
                .font(.caption)
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())

        VStack(alignment: .leading, spacing: 4) {
          Text(feed.displayName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)

          Text("by @\(feed.creatorHandle)")
            .font(.caption)
            .foregroundStyle(.secondary)

          if let description = feed.description {
            Text(description)
              .font(.caption2)
              .foregroundStyle(.tertiary)
              .lineLimit(2)
          }
        }

        Spacer()

        Image(systemName: "plus.circle.fill")
          .font(.title2)
          .foregroundStyle(.blue)
      }
    }
  }
}

// MARK: - Edit Feed Sheet

@available(iOS 26.0, *)
struct EditFeedSheet: View {
  let feed: PinnedFeed
  @Binding var newName: String
  @Environment(\.dismiss) var dismiss
  @Environment(\.pinnedFeedsManager) var pinnedFeedsManager

  var body: some View {
    NavigationView {
      Form {
        Section("Feed Name") {
          TextField("Enter feed name", text: $newName)
            .textFieldStyle(.roundedBorder)
        }
      }
      .navigationTitle("Edit Feed")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") {
            pinnedFeedsManager.renameFeed(feed.uri, to: newName)
            dismiss()
          }
          .disabled(newName.isEmpty)
        }
      }
    }
    .background {
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
    }
  }
}

// MARK: - Environment Key

@available(iOS 26.0, *)
struct PinnedFeedsManagerKey: EnvironmentKey {
  static let defaultValue = PinnedFeedsManager()
}

@available(iOS 26.0, *)
extension EnvironmentValues {
  var pinnedFeedsManager: PinnedFeedsManager {
    get { self[PinnedFeedsManagerKey.self] }
    set { self[PinnedFeedsManagerKey.self] = newValue }
  }
}
