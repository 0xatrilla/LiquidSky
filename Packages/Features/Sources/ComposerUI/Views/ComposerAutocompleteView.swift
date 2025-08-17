import AppRouter
import DesignSystem
import Destinations
import Models
import SwiftUI

public struct ComposerAutocompleteView: View {
  @ObservedObject var autocompleteService: ComposerAutocompleteService
  let onUserSelected: (UserSuggestion) -> Void
  let onHashtagSelected: (HashtagSuggestion) -> Void

  @Namespace private var namespace

  public init(
    autocompleteService: ComposerAutocompleteService,
    onUserSelected: @escaping (UserSuggestion) -> Void,
    onHashtagSelected: @escaping (HashtagSuggestion) -> Void
  ) {
    self.autocompleteService = autocompleteService
    self.onUserSelected = onUserSelected
    self.onHashtagSelected = onHashtagSelected
  }

  public var body: some View {
    VStack(spacing: 0) {
      // Compact horizontal suggestions strip
      if !autocompleteService.userSuggestions.isEmpty
        || !autocompleteService.hashtagSuggestions.isEmpty
      {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            // User suggestions (max 3 for compact UI)
            ForEach(autocompleteService.userSuggestions.prefix(3)) { user in
              CompactSuggestionButton(
                title: user.displayName ?? user.handle,
                subtitle: "@\(user.handle)",
                icon: "person.circle.fill",
                iconColor: .blue,
                action: {
                  onUserSelected(user)
                }
              )
            }

            // Hashtag suggestions (max 2 for compact UI)
            ForEach(autocompleteService.hashtagSuggestions.prefix(2)) { hashtag in
              CompactSuggestionButton(
                title: hashtag.tag,
                subtitle: "\(hashtag.usageCount) posts",
                icon: "number",
                iconColor: .blue,
                action: {
                  onHashtagSelected(hashtag)
                }
              )
            }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
        }
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
            )
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .blur(radius: 8)
            )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
      }

      // Loading indicator (compact)
      if autocompleteService.isSearching {
        HStack(spacing: 8) {
          ProgressView()
            .scaleEffect(0.7)
          Text("Searching...")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          Rectangle()
            .fill(.ultraThinMaterial.opacity(0.8))
        )
      }

      // Error state (compact)
      if let error = autocompleteService.searchError {
        HStack(spacing: 8) {
          Image(systemName: "exclamationmark.triangle")
            .font(.caption)
            .foregroundColor(.orange)
          Text("Search failed")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          Rectangle()
            .fill(.ultraThinMaterial.opacity(0.8))
        )
      }
    }
    .animation(.easeInOut(duration: 0.15), value: autocompleteService.userSuggestions.count)
    .animation(.easeInOut(duration: 0.15), value: autocompleteService.hashtagSuggestions.count)
    .animation(.easeInOut(duration: 0.15), value: autocompleteService.isSearching)
  }
}

// MARK: - Compact Suggestion Button

private struct CompactSuggestionButton: View {
  let title: String
  let subtitle: String
  let icon: String
  let iconColor: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: icon)
          .font(.caption)
          .foregroundColor(iconColor)

        VStack(alignment: .leading, spacing: 1) {
          Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .lineLimit(1)

          Text(subtitle)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 10)
              .stroke(.white.opacity(0.15), lineWidth: 0.5)
          )
          .background(
            RoundedRectangle(cornerRadius: 10)
              .fill(.ultraThinMaterial.opacity(0.3))
              .blur(radius: 4)
          )
      )
      .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    .buttonStyle(.plain)
  }
}
