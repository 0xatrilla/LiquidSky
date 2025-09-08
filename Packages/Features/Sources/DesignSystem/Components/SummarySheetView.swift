import SwiftUI

public struct SummarySheetView: View {
  let title: String
  let summary: String
  let itemCount: Int
  let onDismiss: () -> Void

  @Environment(\.colorScheme) private var colorScheme
  @State private var isVisible = false
  @State private var attributedSummary: AttributedString?

  public init(title: String, summary: String, itemCount: Int, onDismiss: @escaping () -> Void) {
    self.title = title
    self.summary = summary
    self.itemCount = itemCount
    self.onDismiss = onDismiss
  }

  public var body: some View {
    ZStack {
      // Background blur
      Color.black.opacity(0.3)
        .ignoresSafeArea()
        .onTapGesture {
          dismiss()
        }

      // Main content - now properly constrained to safe area
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

              Text("\(itemCount) new items")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

              // Apple Intelligence branding
              HStack {
                Image(systemName: "brain.head.profile")
                  .font(.caption)
                  .foregroundStyle(.white)
                  .padding(6)
                  .background(
                    LinearGradient(
                      colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                  )
                  .clipShape(Circle())

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

            // Summary content - now fills the entire sheet
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
                dismiss()
                // TODO: Scroll to top of feed/notifications
              }
              .buttonStyle(.borderedProminent)
              .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 20)  // Extra padding for scroll area
          }
          .padding(.horizontal, 24)
        }
        .frame(maxHeight: 700)  // Increased height for full summary content
      }
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(.ultraThinMaterial)
          .overlay(
            ZStack {
              // Outer stroke
              RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(colorScheme == .dark ? 0.08 : 0.2), lineWidth: 1)
              // Top highlight for a glass sheen
              RoundedRectangle(cornerRadius: 24)
                .fill(
                  LinearGradient(
                    colors: [Color.white.opacity(colorScheme == .dark ? 0.10 : 0.35), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                  )
                )
                .allowsHitTesting(false)
            }
          )
          .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
      )
      .padding(.horizontal, 16)
      .frame(maxHeight: 800)  // Increased overall sheet height limit
      .offset(y: isVisible ? 0 : 800)
      .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
    }
    .onAppear {
      isVisible = true
      if let attr = try? AttributedString(markdown: summary) {
        attributedSummary = attr
      }
    }
  }

  private func dismiss() {
    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
      isVisible = false
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      onDismiss()
    }
  }
}

#Preview {
  SummarySheetView(
    title: "Feed Summary",
    summary:
      "The developer community has been buzzing with excitement over the latest iOS updates and SwiftUI innovations. Several prominent developers shared their experiences with the new declarative UI patterns, highlighting significant performance improvements and cleaner code architecture. The discussions revealed a growing trend toward more modular app design, with many developers experimenting with SwiftUI's advanced features like custom view modifiers and state management techniques.\n\nCommunity sentiment remains overwhelmingly positive, with developers actively sharing resources, code snippets, and best practices. Notable conversations included deep-dives into accessibility improvements, with several developers showcasing how they've made their apps more inclusive. The feed also featured some interesting project showcases, including a new productivity app that leverages Apple's latest frameworks and a creative coding experiment that demonstrates the power of SwiftUI's animation system.",
    itemCount: 15,
    onDismiss: {}
  )
  .preferredColorScheme(.dark)
}
