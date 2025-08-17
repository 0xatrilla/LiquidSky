import Client
import DesignSystem
import SwiftUI

public struct FeedsListTitleView: View {
  @Binding var filter: FeedsListFilter
  @Binding var searchText: String
  @Binding var isInSearch: Bool
  var isSearchFocused: FocusState<Bool>.Binding
  @Environment(BSkyClient.self) var client

  public init(
    filter: Binding<FeedsListFilter>,
    searchText: Binding<String>,
    isInSearch: Binding<Bool>,
    isSearchFocused: FocusState<Bool>.Binding
  ) {
    self._filter = filter
    self._searchText = searchText
    self._isInSearch = isInSearch
    self.isSearchFocused = isSearchFocused
  }

  public var body: some View {
    HStack(alignment: .center) {
      // Restored original design - only show "Feeds" title, filter text only in dropdown
      Menu {
        ForEach(FeedsListFilter.allCases) { filterOption in
          Button(action: {
            print("Filter selected: \(filterOption)")
            withAnimation(.easeInOut(duration: 0.2)) {
              self.filter = filterOption
            }
          }) {
            HStack {
              Image(systemName: filterOption.icon)
              Text(filterOption.rawValue)
              if filterOption == filter {
                Image(systemName: "checkmark")
                  .foregroundStyle(.blue)
              }
            }
          }
        }
      } label: {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("Feeds")
              .font(.title)
              .fontWeight(.bold)
              .foregroundStyle(.primary)
          }
          VStack(spacing: 6) {
            Image(systemName: "chevron.up")
            Image(systemName: "chevron.down")
          }
          .imageScale(.large)
          .offset(y: 2)
        }
      }
      .buttonStyle(.plain)
      .offset(x: isInSearch ? -80 : 0)
      .opacity(isInSearch ? 0 : 1)
      .animation(.easeInOut(duration: 0.3), value: isInSearch)

      Spacer()

      FeedsListSearchField(
        searchText: $searchText,
        isInSearch: $isInSearch,
        isSearchFocused: isSearchFocused,
        client: client
      )
      .animation(.easeInOut(duration: 0.3), value: isInSearch)
      .contentShape(Rectangle())
      .onTapGesture {
        withAnimation(.bouncy) {
          isInSearch.toggle()
          isSearchFocused.wrappedValue = true
        }
      }
      .transition(.slide)
    }
  }
}
