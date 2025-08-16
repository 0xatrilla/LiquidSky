import SwiftUI
import DesignSystem

public struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var subject = ""
    @State private var message = ""
    @State private var contactMethod = "Email"
    @State private var includeContactInfo = true
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    private let contactMethods = ["Email", "In-App Chat", "Phone"]
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HeaderView(title: "Contact Support", showBack: true)
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
            // Contact Method
            VStack(alignment: .leading, spacing: 8) {
                Text("Preferred Contact Method")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Contact Method", selection: $contactMethod) {
                    ForEach(contactMethods, id: \.self) { method in
                        Text(method).tag(method)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Subject
            VStack(alignment: .leading, spacing: 8) {
                Text("Subject")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Brief description of your issue", text: $subject)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Message
            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextEditor(text: $message)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            // Include Contact Info Toggle
            Toggle("Include my contact information for follow-up", isOn: $includeContactInfo)
                .font(.body)
            
            // Submit Button
            Button {
                submitSupportRequest()
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isSubmitting ? "Submitting..." : "Send Message")
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
            Image(systemName: "envelope.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Message Sent!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Thank you for contacting us. We'll get back to you within 24 hours using your preferred contact method.")
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
        !subject.isEmpty && !message.isEmpty
    }
    
    private func submitSupportRequest() {
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
    ContactSupportView()
}
