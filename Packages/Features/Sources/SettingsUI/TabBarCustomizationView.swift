import Destinations
import Models
import SwiftUI

public struct TabBarCustomizationView: View {
  @State private var settingsService = SettingsService.shared
  @State private var availableTabs: [AppTab] = AppTab.allCases
  @State private var selectedRaw: [String] = []
  @State private var pinnedFeedURIs: [String] = []
  @State private var isEditing: Bool = false

  public init() {}

  public var body: some View {
    NavigationView {
      List {
        Section("Visible Tabs (drag to reorder)") {
          ForEach(selectedTabs, id: \.rawValue) { tab in
            HStack {
              Image(systemName: tab.icon)
              Text(tab.title)
              Spacer()
              Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
            }
            .swipeActions(edge: .trailing) {
              // Swipe to remove from visible → moves to Add Tabs list
              Button(role: .destructive) {
                selectedRaw.removeAll { $0 == tab.rawValue }
                settingsService.tabBarTabsRaw = selectedRaw
              } label: {
                Label("Remove", systemImage: "trash")
              }
            }
          }
          .onMove { indices, newOffset in
            var tabs = selectedTabs
            tabs.move(fromOffsets: indices, toOffset: newOffset)
            selectedRaw = tabs.map { $0.rawValue }
            settingsService.tabBarTabsRaw = selectedRaw
          }
        }

        Section("Add Tabs") {
          ForEach(availableTabs.filter { !selectedRaw.contains($0.rawValue) }, id: \.rawValue) {
            tab in
            HStack {
              Image(systemName: tab.icon)
              Text(tab.title)
              Spacer()
              Button("Add") {
                if !selectedRaw.contains(tab.rawValue) {
                  selectedRaw.append(tab.rawValue)
                  settingsService.tabBarTabsRaw = selectedRaw
                }
              }
              .buttonStyle(.bordered)
            }
            .swipeActions(edge: .trailing) {
              Button {
                if !selectedRaw.contains(tab.rawValue) {
                  selectedRaw.append(tab.rawValue)
                  settingsService.tabBarTabsRaw = selectedRaw
                }
              } label: {
                Label("Add", systemImage: "plus")
              }
              .tint(.blue)
            }
          }
        }

        if !pinnedFeedURIs.isEmpty {
          Section("Pinned Feeds (swipe to remove)") {
            ForEach(pinnedFeedURIs, id: \.self) { uri in
              HStack {
                Image(systemName: "dot.radiowaves.left.and.right")
                Text(SettingsService.shared.pinnedFeedNames[uri] ?? uri)
                  .lineLimit(1)
                  .truncationMode(.middle)
              }
              .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                  pinnedFeedURIs.removeAll { $0 == uri }
                  settingsService.pinnedFeedURIs = pinnedFeedURIs
                } label: {
                  Label("Remove", systemImage: "trash")
                }
              }
            }
            .onMove { indices, newOffset in
              pinnedFeedURIs.move(fromOffsets: indices, toOffset: newOffset)
              settingsService.pinnedFeedURIs = pinnedFeedURIs
            }
          }
        }
      }
      // Toggle edit mode only when needed so swipe-to-delete works when not editing
      .environment(\.editMode, .constant(isEditing ? .active : .inactive))
      .navigationTitle("Customize Tabs")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(isEditing ? "Done" : "Edit") { isEditing.toggle() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Reset") { resetToDefault() }
        }
      }
      .onAppear {
        selectedRaw = settingsService.tabBarTabsRaw
        pinnedFeedURIs = settingsService.pinnedFeedURIs
      }
    }
  }

  private var selectedTabs: [AppTab] {
    selectedRaw.compactMap { AppTab(rawValue: $0) }
  }

  private func resetToDefault() {
    let defaults = [AppTab.feed, .notification, .profile, .settings, .compose]
    selectedRaw = defaults.map { $0.rawValue }
    settingsService.tabBarTabsRaw = selectedRaw
    pinnedFeedURIs = []
    settingsService.pinnedFeedURIs = []
  }
}
