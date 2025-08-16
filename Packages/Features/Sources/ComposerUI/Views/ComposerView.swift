import ATProtoKit
import Client
import DesignSystem
import Models
import SwiftUI

public struct ComposerView: View {
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

  public init(mode: ComposerMode) {
    self.mode = mode
  }

  public var body: some View {
    NavigationStack {
      ComposerTextEditorView(text: $text, selection: $selection, sendState: sendState)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
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
extension ComposerView {
  private func sendPost() async {
    guard canSendPost else { return }

    sendState = .loading
    do {
      switch mode {
      case .newPost:
        _ = try await client.blueskyClient.createPostRecord(text: String(text.characters))
      case .reply:
        // TODO: Create replyRef
        _ = try await client.blueskyClient.createPostRecord(text: String(text.characters))
      }
      dismiss()
    } catch {
      sendState = .error("Failed to send post: \(error.localizedDescription)")
    }
  }
}
