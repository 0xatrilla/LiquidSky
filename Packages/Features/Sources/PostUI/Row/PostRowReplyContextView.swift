import ATProtoKit
import DesignSystem
import Models
import SwiftUI

public struct PostRowReplyContextView: View {
  let replyRef: AppBskyLexicon.Feed.PostRecord.ReplyReference

  public init(replyRef: AppBskyLexicon.Feed.PostRecord.ReplyReference) {
    self.replyRef = replyRef
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "arrowshape.turn.up.left")
          .font(.caption)
          .foregroundColor(.blueskySecondary)

        Text("Replying to a post")
          .font(.caption)
          .foregroundColor(.secondary)

        Spacer()
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.secondary.opacity(0.05))
    )
  }
}

#Preview {
  Text("Reply Context View Preview")
    .padding()
}
