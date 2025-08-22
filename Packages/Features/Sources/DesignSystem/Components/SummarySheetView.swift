import SwiftUI

public struct SummarySheetView: View {
  let title: String
  let summary: String
  let itemCount: Int
  let onDismiss: () -> Void

  @Environment(\.colorScheme) private var colorScheme
  @State private var isVisible = false

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

      // Main content
      VStack(spacing: 0) {
        // Handle bar
        RoundedRectangle(cornerRadius: 2.5)
          .fill(.secondary)
          .frame(width: 36, height: 5)
          .padding(.top, 8)
          .padding(.bottom, 16)

        // Content
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 8) {
            HStack {
              Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.blueskyPrimary)

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
          }

          // Summary content
          VStack(alignment: .leading, spacing: 16) {
            HStack {
              Image(systemName: "brain.head.profile")
                .font(.title3)
                .foregroundColor(.blueskyPrimary)

              Text("AI Summary")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

              Spacer()
            }

            Text(summary)
              .font(.body)
              .foregroundStyle(.primary)
              .multilineTextAlignment(.leading)
              .lineLimit(nil)
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(20)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(.ultraThinMaterial)
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(.quaternary, lineWidth: 0.5)
              )
          )

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
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 24)
              .stroke(.quaternary, lineWidth: 0.5)
          )
      )
      .padding(.horizontal, 16)
      .offset(y: isVisible ? 0 : 600)
      .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
    }
    .onAppear {
      isVisible = true
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
      "You have 15 new posts in your feed, including updates from developers, tech discussions about iOS development, and project updates from the indie dev community.",
    itemCount: 15,
    onDismiss: {}
  )
  .preferredColorScheme(.dark)
}
