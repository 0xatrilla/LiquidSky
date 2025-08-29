import AppRouter
import AuthUI
import Client
import ComposerUI
import DesignSystem
import Destinations
import FeedUI
import MediaUI
import Models
import NotificationsUI
import ProfileUI
import SettingsUI
import SwiftUI
import User

struct AppTabView: View {
  @Environment(AppRouter.self) var router
  @Environment(BSkyClient.self) var client
  @State private var selectedTab: AppTab = .feed

  public var body: some View {
    if UIDevice.current.userInterfaceIdiom == .pad {
      // iPad-specific layout with sidebar and detail view
      iPadLayoutView(router: router, selectedTab: $selectedTab)
    } else {
      // iPhone layout (existing TabView)
      iPhoneLayoutView(router: router, selectedTab: $selectedTab)
    }
  }
}

// MARK: - iPhone Layout View
private struct iPhoneLayoutView: View {
  let router: AppRouter
  @Binding var selectedTab: AppTab
  @Environment(BSkyClient.self) var client

  public var body: some View {
    TabView(
      selection: Binding(
        get: { router.selectedTab },
        set: { router.selectedTab = $0 }
      )
    ) {
      // Feed
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
            .withAppDestinations()
        }
        .onAppear { selectedTab = .feed }
      } label: {
        Label("Feed", systemImage: "square.stack")
      }

      // Notifications
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
            .withAppDestinations()
        }
        .onAppear { selectedTab = .notification }
      } label: {
        Label("Notifications", systemImage: "bell")
      }

      // Profile
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
            .withAppDestinations()
        }
        .onAppear { selectedTab = .profile }
      } label: {
        Label("Profile", systemImage: "person")
      }

      // Settings
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
            .withAppDestinations()
        }
        .onAppear { selectedTab = .settings }
      } label: {
        Label("Settings", systemImage: "gearshape")
      }

      // Native search tab in tab bar
      Tab(value: AppTab.compose, role: .search) {
        NavigationStack(
          path: Binding(
            get: { router[.compose] },
            set: { router[.compose] = $0 }
          )
        ) {
          SimpleSearchView(client: client)
            .withAppDestinations()
        }
        .onAppear { selectedTab = .compose }
      } label: {
        Label("Search", systemImage: "magnifyingglass")
      }
    }
    .tint(.themePrimary)
  }
}

// MARK: - iPad Layout with NavigationSplitView
private struct iPadLayoutView: View {
  let router: AppRouter
  @Binding var selectedTab: AppTab
  @State private var showingComposer = false
  @State private var composerMode: ComposerMode = .newPost

  var body: some View {
    NavigationSplitView {
      // Sidebar - Discover Feed
      DiscoverSidebarView(
        selectedTab: $selectedTab, showingComposer: $showingComposer, composerMode: $composerMode)
    } content: {
      // Content area - Main content based on selected tab
      ContentView(selectedTab: selectedTab, router: router)
    } detail: {
      // Detail area for post content
      DetailView()
    }
    .navigationSplitViewStyle(.balanced)
    .sheet(isPresented: $showingComposer) {
      ComposerView(mode: composerMode)
    }
  }
}

// MARK: - Content View
private struct ContentView: View {
  let selectedTab: AppTab
  let router: AppRouter
  @Environment(BSkyClient.self) var client

  var body: some View {
    Group {
      switch selectedTab {
      case .feed:
        NavigationStack(
          path: Binding(
            get: { router[.feed] },
            set: { router[.feed] = $0 }
          )
        ) {
          FeedsListView()
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
        }
      case .notification:
        NavigationStack(
          path: Binding(
            get: { router[.notification] },
            set: { router[.notification] = $0 }
          )
        ) {
          NotificationsListView()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
        }
      case .profile:
        NavigationStack(
          path: Binding(
            get: { router[.profile] },
            set: { router[.profile] = $0 }
          )
        ) {
          CurrentUserView()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
        }
      case .settings:
        NavigationStack(
          path: Binding(
            get: { router[.settings] },
            set: { router[.settings] = $0 }
          )
        ) {
          SettingsView()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
        }
      case .compose:
        NavigationStack(
          path: Binding(
            get: { router[.compose] },
            set: { router[.compose] = $0 }
          )
        ) {
          SimpleSearchView(client: client)
            .withAppDestinations()
        }
      case .discover:
        NavigationStack(
          path: Binding(
            get: { router[.discover] },
            set: { router[.discover] = $0 }
          )
        ) {
          FeedsListView()
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .withAppDestinations()
        }
      }
    }
    .navigationTitle(selectedTab.displayName)
  }
}

