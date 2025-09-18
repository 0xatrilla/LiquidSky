import Combine
import Foundation
import SwiftUI

@available(iOS 18.0, *)
@Observable
class NotificationBadgeSystem {
  var badges: [String: BadgeInfo] = [:]
  var totalUnreadCount: Int = 0
  var isAnimating: Bool = false

  private var cancellables = Set<AnyCancellable>()
  // private let badgeStore = NotificationBadgeStore.shared // NotificationBadgeStore not available

  init() {
    setupBadgeObservation()
    loadInitialBadges()
  }

  private func setupBadgeObservation() {
    // Observe notification badge store changes
    NotificationCenter.default.publisher(for: .notificationBadgeUpdated)
      .sink { [weak self] notification in
        self?.handleBadgeUpdate(notification)
      }
      .store(in: &cancellables)
  }

  private func loadInitialBadges() {
    // Initialize with current badge counts
    // Note: badgeStore is commented out, using placeholder value for now
    updateBadge(for: "notifications", count: 0, type: .notification)

    // Mock additional badge types for demonstration
    updateBadge(for: "messages", count: 0, type: .message)
    updateBadge(for: "mentions", count: 0, type: .mention)

    calculateTotalCount()
  }

  func updateBadge(for identifier: String, count: Int, type: BadgeType, animated: Bool = true) {
    let oldCount = badges[identifier]?.count ?? 0

    if animated && count != oldCount {
      withAnimation(.smooth(duration: 0.3)) {
        badges[identifier] = BadgeInfo(
          count: count,
          type: type,
          lastUpdated: Date(),
          isNew: count > oldCount
        )
        calculateTotalCount()
      }

      // Reset "new" flag after animation
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if var badge = self.badges[identifier] {
          badge.isNew = false
          self.badges[identifier] = badge
        }
      }
    } else {
      badges[identifier] = BadgeInfo(
        count: count,
        type: type,
        lastUpdated: Date(),
        isNew: false
      )
      calculateTotalCount()
    }

    // Provide haptic feedback for new notifications
    if count > oldCount && count > 0 {
      let impactFeedback = UIImpactFeedbackGenerator(style: .light)
      impactFeedback.impactOccurred()
    }
  }

  func clearBadge(for identifier: String) {
    updateBadge(for: identifier, count: 0, type: badges[identifier]?.type ?? .notification)
  }

  func getBadgeCount(for identifier: String) -> Int {
    badges[identifier]?.count ?? 0
  }

  func getBadgeInfo(for identifier: String) -> BadgeInfo? {
    badges[identifier]
  }

  private func calculateTotalCount() {
    totalUnreadCount = badges.values.reduce(0) { $0 + $1.count }
  }

  private func handleBadgeUpdate(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
      let identifier = userInfo["identifier"] as? String,
      let count = userInfo["count"] as? Int,
      let typeRaw = userInfo["type"] as? String,
      let type = BadgeType(rawValue: typeRaw)
    else { return }

    updateBadge(for: identifier, count: count, type: type)
  }
}

@available(iOS 18.0, *)
struct BadgeInfo {
  let count: Int
  let type: BadgeType
  let lastUpdated: Date
  var isNew: Bool

  var shouldShow: Bool {
    count > 0
  }

  var displayText: String {
    if count > 99 {
      return "99+"
    } else {
      return "\(count)"
    }
  }
}

@available(iOS 18.0, *)
enum BadgeType: String, CaseIterable {
  case notification = "notification"
  case message = "message"
  case mention = "mention"
  case like = "like"
  case repost = "repost"
  case follow = "follow"

  var color: Color {
    switch self {
    case .notification: return .red
    case .message: return .blue
    case .mention: return .purple
    case .like: return .pink
    case .repost: return .green
    case .follow: return .orange
    }
  }

  var icon: String {
    switch self {
    case .notification: return "bell.fill"
    case .message: return "message.fill"
    case .mention: return "at"
    case .like: return "heart.fill"
    case .repost: return "arrow.2.squarepath"
    case .follow: return "person.badge.plus"
    }
  }
}

// MARK: - Enhanced Badge View

@available(iOS 18.0, *)
struct EnhancedBadgeView: View {
  let badgeInfo: BadgeInfo?
  let style: BadgeStyle
  let size: BadgeSize

