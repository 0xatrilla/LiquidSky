import SwiftUI

struct FeedsListDividerView: View {
  var body: some View {
    HStack {
      Rectangle()
        .fill(
          LinearGradient(
            colors: [.blueskyPrimary, .blueskySecondary],
            startPoint: .leading,
            endPoint: .trailing)
        )
        .frame(height: 1)
        .frame(maxWidth: .infinity)
    }
    .listRowSeparator(.hidden)
    .listRowInsets(.init())
  }
}
