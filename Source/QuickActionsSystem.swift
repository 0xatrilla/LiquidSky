import Foundation
import SwiftUI

@available(iOS 18.0, *)
@Observable
class QuickActionsSystem {
  var actions: [QuickAction] = []
  var recentActions: [QuickAction] = []
  var favoriteActions: [QuickAction] = []
  var isPerformingAction = false
  var currentActionProgress: Double = 0.0

  init() {
    setupDefaultActions()
    loadUserPreferences()
  }

  private func setupDefaultActions() {
    actions = [
      // Primary Actions
      QuickAction(
        id: "new-post",
        title: "New Post",
        subtitle: "Create a new post",
        systemImage: "square.and.pencil",
        category: .primary,
        shortcut: "⌘N",
        action: { NotificationCenter.default.post(name: .newPost, object: nil) }
      ),

      QuickAction(
        id: "ai-summary",
        title: "AI Summary",
        subtitle: "Generate feed summary",
        systemImage: "sparkles",
        category: .primary,
        shortcut: "⌘S",
        action: { NotificationCenter.default.post(name: .generateSummary, object: nil) }
      ),

      // Navigation Actions
      QuickAction(
        id: "search",
        title: "Search",
        subtitle: "Search posts and users",
        systemImage: "magnifyingglass",
        category: .navigation,
        shortcut: "⌘F",
        action: {
          NotificationCenter.default.post(name: .navigateToSearch, object: nil)
          NotificationCenter.default.post(name: .focusSearch, object: nil)
        }
      ),

      QuickAction(
        id: "notifications",
        title: "Notifications",
        subtitle: "View notifications",
        systemImage: "bell",
        category: .navigation,
        shortcut: "⌘2",
        action: { NotificationCenter.default.post(name: .navigateToNotifications, object: nil) }
      ),

      QuickAction(
        id: "profile",
        title: "Profile",
        subtitle: "View your profile",
        systemImage: "person",
        category: .navigation,
        shortcut: "⌘4",
        action: { NotificationCenter.default.post(name: .navigateToProfile, object: nil) }
      ),

      // Content Actions
      QuickAction(
        id: "refresh",
        title: "Refresh",
        subtitle: "Refresh current view",
        systemImage: "arrow.clockwise",
        category: .content,
        shortcut: "⌘R",
        action: { NotificationCenter.default.post(name: .refresh, object: nil) }
      ),

      QuickAction(
        id: "bookmark",
        title: "Bookmarks",
        subtitle: "View saved posts",
        systemImage: "bookmark",
        category: .content,
        shortcut: "⌘B",
        action: { /* Navigate to bookmarks */  }
      ),

      // Settings Actions
      QuickAction(
        id: "settings",
        title: "Settings",
        subtitle: "App preferences",
        systemImage: "gearshape",
        category: .settings,
        shortcut: "⌘,",
        action: { NotificationCenter.default.post(name: .navigateToSettings, object: nil) }
      ),

      QuickAction(
        id: "keyboard-shortcuts",
        title: "Keyboard Shortcuts",
        subtitle: "View all shortcuts",
        systemImage: "keyboard",
        category: .settings,
        shortcut: "⌘?",
        action: { NotificationCenter.default.post(name: .showKeyboardShortcuts, object: nil) }
      ),

      // Advanced Actions
      QuickAction(
        id: "toggle-sidebar",
        title: "Toggle Sidebar",
        subtitle: "Show/hide sidebar",
        systemImage: "sidebar.left",
        category: .interface,
        shortcut: "⌘W",
        action: { NotificationCenter.default.post(name: .toggleSidebar, object: nil) }
      ),

      QuickAction(
        id: "focus-mode",
        title: "Focus Mode",
        subtitle: "Distraction-free reading",
        systemImage: "eye",
        category: .interface,
        shortcut: "⌘⇧F",
        action: { /* Toggle focus mode */  }
      ),
    ]
  }

  private func loadUserPreferences() {
    // Load user's favorite and recent actions from UserDefaults
    if let favoriteIds = UserDefaults.standard.array(forKey: "favoriteQuickActions") as? [String] {
      favoriteActions = actions.filter { favoriteIds.contains($0.id) }
    }

    if let recentIds = UserDefaults.standard.array(forKey: "recentQuickActions") as? [String] {
      recentActions = actions.filter { recentIds.contains($0.id) }
    }
  }

  func performAction(_ action: QuickAction) async {
    isPerformingAction = true
    currentActionProgress = 0.0

    // Add to recent actions
    addToRecent(action)

    // Simulate progress for actions that might take time
    if action.category == .primary {
      for i in 1...10 {
        currentActionProgress = Double(i) / 10.0
        try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
      }
    }

    // Perform the action
    action.action()

    // Provide haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    impactFeedback.impactOccurred()

    isPerformingAction = false
    currentActionProgress = 0.0
  }