  enum BadgeStyle {
    case standard
    case glass
    case minimal
  }

  enum BadgeSize {
    case small
    case medium
    case large

    var fontSize: Font {
      switch self {
      case .small: return .caption2
      case .medium: return .caption
      case .large: return .subheadline
      }
    }

    var padding: EdgeInsets {
      switch self {
      case .small: return EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
      case .medium: return EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6)
      case .large: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
      }
    }
  }

  init(badgeInfo: BadgeInfo?, style: BadgeStyle = .glass, size: BadgeSize = .medium) {
    self.badgeInfo = badgeInfo
    self.style = style
    self.size = size
  }

  var body: some View {
    Group {
      if let badgeInfo = badgeInfo, badgeInfo.shouldShow {
        badgeContent(badgeInfo)
      }
    }
  }

  @ViewBuilder
  private func badgeContent(_ badgeInfo: BadgeInfo) -> some View {
    Text(badgeInfo.displayText)
      .font(size.fontSize.weight(.semibold))
      .foregroundStyle(.white)
      .padding(size.padding)
      .background(backgroundView(for: badgeInfo))
      .scaleEffect(badgeInfo.isNew ? 1.2 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.6), value: badgeInfo.isNew)
      .animation(.smooth(duration: 0.2), value: badgeInfo.count)
  }

  @ViewBuilder
  private func backgroundView(for badgeInfo: BadgeInfo) -> some View {
    switch style {
    case .standard:
      Capsule()
        .fill(badgeInfo.type.color)
    case .glass:
      Capsule()
        .fill(badgeInfo.type.color)
        .background(badgeInfo.type.color.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 12).stroke(badgeInfo.type.color.opacity(0.3), lineWidth: 1)
        )
    case .minimal:
      Capsule()
        .fill(badgeInfo.type.color.opacity(0.8))
    }
  }
}

// MARK: - Animated Badge View

@available(iOS 18.0, *)
struct AnimatedBadgeView: View {
  let badgeInfo: BadgeInfo?
  let showIcon: Bool

  @State private var isAnimating = false
  @State private var pulseScale: CGFloat = 1.0

  init(badgeInfo: BadgeInfo?, showIcon: Bool = false) {
    self.badgeInfo = badgeInfo
    self.showIcon = showIcon
  }

  var body: some View {
    Group {
      if let badgeInfo = badgeInfo, badgeInfo.shouldShow {
        HStack(spacing: 4) {
          if showIcon {
            Image(systemName: badgeInfo.type.icon)
              .font(.caption2)
              .foregroundStyle(.white)
          }

          Text(badgeInfo.displayText)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
        }
        .padding(.horizontal, showIcon ? 6 : 4)
        .padding(.vertical, 2)
        .background(
          Capsule()
            .fill(badgeInfo.type.color)
            .background(badgeInfo.type.color.opacity(0.1))
            .overlay(
              RoundedRectangle(cornerRadius: 12).stroke(
                badgeInfo.type.color.opacity(0.3), lineWidth: 1))
        )
        .scaleEffect(pulseScale)
        .onAppear {
          if badgeInfo.isNew {
            startPulseAnimation()
          }
        }
        .onChange(of: badgeInfo.count) { oldValue, newValue in
          if newValue > oldValue {
            startPulseAnimation()
          }
        }
      }
    }
  }

  private func startPulseAnimation() {
    withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
      pulseScale = 1.15
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
      withAnimation(.smooth(duration: 0.3)) {
        pulseScale = 1.0
      }
    }
  }
}

// MARK: - Badge Summary View

@available(iOS 18.0, *)
struct BadgeSummaryView: View {
  @Environment(\.notificationBadgeSystem) var badgeSystem
  let maxVisible: Int

  init(maxVisible: Int = 3) {
    self.maxVisible = maxVisible
  }

  var body: some View {
    HStack(spacing: 4) {
      let visibleBadges = Array(
        badgeSystem.badges.values
          .filter { $0.shouldShow }
          .sorted { $0.lastUpdated > $1.lastUpdated }
          .prefix(maxVisible))

      ForEach(visibleBadges, id: \.type) { badgeInfo in
        AnimatedBadgeView(badgeInfo: badgeInfo, showIcon: true)
      }

      if badgeSystem.badges.values.filter({ $0.shouldShow }).count > maxVisible {
        Text("+\(badgeSystem.badges.values.filter({ $0.shouldShow }).count - maxVisible)")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 4)
          .padding(.vertical, 2)
          .background(
            Capsule()
              .fill(.secondary)
              .background(.secondary.opacity(0.1))
              .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.3), lineWidth: 1))
          )
      }
    }
  }
}

