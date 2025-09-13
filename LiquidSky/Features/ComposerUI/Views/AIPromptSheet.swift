import SwiftUI
import DesignSystem

struct AIPromptSheet: View {
    @Binding var prompt: String
    @Binding var isGenerating: Bool
    @Binding var errorMessage: String?

    var onCancel: () -> Void
    var onGenerate: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .symbolRenderingMode(.multicolor)
                    Text("Tell AI what to write")
                        .font(.headline)
                }

                GlassEffectContainer(cornerRadius: 16) {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: Binding(get: { prompt }, set: { prompt = $0 }))
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(Color.clear)

                        if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Describe what you want to post…")
                                .foregroundStyle(.secondary)
                                .padding(.top, 16)
                                .padding(.leading, 14)
                        }
                    }
                }

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .transition(.opacity)
                }

                Spacer(minLength: 0)

                HStack {
                    Button("Cancel") { onCancel() }
                        .buttonStyle(.bordered)

                    Spacer()

                    Button(action: onGenerate) {
                        if isGenerating {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.blue)
                                Text("Generating…")
                            }
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .symbolRenderingMode(.multicolor)
                                Text("Generate")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating)
                }
            }
            .padding()
            .navigationTitle("Craft with AI")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
