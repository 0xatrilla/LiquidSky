@preconcurrency import ATProtoKit
import DesignSystem
import Models
import Client
import SwiftUI
import User

public struct PostListView: View {
  let datasource: PostsListViewDatasource
  @State private var state: PostsListViewState = .uninitialized
  
  @Environment(PostFilterService.self) private var postFilterService

  public var body: some View {
    List {
      switch state {
      case .loading, .uninitialized:
        placeholderView
      case let .loaded(posts, cursor):
        ForEach(filteredPosts(posts)) { post in
          PostRowView(post: post)
        }
        if cursor != nil {
          nextPageView
        }
      case let .error(error):
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 48))
            .foregroundStyle(.red)
          
          Text("Error Loading Feed")
            .font(.title2)
            .fontWeight(.semibold)
          
          Text(error.localizedDescription)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
          
          Button("Try Again") {
            Task {
              state = .loading
              state = await datasource.loadPosts(with: state)
            }
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .navigationTitle(datasource.title)
    .screenContainer()
    .task {
      if case .uninitialized = state {
        state = .loading
        state = await datasource.loadPosts(with: state)
      }
    }
    .refreshable {
      state = .loading
      state = await datasource.loadPosts(with: state)
    }
  }
  
  private func filteredPosts(_ posts: [PostItem]) -> [PostItem] {
    return postFilterService.filterPosts(posts)
  }

  private var nextPageView: some View {
    HStack {
      ProgressView()
    }
    .task {
      state = await datasource.loadPosts(with: state)
    }
  }

  private var placeholderView: some View {
    ForEach(PostItem.placeholders) { post in
      PostRowView(post: post)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }
  }
}

// MARK: - Data
extension PostListView {
  public static func processFeed(_ feed: [AppBskyLexicon.Feed.FeedViewPostDefinition]) -> [PostItem]
  {
    var postItems: [PostItem] = []
    var processedCount = 0

    func insert(post: AppBskyLexicon.Feed.PostViewDefinition, hasReply: Bool) {
      guard !postItems.contains(where: { $0.uri == post.postItem.uri }) else { return }
      
      var item = post.postItem
      item.hasReply = hasReply
      postItems.append(item)
      processedCount += 1
    }

    for (index, post) in feed.enumerated() {
      print("Processing feed item \(index): \(post.post.postItem.uri)")
      
      if let reply = post.reply {
        switch reply.root {
        case let .postView(post):
          insert(post: post, hasReply: true)

          switch reply.parent {
          case let .postView(parent):
            insert(post: parent, hasReply: true)
          default:
            break
          }
        default:
          break
        }
      }
      insert(post: post.post, hasReply: false)
    }
    
    print("Feed processing complete: \(processedCount) posts processed")
    return postItems
  }
}
