import AppRouter
import Client
import DesignSystem
import Models
import NukeUI
import SwiftUI
import User

public struct EditProfileView: View {
    @Environment(BSkyClient.self) var client
    @Environment(CurrentUser.self) var currentUser
    @Environment(\.dismiss) var dismiss

    @State private var displayName: String
    @State private var description: String
    @State private var isLoading = false
    @State private var error: Error?

    public init() {
        _displayName = State(initialValue: "")
        _description = State(initialValue: "")
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Display Name", text: $displayName)

                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Bio")
                                .foregroundStyle(.secondary)
                                .padding(.leading, 5)
                                .padding(.top, 8)
                        }

                        TextEditor(text: $description)
                            .frame(height: 120)
                    }
                }

                if let error {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button(action: saveProfile) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Save Changes")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                loadCurrentProfile()
            }
        }
    }

    private func loadCurrentProfile() {
        guard let profile = currentUser.profile else { return }

        displayName = profile.profile.displayName ?? ""
        description = profile.profile.description ?? ""
    }

    private func saveProfile() {
        isLoading = true
        error = nil

        Task {
            do {
                guard let currentProfile = currentUser.profile else {
                    throw NSError(
                        domain: "EditProfile", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No current profile found"])
                }

                // For now, just simulate a profile update
                // In a complete implementation, this would update the profile via ATProto
                print(
                    "Profile update requested: displayName=\(displayName), description=\(description)"
                )

                // Simulate a successful update for demo purposes

                // Update local user profile
                try await currentUser.refresh()

                await MainActor.run {
                    isLoading = false
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
}
