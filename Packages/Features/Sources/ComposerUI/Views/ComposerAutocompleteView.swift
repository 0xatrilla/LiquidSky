import Client
import DesignSystem
import SwiftUI

public struct ComposerAutocompleteView: View {
  @ObservedObject var autocompleteService: ComposerAutocompleteService
  let onUserSelected: (UserSuggestion) -> Void
  let onHashtagSelected: (HashtagSuggestion) -> Void

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
      if !autocompleteService.userSuggestions.isEmpty {
        userSuggestionsSection
      }

      if !autocompleteService.hashtagSuggestions.isEmpty {
        hashtagSuggestionsSection
      }

      if autocompleteService.isSearching {
        loadingSection
      }

      if let error = autocompleteService.searchError {
        errorSection(error)
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(.white.opacity(0.2), lineWidth: 1)
    )
  }

  // MARK: - User Suggestions

  private var userSuggestionsSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Users")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)

      ForEach(autocompleteService.userSuggestions) { user in
        Button(action: {
          onUserSelected(user)
        }) {
          HStack(spacing: 12) {
            // Avatar
            if let avatarURL = user.avatarURL {
              AsyncImage(url: avatarURL) { image in
                image
                  .resizable()
                  .scaledToFill()
              } placeholder: {
                Circle()
                  .fill(.gray.opacity(0.3))
              }
              .frame(width: 32, height: 32)
              .clipShape(Circle())
            } else {
              Circle()
                .fill(.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                  Text(String(user.displayName?.first ?? user.handle.first ?? "?"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                )
            }

            // User info
            VStack(alignment: .leading, spacing: 2) {
              HStack(spacing: 4) {
                Text(user.displayName ?? user.handle)
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .foregroundColor(.primary)

                if user.isVerified {
                  Image(systemName: "checkmark.seal.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
              }

              Text("@\(user.handle)")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
        .buttonStyle(.plain)

        if user != autocompleteService.userSuggestions.last {
          Divider()
            .padding(.leading, 60)
        }
      }
    }
  }

  // MARK: - Hashtag Suggestions

  private var hashtagSuggestionsSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Hashtags")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)

      ForEach(autocompleteService.hashtagSuggestions) { hashtag in
        Button(action: {
          onHashtagSelected(hashtag)
        }) {
          HStack(spacing: 12) {
            // Hashtag icon
            Image(systemName: "number")
              .font(.title3)
              .foregroundColor(.purple)
              .frame(width: 32, height: 32)

            // Hashtag info
            VStack(alignment: .leading, spacing: 2) {
              Text("#\(hashtag.tag)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

              Text("\(hashtag.usageCount) posts")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        }
        .buttonStyle(.plain)

        if hashtag != autocompleteService.hashtagSuggestions.last {
          Divider()
            .padding(.leading, 60)
        }
      }
    }
  }

  // MARK: - Loading State

  private var loadingSection: some View {
    HStack(spacing: 12) {
      ProgressView()
        .scaleEffect(0.8)

      Text("Searching...")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  // MARK: - Error State

  private func errorSection(_ error: Error) -> some View {
    HStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle")
        .font(.title3)
        .foregroundColor(.orange)

      Text("Search failed")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }
}
