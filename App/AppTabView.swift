import AppRouter
import AuthUI
// TODO: Re-enable ChatUI import when chat functionality is ready
// import ChatUI
import Client
import ComposerUI
import DesignSystem
import Destinations
import FeedUI
import MediaUI
import Models
import NotificationsUI
import PostUI
import ProfileUI
import SettingsUI
import SwiftUI
import User

@MainActor
struct AppTabView: View {
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @State private var settingsService = SettingsService.shared
  @State private var selectedTab: AppTab = .feed
  @State private var showingSummary = false
  @State private var summaryText = ""
  @State private var isGeneratingSummary = false
  @State private var badgeStore = NotificationBadgeStore.shared

  private var badgeCount: Int? {
    badgeStore.unreadCount > 0 ? badgeStore.unreadCount : nil
  }

  public var body: some View {
    TabView(selection: $selectedTab) {
      ForEach(
        settingsService.tabBarTabsRaw + settingsService.pinnedFeedURIs.map { "feed:\($0)" },
        id: \.self
      ) { key in
        if let tab = AppTab(rawValue: key) {
          switch tab {
          case .feed:
            Tab(value: AppTab.feed) {
              NavigationStack(
                path: Binding(
                  get: { router[.feed] },
                  set: { router[.feed] = $0 }
                )
              ) {
                FeedsListView()
                  .navigationTitle("Discover")
                  .navigationBarTitleDisplayMode(.large)
                  .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                      Button(action: {
                        Task { await generateGlobalSummary() }
                      }) {
                        if isGeneratingSummary {
                          ProgressView().scaleEffect(0.8).foregroundColor(.themeSecondary)
                        } else {
                          Image(systemName: "sparkles").foregroundColor(.themeSecondary)
                        }
                      }
                      .disabled(isGeneratingSummary)

                      Button(action: { router.presentedSheet = .composer(mode: .newPost) }) {
                        Image(systemName: "square.and.pencil").foregroundColor(.themePrimary)
                      }
                    }
                  }
                  .withAppDestinations()
                  .environment(\.currentTab, .feed)
              }
            } label: {
              Label("Feed", systemImage: "square.stack")
            }

          // TODO: Re-enable Messages tab when chat functionality is ready
          /*
          case .messages:
            Tab(value: AppTab.messages) {
              NavigationStack(
                path: Binding(
                  get: { router[.messages] },
                  set: { router[.messages] = $0 }
                )
              ) {
                ConversationsView()
                  .navigationBarTitleDisplayMode(.large)
                  .onReceive(
                    NotificationCenter.default.publisher(for: .init("openSendMessageFromProfile"))
                  ) { note in
                    if let userInfo = note.userInfo,
                      let did = userInfo["did"] as? String,
                      let handle = userInfo["handle"] as? String,
                      let displayName = userInfo["displayName"] as? String
                    {
                      router.selectedTab = .messages
                      Task { @MainActor in
                        // Route to Messages tab and trigger start sheet pre-filled via global notif
                        NotificationCenter.default.post(
                          name: .init("startConversationWithDID"), object: nil,
                          userInfo: ["did": did, "handle": handle, "displayName": displayName])
                      }
                    }
                  }
              }
            } label: {
              Label("Messages", systemImage: "bubble.left.and.bubble.right")
            }
          */

          case .notification:
            Tab(value: AppTab.notification) {
              NavigationStack(
                path: Binding(
                  get: { router[.notification] },
                  set: { router[.notification] = $0 }
                )
              ) {
                NotificationsListView()
                  .navigationTitle("Notifications")
                  .navigationBarTitleDisplayMode(.large)
                  .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                      Button(action: { router.presentedSheet = .composer(mode: .newPost) }) {
                        Image(systemName: "square.and.pencil").foregroundColor(.themePrimary)
                      }
                    }
                  }
                  .withAppDestinations()
                  .environment(\.currentTab, .notification)
              }
            } label: {
              Label("Notifications", systemImage: "bell")
                .badge(badgeStore.unreadCount)
            }

          case .profile:
            Tab(value: AppTab.profile) {
              NavigationStack(
                path: Binding(
                  get: { router[.profile] },
                  set: { router[.profile] = $0 }
                )
              ) {
                CurrentUserView()
                  .navigationTitle("Profile")
                  .navigationBarTitleDisplayMode(.large)
                  .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                      Button(action: { router.presentedSheet = .composer(mode: .newPost) }) {
                        Image(systemName: "square.and.pencil").foregroundColor(.themePrimary)
                      }
                    }
                  }
                  .withAppDestinations()
                  .environment(\.currentTab, .profile)
              }
            } label: {
              Label("Profile", systemImage: "person")
            }

          case .settings:
            Tab(value: AppTab.settings) {
              NavigationStack(
                path: Binding(
                  get: { router[.settings] },
                  set: { router[.settings] = $0 }
                )
              ) {
                SettingsView()
                  .navigationTitle("Settings")
                  .navigationBarTitleDisplayMode(.large)
                  .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                      Button(action: { router.presentedSheet = .composer(mode: .newPost) }) {
                        Image(systemName: "square.and.pencil").foregroundColor(.themePrimary)
                      }
                    }
                  }
                  .withAppDestinations()
                  .environment(\.currentTab, .settings)
              }
            } label: {
              Label("Settings", systemImage: "gearshape")
            }

          case .compose:
            Tab(value: AppTab.compose, role: .search) {
              NavigationStack(
                path: Binding(
                  get: { router[.compose] },
                  set: { router[.compose] = $0 }
                )
              ) {
                EnhancedSearchView(client: client)
                  .navigationTitle("Search")
                  .navigationBarTitleDisplayMode(.large)
                  .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                      Button(action: { router.presentedSheet = .composer(mode: .newPost) }) {
                        Image(systemName: "square.and.pencil").foregroundColor(.themePrimary)
                      }
                    }
                  }
                  .withAppDestinations()
                  .environment(\.currentTab, .compose)
              }
              .onAppear { selectedTab = .compose }
            } label: {
              Label("Search", systemImage: "magnifyingglass")
            }
          }
          // Close switch(tab) scope before handling pinned feed keys
        } else if key.hasPrefix("feed:") {
          let feedURI = String(key.dropFirst(5))
          Tab(value: AppTab.feed) {
            NavigationStack(
              path: Binding(
                get: { router[.feed] },
                set: { router[.feed] = $0 }
              )
            ) {
              let item = FeedItem(
                uri: feedURI,
                displayName: settingsService.pinnedFeedNames[feedURI] ?? "Feed",
                description: nil,
                avatarImageURL: nil,
                creatorHandle: "",
                likesCount: 0,
                liked: false
              )
              PostsFeedView(feedItem: item)
                .withAppDestinations()
                .environment(\.currentTab, .feed)
            }
          } label: {
            Label(
              settingsService.pinnedFeedNames[feedURI] ?? "Feed",
              systemImage: "dot.radiowaves.left.and.right")
          }
        }
      }
    }
    .tint(.themePrimary)
    .sheet(isPresented: $showingSummary) {
      SummarySheetView(
        title: "Feed Summary",
        summary: summaryText,
        itemCount: 0,
        onDismiss: { showingSummary = false }
      )
    }
  }

  // MARK: - Summary Generation

  private func generateGlobalSummary() async {
    isGeneratingSummary = true

    do {
      // Use the existing FeedSummaryService to generate a summary
      let summary = await FeedSummaryService.shared.summarizeFeedPosts([], feedName: "your feeds")
      summaryText = summary
      showingSummary = true
    } catch {
      // Fallback to a simple summary if the service fails
      summaryText = "Unable to generate AI summary at this time. Please try again later."
      showingSummary = true
    }

    isGeneratingSummary = false
  }
}

extension AppTabView {
  fileprivate var currentTabs: [AppTab] {
    settingsService.tabBarTabsRaw.compactMap { AppTab(rawValue: $0) }
  }
}

#Preview {
  AppTabView()
    .environment(AppRouter(initialTab: .feed))
}

// MARK: - Extensions
extension AppTab {
  var displayName: String {
    switch self {
    case .feed: return "Feed"
    // TODO: Re-enable messages case when chat functionality is ready
    // case .messages: return "Messages"
    case .notification: return "Notifications"
    case .profile: return "Profile"
    case .settings: return "Settings"
    case .compose: return "Search"
    }
  }
}