  func toggleFavorite(_ action: QuickAction) {
    if favoriteActions.contains(where: { $0.id == action.id }) {
      favoriteActions.removeAll { $0.id == action.id }
    } else {
      favoriteActions.append(action)
    }
    saveFavorites()
  }

  func isFavorite(_ action: QuickAction) -> Bool {
    favoriteActions.contains { $0.id == action.id }
  }

  private func addToRecent(_ action: QuickAction) {
    recentActions.removeAll { $0.id == action.id }
    recentActions.insert(action, at: 0)

    // Keep only last 10 recent actions
    if recentActions.count > 10 {
      recentActions = Array(recentActions.prefix(10))
    }

    saveRecent()
  }

  private func saveFavorites() {
    let favoriteIds = favoriteActions.map { $0.id }
    UserDefaults.standard.set(favoriteIds, forKey: "favoriteQuickActions")
  }

  private func saveRecent() {
    let recentIds = recentActions.map { $0.id }
    UserDefaults.standard.set(recentIds, forKey: "recentQuickActions")
  }

  func getActionsByCategory(_ category: QuickActionCategory) -> [QuickAction] {
    actions.filter { $0.category == category }
  }
}

@available(iOS 18.0, *)
struct QuickAction: Identifiable, Hashable {
  let id: String
  let title: String
  let subtitle: String
  let systemImage: String
  let category: QuickActionCategory
  let shortcut: String?
  let action: () -> Void

  static func == (lhs: QuickAction, rhs: QuickAction) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

@available(iOS 18.0, *)
enum QuickActionCategory: String, CaseIterable {
  case primary = "Primary"
  case navigation = "Navigation"
  case content = "Content"
  case settings = "Settings"
  case interface = "Interface"

  var color: Color {
    switch self {
    case .primary: return .blue
    case .navigation: return .green
    case .content: return .orange
    case .settings: return .gray
    case .interface: return .purple
    }
  }

  var icon: String {
    switch self {
    case .primary: return "star.fill"
    case .navigation: return "arrow.triangle.turn.up.right.diamond"
    case .content: return "doc.text"
    case .settings: return "gearshape.fill"
    case .interface: return "rectangle.3.group"
    }
  }
}

// MARK: - Quick Actions Panel

@available(iOS 18.0, *)
struct QuickActionsPanel: View {
  @Environment(\.quickActionsSystem) var quickActionsSystem
  @State private var selectedCategory: QuickActionCategory = .primary
  @State private var showingAllActions = false

  var body: some View {
    VStack(spacing: 16) {
      // Header
      HStack {
        Text("Quick Actions")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        Spacer()

        Button(action: { showingAllActions = true }) {
          Image(systemName: "ellipsis.circle")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial)
      }

      // Category Picker
      categoryPicker

      // Actions Grid
      actionsGrid

      // Recent Actions
      if !quickActionsSystem.recentActions.isEmpty {
        recentActionsSection
      }
    }
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .sheet(isPresented: $showingAllActions) {
      AllQuickActionsSheet()
    }
  }

  // MARK: - Category Picker

  @ViewBuilder
  private var categoryPicker: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(QuickActionCategory.allCases, id: \.self) { category in
          CategoryChip(
            category: category,
            isSelected: selectedCategory == category
          ) {
            withAnimation(.smooth(duration: 0.2)) {
              selectedCategory = category
            }
          }
        }
      }
      .padding(.horizontal, 4)
    }
  }

  // MARK: - Actions Grid

  @ViewBuilder
  private var actionsGrid: some View {
    let actions = quickActionsSystem.getActionsByCategory(selectedCategory)
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)

    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(actions.prefix(4), id: \.id) { action in
        QuickActionButton(action: action)
      }
    }
  }

  // MARK: - Recent Actions

  @ViewBuilder
  private var recentActionsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Recent")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(quickActionsSystem.recentActions.prefix(5), id: \.id) { action in
            CompactQuickActionButton(action: action)
          }
        }
        .padding(.horizontal, 4)
      }
    }
  }
}

// MARK: - Category Chip

@available(iOS 18.0, *)
struct CategoryChip: View {
  let category: QuickActionCategory
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 6) {
        Image(systemName: category.icon)
          .font(.caption)
        Text(category.rawValue)
          .font(.caption.weight(.medium))
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(isSelected ? category.color.opacity(0.2) : .clear)
      )
      .overlay {
        if isSelected {
          Capsule()
            .stroke(category.color, lineWidth: 1)
        }
      }
    }
    .buttonStyle(.plain)
    .foregroundStyle(isSelected ? category.color : .secondary)
    .background(.ultraThinMaterial, in: Capsule())
    .overlay(
      Capsule()
        .stroke(isSelected ? category.color.opacity(0.3) : .clear, lineWidth: 1)
    )
  }
}

// MARK: - Quick Action Button

@available(iOS 18.0, *)
struct QuickActionButton: View {
  let action: QuickAction
  @Environment(\.quickActionsSystem) var quickActionsSystem
  @State private var isPressed = false

