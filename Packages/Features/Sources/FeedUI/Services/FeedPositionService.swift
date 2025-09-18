import DesignSystem
import Foundation
import Models
import SwiftUI
import UIKit

@MainActor
@Observable
public final class FeedPositionService {
    public private(set) var newPostsCount: Int = 0
    public private(set) var lastSeenPostURI: String?
    public private(set) var hasUnseenPosts: Bool = false

    public static let shared = FeedPositionService()

    private let userDefaults = UserDefaults.standard
    private let lastSeenPostKey = "lastSeenPostURI"
    private let lastSeenTimeKey = "lastSeenPostTime"
    private let newPostsCountKey = "newPostsCount"

    private init() {}

    // MARK: - Public Methods

    public func saveCurrentPosition(topPostURI: String?) {
        guard let topPostURI = topPostURI else { return }

        lastSeenPostURI = topPostURI
        userDefaults.set(topPostURI, forKey: lastSeenPostKey)
        userDefaults.set(Date().timeIntervalSince1970, forKey: lastSeenTimeKey)

        #if DEBUG
            print("FeedPositionService: Saved position - URI: \(topPostURI)")
        #endif
    }

    public func checkForNewPosts(currentPosts: [PostItem]) async {
        guard let lastSeenURI = lastSeenPostURI else {
            // No previous position, so no new posts to count
            newPostsCount = 0
            hasUnseenPosts = false
            return
        }

        // Find the index of the last seen post in current posts
        if let lastSeenIndex = currentPosts.firstIndex(where: { $0.uri == lastSeenURI }) {
            // Count posts above (newer than) the last seen post
            let newPosts = Array(currentPosts.prefix(lastSeenIndex))
            newPostsCount = newPosts.count
            hasUnseenPosts = newPostsCount > 0

            #if DEBUG
                print("FeedPositionService: Found \(newPostsCount) new posts above last seen post")
            #endif
        } else {
            // Last seen post not found, assume all posts are new
            newPostsCount = currentPosts.count
            hasUnseenPosts = currentPosts.count > 0

            #if DEBUG
                print(
                    "FeedPositionService: Last seen post not found, assuming \(currentPosts.count) new posts"
                )
            #endif
        }

        // Save new posts count for persistence
        userDefaults.set(newPostsCount, forKey: newPostsCountKey)
    }

    public func resetNewPostsCount() {
        newPostsCount = 0
        hasUnseenPosts = false
        userDefaults.removeObject(forKey: newPostsCountKey)

        #if DEBUG
            print("FeedPositionService: Reset new posts count")
        #endif
    }

    public func clearPosition() {
        lastSeenPostURI = nil
        newPostsCount = 0
        hasUnseenPosts = false

        userDefaults.removeObject(forKey: lastSeenPostKey)
        userDefaults.removeObject(forKey: lastSeenTimeKey)
        userDefaults.removeObject(forKey: newPostsCountKey)

        #if DEBUG
            print("FeedPositionService: Cleared position data")
        #endif
    }

    // MARK: - Restoration

    public func restoreSavedPosition() {
        if let savedURI = userDefaults.string(forKey: lastSeenPostKey) {
            lastSeenPostURI = savedURI

            // Check if the saved position is still relevant (within 24 hours)
            if let savedTime = userDefaults.object(forKey: lastSeenTimeKey) as? TimeInterval {
                let savedDate = Date(timeIntervalSince1970: savedTime)
                let hoursSinceSaved = Date().timeIntervalSince(savedDate) / 3600

                if hoursSinceSaved > 24 {
                    // Position is too old, clear it
                    clearPosition()
                    return
                }
            }

            // Restore saved new posts count
            newPostsCount = userDefaults.integer(forKey: newPostsCountKey)
            hasUnseenPosts = newPostsCount > 0

            #if DEBUG
                print(
                    "FeedPositionService: Restored position - URI: \(savedURI), New posts: \(newPostsCount)"
                )
            #endif
        }
    }

    // MARK: - Scroll Position Tracking

    public func updateScrollPosition(visiblePosts: [PostItem]) {
        guard !visiblePosts.isEmpty else { return }

        // The first visible post is considered the current position
        let topPost = visiblePosts.first
        saveCurrentPosition(topPostURI: topPost?.uri)

        #if DEBUG
            print(
                "FeedPositionService: Updated scroll position to top post: \(topPost?.uri ?? "nil")"
            )
        #endif
    }

    // MARK: - App Lifecycle

    public func appDidEnterBackground() {
        // Save current position when app goes to background
        #if DEBUG
            print("FeedPositionService: App entering background, saving position")
        #endif
        // Note: The actual position should be saved by the view when it disappears
    }

    public func appWillEnterForeground() {
        // When app comes to foreground, prepare to check for new posts
        #if DEBUG
            print("FeedPositionService: App entering foreground")
        #endif
        restoreSavedPosition()
    }
}

// MARK: - New Posts Indicator View

public struct NewPostsIndicatorView: View {
    private let action: () -> Void
    @Environment(\.managedObjectContext) private var viewContext

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        let feedPositionService = FeedPositionService.shared
        let colorThemeManager = ColorThemeManager.shared

        if feedPositionService.hasUnseenPosts && feedPositionService.newPostsCount > 0 {
            Button(action: action) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.caption)

                    Text("\(feedPositionService.newPostsCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor(for: colorThemeManager))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .scaleEffect(pulseScale(for: feedPositionService))
            .animation(pulseAnimation, value: feedPositionService.newPostsCount)
        }
    }

    private func backgroundColor(for colorThemeManager: ColorThemeManager) -> Color {
        switch colorThemeManager.currentTheme {
        case .bluesky:
            return Color.blueskyPrimary
        case .sunset:
            return Color.sunsetPrimary
        case .forest:
            return Color.forestPrimary
        case .ocean:
            return Color.oceanPrimary
        case .lavender:
            return Color.lavenderPrimary
        case .fire:
            return Color.firePrimary
        }
    }

    private func pulseScale(for feedPositionService: FeedPositionService) -> Double {
        feedPositionService.hasUnseenPosts ? 1.1 : 1.0
    }

    private var pulseAnimation: Animation {
        .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
    }
}
