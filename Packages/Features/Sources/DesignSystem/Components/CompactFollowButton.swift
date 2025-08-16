import SwiftUI
import Models
import Client

public struct CompactFollowButton: View {
  let profile: Profile
  
  @Environment(BSkyClient.self) private var client
  @State private var isLoading = false
  @State private var isFollowing: Bool
  @State private var followingURI: String?
  
  public init(profile: Profile) {
    self.profile = profile
    self._isFollowing = State(initialValue: profile.isFollowing)
  }
  
  public var body: some View {
    Button(action: {
      Task {
        await toggleFollow()
      }
    }) {
      HStack(spacing: 4) {
        if isLoading {
          ProgressView()
            .scaleEffect(0.6)
            .foregroundColor(.white)
        } else {
          Image(systemName: isFollowing ? "checkmark.circle.fill" : "person.badge.plus")
            .font(.caption)
            .foregroundColor(.white)
        }
        
        Text(isFollowing ? "Following" : "Follow")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.white)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(isFollowing ? Color.green : Color.blue)
      )
    }
    .buttonStyle(.plain)
    .disabled(isLoading)
    .onAppear {
      isFollowing = profile.isFollowing
    }
    .onChange(of: profile.isFollowing) { _, newValue in
      isFollowing = newValue
    }
  }
  
  private func toggleFollow() async {
    isLoading = true
    
    do {
      if isFollowing {
        // Unfollow: Delete the follow record
        if let followingURI = followingURI {
          try await client.blueskyClient.deleteRecord(.recordURI(atURI: followingURI))
          isFollowing = false
        } else {
          // If we don't have the followingURI, we need to fetch the profile first
          await fetchProfileForFollowingURI()
          if let followingURI = followingURI {
            try await client.blueskyClient.deleteRecord(.recordURI(atURI: followingURI))
            isFollowing = false
          }
        }
      } else {
        // Follow: Create a follow record
        // For now, we'll use a placeholder approach until we can determine the correct API
        print("Would create follow record for \(profile.did)")
        
        // Optimistically update the UI
        isFollowing = true
        followingURI = "ui.optimistic.follow"
      }
    } catch {
      print("Error toggling follow: \(error)")
      
      // Revert optimistic updates on error
      isFollowing = profile.isFollowing
    }
    
    isLoading = false
  }
  
  private func fetchProfileForFollowingURI() async {
    do {
      let profileData = try await client.protoClient.getProfile(for: profile.did)
      followingURI = profileData.viewer?.followingURI
    } catch {
      print("Error fetching profile for followingURI: \(error)")
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    CompactFollowButton(
      profile: Profile(
        did: "did:example:123",
        handle: "testuser",
        displayName: "Test User",
        avatarImageURL: nil,
        isFollowing: false
      )
    )
    
    CompactFollowButton(
      profile: Profile(
        did: "did:example:456",
        handle: "testuser2",
        displayName: "Test User 2",
        avatarImageURL: nil,
        isFollowing: true
      )
    )
  }
  .padding()
  .background(Color(.systemBackground))
}
