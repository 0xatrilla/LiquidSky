import AppRouter
import DesignSystem
import Destinations
import Models
import NukeUI
import SwiftUI

public struct UnifiedSearchResultsView: View {
  @ObservedObject var searchService: UnifiedSearchService
  @Environment(\.dismiss) private var dismiss

  public init(searchService: UnifiedSearchService) {
    self.searchService = searchService
  }

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        if searchService.isSearching {
          loadingView
        } else if let error = searchService.searchError {
          errorView(error: error)
        } else if !searchService.searchResults.hasResults {
          emptyStateView
        } else {
          searchResultsList
        }
      }
      .navigationTitle("Search Results")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        #if os(iOS)
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
              dismiss()
            }
          }
        #else
          ToolbarItem(placement: .primaryAction) {
            Button("Done") {
              dismiss()
            }
          }
        #endif
      }
    }
  }

  // MARK: - Loading View

  private var loadingView: some View {
    VStack(spacing: 20) {
      ProgressView()
        .scaleEffect(1.5)

      Text("Searching...")
        .font(.headline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Error View

  private func errorView(error: Error) -> some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 50))
        .foregroundColor(.red)

      Text("Search Error")
        .font(.title2)
        .fontWeight(.semibold)

      Text(error.localizedDescription)
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button("Try Again") {
        // Retry search
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Empty State

  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 50))
        .foregroundColor(.secondary)

      Text("No Results Found")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Try adjusting your search terms or browse trending content")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Search Results List

  private var searchResultsList: some View {
    Group {
      if searchService.searchResults.hasResults {
        List {
          ForEach(Array(searchService.searchResults.feeds.enumerated()), id: \.element.id) {
            _, feed in
            FeedSearchResultRow(feed: feed)
          }
        }
        .listStyle(.plain)
      } else {
        VStack(spacing: 16) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 48))
            .foregroundColor(.secondary)

          Text("No feeds found")
            .font(.title3)
            .fontWeight(.medium)

          Text("Try adjusting your search terms")
            .font(.body)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
      }
    }
  }
}

// MARK: - Feed Search Result Row

struct FeedSearchResultRow: View {
  @Environment(AppRouter.self) var router

  let feed: FeedSearchResult
  @Namespace private var namespace

  var body: some View {
    HStack(spacing: 12) {
      // Feed Icon
      if let avatarURL = feed.avatarURL {
        LazyImage(url: avatarURL) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.blue.opacity(0.3))
              .overlay(
                Image(systemName: "rss")
                  .foregroundColor(.blue)
              )
          }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
          // Navigate to the feed itself since this is not a user profile
          // The feed is already wrapped in a NavigationLink
        }
      } else {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.blue.opacity(0.3))
          .frame(width: 50, height: 50)
          .overlay(
            Image(systemName: "rss")
              .foregroundColor(.blue)
          )
      }

      // Feed Info
      VStack(alignment: .leading, spacing: 4) {
        Text(feed.displayName)
          .font(.headline)
          .fontWeight(.semibold)

        if let description = feed.description, !description.isEmpty {
          Text(description)
            .font(.body)
            .foregroundColor(.primary)
            .lineLimit(2)
        }

        HStack(spacing: 16) {
          Text("By @\(feed.creatorHandle)")
            .font(.caption)
            .foregroundColor(.secondary)

          Label("\(feed.likesCount)", systemImage: "heart")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      // Subscribe Button
      Button(feed.isLiked ? "Subscribed" : "Subscribe") {
        // Subscribe to feed
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(feed.isLiked ? Color.clear : Color.blue)
      .foregroundColor(feed.isLiked ? .secondary : .white)
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(feed.isLiked ? Color.secondary : Color.clear, lineWidth: 1)
      )
      .controlSize(.small)
      .disabled(feed.isLiked)
    }
    .padding(.vertical, 8)
  }
}
