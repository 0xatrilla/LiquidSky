import SwiftUI
import DesignSystem

public struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var bugDescription = ""
    @State private var bugType = "General"
    @State private var includeSystemInfo = true
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    private let bugTypes = ["General", "Crash", "UI Issue", "Performance", "Feature Request"]
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HeaderView(title: "Report a Bug", showBack: true)
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
            // Bug Type Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Bug Type")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Bug Type", selection: $bugType) {
                    ForEach(bugTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Bug Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextEditor(text: $bugDescription)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            // System Info Toggle
            Toggle("Include System Information", isOn: $includeSystemInfo)
                .font(.body)
            
            // Submit Button
            Button {
                submitBugReport()
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isSubmitting ? "Submitting..." : "Submit Report")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(bugDescription.isEmpty ? Color.gray : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(bugDescription.isEmpty || isSubmitting)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
    }
    
    private var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Bug Report Submitted!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Thank you for helping us improve LiquidSky. We'll review your report and get back to you if we need more information.")
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
    
    private func submitBugReport() {
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
    BugReportView()
}
