import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
struct EnhancedNotificationGridView: View {
  @Environment(\.contentColumnManager) var contentManager
  @Environment(\.glassEffectManager) var glassEffectManager
  @Environment(\.notificationBadgeSystem) var badgeSystem
  @State private var notifications: [NotificationItemData] = []
  @State private var isRefreshing = false
  @State private var selectedFilter: NotificationFilterType = .all
  @Namespace private var notificationNamespace

  var body: some View {
    GlassEffectContainer(spacing: 16.0) {
      VStack(spacing: 0) {
        // Filter header
        notificationFilterHeader

        // Notifications list
        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(groupedNotifications, id: \.id) { group in
              NotificationGroupView(group: group)
                .glassEffectID(group.id, in: notificationNamespace)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
        .refreshable {
          await refreshNotifications()
        }
      }
    }
    .onAppear {
      loadInitialNotifications()
    }
    .onChange(of: selectedFilter) { _, newFilter in
      withAnimation(.smooth(duration: 0.3)) {
        // Filter will be applied in computed property
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .refresh)) { _ in
      Task {
        await refreshNotifications()
      }
    }
  }

  // MARK: - Filter Header

  @ViewBuilder
  private var notificationFilterHeader: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(NotificationFilterType.allCases, id: \.self) { filter in
          NotificationFilterChip(
            filter: filter,
            isSelected: selectedFilter == filter,
            count: getNotificationCount(for: filter)
          ) {
            withAnimation(.smooth(duration: 0.2)) {
              selectedFilter = filter
            }
          }
        }
      }
      .padding(.horizontal, 16)
    }
    .padding(.vertical, 8)
  }

  // MARK: - Computed Properties

  private var filteredNotifications: [NotificationItemData] {
    switch selectedFilter {
    case .all:
      return notifications
    case .mentions:
      return notifications.filter { $0.type == .mention }
    case .likes:
      return notifications.filter { $0.type == .like }
    case .reposts:
      return notifications.filter { $0.type == .repost }
    case .follows:
      return notifications.filter { $0.type == .follow }
    }
  }

  private var groupedNotifications: [NotificationGroup] {
    let grouped = Dictionary(grouping: filteredNotifications) { notification in
      Calendar.current.startOfDay(for: notification.timestamp)
    }

    return grouped.map { date, notifications in
      NotificationGroup(
        id: "group-\(date.timeIntervalSince1970)",
        date: date,
        notifications: notifications.sorted { $0.timestamp > $1.timestamp }
      )
    }.sorted { $0.date > $1.date }
  }

  // MARK: - Data Methods

  private func loadInitialNotifications() {
    notifications = generateMockNotifications()
  }

  private func refreshNotifications() async {
    isRefreshing = true

    // Simulate network request
    try? await Task.sleep(nanoseconds: 800_000_000)  // 800ms

    withAnimation(.smooth(duration: 0.5)) {
      notifications = generateMockNotifications()
    }

    isRefreshing = false
  }

  private func getNotificationCount(for filter: NotificationFilterType) -> Int {
    switch filter {
    case .all:
      return notifications.count
    case .mentions:
      return notifications.filter { $0.type == .mention }.count
    case .likes:
      return notifications.filter { $0.type == .like }.count
    case .reposts:
      return notifications.filter { $0.type == .repost }.count
    case .follows:
      return notifications.filter { $0.type == .follow }.count
    }
  }

  private func generateMockNotifications() -> [NotificationItemData] {
    let types: [NotificationItemData.NotificationType] = [
      .like, .repost, .follow, .mention, .reply,
    ]

    return (1...30).map { index in
      let type = types.randomElement()!
      let timestamp = Date().addingTimeInterval(-Double(index * 1800))  // 30 minutes apart

      return NotificationItemData(
        id: "notification-\(index)",
        type: type,
        actorName: "User \(index)",
        actorHandle: "@user\(index)",
        actorAvatar: nil,
        content: generateNotificationContent(for: type, index: index),
        timestamp: timestamp,
        isRead: index > 5,  // First 5 are unread
        postContent: type != .follow ? "Sample post content for notification \(index)" : nil,
        postMediaUrl: index % 4 == 0 ? "https://picsum.photos/100/100" : nil
      )
    }
  }

  private func generateNotificationContent(
    for type: NotificationItemData.NotificationType, index: Int
  ) -> String {
    switch type {
    case .like:
      return "liked your post"
    case .repost:
      return "reposted your post"
    case .follow:
      return "started following you"
    case .mention:
      return "mentioned you in a post"
    case .reply:
      return "replied to your post"
    }
  }
}

// MARK: - Notification Filter Chip

@available(iPadOS 26.0, *)
struct NotificationFilterChip: View {
  let filter: NotificationFilterType
  let isSelected: Bool
  let count: Int
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 6) {
        Image(systemName: filter.icon)
          .font(.caption)

        Text(filter.title)
          .font(.caption.weight(.medium))

        if count > 0 {
          Text("\(count)")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(filter.color, in: Capsule())
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(isSelected ? filter.color.opacity(0.2) : Color.clear)
      )
      .overlay {
        if isSelected {
          Capsule()
            .stroke(filter.color, lineWidth: 1)
        }
      }
    }
    .buttonStyle(.plain)
    .foregroundStyle(isSelected ? filter.color : .secondary)
  }
}

// MARK: - Notification Group View

