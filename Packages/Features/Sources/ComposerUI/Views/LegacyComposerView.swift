import ATProtoKit
import Client
import Destinations
import Models
import SwiftUI

// Simple fallback composer for iOS < 26
public struct LegacyComposerView: View {
  @Environment(BSkyClient.self) private var client
  @Environment(\.dismiss) private var dismiss
  @Environment(PostFilterService.self) private var postFilterService

  @State private var text: AttributedString = ""
  @State private var sendState: ComposerSendState = .idle
  @State private var errorMessage: String?

  let mode: ComposerMode

  public init(mode: ComposerMode) { self.mode = mode }

  // Convenience initializer to accept routing type directly
  public init(mode: ComposerDestinationMode) {
    switch mode {
    case .newPost:
      self.mode = .newPost
    case .reply(let post):
      self.mode = .reply(post)
    }
  }

  public var body: some View {
    NavigationStack {
      VStack(spacing: 12) {
        TextEditor(
          text: Binding(
            get: { String(text.characters) },
            set: { newValue in text = AttributedString(newValue) }
          )
        )
        .textInputAutocapitalization(.sentences)
        .disableAutocorrection(false)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))

        if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
      }
      .padding()
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ComposerToolbarView(text: $text, sendState: $sendState)
        ComposerHeaderView(sendState: $sendState) { await send() }
      }
    }
  }

  private var title: String {
    switch mode {
    case .newPost: return "New Post"
    case .reply(let post): return "Reply to \(post.author.displayName ?? post.author.handle)"
    }
  }

  private var canSend: Bool {
    switch mode {
    case .newPost: return true
    case .reply(let post): return postFilterService.canReplyToPost(post)
    }
  }

  private func send() async {
    let plain = String(text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
    guard !plain.isEmpty else { return }
    sendState = .loading
    do {
      switch mode {
      case .newPost:
        _ = try await client.blueskyClient.createPostRecord(text: plain)
      case .reply(let post):
        let parentRef = ComAtprotoLexicon.Repository.StrongReference(
          recordURI: post.uri,
          cidHash: post.cid
        )
        let rootRef: ComAtprotoLexicon.Repository.StrongReference = {
          if let reply = post.replyRef {
            let mirror = Mirror(reflecting: reply)
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
              return .init(recordURI: rootURI, cidHash: rootCID)
            }
          }
          return parentRef
        }()
        let replyRef = AppBskyLexicon.Feed.PostRecord.ReplyReference(
          root: rootRef, parent: parentRef)
        _ = try await client.blueskyClient.createPostRecord(text: plain, replyTo: replyRef)
      }
      dismiss()
    } catch {
      errorMessage = "Failed to send: \(error.localizedDescription)"
      sendState = .error(errorMessage ?? "Failed to send")
    }
  }
}
