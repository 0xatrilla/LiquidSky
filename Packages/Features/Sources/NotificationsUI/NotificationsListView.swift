import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct NotificationsListView: View {
  @Environment(BSkyClient.self) var client
  @Environment(AppRouter.self) var router
  @State private var notificationsGroups: [NotificationsGroup] = []
  @State private var cursor: String?
  @State private var isLoading = false
  @State private var error: Error?
  @State private var showingSummary = false
  @State private var summaryText: String?
  @State private var newNotificationsCount = 0
  @State private var previousNotificationsCount = 0

  @StateObject private var simpleSummaryService = SimpleSummaryService()

  public init() {}

  public var body: some View {
    VStack(spacing: 0) {
      if isLoading && notificationsGroups.isEmpty {
        loadingView
      } else if let error = error, (error as? CancellationError) == nil {
        errorView(error: error)
      } else if notificationsGroups.isEmpty {
        emptyStateView
      } else {
        notificationsContentView
      }
    }
    .navigationTitle("Notifications")
    .navigationBarTitleDisplayMode(.large)
    .task {
      await fetchNotifications()
    }
    .refreshable {
      // Prevent multiple simultaneous refreshes
      guard !isLoading else { return }

      // Track previous notification count to detect new ones
      previousNotificationsCount = notificationsGroups.count

      cursor = nil
      await fetchNotifications()

      // Check for new notifications and offer summary if 10+
      newNotificationsCount = notificationsGroups.count - previousNotificationsCount
      if newNotificationsCount >= 10 {
        await offerSummary(for: Array(notificationsGroups.prefix(newNotificationsCount)))
      }
    }
    .sheet(isPresented: $showingSummary) {
      if let summaryText = summaryText {
        SummarySheetView(
          title: "Notifications Summary",
          summary: summaryText,
          itemCount: newNotificationsCount,
          onDismiss: { showingSummary = false }
        )
      }
    }
  }

  // MARK: - Loading View
  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.2)

      Text("Loading notifications...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Error View
  private func errorView(error: Error) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 40))
        .foregroundStyle(.red)

      Text("Something went wrong")
        .font(.headline)
        .foregroundStyle(.primary)

      Text(error.localizedDescription)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      Button(action: {
        Task {
          await fetchNotifications()
        }
      }) {
        Text("Try Again")
          .font(.subheadline)
          .foregroundColor(.white)
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.blue)
          )
      }
      .buttonStyle(.plain)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Empty State View
  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemName: "checkmark.circle")
        .font(.system(size: 40))
        .foregroundStyle(.green)

      Text("All caught up!")
        .font(.headline)
        .foregroundStyle(.primary)

      Text("You're up to date with all your notifications.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Notifications Content View
  private var notificationsContentView: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        // Simple notifications list
        ForEach(notificationsGroups) { group in
          EnhancedNotificationRow(group: group, router: router)
        }

        // Simple load more button
        if cursor != nil {
          Button(action: {
            Task {
              await fetchNotifications()
            }
          }) {
            HStack {
              Text("Load More")
                .font(.subheadline)
                .foregroundStyle(.blue)
              Image(systemName: "arrow.down")
                .font(.caption)
                .foregroundStyle(.blue)
            }
            .padding()
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private func fetchNotifications() async {
    guard !isLoading else { return }

    isLoading = true
    error = nil

    do {
      if let cursor {
        let response = try await client.protoClient.listNotifications(
          isPriority: false, cursor: cursor)
        self.notificationsGroups.append(
          contentsOf: await NotificationsGroup.groupNotifications(
            client: client, response.notifications)
        )
        self.cursor = response.cursor
      } else {
        let response = try await client.protoClient.listNotifications(isPriority: false)
        self.notificationsGroups = await NotificationsGroup.groupNotifications(
          client: client, response.notifications)
        self.cursor = response.cursor
      }

      // Local alert when Bluesky notifications arrive (optional per preferences)
      if NotificationPreferences.shared.notifyOnBlueskyNotifications,
        !notificationsGroups.isEmpty
      {
        let content = UNMutableNotificationContent()
        content.title = "New Notifications"
        content.body = "You have new activity on Horizon."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(
          identifier: UUID().uuidString, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(req)
      }
    } catch {
      // Handle cancellation gracefully
      if (error as? CancellationError) != nil {
        // Task was cancelled, don't show error
        isLoading = false
        return
      }
      #if DEBUG
        print("Failed to fetch notifications: \(error)")
      #endif
      self.error = error
    }

    isLoading = false
  }

  private func offerSummary(for newNotifications: [NotificationsGroup]) async {
    let summary = await simpleSummaryService.summarizeNewNotifications(newNotifications.count)
    summaryText = summary
    showingSummary = true
  }
}

// MARK: - Notification Row

public struct NotificationRow: View {
  let group: NotificationsGroup

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      switch group.type {
      case .reply:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "replied to your post"
        )
      case .follow:
        GroupedNotificationRow(group: group) { count in
          let firstUser =
            group.notifications.first?.author.displayName ?? group.notifications.first?.author
            .actorHandle ?? "Someone"
          return count == 1
            ? "\(firstUser) followed you" : "\(firstUser) and \(count - 1) others followed you"
        }
      case .like:
        GroupedNotificationRow(group: group) { count in
          let firstUser =
            group.notifications.first?.author.displayName ?? group.notifications.first?.author
            .actorHandle ?? "Someone"
          return count == 1
            ? "\(firstUser) liked your post"
            : "\(firstUser) and \(count - 1) others liked your post"
        }
      case .repost:
        GroupedNotificationRow(group: group) { count in
          let firstUser =
            group.notifications.first?.author.displayName ?? group.notifications.first?.author
            .actorHandle ?? "Someone"
          return count == 1
            ? "\(firstUser) reposted your post"
            : "\(firstUser) and \(count - 1) others reposted your post"
        }
      case .mention:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "mentioned you"
        )
      case .quote:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "quoted your post"
        )
      case .likeViaRepost:
        GroupedNotificationRow(group: group) { count in
          let firstUser =
            group.notifications.first?.author.displayName ?? group.notifications.first?.author
            .actorHandle ?? "Someone"
          return count == 1
            ? "\(firstUser) liked your post via repost"
            : "\(firstUser) and \(count - 1) others liked your post via repost"
        }
      case .repostViaRepost:
        GroupedNotificationRow(group: group) { count in
          let firstUser =
            group.notifications.first?.author.displayName ?? group.notifications.first?.author
            .actorHandle ?? "Someone"
          return count == 1
            ? "\(firstUser) reposted a repost of your post"
            : "\(firstUser) and \(count - 1) others reposted a repost of your post"
        }
      case .starterpackjoined:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "joined the starter pack"
        )
      case .verified:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "verified their account"
        )
      case .unverified:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "unverified their account"
        )
      case .unknown:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "interacted with your post"
        )
      @unknown default:
        SingleNotificationRow(
          notification: group.notifications[0],
          postItem: group.postItem,
          actionText: "interacted with your post"
        )
      }
    }
  }
}