// MARK: - Detail View
private struct DetailView: View {
  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "rectangle.on.rectangle")
        .font(.system(size: 80))
        .foregroundColor(.secondary)

      Text("Select a post to view details")
        .font(.title)
        .foregroundColor(.secondary)

      Text(
        "This area will show post details, replies, and related content when you select a post from the feed."
      )
      .font(.body)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 40)

      VStack(spacing: 12) {
        Text("iPad Features:")
          .font(.title2)
          .foregroundColor(.primary)

        VStack(alignment: .leading, spacing: 8) {
          FeatureRow(
            icon: "sidebar.left", title: "Sidebar Navigation",
            description: "Quick access to all sections")
          FeatureRow(
            icon: "keyboard", title: "Keyboard Shortcuts",
            description: "Navigate with ⌘+number keys")
          FeatureRow(
            icon: "trackpad", title: "Trackpad Support",
            description: "Enhanced gestures and navigation")
          FeatureRow(
            icon: "menubar", title: "Menu Bar", description: "Access common actions from the top")
          FeatureRow(
            icon: "rectangle.split.3x3", title: "Multi-column Layout",
            description: "Optimal use of large screen")
        }
        .padding(.horizontal, 20)
      }
      .padding(.top, 20)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
  }
}

// MARK: - Feature Row Component
private struct FeatureRow: View {
  let icon: String
  let title: String
  let description: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.blue)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.headline)
        Text(description)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
  }
}

// MARK: - Discover Sidebar View (Native Liquid Glass)
private struct DiscoverSidebarView: View {
  @Binding var selectedTab: AppTab
  @Binding var showingComposer: Bool
  @Binding var composerMode: ComposerMode
  @Environment(CurrentUser.self) var currentUser
  @Environment(BSkyClient.self) var client

  var body: some View {
    VStack(spacing: 0) {
      // Header with app branding
      VStack(spacing: 12) {
        HStack {
          Image(systemName: "cloud.fill")
            .font(.title2)
            .foregroundColor(.blue)

          Text("LiquidSky")
            .font(.title2)
            .fontWeight(.bold)

          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)

        // Quick Actions
        HStack(spacing: 12) {
          Button("New Post") {
            composerMode = .newPost
            showingComposer = true
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)

          Button("Search") {
            selectedTab = .compose
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }
        .padding(.horizontal, 16)
      }
      .padding(.bottom, 16)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(.ultraThinMaterial)
          .padding(.horizontal, 8)
      )

      // Navigation Links
      VStack(spacing: 2) {
        Button(action: { selectedTab = .feed }) {
          SidebarRow(icon: "house.fill", title: "Home", isSelected: selectedTab == .feed)
        }
        .buttonStyle(.plain)

        Button(action: { selectedTab = .discover }) {
          SidebarRow(icon: "safari", title: "Discover", isSelected: selectedTab == .discover)
        }
        .buttonStyle(.plain)

        Button(action: { selectedTab = .notification }) {
          SidebarRow(icon: "bell", title: "Notifications", isSelected: selectedTab == .notification)
        }
        .buttonStyle(.plain)

        Button(action: { selectedTab = .profile }) {
          SidebarRow(icon: "person", title: "Profile", isSelected: selectedTab == .profile)
        }
        .buttonStyle(.plain)

        Button(action: { selectedTab = .settings }) {
          SidebarRow(icon: "gearshape", title: "Settings", isSelected: selectedTab == .settings)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 8)

      Spacer()

      // Account Section at Bottom
      VStack(spacing: 12) {
        Divider()
          .padding(.horizontal, 16)

        HStack(spacing: 12) {
          AsyncImage(url: currentUser.profile?.avatarImageURL) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .scaledToFit()
            default:
              Circle()
                .fill(.gray.opacity(0.3))
            }
          }
          .frame(width: 32, height: 32)
          .clipShape(Circle())

          VStack(alignment: .leading, spacing: 2) {
            Text(currentUser.profile?.displayName ?? "User")
              .font(.subheadline)
              .fontWeight(.medium)
              .lineLimit(1)
            Text("@\(currentUser.profile?.actorHandle ?? "user")")
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(1)
          }

          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
      }
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(.ultraThinMaterial)
          .padding(.horizontal, 8)
      )
    }
    .navigationTitle("")
    .navigationBarHidden(true)
    .background(Color(.systemGroupedBackground))
  }
}

// MARK: - Sidebar Row Component
private struct SidebarRow: View {
  let icon: String
  let title: String
  let isSelected: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(isSelected ? .blue : .primary)
        .frame(width: 20)

      Text(title)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(isSelected ? .blue : .primary)

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
    )
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
    case .notification: return "Notifications"
    case .profile: return "Profile"
    case .settings: return "Settings"
    case .compose: return "Search"
    case .discover: return "Discover"
    }
  }
}
