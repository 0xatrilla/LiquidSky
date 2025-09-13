import Auth
import Models
import SwiftUI
import User

public struct CustomDomainView: View {
  @Environment(CurrentUser.self) private var currentUser

  @State private var domain: String = ""
  @State private var copied = false

  public init() {}

  public var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          header

          instructions

          dnsSection

          completeSection
        }
        .padding(20)
      }
      .navigationTitle("Custom Domain")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Use your own domain as your Bluesky handle")
        .font(.headline)
      Text(
        "This links your domain to your Bluesky identity. Your followers and data stay portable."
      )
      .font(.subheadline)
      .foregroundColor(.secondary)
    }
  }

  private var instructions: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Step 1 — Choose your domain")
        .font(.subheadline)
        .fontWeight(.semibold)
      TextField("example.com", text: $domain)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .textFieldStyle(.roundedBorder)

      Text("Step 2 — Add a DNS TXT record")
        .font(.subheadline)
        .fontWeight(.semibold)
        .padding(.top, 8)
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text("Host:")
            .foregroundStyle(.secondary)
          Text("@ or your domain provider's root selector")
        }
        HStack {
          Text("Type:")
            .foregroundStyle(.secondary)
          Text("TXT")
        }
        HStack(alignment: .top) {
          Text("Value:")
            .foregroundStyle(.secondary)
          Text("did=\(currentUser.profile?.actorDID ?? "")")
            .textSelection(.enabled)
        }
        Button(action: {
          UIPasteboard.general.string = "did=\(currentUser.profile?.actorDID ?? "")"
          copied = true
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
        }) {
          Label(
            copied ? "Copied" : "Copy TXT value", systemImage: copied ? "checkmark" : "doc.on.doc")
        }
        .buttonStyle(.bordered)
      }
    }
  }

  private var completeSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Step 3 — Complete the change")
        .font(.subheadline)
        .fontWeight(.semibold)
      Text(
        "Once your DNS record propagates, finish linking the handle from Bluesky's handle settings."
      )
      .foregroundStyle(.secondary)

      HStack(spacing: 12) {
        Link(
          "Open Bluesky Handle Settings",
          destination: URL(string: "https://bsky.app/settings/handle")!
        )
        .buttonStyle(.borderedProminent)

        Link(
          "Learn More",
          destination: URL(string: "https://blueskyweb.xyz/blog/3-6-2023-custom-domains")!
        )
        .buttonStyle(.bordered)
      }

      Text(
        "Tip: DNS changes can take time (up to 24 hours). You can keep using your current handle until the switch is complete."
      )
      .font(.footnote)
      .foregroundStyle(.secondary)
      .padding(.top, 8)
    }
    .padding(.top, 8)
  }

  private var dnsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Your DID")
        .font(.subheadline)
        .fontWeight(.semibold)
      Text(currentUser.profile?.actorDID ?? "")
        .font(.footnote)
        .textSelection(.enabled)
        .lineLimit(2)
        .foregroundStyle(.secondary)
    }
    .padding(.top, 8)
  }
}
