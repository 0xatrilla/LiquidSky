import SwiftUI
import Models

struct AdvancedAIFeaturesSheet: View {
  @Binding var selectedFeature: AIFeature
  @Binding var tone: ReplyTone
  @Binding var includeEmojis: Bool
  @Binding var translationTargetLanguage: String
  @Binding var isGenerating: Bool
  @Binding var isTranslating: Bool
  @Binding var errorMessage: String?
  @Binding var translationError: String?
  
  let onCancel: () -> Void
  let onCompose: () -> Void
  let onTranslate: () -> Void
  let onImprove: () -> Void
  let onSummarize: () -> Void
  
  @State private var aiPrompt: String = ""
  @State private var showingLanguagePicker = false
  
  private let supportedLanguages = [
    ("en", "English"),
    ("es", "Spanish"),
    ("fr", "French"),
    ("de", "German"),
    ("it", "Italian"),
    ("pt", "Portuguese"),
    ("ru", "Russian"),
    ("ja", "Japanese"),
    ("ko", "Korean"),
    ("zh", "Chinese")
  ]
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        // Feature Selection
        Picker("AI Feature", selection: $selectedFeature) {
          ForEach(AIFeature.allCases, id: \.self) { feature in
            Text(feature.title).tag(feature)
          }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        
        // Feature-specific content
        Group {
          switch selectedFeature {
          case .compose:
            composeView
          case .translate:
            translateView
          case .improve:
            improveView
          case .summarize:
            summarizeView
          }
        }
        .animation(.easeInOut, value: selectedFeature)
        
        Spacer()
        
        // Action Buttons
        VStack(spacing: 12) {
          if let error = errorMessage ?? translationError {
            Text(error)
              .foregroundColor(.red)
              .font(.caption)
              .multilineTextAlignment(.center)
          }
          
          HStack(spacing: 16) {
            Button("Cancel", role: .cancel) {
              onCancel()
            }
            .buttonStyle(.bordered)
            
            Button(action: performAction) {
              HStack {
                if isGenerating || isTranslating {
                  ProgressView()
                    .scaleEffect(0.8)
                }
                Text(actionButtonTitle)
              }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isGenerating || isTranslating)
          }
        }
        .padding(.horizontal)
        .padding(.bottom)
      }
      .navigationTitle("AI Assistant")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
  
  // MARK: - Feature Views
  
  private var composeView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Generate a new post with AI")
        .font(.headline)
      
      VStack(alignment: .leading, spacing: 12) {
        Text("What would you like to post about?")
          .font(.subheadline)
          .foregroundColor(.secondary)
        
        TextField("Describe your post idea...", text: $aiPrompt, axis: .vertical)
          .textFieldStyle(.roundedBorder)
          .lineLimit(3...6)
      }
      
      VStack(alignment: .leading, spacing: 12) {
        Text("Tone")
          .font(.subheadline)
          .foregroundColor(.secondary)
        
        Picker("Tone", selection: $tone) {
          ForEach(ReplyTone.allCases, id: \.self) { tone in
            Text(tone.rawValue.capitalized).tag(tone)
          }
        }
        .pickerStyle(MenuPickerStyle())
      }
      
      Toggle("Include emojis", isOn: $includeEmojis)
        .toggleStyle(SwitchToggleStyle())
    }
    .padding()
  }
  
  private var translateView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Translate your post")
        .font(.headline)
      
      VStack(alignment: .leading, spacing: 12) {
        Text("Target Language")
          .font(.subheadline)
          .foregroundColor(.secondary)
        
        Button(action: { showingLanguagePicker = true }) {
          HStack {
            Text(selectedLanguageName)
            Spacer()
            Image(systemName: "chevron.down")
          }
          .padding()
          .background(Color(.systemGray6))
          .cornerRadius(8)
        }
        .sheet(isPresented: $showingLanguagePicker) {
          LanguagePickerSheet(
            selectedLanguage: $translationTargetLanguage,
            languages: supportedLanguages,
            isPresented: $showingLanguagePicker
          )
        }
      }
      
      Text("Your current text will be translated to \(selectedLanguageName).")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
  
  private var improveView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Improve your post")
        .font(.headline)
      
      VStack(alignment: .leading, spacing: 8) {
        Text("AI will enhance your post for:")
          .font(.subheadline)
          .foregroundColor(.secondary)
        
        VStack(alignment: .leading, spacing: 4) {
          Label("Clarity and readability", systemImage: "textformat")
          Label("Engagement and impact", systemImage: "heart")
          Label("Professional tone", systemImage: "person.badge.plus")
          Label("Character optimization", systemImage: "text.alignleft")
        }
        .font(.caption)
        .foregroundColor(.secondary)
      }
      
      Text("Your current text will be improved while maintaining its original meaning.")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
  
  private var summarizeView: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Summarize your post")
        .font(.headline)
      
      VStack(alignment: .leading, spacing: 8) {
        Text("AI will create a concise version that:")
          .font(.subheadline)
          .foregroundColor(.secondary)
        
        VStack(alignment: .leading, spacing: 4) {
          Label("Keeps key points", systemImage: "checkmark.circle")
          Label("Fits character limit", systemImage: "textformat.abc")
          Label("Maintains engagement", systemImage: "heart")
          Label("Improves readability", systemImage: "eye")
        }
        .font(.caption)
        .foregroundColor(.secondary)
      }
      
      Text("Your current text will be condensed into a shorter, more impactful post.")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
  
  // MARK: - Computed Properties
  
  private var selectedLanguageName: String {
    supportedLanguages.first { $0.0 == translationTargetLanguage }?.1 ?? "English"
  }
  
  private var actionButtonTitle: String {
    switch selectedFeature {
    case .compose:
      return "Generate Post"
    case .translate:
      return "Translate"
    case .improve:
      return "Improve Text"
    case .summarize:
      return "Summarize"
    }
  }
  
  // MARK: - Actions
  
  private func performAction() {
    switch selectedFeature {
    case .compose:
      onCompose()
    case .translate:
      onTranslate()
    case .improve:
      onImprove()
    case .summarize:
      onSummarize()
    }
  }
}

// MARK: - Supporting Views

struct LanguagePickerSheet: View {
  @Binding var selectedLanguage: String
  let languages: [(String, String)]
  @Binding var isPresented: Bool
  
  var body: some View {
    NavigationView {
      List(languages, id: \.0) { language in
        Button(action: {
          selectedLanguage = language.0
          isPresented = false
        }) {
          HStack {
            Text(language.1)
            Spacer()
            if selectedLanguage == language.0 {
              Image(systemName: "checkmark")
                .foregroundColor(.blue)
            }
          }
        }
        .foregroundColor(.primary)
      }
      .navigationTitle("Select Language")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            isPresented = false
          }
        }
      }
    }
  }
}

// MARK: - Supporting Types

enum AIFeature: CaseIterable {
  case compose
  case translate
  case improve
  case summarize
  
  var title: String {
    switch self {
    case .compose:
      return "Compose"
    case .translate:
      return "Translate"
    case .improve:
      return "Improve"
    case .summarize:
      return "Summarize"
    }
  }
  
  var icon: String {
    switch self {
    case .compose:
      return "sparkles"
    case .translate:
      return "globe"
    case .improve:
      return "wand.and.stars"
    case .summarize:
      return "doc.text"
    }
  }
}
