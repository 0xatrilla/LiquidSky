import Client
import DesignSystem
import FeedUI
import Models
import SwiftUI

public struct FeedsListSearchField: View {
  @Binding var searchText: String
  @Binding var isInSearch: Bool
  var isSearchFocused: FocusState<Bool>.Binding

  @StateObject private var searchService: UnifiedSearchService

  public init(
    searchText: Binding<String>,
    isInSearch: Binding<Bool>,
    isSearchFocused: FocusState<Bool>.Binding,
    client: BSkyClient
  ) {
    _searchText = searchText
    _isInSearch = isInSearch
    self.isSearchFocused = isSearchFocused
    self._searchService = StateObject(wrappedValue: UnifiedSearchService(client: client))
  }

  public var body: some View {
    GlassEffectContainer {
      HStack {
        HStack {
          Image(systemName: "magnifyingglass")
          TextField("Search users, posts, feeds...", text: $searchText)
            .focused(isSearchFocused)
            .allowsHitTesting(isInSearch)
            .onChange(of: searchText) { _, newValue in
              if !newValue.isEmpty {
                Task {
                  await searchService.search(query: newValue)
                }
              } else {
                searchService.clearSearch()
              }
            }
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
              searchService.clearSearch()
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
