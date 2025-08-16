import SwiftUI
import DesignSystem

public struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HeaderView(title: "Privacy Policy", showBack: true)
                        .padding(.horizontal, 16)
                    
                    // Privacy Policy Content
                    VStack(alignment: .leading, spacing: 20) {
                        PolicySection(
                            title: "Information We Collect",
                            content: "We collect information you provide directly to us, such as when you create an account, post content, or contact us for support. This may include your username, email address, and any content you post."
                        )
                        
                        PolicySection(
                            title: "How We Use Your Information",
                            content: "We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to ensure the security of our platform."
                        )
                        
                        PolicySection(
                            title: "Information Sharing",
                            content: "We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy or as required by law."
                        )
                        
                        PolicySection(
                            title: "Data Security",
                            content: "We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction."
                        )
                        
                        PolicySection(
                            title: "Your Rights",
                            content: "You have the right to access, update, or delete your personal information. You can also opt out of certain communications and control your privacy settings."
                        )
                        
                        PolicySection(
                            title: "Contact Us",
                            content: "If you have any questions about this Privacy Policy, please contact us through the app's support system."
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

// MARK: - Policy Section
private struct PolicySection: View {
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
    PrivacyPolicyView()
}
