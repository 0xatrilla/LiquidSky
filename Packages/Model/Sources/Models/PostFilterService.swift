import Foundation
import Models

// MARK: - Post Filter Service
@MainActor
@Observable
public final class PostFilterService {
    public static let shared = PostFilterService()
    
    private let settingsService = SettingsService.shared
    
    private init() {}
    
    // MARK: - Post Filtering
    public func filterPosts(_ posts: [PostItem]) -> [PostItem] {
        posts.filter { post in
            // Filter out reposts if disabled
            if !settingsService.showReposts && post.isRepost {
                return false
            }
            
            // Filter out replies if disabled
            if !settingsService.showReplies && post.hasReply {
                return false
            }
            
            // Filter out sensitive content if disabled
            if !settingsService.showSensitiveContent && post.isSensitive {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Individual Post Checks
    public func shouldShowPost(_ post: PostItem) -> Bool {
        // Check repost setting
        if !settingsService.showReposts && post.isRepost {
            return false
        }
        
        // Check reply setting
        if !settingsService.showReplies && post.hasReply {
            return false
        }
        
        // Check sensitive content setting
        if !settingsService.showSensitiveContent && post.isSensitive {
            return false
        }
        
        return true
    }
    
    // MARK: - Privacy Controls
    public func canMentionUser(_ userId: String) -> Bool {
        // This would integrate with the user's privacy settings
        // For now, return the global setting
        return settingsService.allowMentions
    }
    
    public func canReplyToPost(_ post: PostItem) -> Bool {
        // This would integrate with the post author's privacy settings
        // For now, return the global setting
        return settingsService.allowReplies
    }
    
    public func canQuotePost(_ post: PostItem) -> Bool {
        // This would integrate with the post author's privacy settings
        // For now, return the global setting
        return settingsService.allowQuotes
    }
}

// MARK: - Post Item Extensions
extension PostItem {
    /// Whether this post is a repost
    public var isRepost: Bool {
        // Check if this is a repost based on the post content or metadata
        // This is a placeholder - implement based on your actual post structure
        return false // TODO: Implement actual repost detection
    }
    
    /// Whether this post contains sensitive content
    public var isSensitive: Bool {
        // Check if this post is marked as sensitive
        // This is a placeholder - implement based on your actual post structure
        return false // TODO: Implement actual sensitive content detection
    }
}
