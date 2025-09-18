import Models
import SwiftUI

@available(iOS 26.0, *)
public struct ComposerPostContextView: View {
    let post: PostItem
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    
    public init(post: PostItem) {
        self.post = post
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "arrowshape.turn.up.left")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Replying to")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("@\(post.author.handle)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Post Content
            VStack(alignment: .leading, spacing: 8) {
                // Author Info
                HStack(spacing: 8) {
                    AsyncImage(url: post.author.avatarImageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.author.displayName ?? post.author.handle)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("@\(post.author.handle)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(formatRelativeTime(post.indexedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Post Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.content)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(isExpanded ? nil : 3)
                        .multilineTextAlignment(.leading)
                    
                    // Show more/less button if content is long
                    if shouldShowExpandButton {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "Show less" : "Show more")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Post Stats (if any)
                if post.replyCount > 0 || post.repostCount > 0 || post.likeCount > 0 {
                    HStack(spacing: 16) {
                        if post.replyCount > 0 {
                            Label("\(post.replyCount)", systemImage: "bubble")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if post.repostCount > 0 {
                            Label("\(post.repostCount)", systemImage: "repeat")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if post.likeCount > 0 {
                            Label("\(post.likeCount)", systemImage: "heart")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Helper Functions
    
    private var shouldShowExpandButton: Bool {
        // Show expand button if content is longer than what would fit in 3 lines
        let words = post.content.components(separatedBy: .whitespacesAndNewlines)
        return words.count > 15 // Rough estimate for 3 lines
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    VStack {
        ComposerPostContextView(
            post: PostItem(
                uri: "at://did:plc:preview/app.bsky.feed.post/preview",
                cid: "preview",
                indexedAt: Date().addingTimeInterval(-3600), // 1 hour ago
                author: Profile(
                    did: "did:plc:preview",
                    handle: "preview.user",
                    displayName: "Preview User",
                    avatarImageURL: nil,
                    description: nil,
                    followersCount: 0,
                    followingCount: 0,
                    postsCount: 0,
                    isFollowing: false,
                    isFollowedBy: false,
                    isBlocked: false,
                    isBlocking: false,
                    isMuted: false
                ),
                content: "This is a sample post that you're replying to. It contains some interesting content that you want to respond to with your own thoughts and opinions.",
                replyCount: 5,
                repostCount: 12,
                likeCount: 42,
                likeURI: nil,
                repostURI: nil,
                replyRef: nil,
                inReplyToHandle: nil,
                repostedBy: nil,
                embed: nil,
                isSensitive: false,
                contentWarning: nil
            )
        )
        
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