  var body: some View {
    Button {
      Task {
        await quickActionsSystem.performAction(action)
      }
    } label: {
      VStack(spacing: 8) {
        // Icon
        Image(systemName: action.systemImage)
          .font(.title2)
          .foregroundStyle(action.category.color)
          .frame(width: 32, height: 32)

        // Title and subtitle
        VStack(spacing: 2) {
          Text(action.title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(1)

          Text(action.subtitle)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
        }

        // Shortcut
        if let shortcut = action.shortcut {
          Text(shortcut)
            .font(.caption2.monospaced())
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 3))
        }
      }
      .padding(12)
      .frame(maxWidth: .infinity, minHeight: 100)
    }
    .buttonStyle(.plain)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.ultraThinMaterial)
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .onLongPressGesture(minimumDuration: 0) { pressing in
      withAnimation(.smooth(duration: 0.1)) {
        isPressed = pressing
      }
    } perform: {
    }
    .contextMenu {
      Button(quickActionsSystem.isFavorite(action) ? "Remove from Favorites" : "Add to Favorites") {
        quickActionsSystem.toggleFavorite(action)
      }
    }
    .overlay(alignment: .topTrailing) {
      if quickActionsSystem.isFavorite(action) {
        Image(systemName: "star.fill")
          .font(.caption2)
          .foregroundStyle(.yellow)
          .padding(4)
      }
    }
  }
}

// MARK: - Compact Quick Action Button

@available(iOS 18.0, *)
struct CompactQuickActionButton: View {
  let action: QuickAction
  @Environment(\.quickActionsSystem) var quickActionsSystem

  var body: some View {
    Button {
      Task {
        await quickActionsSystem.performAction(action)
      }
    } label: {
      VStack(spacing: 4) {
        Image(systemName: action.systemImage)
          .font(.subheadline)
          .foregroundStyle(action.category.color)
          .frame(width: 20, height: 20)

        Text(action.title)
          .font(.caption2.weight(.medium))
          .foregroundStyle(.primary)
          .lineLimit(1)
      }
      .padding(8)
      .frame(width: 60, height: 60)
    }
    .buttonStyle(.plain)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(.ultraThinMaterial)
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
  }
}

// MARK: - All Quick Actions Sheet

@available(iOS 18.0, *)
struct AllQuickActionsSheet: View {
  @Environment(\.dismiss) var dismiss
  @Environment(\.quickActionsSystem) var quickActionsSystem
  @State private var searchText = ""

  var body: some View {
    NavigationView {
      VStack {
        // Search bar
        GestureAwareSearchBar(text: $searchText, placeholder: "Search actions...")
          .padding()

        // Actions list
        List {
          ForEach(QuickActionCategory.allCases, id: \.self) { category in
            let actions = filteredActions(for: category)
            if !actions.isEmpty {
              Section(category.rawValue) {
                ForEach(actions, id: \.id) { action in
                  QuickActionRow(action: action)
                }
              }
            }
          }
        }
      }
      .navigationTitle("All Quick Actions")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  private func filteredActions(for category: QuickActionCategory) -> [QuickAction] {
    let categoryActions = quickActionsSystem.getActionsByCategory(category)

    if searchText.isEmpty {
      return categoryActions
    } else {
      return categoryActions.filter { action in
        action.title.localizedCaseInsensitiveContains(searchText)
          || action.subtitle.localizedCaseInsensitiveContains(searchText)
      }
    }
  }
}

// MARK: - Quick Action Row

@available(iOS 18.0, *)
struct QuickActionRow: View {
  let action: QuickAction
  @Environment(\.quickActionsSystem) var quickActionsSystem

  var body: some View {
    Button {
      Task {
        await quickActionsSystem.performAction(action)
      }
    } label: {
      HStack(spacing: 12) {
        Image(systemName: action.systemImage)
          .font(.title3)
          .foregroundStyle(action.category.color)
          .frame(width: 24, height: 24)

        VStack(alignment: .leading, spacing: 2) {
          Text(action.title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)

          Text(action.subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        if let shortcut = action.shortcut {
          Text(shortcut)
            .font(.caption.monospaced())
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
        }

        if quickActionsSystem.isFavorite(action) {
          Image(systemName: "star.fill")
            .font(.caption)
            .foregroundStyle(.yellow)
        }
      }
      .padding(.vertical, 4)
    }
    .buttonStyle(.plain)
    .contextMenu {
      Button(quickActionsSystem.isFavorite(action) ? "Remove from Favorites" : "Add to Favorites") {
        quickActionsSystem.toggleFavorite(action)
      }
    }
  }
}

// MARK: - Environment Key

@available(iOS 18.0, *)
struct QuickActionsSystemKey: EnvironmentKey {
  static let defaultValue = QuickActionsSystem()
}

@available(iOS 18.0, *)
extension EnvironmentValues {
  var quickActionsSystem: QuickActionsSystem {
    get { self[QuickActionsSystemKey.self] }
    set { self[QuickActionsSystemKey.self] = newValue }
  }
}

// MARK: - Notification Extensions
