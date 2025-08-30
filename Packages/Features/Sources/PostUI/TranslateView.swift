import AppRouter
import Models
import SwiftUI

#if canImport(Translation)
@preconcurrency import Translation
#endif

public struct TranslateView: View {
  @Environment(\.dismiss) private var dismiss

  let post: PostItem

  @State private var translatedText: String = ""
  @State private var isLoading = true
  @State private var error: String?

  #if canImport(Translation)
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var availableLanguages: [Locale.Language] = []
    @State private var selectedTargetLanguage: Locale.Language?
  #endif

  public init(post: PostItem) {
    self.post = post
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        mainContent
      }
      .navigationTitle("Translate Post")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    #if canImport(Translation)
      .task {
        await loadAvailableLanguages()
      }
      .translationTask(translationConfiguration) { session in
        await performTranslation(with: session)
      }
    #else
      .task {
        error = "Translation is not available on this device."
        isLoading = false
      }
    #endif
  }

  private var mainContent: some View {
    VStack(alignment: .leading, spacing: 20) {
      originalPostSection
      Divider()
      #if canImport(Translation)
        languageSelectionSection
      #endif
      translationSection
    }
    .padding()
  }

  private var originalPostSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Original")
        .font(.headline)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 12) {
        authorInfoRow
        originalTextRow
      }
      .padding()
      .background(.gray.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  private var authorInfoRow: some View {
    HStack {
      AsyncImage(url: post.author.avatarImageURL) { phase in
        switch phase {
        case .success(let image):
          image
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .clipShape(Circle())
        default:
          Circle()
            .fill(.gray.opacity(0.2))
            .frame(width: 32, height: 32)
        }
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(post.author.displayName ?? post.author.handle)
          .font(.subheadline)
          .fontWeight(.semibold)
        Text("@\(post.author.handle)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
  }

  private var originalTextRow: some View {
    Text(post.content)
      .font(.body)
      .lineLimit(nil)
      .multilineTextAlignment(.leading)
  }

  #if canImport(Translation)
    private var languageSelectionSection: some View {
      VStack(alignment: .leading, spacing: 12) {
        Text("Translate to")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Picker("Target Language", selection: $selectedTargetLanguage) {
          ForEach(availableLanguages, id: \.self) { language in
            Text(language.languageCode?.identifier.capitalized ?? "Unknown")
              .tag(language as Locale.Language?)
          }
        }
        .pickerStyle(.menu)
        .onChange(of: selectedTargetLanguage) { oldValue, newValue in
          if let language = newValue {
            translationConfiguration = TranslationSession.Configuration(
              source: nil,
              target: language
            )
          }
        }
      }
      .opacity(availableLanguages.isEmpty ? 0 : 1)
    }
  #endif

  private var translationSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Translation")
          .font(.headline)
          .foregroundStyle(.secondary)

        Spacer()

        if isLoading {
          ProgressView()
            .scaleEffect(0.8)
        }
      }

      if let error {
        errorView(error: error)
      } else {
        translationContentView
      }
    }
  }

  private func errorView(error: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Translation Error")
        .font(.subheadline)
        .foregroundStyle(.red)

      Text(error)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding()
    .background(.red.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  private var translationContentView: some View {
    VStack(alignment: .leading, spacing: 12) {
      if translatedText.isEmpty && !isLoading {
        Text("Translation will appear here")
          .font(.body)
          .foregroundStyle(.secondary)
          .italic()
      } else {
        Text(translatedText)
          .font(.body)
          .lineLimit(nil)
          .multilineTextAlignment(.leading)
      }
    }
    .padding()
    .background(.blue.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  #if canImport(Translation)
    private func loadAvailableLanguages() async {
      let languageAvailability = LanguageAvailability()
      availableLanguages = await languageAvailability.supportedLanguages

      // Set default target language to Spanish if available, otherwise first available
      if let spanish = availableLanguages.first(where: { $0.languageCode?.identifier == "es" }) {
        selectedTargetLanguage = spanish
      } else if let first = availableLanguages.first {
        selectedTargetLanguage = first
      }
    }

    private func performTranslation(with session: TranslationSession) async {
      isLoading = true
      error = nil

      do {
        let response = try await session.translate(post.content)
        translatedText = response.targetText
        isLoading = false
      } catch {
        self.error = "Translation failed: \(error.localizedDescription)"
        isLoading = false
      }
    }
  #endif
}
