import Models
import SwiftUI

public struct BoostIndicatorDemoView: View {
  public init() {}

  public var body: some View {
    VStack(spacing: 20) {
      Text("Boost Indicator Examples")
        .font(.title)
        .fontWeight(.bold)

      // Example 1: Post with boost count
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Circle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: 40, height: 40)

          VStack(alignment: .leading) {
            Text("John Doe")
              .font(.headline)
            Text("@johndoe")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()
        }

        Text("This is an example post that shows how boost indicators work in the timeline.")
          .font(.body)

        // Boost indicator showing boost count
        BoostIndicatorView(repostCount: 5)

        HStack {
          Text("2 hours ago")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
      }
      .padding()
      .background(Color.gray.opacity(0.1))
      .cornerRadius(12)

      // Example 2: Post that you boosted
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Circle()
            .fill(Color.green.opacity(0.3))
            .frame(width: 40, height: 40)

          VStack(alignment: .leading) {
            Text("Jane Smith")
              .font(.headline)
            Text("@janesmith")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()
        }

        Text("This is another example post that you personally boosted.")
          .font(.body)

        // Boost indicator showing "You boosted"
        BoostIndicatorView(repostCount: 0, isReposted: true)

        HStack {
          Text("1 hour ago")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
      }
      .padding()
      .background(Color.gray.opacity(0.1))
      .cornerRadius(12)

      // Example 3: Post with no boosts
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Circle()
            .fill(Color.orange.opacity(0.3))
            .frame(width: 40, height: 40)

          VStack(alignment: .leading) {
            Text("Bob Wilson")
              .font(.headline)
            Text("@bobwilson")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()
        }

        Text("This post has no boosts yet.")
          .font(.body)

        HStack {
          Text("30 minutes ago")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
      }
      .padding()
      .background(Color.gray.opacity(0.1))
      .cornerRadius(12)

      Spacer()
    }
    .padding()
  }
}

#Preview {
  BoostIndicatorDemoView()
}
