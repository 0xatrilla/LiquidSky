import Models
import SwiftUI

public struct RepostIndicatorView: View {
  let repostedBy: Profile

  public init(repostedBy: Profile) {
    self.repostedBy = repostedBy
  }

  public var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "arrow.2.squarepath")
        .font(.caption2)
        .foregroundColor(.secondary)

      Text("\(repostedBy.displayName ?? repostedBy.handle) reposted")
        .font(.caption)
        .foregroundColor(.secondary)
        .fontWeight(.medium)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(8)
  }
}

#Preview {
  VStack(spacing: 20) {
    RepostIndicatorView(
      repostedBy: Profile(
        did: "did:example:123",
        handle: "jessiegender",
        displayName: "Jessie Gender",
        avatarImageURL: nil
      ))

    RepostIndicatorView(
      repostedBy: Profile(
        did: "did:example:456",
        handle: "adriaan",
        displayName: "Adriaan",
        avatarImageURL: nil
      ))
  }
  .padding()
}
