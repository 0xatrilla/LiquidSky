import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import PostUI
import SwiftUI

public struct ProfileView: View {
    let profile: Profile
    let showBack: Bool
    let isCurrentUser: Bool

    @Namespace private var namespace
    @Environment(AppRouter.self) var router
    @Environment(BSkyClient.self) var client

    @State private var fullProfile: Profile?
    @State private var isLoadingProfile = false
    @State private var profileError: Error?
    @State private var selectedTab: ProfileTab = .posts

    public init(profile: Profile, showBack: Bool = true, isCurrentUser: Bool = false) {
        self.profile = profile
        self.showBack = showBack
        self.isCurrentUser = isCurrentUser
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Header
                profileHeader
                    .padding(.horizontal)
                    .padding(.top)

                // Profile Stats
                profileStats
                    .padding(.horizontal)
                    .padding(.vertical, 16)

                // Bio Section
                if let description = (fullProfile ?? profile).description, !description.isEmpty {
                    bioSection(description: description)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }

                // Relationship Status (for other users)
                if !isCurrentUser {
                    relationshipStatusSection
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }

                // Action Buttons
                actionButtons
                    .padding(.horizontal)
                    .padding(.bottom, 24)

                // Content Tabs
                contentTabs
                    .padding(.horizontal)
            }
        }
        .background(.background)
        .navigationBarBackButtonHidden(!showBack)
        .task {
            await fetchFullProfile()
        }
        .onChange(of: isCurrentUser) { _, newValue in
            // If we're viewing another user's profile and the likes tab is selected, switch to posts
            if !newValue && selectedTab == .likes {
                selectedTab = .posts
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            // Avatar
            if let avatarURL = (fullProfile ?? profile).avatarImageURL {
                AsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.themePrimary.opacity(0.3), lineWidth: 2)
                )
                .onTapGesture {
                    router.presentedSheet = SheetDestination.fullScreenProfilePicture(
                        imageURL: avatarURL,
                        namespace: namespace
                    )
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text((fullProfile ?? profile).displayName ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("@\((fullProfile ?? profile).handle)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Profile Stats
    private var profileStats: some View {
        HStack(spacing: 32) {
            VStack(spacing: 4) {
                Text("\((fullProfile ?? profile).postsCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("Posts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                router.presentedSheet = .followingList(profile: fullProfile ?? profile)
            }) {
                VStack(spacing: 4) {
                    Text("\((fullProfile ?? profile).followingCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            Button(action: {
                router.presentedSheet = .followersList(profile: fullProfile ?? profile)
            }) {
                VStack(spacing: 4) {
                    Text("\((fullProfile ?? profile).followersCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bio Section
    private func bioSection(description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            ClickableBioText(text: (fullProfile ?? profile).description ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            ShareLink(
                item: createProfileShareText(),
                subject: Text("Check out this profile"),
                message: Text("I found this interesting profile on Bluesky")
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                    )
            }

            Menu {
                if !isCurrentUser {
                    // TODO: Re-enable Send Message button when chat functionality is ready
                    /*
                    Button(action: {
                      NotificationCenter.default.post(
                        name: .init("openSendMessageFromProfile"),
                        object: nil,
                        userInfo: [
                          "did": (fullProfile ?? profile).did,
                          "handle": (fullProfile ?? profile).handle,
                          "displayName": (fullProfile ?? profile).displayName
                            ?? (fullProfile ?? profile).handle,
                        ]
                      )
                    }) {
                      Label("Send Message", systemImage: "paperplane")
                    }
                    */

                    // Per-account post notifications
                    Button(action: {
                        NotificationPreferences.shared.toggleSubscription(for: profile.did)
                    }) {
                        let enabled = NotificationPreferences.shared.isSubscribed(to: profile.did)
                        Label(
                            enabled ? "Disable Notifications" : "Enable Notifications",
                            systemImage: enabled ? "bell.slash" : "bell")
                    }

                    Button(action: {
                        Task { await toggleMute() }
                    }) {
                        Label(
                            profile.isMuted ? "Unmute" : "Mute",
                            systemImage: profile.isMuted ? "speaker" : "speaker.slash")
                    }

                    Button(action: {
                        Task { await toggleBlock() }
                    }) {
                        Label(
                            profile.isBlocked ? "Unblock" : "Block",
                            systemImage: profile.isBlocked
                                ? "person.crop.circle.badge.checkmark"
                                : "person.crop.circle.badge.minus")
                    }
                    .foregroundColor(.red)

                    Divider()

                    Button(action: {
                        // TODO: Implement add to list
                    }) {
                        Label("Add to List", systemImage: "list.bullet")
                    }

                    Button(action: {
                        // TODO: Implement report user
                    }) {
                        Label("Report", systemImage: "exclamationmark.triangle")
                    }
                    .foregroundColor(.orange)
                } else {
                    Button(action: {
                        router.presentedSheet = .editProfile
                    }) {
                        Label("Edit Profile", systemImage: "pencil")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Share Helper
    private func createProfileShareText() -> String {
        var shareText = ""

        if let displayName = (fullProfile ?? profile).displayName {
            shareText += "\(displayName)"
        }

        shareText += " (@\((fullProfile ?? profile).handle))"

        if let description = (fullProfile ?? profile).description, !description.isEmpty {
            shareText += "\n\n\(description)"
        }

        shareText += "\n\nProfile: https://bsky.app/profile/\((fullProfile ?? profile).handle)"

        return shareText
    }

    // MARK: - Content Tabs
    private var contentTabs: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Content")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }

            // Horizontal Tab Picker
            Picker("Content Type", selection: $selectedTab) {
                Text("Posts").tag(ProfileTab.posts)
                Text("Replies").tag(ProfileTab.replies)
                Text("Media").tag(ProfileTab.media)
                if isCurrentUser {
                    Text("Likes").tag(ProfileTab.likes)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Tab Content - using direct content instead of TabView to allow proper scrolling
            Group {
                switch selectedTab {
                case .posts:
                    PostsProfileView(profile: profile, filter: .postsWithNoReplies)
                        .environment(PostFilterService.shared)
                        .environment(\.currentTab, .profile)
                case .replies:
                    PostsProfileView(profile: profile, filter: .userReplies)
                        .environment(PostFilterService.shared)
                        .environment(\.currentTab, .profile)
                case .media:
                    PostsProfileView(profile: profile, filter: .postsWithMedia)
                        .environment(PostFilterService.shared)
                        .environment(\.currentTab, .profile)
                case .likes:
                    PostsLikesView(profile: profile)
                }
            }
        }
    }

    // MARK: - Relationship Status Section
    private var relationshipStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Relationship")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                // Follow/Unfollow Button
                FollowButton(profile: fullProfile ?? profile, size: .medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Fetch Full Profile
    private func fetchFullProfile() async {
        isLoadingProfile = true
        profileError = nil

        do {
            let profileData = try await client.protoClient.getProfile(for: profile.did)

            // Store the followingURI for follow/unfollow operations
            // followingURI = profileData.viewer?.followingURI // This line is removed

            fullProfile = Profile(
                did: profileData.actorDID,
                handle: profileData.actorHandle,
                displayName: profileData.displayName,
                avatarImageURL: profileData.avatarImageURL,
                description: profileData.description,
                followersCount: profileData.followerCount ?? 0,
                followingCount: profileData.followCount ?? 0,
                postsCount: profileData.postCount ?? 0,
                isFollowing: profileData.viewer?.followingURI != nil,
                isFollowedBy: profileData.viewer?.followedByURI != nil,
                isBlocked: profileData.viewer?.isBlocked == true,
                isBlocking: profileData.viewer?.blockingURI != nil,
                isMuted: profileData.viewer?.isMuted == true
            )
        } catch {
            profileError = error
            print("Error fetching full profile: \(error)")
        }

        isLoadingProfile = false
    }

    // MARK: - Profile Actions
    private func toggleMute() async {
        if profile.isMuted {
            _ = try? await client.protoClient.unmuteActor(profile.did)
        } else {
            _ = try? await client.protoClient.muteActor(profile.did)
        }
    }

    private func toggleBlock() async {
        if profile.isBlocked {
            if let blockingURI = try? await client.protoClient.getProfile(for: profile.did).viewer?
                .blockingURI
            {
                try? await client.blueskyClient.deleteRecord(.recordURI(atURI: blockingURI))
            }
            BlockedUsersService.shared.unblockUser(did: profile.did)
        } else {
            _ = try? await client.blueskyClient.createBlockRecord(
                ofType: .actorBlock(actorDID: profile.did))
            BlockedUsersService.shared.blockUser(did: profile.did, handle: profile.handle)
        }
    }

    // The toggleFollow method and its related state variables are removed as per the edit hint.
}

// MARK: - Clickable Bio Text
private struct ClickableBioText: View {
    let text: String
    @Environment(AppRouter.self) private var router

    var body: some View {
        let attributedString = createAttributedString(from: text)

        Text(attributedString)
            .font(.body)
            .foregroundColor(.primary)
            .textSelection(.enabled)
            .onTapGesture { location in
                handleTap(at: location)
            }
    }

    private func createAttributedString(from text: String) -> AttributedString {
        var attributedString = AttributedString(text)

        // Find URLs in the text and make them clickable
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches =
            detector?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []

        for match in matches {
            if let range = Range(match.range, in: text) {
                let attributedRange = AttributedString(text[range]).range(of: String(text[range]))
                if match.url != nil, let attributedRange = attributedRange {
                    attributedString[attributedRange].foregroundColor = .blue
                    attributedString[attributedRange].underlineStyle = .single
                }
            }
        }

        return attributedString
    }

    private func handleTap(at location: CGPoint) {
        // Extract the tapped text and check if it's a URL
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches =
            detector?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []

        for match in matches {
            if let url = match.url {
                // Open URL in Safari or in-app browser
                UIApplication.shared.open(url)
                break
            }
        }
    }
}

// MARK: - Profile Tab Enum
enum ProfileTab: Int, CaseIterable {
    case posts = 0
    case replies = 1
    case media = 2
    case likes = 3
}

// MARK: - Stat Item
struct StatItem: View {
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
