import Foundation
import SwiftUI

// MARK: - Notification Names

@available(iPadOS 26.0, *)
@Observable
@MainActor
class KeyboardShortcutsManager {
  var shortcuts: [KeyboardShortcut] = []
  var isEnabled = true

  init() {
    setupDefaultShortcuts()
  }

  private func setupDefaultShortcuts() {
    shortcuts = [
      // Navigation shortcuts
      KeyboardShortcut(
        key: .init("1"),
        modifiers: .command,
        title: "Go to Feed",
        action: {
          NotificationCenter.default.post(name: Notification.Name("navigateToFeed"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .init("2"),
        modifiers: .command,
        title: "Go to Notifications",
        action: {
          NotificationCenter.default.post(
            name: Notification.Name("navigateToNotifications"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .init("3"),
        modifiers: .command,
        title: "Go to Search",
        action: {
          NotificationCenter.default.post(name: Notification.Name("navigateToSearch"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .init("4"),
        modifiers: .command,
        title: "Go to Profile",
        action: {
          NotificationCenter.default.post(name: Notification.Name("navigateToProfile"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .init("5"),
        modifiers: .command,
        title: "Go to Settings",
        action: {
          NotificationCenter.default.post(
            name: Notification.Name("navigateToSettings"), object: nil)
        }
      ),

      // Action shortcuts
      KeyboardShortcut(
        key: .init("n"),
        modifiers: .command,
        title: "New Post",
        action: { NotificationCenter.default.post(name: Notification.Name("newPost"), object: nil) }
      ),
      KeyboardShortcut(
        key: .init("f"),
        modifiers: .command,
        title: "Search",
        action: {
          NotificationCenter.default.post(name: Notification.Name("focusSearch"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .init("r"),
        modifiers: .command,
        title: "Refresh",
        action: { NotificationCenter.default.post(name: Notification.Name("refresh"), object: nil) }
      ),

      // Column management
      KeyboardShortcut(
        key: .init("w"),
        modifiers: .command,
        title: "Toggle Sidebar",
        action: {
          NotificationCenter.default.post(name: Notification.Name("toggleSidebar"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .init("d"),
        modifiers: .command,
        title: "Toggle Detail",
        action: {
          NotificationCenter.default.post(name: Notification.Name("toggleDetail"), object: nil)
        }
      ),

      // Navigation within columns
      KeyboardShortcut(
        key: .upArrow,
        modifiers: [],
        title: "Previous Item",
        action: {
          NotificationCenter.default.post(name: Notification.Name("navigatePrevious"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .downArrow,
        modifiers: [],
        title: "Next Item",
        action: {
          NotificationCenter.default.post(name: Notification.Name("navigateNext"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .leftArrow,
        modifiers: [],
        title: "Previous Column",
        action: {
          NotificationCenter.default.post(
            name: Notification.Name("navigateLeftColumn"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .rightArrow,
        modifiers: [],
        title: "Next Column",
        action: {
          NotificationCenter.default.post(
            name: Notification.Name("navigateRightColumn"), object: nil)
        }
      ),

      // Quick actions
      KeyboardShortcut(
        key: .space,
        modifiers: [],
        title: "Select/Activate",
        action: {
          NotificationCenter.default.post(name: Notification.Name("activateSelected"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .escape,
        modifiers: [],
        title: "Cancel/Back",
        action: {
          NotificationCenter.default.post(name: Notification.Name("cancelAction"), object: nil)
        }
      ),
      KeyboardShortcut(
        key: .return,
        modifiers: [],
        title: "Confirm/Open",
        action: {
          NotificationCenter.default.post(name: Notification.Name("confirmAction"), object: nil)
        }
      ),
    ]
  }

  func addShortcut(_ shortcut: KeyboardShortcut) {
    shortcuts.append(shortcut)
  }

  func removeShortcut(withKey key: KeyEquivalent, modifiers: EventModifiers) {
    shortcuts.removeAll { $0.key == key && $0.modifiers == modifiers }
  }

  func handleKeyPress(_ key: KeyEquivalent, modifiers: EventModifiers) -> Bool {
    guard isEnabled else { return false }

    for shortcut in shortcuts {
      if shortcut.key == key && shortcut.modifiers == modifiers {
        shortcut.action()
        return true
      }
    }

    return false
  }

  func getShortcutsForDisplay() -> [KeyboardShortcutGroup] {
    let grouped = Dictionary(grouping: shortcuts) { shortcut in
      if shortcut.modifiers.contains(.command) {
        return "Navigation & Actions"
      } else {
        return "Quick Keys"
      }
    }

    return grouped.map { (key, shortcuts) in
      KeyboardShortcutGroup(title: key, shortcuts: shortcuts.sorted { $0.title < $1.title })
    }
  }
}

@available(iPadOS 26.0, *)
struct KeyboardShortcut {
  let key: KeyEquivalent
  let modifiers: EventModifiers
  let title: String
  let action: () -> Void

  var displayString: String {
    var components: [String] = []

    if modifiers.contains(.command) {
      components.append("⌘")
    }
    if modifiers.contains(.option) {
      components.append("⌥")
    }
    if modifiers.contains(.control) {
      components.append("⌃")
    }
    if modifiers.contains(.shift) {
      components.append("⇧")
    }

    // Add the key
    switch key {
    case .upArrow:
      components.append("↑")
    case .downArrow:
      components.append("↓")
    case .leftArrow:
      components.append("←")
    case .rightArrow:
      components.append("→")
    case .space:
      components.append("Space")
    case .escape:
      components.append("Esc")
    case .return:
      components.append("Return")
    default:
      components.append(String(describing: key).uppercased())
    }

    return components.joined()
  }
}

@available(iPadOS 26.0, *)
struct KeyboardShortcutGroup {
  let title: String
  let shortcuts: [KeyboardShortcut]
}

// MARK: - Keyboard Shortcuts View Modifier

@available(iPadOS 26.0, *)
struct KeyboardShortcutsModifier: ViewModifier {
  @Environment(\.keyboardShortcutsManager) var shortcutsManager

  func body(content: Content) -> some View {
    content
      .onKeyPress { keyPress in
        let handled = shortcutsManager.handleKeyPress(keyPress.key, modifiers: keyPress.modifiers)
        return handled ? .handled : .ignored
      }
  }
}

@available(iPadOS 26.0, *)
extension View {
  func keyboardShortcuts() -> some View {
    self.modifier(KeyboardShortcutsModifier())
  }
}

// MARK: - Focus Management

@available(iPadOS 26.0, *)
@Observable
class FocusManager {
  var focusedColumn: FocusedColumn = .sidebar
  var focusedItemIndex: Int = 0
  var maxItemsInColumn: [FocusedColumn: Int] = [:]

  enum FocusedColumn: CaseIterable {
    case sidebar, content, detail
  }

  func moveFocus(to column: FocusedColumn) {
    focusedColumn = column
    focusedItemIndex = 0
  }

  func moveFocusUp() {
    focusedItemIndex = max(0, focusedItemIndex - 1)
  }

  func moveFocusDown() {
    let maxItems = maxItemsInColumn[focusedColumn] ?? 0
    focusedItemIndex = min(maxItems - 1, focusedItemIndex + 1)
  }

  func moveFocusLeft() {
    switch focusedColumn {
    case .content:
      moveFocus(to: .sidebar)
    case .detail:
      moveFocus(to: .content)
    case .sidebar:
      break  // Already at leftmost column
    }
  }

  func moveFocusRight() {
    switch focusedColumn {
    case .sidebar:
      moveFocus(to: .content)
    case .content:
      moveFocus(to: .detail)
    case .detail:
      break  // Already at rightmost column
    }
  }

  func updateMaxItems(for column: FocusedColumn, count: Int) {
    maxItemsInColumn[column] = count
  }
}

// MARK: - Keyboard Shortcuts Help View

@available(iPadOS 26.0, *)
struct KeyboardShortcutsHelpView: View {
  @Environment(\.keyboardShortcutsManager) var shortcutsManager
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationView {
      List {
        ForEach(shortcutsManager.getShortcutsForDisplay(), id: \.title) { group in
          Section(group.title) {
            ForEach(group.shortcuts, id: \.title) { shortcut in
              HStack {
                Text(shortcut.title)
                  .font(.subheadline)

                Spacer()

                Text(shortcut.displayString)
                  .font(.caption.monospaced())
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
              }
            }
          }
        }
      }
      .navigationTitle("Keyboard Shortcuts")
      .navigationBarTitleDisplayMode(.large)
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

// MARK: - Environment Keys

@available(iPadOS 26.0, *)
struct KeyboardShortcutsManagerKey: EnvironmentKey {
  static let defaultValue = KeyboardShortcutsManager()
}

@available(iPadOS 26.0, *)
struct FocusManagerKey: EnvironmentKey {
  static let defaultValue = FocusManager()
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var keyboardShortcutsManager: KeyboardShortcutsManager {
    get { self[KeyboardShortcutsManagerKey.self] }
    set { self[KeyboardShortcutsManagerKey.self] = newValue }
  }

  var focusManager: FocusManager {
    get { self[FocusManagerKey.self] }
    set { self[FocusManagerKey.self] = newValue }
  }
}
