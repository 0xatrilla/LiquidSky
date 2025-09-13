import DesignSystem
import Foundation
import Nuke
import NukeUI
import SwiftUI

public struct FullScreenProfilePictureView: View {
  @Environment(\.dismiss) private var dismiss

  let imageURL: URL
  let namespace: Namespace.ID

  @State private var isSaved: Bool = false
  @GestureState private var zoom = 1.0

  public init(imageURL: URL, namespace: Namespace.ID) {
    self.imageURL = imageURL
    self.namespace = namespace
  }

  public var body: some View {
    NavigationStack {
      GeometryReader { geometry in
        LazyImage(
          request: .init(
            url: imageURL,
            priority: .veryHigh)
        ) { state in
          if let image = state.image {
            image
              .resizable()
              .scaledToFit()
              .scaleEffect(zoom)
              .gesture(
                MagnifyGesture()
                  .updating($zoom) { value, gestureState, transaction in
                    gestureState = value.magnification
                  }
              )
          } else {
            RoundedRectangle(cornerRadius: 8)
              .fill(.thinMaterial)
              .overlay(
                ProgressView()
                  .scaleEffect(1.5)
              )
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .foregroundStyle(.primary)
          }
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
          shareButton
        }
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTransition(.zoom(sourceID: "profilePicture", in: namespace))
  }

  private var shareButton: some View {
    ShareLink(item: imageURL) {
      Image(systemName: "square.and.arrow.up")
        .foregroundStyle(.primary)
    }
  }
}
