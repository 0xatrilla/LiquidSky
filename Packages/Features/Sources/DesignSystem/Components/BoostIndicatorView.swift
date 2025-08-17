import Models
import SwiftUI

public struct BoostIndicatorView: View {
  let repostCount: Int
  let isReposted: Bool

  public init(repostCount: Int, isReposted: Bool = false) {
    self.repostCount = repostCount
    self.isReposted = isReposted
  }

  public var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "arrow.2.squarepath")
        .font(.caption2)
        .foregroundColor(.secondary)

      if isReposted {
        Text("You boosted")
          .font(.caption)
          .foregroundColor(.secondary)
      } else if repostCount > 0 {
        Text("\(repostCount) boost\(repostCount == 1 ? "" : "s")")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 4)
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(12)
  }
}

#Preview {
  VStack(spacing: 20) {
    BoostIndicatorView(repostCount: 5)
    BoostIndicatorView(repostCount: 1)
    BoostIndicatorView(repostCount: 0, isReposted: true)
  }
  .padding()
  .background(Color.gray.opacity(0.1))
}
