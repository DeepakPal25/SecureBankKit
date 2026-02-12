import SwiftUI
import SecureBankKit

struct KeychainDemoView: View {
    private let keychain = KeychainManager(service: "com.securebankkit.demo")
    @State private var keyInput = ""
    @State private var valueInput = ""
    @State private var readResult = ""
    @State private var statusMessage = ""

    var body: some View {
        List {
            Section("Save to Keychain") {
                TextField("Key", text: $keyInput)
                    .textInputAutocapitalization(.never)
                TextField("Value", text: $valueInput)
                    .textInputAutocapitalization(.never)

                Button("Save") {
                    save()
                }
                .disabled(keyInput.isEmpty || valueInput.isEmpty)
            }

            Section("Read from Keychain") {
                Button("Read Value") {
                    read()
                }
                .disabled(keyInput.isEmpty)

                if !readResult.isEmpty {
                    HStack {
                        Text("Result:")
                        Spacer()
                        Text(readResult)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Delete") {
                Button("Delete Key") {
                    delete()
                }
                .disabled(keyInput.isEmpty)

                Button("Delete All", role: .destructive) {
                    deleteAll()
                }
            }

            if !statusMessage.isEmpty {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Keychain Storage")
    }

    private func save() {
        do {
            try keychain.save(string: valueInput, forKey: keyInput)
            statusMessage = "Saved '\(keyInput)' successfully"
        } catch {
            statusMessage = "Error: \(error)"
        }
    }

    private func read() {
        do {
            if let value = try keychain.readString(forKey: keyInput) {
                readResult = value
                statusMessage = "Read successful"
            } else {
                readResult = "(nil)"
                statusMessage = "Key not found"
            }
        } catch {
            statusMessage = "Error: \(error)"
        }
    }

    private func delete() {
        do {
            try keychain.delete(forKey: keyInput)
            readResult = ""
            statusMessage = "Deleted '\(keyInput)'"
        } catch {
            statusMessage = "Error: \(error)"
        }
    }

    private func deleteAll() {
        do {
            try keychain.deleteAll()
            readResult = ""
            statusMessage = "All keys deleted"
        } catch {
            statusMessage = "Error: \(error)"
        }
    }
}

#Preview {
    NavigationStack {
        KeychainDemoView()
    }
}
