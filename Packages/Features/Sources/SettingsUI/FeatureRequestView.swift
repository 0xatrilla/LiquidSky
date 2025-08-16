import SwiftUI
import DesignSystem

public struct FeatureRequestView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var featureTitle = ""
    @State private var featureDescription = ""
    @State private var priority = "Medium"
    @State private var category = "General"
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    private let priorities = ["Low", "Medium", "High", "Critical"]
    private let categories = ["General", "UI/UX", "Performance", "Social Features", "Media", "Privacy", "Other"]
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HeaderView(title: "Feature Request", showBack: true)
                        .padding(.horizontal, 16)
                    
                    if showSuccess {
                        successView
                    } else {
                        formView
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationBarHidden(true)
    }
    
    private var formView: some View {
        VStack(spacing: 20) {
            // Feature Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Feature Title")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Brief description of the feature", text: $featureTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Category Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Priority Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Priority", selection: $priority) {
                    ForEach(priorities, id: \.self) { priority in
                        Text(priority).tag(priority)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Feature Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Detailed Description")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextEditor(text: $featureDescription)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            // Submit Button
            Button {
                submitFeatureRequest()
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isSubmitting ? "Submitting..." : "Submit Request")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.blue : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSubmit || isSubmitting)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
    }
    
    private var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            Text("Feature Request Submitted!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Thank you for your suggestion! We'll review your feature request and consider it for future updates.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
    }
    
    private var canSubmit: Bool {
        !featureTitle.isEmpty && !featureDescription.isEmpty
    }
    
    private func submitFeatureRequest() {
        isSubmitting = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            showSuccess = true
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
    }
}

#Preview {
    FeatureRequestView()
}
