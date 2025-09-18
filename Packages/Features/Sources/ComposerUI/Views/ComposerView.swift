import ATProtoKit
import Client
import DesignSystem
import Models
import SwiftUI

// Modern (iOS 26+) composer implementation used by the unified ComposerView
@available(iOS 26.0, *)
public struct ModernComposerInnerView: View {
  @Environment(BSkyClient.self) private var client
  @Environment(\.dismiss) private var dismiss
  @Environment(PostFilterService.self) private var postFilterService

  @State var presentationDetent: PresentationDetent = .large

  @State private var text = AttributedString()
  @State private var selection = AttributedTextSelection()

  @State private var sendState: ComposerSendState = .idle

  let mode: ComposerMode

  private var title: String {
    switch mode {
    case .newPost:
      return "New Post"
    case .reply(let post):
      return "Reply to \(post.author.displayName ?? post.author.handle)"
    }
  }

  private var canSendPost: Bool {
    switch mode {
    case .newPost:
      return true
    case .reply(let post):
      return postFilterService.canReplyToPost(post)
    }
  }
  
  private var replyPost: PostItem? {
    switch mode {
    case .newPost:
      return nil
    case .reply(let post):
      return post
    }
  }

  public init(mode: ComposerMode) {
    self.mode = mode
  }

  public var body: some View {
    NavigationStack {
      ComposerTextEditorView(
        text: $text, 
        selection: $selection, 
        sendState: sendState,
        post: replyPost
      )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
        .toolbar {
          ComposerToolbarView(
            text: $text,
            sendState: $sendState
          )
          ComposerHeaderView(
            sendState: $sendState,
            onSend: sendPost
          )
        }
        .disabled(!canSendPost)
        .overlay {
          if !canSendPost {
            VStack(spacing: 16) {
              Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

              Text("Cannot Reply")
                .font(.title2)
                .fontWeight(.semibold)

              Text("This user has disabled replies to their posts")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
        }
    }
    .presentationDetents([.height(200), .large], selection: $presentationDetent)
    .presentationBackgroundInteraction(.enabled)
  }
}

// MARK: - Network
@available(iOS 26.0, *)
extension ModernComposerInnerView {
  private func sendPost() async {
    guard canSendPost else { return }

    sendState = .loading
    do {
      switch mode {
      case .newPost:
        _ = try await client.blueskyClient.createPostRecord(text: String(text.characters))
      case .reply(let post):
        // Create proper reply reference
        // For replies, the parent is the post being replied to
        // The root is either the original post in the thread or the same as parent for top-level replies
        let parentRef = ComAtprotoLexicon.Repository.StrongReference(
          recordURI: post.uri,
          cidHash: post.cid
        )

        // If the post being replied to is itself a reply, use its root
        // Otherwise, use the post itself as the root
        let rootRef: ComAtprotoLexicon.Repository.StrongReference
        if let existingReplyRef = post.replyRef {
          // Use reflection to extract the root URI and CID
          let mirror = Mirror(reflecting: existingReplyRef)
          if let rootChild = mirror.children.first(where: { $0.label == "root" }) {
            let rootMirror = Mirror(reflecting: rootChild.value)
            var rootURI = post.uri
            var rootCID = post.cid

            for child in rootMirror.children {
              if child.label == "recordURI", let uri = child.value as? String {
                rootURI = uri
              } else if child.label == "cidHash", let cid = child.value as? String {
                rootCID = cid
              }
            }
            rootRef = ComAtprotoLexicon.Repository.StrongReference(
              recordURI: rootURI,
              cidHash: rootCID
            )
          } else {
            rootRef = parentRef
          }
        } else {
          // This is a top-level post, so root = parent
          rootRef = parentRef
        }

        let replyRef = AppBskyLexicon.Feed.PostRecord.ReplyReference(
          root: rootRef,
          parent: parentRef
        )

        _ = try await client.blueskyClient.createPostRecord(
          text: String(text.characters),
          replyTo: replyRef
        )
      }
      dismiss()
    } catch {
      sendState = .error("Failed to send post: \(error.localizedDescription)")
    }
  }
}
