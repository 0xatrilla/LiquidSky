import Destinations
import Models
import SwiftUI

public struct TabBarCustomizationView: View {
  @State private var settingsService = SettingsService.shared
  @State private var availableTabs: [AppTab] = AppTab.allCases
  @State private var selectedRaw: [String] = []

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
          }
          .onMove { indices, newOffset in
            var tabs = selectedTabs
            tabs.move(fromOffsets: indices, toOffset: newOffset)
            selectedRaw = tabs.map { $0.rawValue }
            settingsService.tabBarTabsRaw = selectedRaw
          }
        }

        Section("Add/Remove Tabs") {
          ForEach(availableTabs, id: \.rawValue) { tab in
            Toggle(
              isOn: Binding(
                get: { selectedRaw.contains(tab.rawValue) },
                set: { isOn in
                  if isOn {
                    if !selectedRaw.contains(tab.rawValue) {
                      selectedRaw.append(tab.rawValue)
                    }
                  } else {
                    selectedRaw.removeAll { $0 == tab.rawValue }
                  }
                  // De-duplicate defensively then persist
                  selectedRaw = Array(NSOrderedSet(array: selectedRaw)) as? [String] ?? selectedRaw
                  settingsService.tabBarTabsRaw = selectedRaw
                }
              )
            ) {
              HStack {
                Image(systemName: tab.icon)
                Text(tab.title)
              }
            }
          }
        }
      }
      .environment(\.editMode, .constant(.active))
      .navigationTitle("Customize Tabs")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Reset") { resetToDefault() }
        }
      }
      .onAppear {
        selectedRaw = settingsService.tabBarTabsRaw
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
  }
}
