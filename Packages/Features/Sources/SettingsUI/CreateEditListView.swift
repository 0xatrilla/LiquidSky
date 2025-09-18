import Client
import Models
import SwiftUI
import User

public struct CreateEditListView: View {
  let list: UserList?

  @Environment(BSkyClient.self) private var client
  @Environment(CurrentUser.self) private var currentUser
  @Environment(\.dismiss) private var dismiss

  @State private var listName: String = ""
  @State private var listDescription: String = ""
  @State private var selectedPurpose: UserList.Purpose = .curation
  @State private var isLoading = false
  @State private var error: Error?
  @State private var showingSuccessAlert = false

  public init(list: UserList? = nil) {
    self.list = list
  }

  public var body: some View {
    NavigationView {
      Form {
        Section("List Details") {
          TextField("List Name", text: $listName)
            .textFieldStyle(.roundedBorder)

          TextField("Description (Optional)", text: $listDescription, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(3...6)
        }

        Section("Purpose") {
          Picker("Purpose", selection: $selectedPurpose) {
            HStack {
              Image(systemName: "star")
                .foregroundColor(.yellow)
              Text("Curation")
            }
            .tag(UserList.Purpose.curation)

            HStack {
              Image(systemName: "hand.raised")
                .foregroundColor(.orange)
              Text("Moderation")
            }
            .tag(UserList.Purpose.moderation)
          }
          .pickerStyle(.menu)

          Text(purposeDescription)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        if let error = error {
          Section {
            Text("Error: \(error.localizedDescription)")
              .foregroundColor(.red)
              .font(.caption)
          }
        }
      }
      .navigationTitle(list == nil ? "Create List" : "Edit List")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button(list == nil ? "Create" : "Save") {
            Task {
              await saveList()
            }
          }
          .disabled(listName.isEmpty || isLoading)
        }
      }
      .onAppear {
        if let list = list {
          listName = list.name
          listDescription = list.description ?? ""
          selectedPurpose = list.purpose
        }
      }
      .alert("Success", isPresented: $showingSuccessAlert) {
        Button("OK") {
          dismiss()
        }
      } message: {
        Text(list == nil ? "List created successfully!" : "List updated successfully!")
      }
    }
  }

  private var purposeDescription: String {
    switch selectedPurpose {
    case .curation:
      return "A list for curating interesting accounts to follow"
    case .moderation:
      return "A list for moderation purposes (muting/blocking)"
    case .mute:
      return "A list for muting accounts"
    case .block:
      return "A list for blocking accounts"
    }
  }

  private func saveList() async {
    guard !listName.isEmpty else { return }

    isLoading = true
    error = nil

    do {
      if let list = list {
        // Update existing list
        try await updateList(list)
      } else {
        // Create new list
        try await createList()
      }

      showingSuccessAlert = true
    } catch {
      self.error = error
    }

    isLoading = false
  }

  private func createList() async throws {
    let listManagementService = ListManagementService(client: client)
    let _ = try await listManagementService.createList(
      name: listName,
      description: listDescription.isEmpty ? nil : listDescription,
      purpose: selectedPurpose
    )
  }

  private func updateList(_ list: UserList) async throws {
    let listManagementService = ListManagementService(client: client)
    try await listManagementService.updateList(
      listURI: list.id,
      name: listName,
      description: listDescription.isEmpty ? nil : listDescription,
      purpose: selectedPurpose
    )
  }
}

#Preview {
  CreateEditListView()
}
