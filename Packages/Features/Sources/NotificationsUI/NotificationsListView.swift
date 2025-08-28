import Client
import DesignSystem
import Models
import SwiftUI

public struct NotificationsListView: View {
  @Environment(BSkyClient.self) var client
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
        VStack(spacing: 16) {
          ProgressView()
            .scaleEffect(1.2)
          Text("Loading notifications...")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let error = error, (error as? CancellationError) == nil {
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 48))
            .foregroundStyle(.red)

          Text("Error Loading Notifications")
            .font(.title2)
            .fontWeight(.semibold)

          Text(error.localizedDescription)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

          Button("Try Again") {
            Task {
              await fetchNotifications()
            }
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if notificationsGroups.isEmpty {
        VStack(spacing: 16) {
          Image(systemName: "bell.slash")
            .font(.system(size: 48))
            .foregroundStyle(.secondary)

          Text("No Notifications")
            .font(.title2)
            .fontWeight(.semibold)

          Text("You're all caught up!")
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack(spacing: 16) {
            // Show summary button if there are 10+ new notifications
            if newNotificationsCount >= 10 {
              SummaryButtonView(itemCount: newNotificationsCount) {
                showingSummary = true
              }
              .padding(.horizontal, 16)
            }

            ForEach(notificationsGroups) { group in
              NotificationRow(group: group)
            }

            if let cursor = cursor {
              Button("Load More") {
                Task {
                  await fetchNotifications()
                }
              }
              .buttonStyle(.bordered)
              .padding()
            }
          }
          .padding(.vertical, 16)
        }
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
          count == 1 ? " followed you" : " and \(count - 1) others followed you"
        }
      case .like:
        GroupedNotificationRow(group: group) { count in
          count == 1 ? " liked your post" : " and \(count - 1) others liked your post"
        }
      case .repost:
        GroupedNotificationRow(group: group) { count in
          count == 1 ? " reposted your post" : " and \(count - 1) others reposted your post"
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
          count == 1
            ? " liked your post via repost" : " and \(count - 1) others liked your post via repost"
        }
      case .repostViaRepost:
        GroupedNotificationRow(group: group) { count in
          count == 1
            ? " reposted your post via repost"
            : " and \(count - 1) others reposted your post via repost"
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
