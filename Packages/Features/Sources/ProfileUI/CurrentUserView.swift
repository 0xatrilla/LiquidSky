import SwiftUI
import User

public struct CurrentUserView: View {
  @Environment(CurrentUser.self) private var currentUser

  public init() {}

  public var body: some View {
    Group {
      if let profile = currentUser.profile {
        ProfileView(profile: profile.profile, showBack: false, isCurrentUser: true)
      } else {
        ProgressView()
      }
    }
    .onAppear {
      checkForSearchNavigation()
    }
  }

  private func checkForSearchNavigation() {
    // Check if we have a search navigation target stored
    if let userHandle = UserDefaults.standard.string(forKey: "search_navigate_to_user") {
      // Clear the stored value immediately to prevent re-navigation
      UserDefaults.standard.removeObject(forKey: "search_navigate_to_user")
      print("Search navigation to user: \(userHandle)")
      // TODO: Implement proper navigation once environment access is resolved
    }
  }
}
