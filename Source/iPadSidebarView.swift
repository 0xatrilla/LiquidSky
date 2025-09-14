import AppRouter
import Client
import Destinations
import Foundation
import Models
import SwiftUI
import UIKit
import User

// MARK: - SidebarItem

@available(iOS 26.0, *)
enum SidebarItem: CaseIterable, Identifiable, Hashable {
  case feed
  case notification
  case compose
  case profile
  case settings
  case pinnedFeed(String)
  
  var id: String {
    switch self {
    case .feed:
      return "feed"
    case .notification:
      return "notification"
    case .compose:
      return "compose"
    case .profile:
      return "profile"
    case .settings:
      return "settings"
    case .pinnedFeed(let uri):
      return "pinned_\(uri)"
    }
  }
  
  var displayName: String {
    switch self {
    case .feed:
      return "Feed"
    case .notification:
      return "Notifications"
    case .compose:
      return "Compose"
    case .profile:
      return "Profile"
    case .settings:
      return "Settings"
    case .pinnedFeed(let uri):
      return extractFeedName(from: uri)
    }
  }
  
  var systemImage: String {
    switch self {
    case .feed:
      return "house"
    case .notification:
      return "bell"
    case .compose:
      return "plus.circle"
    case .profile:
      return "person"
    case .settings:
      return "gear"
    case .pinnedFeed:
      return "star"
    }
  }
  
  static var allCases: [SidebarItem] {
    [.feed, .notification, .compose, .profile, .settings]
  }
  
  static var mainItems: [SidebarItem] {
    [.feed, .notification, .compose, .profile, .settings]
  }
  
  // Hashable conformance
  func hash(into hasher: inout Hasher) {
    switch self {
    case .feed:
      hasher.combine("feed")
    case .notification:
      hasher.combine("notification")
    case .compose:
      hasher.combine("compose")
    case .profile:
      hasher.combine("profile")
    case .settings:
      hasher.combine("settings")
    case .pinnedFeed(let uri):
      hasher.combine("pinnedFeed")
      hasher.combine(uri)
    }
  }
  
  // Equatable conformance
  static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
    switch (lhs, rhs) {
    case (.feed, .feed), (.notification, .notification), (.compose, .compose), 
         (.profile, .profile), (.settings, .settings):
      return true
    case (.pinnedFeed(let lhsURI), .pinnedFeed(let rhsURI)):
      return lhsURI == rhsURI
    default:
      return false
    }
  }
  
  private func extractFeedName(from uri: String) -> String {
    // Extract a readable name from the feed URI
    if uri.contains("at://") {
      let components = uri.components(separatedBy: "/")
      if let lastComponent = components.last, !lastComponent.isEmpty {
        return lastComponent.capitalized
      }
    }
    return "Custom Feed"
  }
}

@available(iOS 26.0, *)
struct iPadSidebarView: View {
  @Environment(Router<AppTab, RouterDestination, SheetDestination>.self) var router
  @Environment(BSkyClient.self) var client
  @Environment(CurrentUser.self) var currentUser
  @State private var settingsService = SettingsService.shared
  @State private var badgeStore = NotificationBadgeStore.shared
  
  // Sidebar state
  @State private var selectedItem: SidebarItem = .feed
  @State private var showingAccountSwitcher = false
  
