import DesignSystem
import SwiftUI

struct FeedsListErrorView: View {
  let error: Error
  let retry: () async -> Void

  var body: some View {
    VStack {
      Text("Error: \(error.localizedDescription)")
        .foregroundColor(.red)
      Button {
        Task {
          await retry()
        }
      } label: {
        Text("Retry")
          .padding()
      }
      .modifier(ButtonStyleModifier())
    }
    .listRowSeparator(.hidden)
  }
}

struct ButtonStyleModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.buttonStyle(.glass)
    } else {
      content.buttonStyle(.bordered)
    }
  }
}
