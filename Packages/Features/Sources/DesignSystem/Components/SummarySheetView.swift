import Models
import SwiftUI

public struct SummarySheetView: View {
    let title: String
    let summary: String
    let itemCount: Int
    let onDismiss: () -> Void
    let onViewAll: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var attributedSummary: AttributedString?

    public init(title: String, summary: String, itemCount: Int, onDismiss: @escaping () -> Void, onViewAll: (() -> Void)? = nil) {
        self.title = title
        self.summary = summary
        self.itemCount = itemCount
        self.onDismiss = onDismiss
        self.onViewAll = onViewAll
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(.secondary)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            // Scrollable content area
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .symbolRenderingMode(.multicolor)

                            Text(title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)

                            Spacer()
                        }

                        if PlatformFeatures.supportsAppleIntelligenceBranding {
                            HStack {
                                Image("appleai", bundle: .main)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text("Powered by Apple Intelligence")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .overlay(
                                        LinearGradient(
                                            colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing
                                        )
                                        .mask(
                                            Text("Powered by Apple Intelligence")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        )
                                    )
                                    .foregroundStyle(.clear)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.15), .purple.opacity(0.15)], startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .clipShape(Capsule())
                                    )

                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }

                    // Summary content
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            if let attributedSummary {
                                Text(attributedSummary)
                            } else {
                                Text(summary)
                            }
                        }
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(5)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // Action buttons
                    HStack(spacing: 16) {
                        Button("Dismiss") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                        Button("View All") {
                            onViewAll?()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            if PlatformFeatures.supportsLiquidDesign {
                Color(.systemBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .fill(.ultraThinMaterial)
                    )
            } else {
                Color(.systemBackground)
            }
        }
        .onAppear {
            if let attr = try? AttributedString(markdown: summary) {
                attributedSummary = attr
            }
        }
    }
}

#Preview {
    SummarySheetView(
        title: "Feed Summary",
        summary:
            "The developer community has been buzzing with excitement over the latest iOS updates and SwiftUI innovations. Several prominent developers shared their experiences with the new declarative UI patterns, highlighting significant performance improvements and cleaner code architecture. The discussions revealed a growing trend toward more modular app design, with many developers experimenting with SwiftUI's advanced features like custom view modifiers and state management techniques.\n\nCommunity sentiment remains overwhelmingly positive, with developers actively sharing resources, code snippets, and best practices. Notable conversations included deep-dives into accessibility improvements, with several developers showcasing how they've made their apps more inclusive. The feed also featured some interesting project showcases, including a new productivity app that leverages Apple's latest frameworks and a creative coding experiment that demonstrates the power of SwiftUI's animation system.",
        itemCount: 15,
        onDismiss: {},
        onViewAll: {}
    )
    .preferredColorScheme(.dark)
}
