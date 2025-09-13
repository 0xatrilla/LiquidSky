import Client
import Models
import SwiftUI

public struct FeedView: View {
  @Environment(BSkyClient.self) var client
  @Environment(PostContextProvider.self) var postDataControllerProvider
  @Environment(PostFilterService.self) var postFilterService

  public init() {}

  public var body: some View {
    NavigationStack {
      FeedsListView()
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
    }
  }
}
