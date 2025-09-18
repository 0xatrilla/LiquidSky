import AppRouter
import Client
import DesignSystem
import Destinations
import Models
import SwiftUI
import User

public struct BookmarksListView: View {
    @Environment(BSkyClient.self) var client
    @Environment(AppRouter.self) var router
    @State private var bookmarkedPosts: [PostItem] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var bookmarkService: BookmarkService?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            if isLoading && bookmarkedPosts.isEmpty {
                loadingView
            } else if let error = error {
                errorView(error: error)
            } else if bookmarkedPosts.isEmpty {
                emptyStateView
            } else {
                bookmarksContentView
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadBookmarks()
        }
        .refreshable {
            await loadBookmarks()
        }
        .onAppear {
            bookmarkService = BookmarkService(client: client)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading bookmarks...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.red)
            
            Text("Something went wrong")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                Task {
                    await loadBookmarks()
                }
            }) {
                Text("Try Again")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No Bookmarks Yet")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Posts you bookmark will appear here and sync across all your Bluesky apps.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Bookmarks Content View
    private var bookmarksContentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(bookmarkedPosts) { post in
                    PostRowView(post: post, showEngagementDetails: true)
                        .onTapGesture {
                            router[.bookmarks].append(.post(post))
                        }
                }
            }
        }
    }
    
    // MARK: - Load Bookmarks
    private func loadBookmarks() async {
        guard let bookmarkService = bookmarkService else { return }
        
        isLoading = true
        error = nil
        
        do {
            bookmarkedPosts = try await bookmarkService.getBookmarks()
        } catch {
            self.error = error
            #if DEBUG
            print("BookmarksListView: Failed to load bookmarks: \(error)")
            #endif
        }
        
        isLoading = false
    }
}

// MARK: - Post Row View
private struct PostRowView: View {
    let post: PostItem
    let showEngagementDetails: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author info
            HStack {
                AsyncImage(url: post.author.avatarImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 32, height: 32)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.displayName ?? post.author.handle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("@\(post.author.handle)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(post.indexedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Post content
            Text(post.content)
                .font(.body)
            
            // Engagement details
            if showEngagementDetails {
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                        Text("\(post.likeCount)")
                    }
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.2.squarepath")
                        Text("\(post.repostCount)")
                    }
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("\(post.replyCount)")
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .font(.caption)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        BookmarksListView()
            .environment(AppRouter(initialTab: .bookmarks))
    }
}
