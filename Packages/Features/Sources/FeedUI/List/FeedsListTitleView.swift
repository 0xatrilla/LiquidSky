import Client
import DesignSystem
import SwiftUI

public struct FeedsListTitleView: View {
  @Binding var filter: FeedsListFilter
  @Environment(BSkyClient.self) var client

  public init(
    filter: Binding<FeedsListFilter>
  ) {
    self._filter = filter
  }

  public var body: some View {
    HStack(alignment: .center) {
      // Feeds filter menu
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

      Spacer()
    }
  }
}
