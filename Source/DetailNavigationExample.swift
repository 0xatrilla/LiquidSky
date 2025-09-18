import SwiftUI
import Models

// MARK: - Example Custom Post Row with Detail Navigation

@available(iOS 18.0, *)
struct DetailNavigationPostRow: View {
  let post: PostItem
  
  var body: some View {
    Button(action: {
      // Navigate to post detail in the detail pane using existing system
      DetailNavigationHelper.showPostDetail(
        postId: post.uri,
        title: "Post by \(post.author.displayName ?? "Unknown")"
      )
    }) {
      HStack {
        // Post content here
        VStack(alignment: .leading) {
          Text(post.author.displayName ?? "Unknown")
            .font(.headline)
          Text(post.content)
            .font(.body)
        }
        Spacer()
      }
      .padding()
      .background(Color(.systemBackground))
      .cornerRadius(8)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Example Profile Button with Detail Navigation

@available(iOS 18.0, *)
struct DetailNavigationProfileButton: View {
  let profile: Profile
  
  var body: some View {
    Button(action: {
      // Navigate to profile in the detail pane using existing system
      DetailNavigationHelper.showProfileDetail(
        profileId: profile.did,
        title: profile.displayName ?? "Profile"
      )
    }) {
      HStack {
        // Profile content here
        VStack(alignment: .leading) {
          Text(profile.displayName ?? "Unknown")
            .font(.headline)
          Text("@\(profile.handle)")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        Spacer()
      }
      .padding()
      .background(Color(.systemBackground))
      .cornerRadius(8)
    }
    .buttonStyle(.plain)
  }
}
