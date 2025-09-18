import FeedUI
import Foundation
import Models
import NotificationsUI
import ProfileUI
import SettingsUI
import SwiftUI

@available(iOS 18.0, *)
struct AdaptiveGridView<Item: Identifiable, Content: View>: View {
  let items: [Item]
  let content: (Item) -> Content

  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @Environment(\.verticalSizeClass) var verticalSizeClass

  private var columns: [GridItem] {
    let columnCount: Int

    switch (horizontalSizeClass, verticalSizeClass) {
    case (.regular, .regular):
      columnCount = 3  // Three columns on large iPads
    case (.regular, .compact):
      columnCount = 2  // Two columns in landscape
    default:
      columnCount = 1  // Single column on compact sizes
    }

    return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 16) {
      ForEach(items) { item in
        GlassCard(cornerRadius: 12, isInteractive: true) {
          content(item)
        }
      }
    }
    .padding()
  }
}

@available(iOS 18.0, *)
struct FeedCardView: View {
  let feed: FeedItem
  @State private var isHovered = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Feed header
      HStack {
        AsyncImage(url: feed.avatarImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle()
            .fill(.blue.gradient)
            .overlay {
              Image(systemName: "square.stack")
                .foregroundStyle(.white)
                .font(.title3)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())

        VStack(alignment: .leading, spacing: 2) {
          Text(feed.displayName)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)

          Text("by @\(feed.creatorHandle)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }

      // Feed description
      if let description = feed.description {
        Text(description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(3)
      }

      // Feed stats
      HStack {
        HStack(spacing: 4) {
          Image(systemName: feed.liked ? "heart.fill" : "heart")
            .foregroundStyle(feed.liked ? .red : .secondary)
          Text("\(feed.likesCount)")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }

        Spacer()

        GlassButton("View", systemImage: "arrow.right", style: .interactive) {
          // Handle feed selection
        }
      }
    }
    .padding()
    .scaleEffect(isHovered ? 1.02 : 1.0)
    .animation(.smooth(duration: 0.2), value: isHovered)
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

// Removed duplicate EnhancedNotificationGridView - using the one in EnhancedNotificationGridView.swift