  var body: some View {
    List {
      mainNavigationSection
      pinnedFeedsSection
      quickActionsSection
    }
    .listStyle(.sidebar)
    .navigationTitle("Horizon")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        accountButton
      }
    }
    .onChange(of: selectedItem) { _, newItem in
      handleSidebarSelection(newItem)
    }
    .sheet(isPresented: $showingAccountSwitcher) {
      AccountSwitcherView()
    }
  }
  
  // MARK: - View Components
  
  @ViewBuilder
  private var mainNavigationSection: some View {
    Section {
      ForEach(SidebarItem.mainItems, id: \.self) { item in
        SidebarRow(
          item: item,
          isSelected: selectedItem == item,
          badgeCount: badgeCount(for: item)
        )
        .onTapGesture {
          selectedItem = item
        }
      }
    } header: {
      Text("Navigation")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
  
  @ViewBuilder
  private var pinnedFeedsSection: some View {
    if !settingsService.pinnedFeedURIs.isEmpty {
      Section {
        ForEach(settingsService.pinnedFeedURIs, id: \.self) { feedURI in
          SidebarRow(
            item: .pinnedFeed(feedURI),
            isSelected: selectedItem == .pinnedFeed(feedURI),
            badgeCount: nil
          )
          .onTapGesture {
            selectedItem = .pinnedFeed(feedURI)
          }
        }
      } header: {
        Text("Pinned Feeds")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  @ViewBuilder
  private var quickActionsSection: some View {
    Section {
      Button(action: {
        router.presentedSheet = .composer(mode: .newPost)
      }) {
        Label("Compose", systemImage: "square.and.pencil")
          .foregroundStyle(.primary)
      }
      .buttonStyle(.plain)
      
      Button(action: {
        router.selectedTab = .compose
      }) {
        Label("Search", systemImage: "magnifyingglass")
          .foregroundStyle(.primary)
      }
      .buttonStyle(.plain)
    } header: {
      Text("Quick Actions")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
  
  @ViewBuilder
  private var accountButton: some View {
    Button(action: {
      showingAccountSwitcher = true
    }) {
      AsyncImage(url: nil) { image in
        image
          .resizable()
          .scaledToFill()
      } placeholder: {
        Image(systemName: "person.circle.fill")
          .font(.title2)
      }
      .frame(width: 32, height: 32)
      .clipShape(Circle())
    }
  }
  
  // MARK: - Helper Methods
  
  private func badgeCount(for item: SidebarItem) -> Int? {
    switch item {
    case .notification:
      return badgeStore.unreadCount > 0 ? badgeStore.unreadCount : nil
    default:
      return nil
    }
  }
  
  private func createFeedItem(for feedURI: String) -> FeedItem {
    FeedItem(
      uri: feedURI,
      displayName: settingsService.pinnedFeedNames[feedURI] ?? "Feed",
      description: nil,
      avatarImageURL: nil,
      creatorHandle: "",
      likesCount: 0,
      liked: false
    )
  }
  
  private func handleSidebarSelection(_ item: SidebarItem) {
    switch item {
    case .feed:
      router.selectedTab = .feed
    case .notification:
      router.selectedTab = .notification
    case .compose:
      router.selectedTab = .compose
    case .profile:
      router.selectedTab = .profile
    case .settings:
      router.selectedTab = .settings
    case .pinnedFeed(_):
      // Handle pinned feed selection
      router.selectedTab = .feed
      // Could navigate to specific feed here
    }
  }
}

// MARK: - Sidebar Row Component

@available(iOS 26.0, *)
struct SidebarRow: View {
  let item: SidebarItem
  let isSelected: Bool
  let badgeCount: Int?
  
  @State private var isHovering = false
  
  var body: some View {
    HStack(spacing: 12) {
      // Icon
      Image(systemName: item.systemImage)
        .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
        .foregroundStyle(iconColor)
        .frame(width: 20, height: 20)
      
      // Title
      Text(item.displayName)
        .font(.subheadline.weight(isSelected ? .semibold : .regular))
        .foregroundStyle(textColor)
      
      Spacer()
      
      // Badge
      if let badgeCount = badgeCount, badgeCount > 0 {
        Text("\(badgeCount)")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.red, in: Capsule())
      }
    }
    .padding(.vertical, 4)
    .background(backgroundStyle)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovering = hovering
      }
    }
  }
  
  private var iconColor: Color {
    if isSelected {
      return .blue
    } else if isHovering {
      return .primary
    } else {
      return .secondary
    }
  }
  
  private var textColor: Color {
    if isSelected {
      return .primary
    } else if isHovering {
      return .primary
    } else {
      return .secondary
    }
  }
  
  private var backgroundStyle: some ShapeStyle {
    if isSelected {
      return Color.blue.opacity(0.1)
    } else if isHovering {
      return Color.primary.opacity(0.05)
    } else {
      return Color.clear
    }
  }
}

// MARK: - Account Switcher View

@available(iOS 26.0, *)
struct AccountSwitcherView: View {
  @Environment(\.dismiss) var dismiss
  @Environment(AccountManager.self) var accountManager
  
  var body: some View {
    NavigationView {
      List {
        ForEach(accountManager.accounts, id: \.id) { account in
          AccountRow(account: account)
        }
      }
      .navigationTitle("Switch Account")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

@available(iOS 26.0, *)
struct AccountRow: View {
  let account: Account
  
  var body: some View {
    HStack(spacing: 12) {
        AsyncImage(url: URL(string: account.avatarUrl ?? "")) { image in
        image
          .resizable()
          .scaledToFill()
      } placeholder: {
        Image(systemName: "person.circle.fill")
          .font(.title2)
      }
      .frame(width: 40, height: 40)
      .clipShape(Circle())
      
      VStack(alignment: .leading, spacing: 2) {
        Text(account.displayName ?? account.handle)
          .font(.headline)
          .foregroundStyle(.primary)
        
        Text("@\(account.handle)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
    }
    .padding(.vertical, 4)
  }
}


// MARK: - Preview

#Preview {
  if #available(iOS 26.0, *) {
    iPadSidebarView()
      .environment(Router<AppTab, RouterDestination, SheetDestination>(initialTab: .feed))
  } else {
    Text("iOS 26.0 required")
  }
}
