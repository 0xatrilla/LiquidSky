import Foundation
import FoundationModels

@MainActor
@Observable
public class FeedSummaryService {
    public static let shared = FeedSummaryService()
    private var languageModelSession: LanguageModelSession?
    
    private init() {
        // Initialize Apple Intelligence session if available
        if #available(iOS 18.1, *) {
            do {
                languageModelSession = LanguageModelSession {
                    """
                    You are an expert social media content summarizer. Your task is to create concise, insightful summaries of social media posts from the last 12 hours.
                    
                    Focus on:
                    - Key themes and topics being discussed
                    - Notable conversations or trending subjects  
                    - Important announcements or news
                    - Community sentiment and reactions
                    
                    Keep summaries engaging and informative while being concise. Highlight the most interesting and relevant content.
                    """
                }
            } catch {
                print("Failed to initialize Apple Intelligence: \(error)")
                languageModelSession = nil
            }
        }
    }
    
    public func summarizeFeedPosts(_ posts: [Any], feedName: String) async -> String {
        // Filter posts from last 12 hours using reflection
        let twelveHoursAgo = Date().addingTimeInterval(-12 * 60 * 60)
        let recentPosts = posts.filter { post in
            if let indexedAt = getIndexedAt(from: post) {
                return indexedAt >= twelveHoursAgo
            }
            return false
        }
        
        guard !recentPosts.isEmpty else {
            return "No posts found in the last 12 hours for \(feedName)."
        }
        
        // Try Apple Intelligence first, fallback to basic summary
        if #available(iOS 18.1, *), let session = languageModelSession {
            return await generateAISummary(posts: recentPosts, feedName: feedName, session: session)
        } else {
            return generateBasicSummary(posts: recentPosts, feedName: feedName)
        }
    }
    
    private func getIndexedAt(from post: Any) -> Date? {
        let mirror = Mirror(reflecting: post)
        for child in mirror.children {
            if child.label == "indexedAt", let date = child.value as? Date {
                return date
            }
        }
        return nil
    }
    
    private func getPostContent(from post: Any) -> String? {
        let mirror = Mirror(reflecting: post)
        for child in mirror.children {
            if child.label == "content", let content = child.value as? String {
                return content
            }
        }
        return nil
    }
    
    private func getAuthorHandle(from post: Any) -> String? {
        let mirror = Mirror(reflecting: post)
        for child in mirror.children {
            if child.label == "author" {
                let authorMirror = Mirror(reflecting: child.value)
                for authorChild in authorMirror.children {
                    if authorChild.label == "handle", let handle = authorChild.value as? String {
                        return handle
                    }
                }
            }
        }
        return nil
    }
    
    private func getAuthorDisplayName(from post: Any?) -> String? {
        guard let post = post else { return nil }
        let mirror = Mirror(reflecting: post)
        
        for child in mirror.children {
            if child.label == "author" {
                let authorMirror = Mirror(reflecting: child.value)
                for authorChild in authorMirror.children {
                    if authorChild.label == "displayName",
                       let displayName = authorChild.value as? String,
                       !displayName.isEmpty {
                        return displayName
                    }
                }
            }
        }
        return nil
    }
    
    @available(iOS 18.1, *)
    private func generateAISummary(posts: [Any], feedName: String, session: LanguageModelSession) async -> String {
        // Prepare post content for AI analysis
        let postContents = posts.compactMap { post -> String? in
            guard let content = getPostContent(from: post),
                  let handle = getAuthorHandle(from: post) else { return nil }
            
            let displayName = getAuthorDisplayName(from: post) ?? handle
            let timeAgo = getIndexedAt(from: post).map { formatRelativeTime($0) } ?? "unknown time"
            
            return "@\(handle) (\(displayName)) - \(timeAgo):\n\(content)\n"
        }
        
        let combinedContent = postContents.prefix(50).joined(separator: "\n---\n")
        
        let prompt = """
        Please analyze and summarize the following social media posts from the "\(feedName)" feed over the last 12 hours.
        
        Posts (\(posts.count) total):
        \(combinedContent)
        
        Create a concise, engaging summary that captures:
        1. Main themes and topics being discussed
        2. Notable conversations or trending subjects
        3. Key insights or interesting points raised
        4. Overall community sentiment
        
        Keep it informative but conversational, as if explaining to a friend what they missed.
        """
        
        do {
            let response = try await session.respond(to: prompt)
            return "**AI-Powered Feed Summary - Last 12 Hours**\n\n\(response.content)\n\n*Summary generated using Apple Intelligence*"
        } catch {
            print("Apple Intelligence summary failed: \(error)")
            // Fallback to basic summary
            return generateBasicSummary(posts: posts, feedName: feedName)
        }
    }
    
    private func generateBasicSummary(posts: [Any], feedName: String) -> String {
        let postCount = posts.count
        let contributors = Set(posts.compactMap { getAuthorHandle(from: $0) })
        let contributorCount = contributors.count
        
        // Group posts by author for better organization
        let postsByAuthor = Dictionary(grouping: posts) { post in
            getAuthorHandle(from: post) ?? "Unknown"
        }
        
        var summary = "**Feed Summary - Last 12 Hours**\n\n"
        summary += "**\(postCount)** posts from **\(contributorCount)** people\n\n"
        
        // Create detailed content summary by author
        let sortedAuthors = postsByAuthor.sorted { $0.value.count > $1.value.count }
        
        for (author, authorPosts) in sortedAuthors.prefix(8) {
            let displayName = getAuthorDisplayName(from: authorPosts.first) ?? author
            summary += "**@\(author)** (\(displayName)):\n"
            
            for post in authorPosts.prefix(3) { // Show up to 3 posts per author
                if let content = getPostContent(from: post) {
                    let truncatedContent = truncateContent(content, maxLength: 120)
                    summary += "• \(truncatedContent)\n"
                }
            }
            
            if authorPosts.count > 3 {
                summary += "• ... and \(authorPosts.count - 3) more posts\n"
            }
            summary += "\n"
        }
        
        if sortedAuthors.count > 8 {
            summary += "... and \(sortedAuthors.count - 8) more contributors\n\n"
        }
        
        let aiAvailability = if #available(iOS 18.1, *) {
            languageModelSession != nil ? "Apple Intelligence available but failed - using fallback summary." : "Apple Intelligence unavailable on this device."
        } else {
            "Requires iOS 18.1+ for Apple Intelligence integration."
        }
        
        summary += "*Basic summary generated. \(aiAvailability)*"
        
        return summary
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func truncateContent(_ content: String, maxLength: Int) -> String {
        if content.count <= maxLength {
            return content
        }
        
        let truncated = String(content.prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        } else {
            return truncated + "..."
        }
    }
}
