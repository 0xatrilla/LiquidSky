import DesignSystem
import SwiftUI

public struct TermsOfServiceView: View {
  @Environment(\.dismiss) private var dismiss

  public init() {}

  public var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          HeaderView(title: "Terms of Service", showBack: true)
            .padding(.horizontal, 16)

          // Terms Content
          VStack(alignment: .leading, spacing: 20) {
            TermsSection(
              title: "Acceptance of Terms",
              content:
                "By accessing and using Horizon, you accept and agree to be bound by the terms and provision of this agreement."
            )

            TermsSection(
              title: "Use License",
              content:
                "Permission is granted to temporarily download one copy of Horizon for personal, non-commercial transitory viewing only."
            )

            TermsSection(
              title: "User Conduct",
              content:
                "You agree not to use the service to post, transmit, or otherwise make available any content that is unlawful, harmful, threatening, abusive, or otherwise objectionable."
            )

            TermsSection(
              title: "Content Responsibility",
              content:
                "You are responsible for all content you post, transmit, or otherwise make available through the service. We do not control or endorse user content."
            )

            TermsSection(
              title: "Privacy",
              content:
                "Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the service."
            )

            TermsSection(
              title: "Termination",
              content:
                "We may terminate or suspend your account and bar access to the service immediately, without prior notice, for any reason whatsoever."
            )

            TermsSection(
              title: "Changes to Terms",
              content:
                "We reserve the right to modify or replace these terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect."
            )

            TermsSection(
              title: "Contact Information",
              content:
                "If you have any questions about these Terms of Service, please contact us through the app's support system."
            )
          }
          .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
      }
    }
    .navigationBarHidden(true)
  }
}

// MARK: - Terms Section
private struct TermsSection: View {
  let title: String
  let content: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .foregroundColor(.primary)

      Text(content)
        .font(.body)
        .foregroundColor(.secondary)
        .lineLimit(nil)
    }
  }
}

#Preview {
  TermsOfServiceView()
}
