import Models
import SwiftUI

public struct PostEngagementDetailsView: View {
  let post: PostItem

  @State private var showingLikesSheet = false
  @State private var showingRepostsSheet = false

  public init(post: PostItem) {
    self.post = post
  }

  public var body: some View {
    VStack(spacing: 6) {
      // Likes section
      if post.likeCount > 0 {
        Button(action: {
          showingLikesSheet = true
        }) {
          HStack(spacing: 8) {
            Image(systemName: "heart.fill")
              .font(.caption)
              .foregroundStyle(.red)
            
            Text("\(post.likeCount) \(post.likeCount == 1 ? "like" : "likes")")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color(.systemGray6))
          .cornerRadius(8)
        }
        .buttonStyle(.plain)
      }

      // Reposts section
      if post.repostCount > 0 {
        Button(action: {
          showingRepostsSheet = true
        }) {
          HStack(spacing: 8) {
            Image(systemName: "arrow.2.squarepath")
              .font(.caption)
              .foregroundStyle(.blue)
            
            Text("\(post.repostCount) \(post.repostCount == 1 ? "repost" : "reposts")")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color(.systemGray6))
          .cornerRadius(8)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 8)
    .sheet(isPresented: $showingLikesSheet) {
      PostLikesSheet(post: post)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showingRepostsSheet) {
      PostRepostsSheet(post: post)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
  }
}
