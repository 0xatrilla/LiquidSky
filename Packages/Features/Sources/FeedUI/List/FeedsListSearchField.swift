import Client
import DesignSystem
import Models
import SwiftUI

public struct FeedsListSearchField: View {
  @Binding var searchText: String
  @Binding var isInSearch: Bool
  var isSearchFocused: FocusState<Bool>.Binding

  public init(
    searchText: Binding<String>,
    isInSearch: Binding<Bool>,
    isSearchFocused: FocusState<Bool>.Binding,
    client: BSkyClient
  ) {
    _searchText = searchText
    _isInSearch = isInSearch
    self.isSearchFocused = isSearchFocused
  }

  public var body: some View {
    GlassEffectContainer {
      HStack {
        HStack {
          Image(systemName: "magnifyingglass")
          TextField("Search feeds...", text: $searchText)
            .focused(isSearchFocused)
            .allowsHitTesting(isInSearch)
        }
        .frame(maxWidth: isInSearch ? .infinity : 100)
        .padding()
        .glassEffect(in: Capsule())

        if isInSearch {
          Button {
            withAnimation {
              isInSearch.toggle()
              isSearchFocused.wrappedValue = false
              searchText = ""
            }
          } label: {
            Image(systemName: "xmark")
              .frame(width: 50, height: 50)
              .foregroundStyle(.blue)
              .glassEffect(in: Circle())
          }
        }
      }
    }
  }
}