// MARK: - Badge Modifier

@available(iOS 18.0, *)
struct BadgeModifier: ViewModifier {
  let badgeInfo: BadgeInfo?
  let alignment: Alignment
  let offset: CGSize
  let style: EnhancedBadgeView.BadgeStyle

  init(
    badgeInfo: BadgeInfo?,
    alignment: Alignment = .topTrailing,
    offset: CGSize = CGSize(width: 8, height: -8),
    style: EnhancedBadgeView.BadgeStyle = .glass
  ) {
    self.badgeInfo = badgeInfo
    self.alignment = alignment
    self.offset = offset
    self.style = style
  }

  func body(content: Content) -> some View {
    content
      .overlay(alignment: alignment) {
        EnhancedBadgeView(badgeInfo: badgeInfo, style: style, size: .small)
          .offset(offset)
      }
  }
}

@available(iOS 18.0, *)
extension View {
  func badge(
    _ badgeInfo: BadgeInfo?, alignment: Alignment = .topTrailing,
    offset: CGSize = CGSize(width: 8, height: -8), style: EnhancedBadgeView.BadgeStyle = .glass
  ) -> some View {
    self.modifier(
      BadgeModifier(badgeInfo: badgeInfo, alignment: alignment, offset: offset, style: style))
  }
}

// MARK: - Badge Animation Coordinator

@available(iOS 18.0, *)
@Observable
class BadgeAnimationCoordinator {
  var activeAnimations: Set<String> = []

  func startAnimation(for identifier: String) {
    activeAnimations.insert(identifier)

    // Remove after animation duration
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      self.activeAnimations.remove(identifier)
    }
  }

  func isAnimating(_ identifier: String) -> Bool {
    activeAnimations.contains(identifier)
  }
}

// MARK: - Notification Extensions

extension Notification.Name {
  static let notificationBadgeUpdated = Notification.Name("notificationBadgeUpdated")
}

// MARK: - Environment Keys

@available(iOS 18.0, *)
struct NotificationBadgeSystemKey: EnvironmentKey {
  static let defaultValue = NotificationBadgeSystem()
}

@available(iOS 18.0, *)
extension EnvironmentValues {
  var notificationBadgeSystem: NotificationBadgeSystem {
    get { self[NotificationBadgeSystemKey.self] }
    set { self[NotificationBadgeSystemKey.self] = newValue }
  }
}

// MARK: - Badge Testing View

@available(iOS 18.0, *)
struct BadgeTestingView: View {
  @Environment(\.notificationBadgeSystem) var badgeSystem
  @State private var testCount = 0

  var body: some View {
    VStack(spacing: 20) {
      Text("Badge System Testing")
        .font(.title2.weight(.semibold))

      HStack(spacing: 16) {
        ForEach(BadgeType.allCases, id: \.self) { type in
          VStack {
            Circle()
              .fill(type.color.opacity(0.2))
              .frame(width: 40, height: 40)
              .overlay {
                Image(systemName: type.icon)
                  .foregroundStyle(type.color)
              }
              .badge(badgeSystem.getBadgeInfo(for: type.rawValue))

            Text(type.rawValue.capitalized)
              .font(.caption)
          }
          .onTapGesture {
            let currentCount = badgeSystem.getBadgeCount(for: type.rawValue)
            badgeSystem.updateBadge(for: type.rawValue, count: currentCount + 1, type: type)
          }
        }
      }

      Button("Clear All Badges") {
        for type in BadgeType.allCases {
          badgeSystem.clearBadge(for: type.rawValue)
        }
      }
      .buttonStyle(.borderedProminent)

      BadgeSummaryView()
    }
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
  }
}

#Preview {
  if #available(iOS 26.0, *) {
    BadgeTestingView()
      .environment(NotificationBadgeSystem())
  } else {
    Text("iOS 26.0 required")
  }
}
