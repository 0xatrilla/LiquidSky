import Client
import Models
import SwiftUI

public struct NotificationsView: View {
  @Environment(BSkyClient.self) var client

  public init() {}

  public var body: some View {
    NavigationStack {
      NotificationsListView()
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
  }
}
