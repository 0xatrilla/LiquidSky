import AppRouter
import Foundation
import Models
import SwiftUI
import UIKit

@available(iOS 26.0, *)
struct SidebarNavigationView: View {

  var body: some View {
    VStack {
      Text("Sidebar Navigation")
        .font(.title)
        .padding()
      
      List {
        Text("Feed")
        Text("Notifications") 
        Text("Search")
        Text("Profile")
        Text("Settings")
      }
    }
    .navigationTitle("Horizon")
  }
}

// MARK: - Notification Extensions

extension Notification.Name {
  static let generateSummary = Notification.Name("generateSummary")
  static let showKeyboardShortcuts = Notification.Name("showKeyboardShortcuts")
}
