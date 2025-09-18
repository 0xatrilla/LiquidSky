import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI
import User

extension EnvironmentValues {
    @Entry public var hideMoreActions = false
}

public struct PostRowActionsView: View {
    @Environment(\.hideMoreActions) var hideMoreActions
    @Environment(\.currentTab) var currentTab
    @Environment(PostContext.self) var dataController
    @Environment(AppRouter.self) var router
    @Environment(PostFilterService.self) var postFilterService
    @Environment(CurrentUser.self) var currentUser
    @Environment(BSkyClient.self) var client

    let post: PostItem
    
    @State private var isBookmarked = false
    @State private var isBookmarking = false
    @State private var bookmarkService: BookmarkService?

    public init(post: PostItem) {
        self.post = post
    }

    private var isOwnPost: Bool {
        currentUser.profile?.actorDID == post.author.did
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            // Reply Button
            if postFilterService.canReplyToPost(post) {
                Button(action: {
                    router.presentedSheet = .composer(mode: .reply(post))
                }) {
                    Label("\(post.replyCount)", systemImage: "bubble")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.themePrimary)
            }

            // Repost Button
            if postFilterService.canQuotePost(post) {
                Button(action: {
                    Task {
                        await dataController.toggleRepost()
                    }
                }) {
                    Label("\(dataController.repostCount)", systemImage: "quote.bubble")
                        .contentTransition(.numericText(value: Double(dataController.repostCount)))
                        .monospacedDigit()
                        .lineLimit(1)
                        .animation(.smooth, value: dataController.repostCount)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .symbolVariant(dataController.isReposted ? .fill : .none)
                .foregroundColor(.themeSecondary)
            }

            // Like Button
            Button(action: {
                Task {
                    await dataController.toggleLike()
                }
            }) {
                Label("\(dataController.likeCount)", systemImage: "heart")
                    .lineLimit(1)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .symbolVariant(dataController.isLiked ? .fill : .none)
            .symbolEffect(.bounce, value: dataController.isLiked)
            .contentTransition(.numericText(value: Double(dataController.likeCount)))
            .monospacedDigit()
            .animation(.smooth, value: dataController.likeCount)
            .foregroundColor(.themeAccent)

            Spacer()

            if !hideMoreActions {
                Menu {
                    // Share post
                    Button(action: {
                        sharePost()
                    }) {
                        Label("Share Post", systemImage: "square.and.arrow.up")
                    }

                    // Copy post text
                    Button(action: {
                        copyPostText()
                    }) {
                        Label("Copy Text", systemImage: "doc.on.doc")
                    }

                    // Copy post link
                    Button(action: {
                        copyPostLink()
                    }) {
                        Label("Copy Link", systemImage: "link")
                    }

                    // Bookmark post
                    Button(action: {
                        Task {
                            await toggleBookmark()
                        }
                    }) {
                        Label(
                            isBookmarked ? "Remove Bookmark" : "Bookmark",
                            systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                        )
                    }
                    .disabled(isBookmarking)

                    Divider()

                    // Translate post (placeholder for future implementation)
                    Button(action: {
                        translatePost()
                    }) {
                        Label("Translate", systemImage: "character.bubble")
                    }

                    // Report post
                    Button(action: {
                        reportPost()
                    }) {
                        Label("Report Post", systemImage: "exclamationmark.triangle")
                    }

                    // Block user
                    Button(action: {
                        blockUser()
                    }) {
                        Label("Block @\(post.author.handle)", systemImage: "person.slash")
                    }

                    // Mute user
                    Button(action: {
                        muteUser()
                    }) {
                        Label("Mute @\(post.author.handle)", systemImage: "speaker.slash")
                    }

                    Divider()

                    // View profile
                    Button(action: {
                        viewProfile()
                    }) {
                        Label("View Profile", systemImage: "person.circle")
                    }

                    // View in thread
                    if post.isReplyTo || post.hasReply {
                        Button(action: {
                            viewInThread()
                        }) {
                            Label("View Thread", systemImage: "bubble.left.and.bubble.right")
                        }
                    }

                    // Conditional actions based on post state
                    if dataController.isLiked {
                        Button(action: {
                            Task {
                                await dataController.toggleLike()
                            }
                        }) {
                            Label("Unlike", systemImage: "heart.slash")
                        }
                    }

                    if dataController.isReposted {
                        Button(action: {
                            Task {
                                await dataController.toggleRepost()
                            }
                        }) {
                            Label("Remove Repost", systemImage: "arrow.2.squarepath.slash")
                        }
                    }

                    // Delete post option for own posts
                    if isOwnPost {
                        Divider()
                        Button(action: {
                            Task {
                                await deletePost()
                            }
                        }) {
                            Label("Delete Post", systemImage: "trash")
                        }
                        .foregroundColor(.red)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.themePrimary)
            }
        }
        .buttonStyle(.plain)
        .labelStyle(.customSpacing(4))
        .font(.callout)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .onAppear {
            bookmarkService = BookmarkService(client: client)
            Task {
                await checkBookmarkStatus()
            }
        }
    }

    // MARK: - Action Methods

    private func sharePost() {
        let postText = post.content
        let postLink =
            "https://bsky.app/profile/\(post.author.handle)/post/\(post.uri.components(separatedBy: "/").last ?? "")"

        let activityVC = UIActivityViewController(
            activityItems: [postText, postLink],
            applicationActivities: nil
        )

        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }

    private func copyPostText() {
        UIPasteboard.general.string = post.content
        showToast(message: "Text copied to clipboard")
    }

    private func copyPostLink() {
        let postLink =
            "https://bsky.app/profile/\(post.author.handle)/post/\(post.uri.components(separatedBy: "/").last ?? "")"
        UIPasteboard.general.string = postLink
        showToast(message: "Link copied to clipboard")
    }

    private func toggleBookmark() async {
        guard let bookmarkService = bookmarkService else { return }
        
        isBookmarking = true
        
        do {
            if isBookmarked {
                try await bookmarkService.removeBookmark(for: post)
                isBookmarked = false
                showToast(message: "Bookmark removed")
            } else {
                try await bookmarkService.createBookmark(for: post)
                isBookmarked = true
                showToast(message: "Post bookmarked")
            }
        } catch {
            showToast(message: "Failed to update bookmark")
            #if DEBUG
            print("PostRowActionsView: Bookmark error: \(error)")
            #endif
        }
        
        isBookmarking = false
    }
    
    private func checkBookmarkStatus() async {
        guard let bookmarkService = bookmarkService else { return }
        
        do {
            isBookmarked = try await bookmarkService.isBookmarked(post)
        } catch {
            #if DEBUG
            print("PostRowActionsView: Failed to check bookmark status: \(error)")
            #endif
        }
    }

    private func translatePost() {
        router.presentedSheet = .translate(post: post)
    }

    private func reportPost() {
        // Show report options
        let alert = UIAlertController(
            title: "Report Post",
            message: "Why are you reporting this post?",
            preferredStyle: .actionSheet
        )

        let reasons = [
            "Spam",
            "Harassment or bullying",
            "False information",
            "Violence or threats",
            "Inappropriate content",
            "Other",
        ]

        for reason in reasons {
            alert.addAction(
                UIAlertAction(title: reason, style: .default) { _ in
                    Task {
                        await self.submitReport(reason: reason)
                    }
                })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        {
            window.rootViewController?.present(alert, animated: true)
        }
    }

    private func submitReport(reason: String) async {
        // First, try to submit the report to Bluesky
        do {
            // Attempt to use ATProtoKit's reporting functionality if available
            try await submitBlueskyReport(reason: reason)

            await MainActor.run {
                self.showToast(message: "Post reported successfully for: \(reason)")
            }
        } catch {
            // If Bluesky reporting fails, fall back to local reporting
            await MainActor.run {
                self.showToast(message: "Report submitted locally for: \(reason)")
                print("Bluesky reporting failed: \(error). Using local fallback.")
            }

            // Store report locally for future reference
            await storeLocalReport(reason: reason)
        }
    }

    private func submitBlueskyReport(reason: String) async throws {
        // Get the client from the PostContext
        let client = dataController.getClient()
        
        // Create reporting service and submit the report
        let reportingService = ReportingService(client: client)
        try await reportingService.reportPost(
            uri: post.uri,
            cid: post.cid,
            reason: reason
        )
    }

    private func mapToBlueskyReason(_ uiReason: String) -> String {
        // Map our UI reasons to Bluesky's internal reporting reasons
        switch uiReason {
        case "Spam":
            return "com.atproto.moderation.defs#reasonSpam"
        case "Harassment or bullying":
            return "com.atproto.moderation.defs#reasonHarassment"
        case "False information":
            return "com.atproto.moderation.defs#reasonMisleading"
        case "Violence or threats":
            return "com.atproto.moderation.defs#reasonViolence"
        case "Inappropriate content":
            return "com.atproto.moderation.defs#reasonSexual"
        case "Other":
            return "com.atproto.moderation.defs#reasonOther"
        default:
            return "com.atproto.moderation.defs#reasonOther"
        }
    }

    private func storeLocalReport(reason: String) async {
        // Store the report locally for future reference
        let report = LocalReport(
            postURI: post.uri,
            postCID: post.cid,
            authorHandle: post.author.handle,
            reason: reason,
            timestamp: Date()
        )

        // Add to UserDefaults for now (could be moved to Core Data later)
        let defaults = UserDefaults.standard
        var reports = defaults.array(forKey: "localReports") as? [[String: Any]] ?? []

        let reportDict: [String: Any] = [
            "postURI": report.postURI,
            "postCID": report.postCID,
            "authorHandle": report.authorHandle,
            "reason": report.reason,
            "timestamp": report.timestamp.timeIntervalSince1970,
        ]

        reports.append(reportDict)
        defaults.set(reports, forKey: "localReports")
    }

    private func blockUser() {
        Task {
            await performBlockUser()
        }
    }

    private func muteUser() {
        Task {
            await performMuteUser()
        }
    }

    private func performBlockUser() async {
        do {
            // Get the client from the PostContext
            let client = dataController.getClient()

            // Use the actual Bluesky blocking API
            let blockURI = try await client.blueskyClient.createBlockRecord(
                ofType: .actorBlock(actorDID: post.author.did)
            )
            
            // Also update local blocking service
            BlockedUsersService.shared.blockUser(did: post.author.did, handle: post.author.handle)

            await MainActor.run {
                self.showToast(message: "User @\(post.author.handle) blocked successfully")
            }
            
            #if DEBUG
            print("Successfully blocked user \(post.author.handle) with URI: \(blockURI.recordURI)")
            #endif

        } catch {
            // Fall back to local blocking if Bluesky API fails
            print("Bluesky blocking API failed: \(error). Using local fallback.")

            BlockedUsersService.shared.blockUser(did: post.author.did, handle: post.author.handle)

            await MainActor.run {
                self.showToast(
                    message: "User @\(post.author.handle) blocked locally (will sync when API is available)"
                )
            }
        }
    }

    private func performMuteUser() async {
        do {
            // Get the client from the PostContext
            let client = dataController.getClient()

            // Use the actual Bluesky muting API
            try await client.protoClient.muteActor(post.author.did)
            
            // Also update local muting service
            MutedUsersService.shared.muteUser(did: post.author.did, handle: post.author.handle)

            await MainActor.run {
                self.showToast(message: "User @\(post.author.handle) muted successfully")
            }
            
            #if DEBUG
            print("Successfully muted user \(post.author.handle)")
            #endif

        } catch {
            // Fall back to local muting if Bluesky API fails
            print("Bluesky muting API failed: \(error). Using local fallback.")

            MutedUsersService.shared.muteUser(did: post.author.did, handle: post.author.handle)

            await MainActor.run {
                self.showToast(
                    message: "User @\(post.author.handle) muted locally (will sync when API is available)"
                )
            }
        }
    }

    private func viewProfile() {
        router[currentTab].append(.profile(post.author))
    }

    private func viewInThread() {
        router[currentTab].append(.post(post))
    }

    private func showToast(message: String) {
        // Simple toast notification using UIKit
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true

        // Get the window to present the toast
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        {
            let windowSize = window.frame.size
            let toastSize = CGSize(width: 200, height: 35)
            let toastX = (windowSize.width - toastSize.width) / 2
            let toastY = windowSize.height - 100

            toastLabel.frame = CGRect(
                x: toastX, y: toastY, width: toastSize.width, height: toastSize.height)
            window.addSubview(toastLabel)

            // Animate the toast
            UIView.animate(
                withDuration: 2.0, delay: 0.1, options: .curveEaseOut,
                animations: {
                    toastLabel.alpha = 0.0
                },
                completion: { _ in
                    toastLabel.removeFromSuperview()
                })
        }
    }

    private func deletePost() async {
        do {
            // Get the client from the PostContext
            let client = dataController.getClient()

            // Delete the post using ATProtoKit
            try await client.blueskyClient.deleteRecord(.recordURI(atURI: post.uri))

            await MainActor.run {
                self.showToast(message: "Post deleted successfully")
            }

            // TODO: Refresh the feed or remove the post from the UI
            // This would require a callback or notification to the parent view

        } catch {
            await MainActor.run {
                self.showToast(message: "Failed to delete post: \(error.localizedDescription)")
            }
        }
    }

}

// MARK: - Supporting Types

private struct LocalReport {
    let postURI: String
    let postCID: String
    let authorHandle: String
    let reason: String
    let timestamp: Date
}

private enum ReportError: Error, LocalizedError {
    case clientNotAvailable
    case blueskyReportingNotAvailable

    var errorDescription: String? {
        switch self {
        case .clientNotAvailable:
            return "Client not available for reporting"
        case .blueskyReportingNotAvailable:
            return "Bluesky reporting API not yet available"
        }
    }
}
