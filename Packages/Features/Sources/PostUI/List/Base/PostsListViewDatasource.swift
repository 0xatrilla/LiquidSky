import Models
import SwiftUI

@MainActor
public protocol PostsListViewDatasource {
  var title: String { get }
  func loadPosts(with state: PostsListViewState) async throws -> PostsListViewState
}
