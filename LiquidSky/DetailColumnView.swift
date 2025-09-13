import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
struct DetailColumnView: View {
  @Environment(\.detailColumnManager) var detailManager
  @Environment(\.glassEffectManager) var glassEffectManager
  @Namespace private var detailNamespace

  var body: some View {
    NavigationStack {
      GlassEffectContainer(spacing: 16.0) {
        if let currentType = detailManager.currentDetailType {
          // Show detail content based on current type
          detailContentView(for: currentType)
        } else {
          // Empty state
          detailEmptyStateView
        }
      }
      .navigationTitle(navigationTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .topBarLeading) {
          if detailManager.canGoBack {
            backButton
          }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
          if detailManager.currentDetailType != nil {
            breadcrumbMenu
          }
        }
      }
    }
    .background(.ultraThinMaterial)
  }

  // MARK: - Detail Content View

  @ViewBuilder
  private func detailContentView(for type: DetailType) -> some View {
    Group {
      switch type {
      case .post, .thread:
        if let currentItem = detailManager.detailStack.last {
          EnhancedPostDetailView(postId: currentItem.id)
        }

      case .profile:
        if let currentItem = detailManager.detailStack.last {
          EnhancedProfileDetailView(profileId: currentItem.id)
        }

      case .media:
        if let currentItem = detailManager.detailStack.last {
          EnhancedMediaDetailView(mediaId: currentItem.id)
        }

      case .list:
        listDetailView
      }
    }
    .transition(
      .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
      ))
  }

  @ViewBuilder
  private var listDetailView: some View {
    // Placeholder for list detail view
    ContentUnavailableView(
      "List Detail",
      systemImage: "list.bullet",
      description: Text("List detail view would be implemented here")
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }

  // MARK: - Empty State View

  @ViewBuilder
  private var detailEmptyStateView: some View {
    GestureAwareGlassCard(
      cornerRadius: 24,
      isInteractive: false
    ) {
      VStack(spacing: 24) {
        // Animated icon
        ZStack {
          Circle()
            .fill(.blue.opacity(0.1))
            .frame(width: 120, height: 120)

          Image(systemName: "sidebar.right")
            .font(.system(size: 40, weight: .light))
            .foregroundStyle(.blue)
        }
        .background(.blue.opacity(0.1), in: Circle())
        .overlay(Circle().stroke(.blue.opacity(0.3), lineWidth: 2))

        VStack(spacing: 12) {
          Text("Select an item")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.primary)

          Text("Choose something from the content area to view details here")
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(3)
        }

        // Quick tips
        VStack(alignment: .leading, spacing: 8) {
          DetailTipRow(
            icon: "hand.tap",
            text: "Tap any post to view details"
          )

          DetailTipRow(
            icon: "person.circle",
            text: "Tap profiles to see full information"
          )

          DetailTipRow(
            icon: "photo",
            text: "Tap media for full-screen viewing"
          )
        }
        .padding(.top, 8)
      }
      .padding(32)
    }
    .background(.ultraThinMaterial.opacity(0.8))
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  // MARK: - Navigation Components

  @ViewBuilder
  private var backButton: some View {
    Button {
      withAnimation(.smooth(duration: 0.3)) {
        detailManager.popDetail()
      }
    } label: {
      HStack(spacing: 6) {
        Image(systemName: "chevron.left")
          .font(.subheadline.weight(.medium))

        Text("Back")
          .font(.subheadline.weight(.medium))
      }
      .foregroundStyle(.blue)
    }
    .buttonStyle(.plain)
    .background(.blue.opacity(0.1))
    .clipShape(Capsule())
  }

  @ViewBuilder
  private var breadcrumbMenu: some View {
    Menu {
      ForEach(detailManager.currentBreadcrumb.dropLast()) { breadcrumb in
        Button {
          // Navigate to specific breadcrumb level
          navigateToBreadcrumb(breadcrumb)
        } label: {
          HStack {
            Text(breadcrumb.title)
            Spacer()
            Image(systemName: "arrow.up.right")
          }
        }
      }

      if detailManager.detailStack.count > 1 {
        Divider()

        Button {
          withAnimation(.smooth(duration: 0.3)) {
            detailManager.popToRoot()
          }
        } label: {
          HStack {
            Text("Clear All")
            Spacer()
            Image(systemName: "trash")
          }
        }
      }
    } label: {
      HStack(spacing: 4) {
        Text("\(detailManager.detailStack.count)")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.blue)

        Image(systemName: "chevron.down")
          .font(.caption2)
          .foregroundStyle(.blue)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.blue.opacity(0.1), in: Capsule())
      .overlay {
        Capsule()
          .stroke(.blue.opacity(0.3), lineWidth: 1)
      }
    }
    .background(.ultraThinMaterial.opacity(0.9), in: Capsule())
    .overlay(Capsule().stroke(.blue.opacity(0.3), lineWidth: 1))
  }

  // MARK: - Helper Properties

  private var navigationTitle: String {
    if let currentItem = detailManager.detailStack.last {
      return currentItem.title
    } else {
      return "Detail"
    }
  }

  // MARK: - Helper Methods

  private func navigateToBreadcrumb(_ breadcrumb: BreadcrumbItem) {
    guard let index = detailManager.detailStack.firstIndex(where: { $0.id == breadcrumb.id }) else {
      return
    }

    withAnimation(.smooth(duration: 0.3)) {
      // Remove all items after the selected breadcrumb
      detailManager.detailStack = Array(detailManager.detailStack.prefix(index + 1))

      if let lastItem = detailManager.detailStack.last {
        detailManager.currentDetailType = lastItem.type
      }
    }
  }
}

// MARK: - Detail Tip Row

@available(iPadOS 26.0, *)
struct DetailTipRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.subheadline)
        .foregroundStyle(.blue)
        .frame(width: 20, height: 20)

      Text(text)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Spacer()
    }
  }
}

// MARK: - Detail Navigation Extensions

@available(iPadOS 26.0, *)
extension DetailColumnManager {
  func showPostDetail(postId: String, title: String = "Post") {
    let detailItem = DetailItem(id: postId, type: .post, title: title)
    showDetail(detailItem)

    Task {
      await loadDetailContent(for: detailItem)
    }
  }

  func showProfileDetail(profileId: String, title: String = "Profile") {
    let detailItem = DetailItem(id: profileId, type: .profile, title: title)
    showDetail(detailItem)

    Task {
      await loadDetailContent(for: detailItem)
    }
  }

  func showMediaDetail(mediaId: String, title: String = "Media") {
    let detailItem = DetailItem(id: mediaId, type: .media, title: title)
    showDetail(detailItem)

    Task {
      await loadDetailContent(for: detailItem)
    }
  }

  func showThreadDetail(threadId: String, title: String = "Thread") {
    let detailItem = DetailItem(id: threadId, type: .thread, title: title)
    showDetail(detailItem)

    Task {
      await loadDetailContent(for: detailItem)
    }
  }
}

// MARK: - Preview

#Preview {
  if #available(iPadOS 26.0, *) {
    DetailColumnView()
      .environment(DetailColumnManager())
      .environment(LiquidGlassEffectManager())
  } else {
    Text("iPadOS 26.0 required")
  }
}