@available(iPadOS 26.0, *)
struct NotificationGroupView: View {
  let group: NotificationGroup

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Group header
      HStack {
        Text(group.date, style: .date)
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        Spacer()

        Text("\(group.notifications.count) notifications")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

      // Notifications
      LazyVStack(spacing: 8) {
        ForEach(group.notifications) { notification in
          EnhancedNotificationRow(notification: notification)
        }
      }
    }
  }
}

// MARK: - Enhanced Notification Row

@available(iPadOS 26.0, *)
struct EnhancedNotificationRow: View {
  let notification: NotificationItemData
  @State private var isHovering = false
  @State private var isPencilHovering = false
  @State private var hoverIntensity: CGFloat = 0

  private let rowId = UUID().uuidString

  var body: some View {
    GestureAwareGlassCard(
      cornerRadius: 12,
      isInteractive: true
    ) {
      HStack(spacing: 12) {
        // Notification type icon
        notificationTypeIcon

        // Actor avatar
        AsyncImage(url: notification.actorAvatar) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(.quaternary)
            .overlay {
              Image(systemName: "person.fill")
                .foregroundStyle(.secondary)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())

        // Content
        VStack(alignment: .leading, spacing: 4) {
          // Actor and action
          HStack {
            Text(notification.actorName)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.primary)

            Text(notification.content)
              .font(.subheadline)
              .foregroundStyle(.secondary)

            Spacer()

            Text(notification.timestamp, style: .relative)
              .font(.caption)
              .foregroundStyle(.tertiary)
          }

          // Post content (if applicable)
          if let postContent = notification.postContent {
            Text(postContent)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
              .padding(.top, 2)
          }
        }

        // Post media thumbnail (if applicable)
        if let mediaUrl = notification.postMediaUrl {
          AsyncImage(url: URL(string: mediaUrl)) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            RoundedRectangle(cornerRadius: 6)
              .fill(.quaternary)
          }
          .frame(width: 40, height: 40)
          .clipShape(RoundedRectangle(cornerRadius: 6))
        }

        // Unread indicator
        if !notification.isRead {
          Circle()
            .fill(.blue)
            .frame(width: 8, height: 8)
        }
      }
      .padding(12)
    }
    .opacity(notification.isRead ? 0.8 : 1.0)
    .scaleEffect(scaleEffect)
    .brightness(hoverIntensity * 0.05)
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
    .swipeActions(edge: .trailing) {
      Button("Mark Read") {
        // Handle mark as read
      }
      .tint(.blue)

      Button("Delete") {
        // Handle delete
      }
      .tint(.red)
    }
    .contextMenu {
      notificationContextMenu
    }
  }

  // MARK: - Components

  @ViewBuilder
  private var notificationTypeIcon: some View {
    Image(systemName: notification.type.icon)
      .font(.subheadline)
      .foregroundStyle(notification.type.color)
      .frame(width: 20, height: 20)
      .background(
        Circle()
          .fill(notification.type.color.opacity(0.1))
      )
  }

  @ViewBuilder
  private var notificationContextMenu: some View {
    Button("Mark as Read") {
      // Handle mark as read
    }

    Button("View Profile") {
      // Handle view profile
    }

    if notification.postContent != nil {
      Button("View Post") {
        // Handle view post
      }
    }

    Divider()

    Button("Mute User") {
      // Handle mute
    }

    Button("Delete", role: .destructive) {
      // Handle delete
    }
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
}

// MARK: - Data Models

@available(iPadOS 26.0, *)
struct NotificationGroup: Identifiable {
  let id: String
  let date: Date
  let notifications: [NotificationItemData]
}

@available(iPadOS 26.0, *)
struct NotificationItemData: Identifiable, Hashable {
  let id: String
  let type: NotificationType
  let actorName: String
  let actorHandle: String
  let actorAvatar: URL?
  let content: String
  let timestamp: Date
  let isRead: Bool
  let postContent: String?
  let postMediaUrl: String?

  enum NotificationType: CaseIterable {
    case like, repost, follow, mention, reply

    var icon: String {
      switch self {
      case .like: return "heart.fill"
      case .repost: return "arrow.2.squarepath"
      case .follow: return "person.badge.plus"
      case .mention: return "at"
      case .reply: return "bubble.left"
      }
    }

    var color: Color {
      switch self {
      case .like: return .red
      case .repost: return .green
      case .follow: return .blue
      case .mention: return .orange
      case .reply: return .purple
      }
    }

    var title: String {
      switch self {
      case .like: return "Likes"
      case .repost: return "Reposts"
      case .follow: return "Follows"
      case .mention: return "Mentions"
      case .reply: return "Replies"
      }
    }
  }

  static func == (lhs: NotificationItemData, rhs: NotificationItemData) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - Extensions

@available(iPadOS 26.0, *)
extension NotificationFilterType {
  static var allCases: [NotificationFilterType] {
    [.all, .mentions, .likes, .reposts, .follows]
  }

  var icon: String {
    switch self {
    case .all: return "bell"
    case .mentions: return "at"
    case .likes: return "heart"
    case .reposts: return "arrow.2.squarepath"
    case .follows: return "person.badge.plus"
    }
  }

  var title: String {
    switch self {
    case .all: return "All"
    case .mentions: return "Mentions"
    case .likes: return "Likes"
    case .reposts: return "Reposts"
    case .follows: return "Follows"
    }
  }

  var color: Color {
    switch self {
    case .all: return .blue
    case .mentions: return .orange
    case .likes: return .red
    case .reposts: return .green
    case .follows: return .purple
    }
  }
}
