import SwiftUI
import SecureBankKit

struct TokenDemoView: View {
    private let keychain = KeychainManager(service: "com.securebankkit.demo.tokens")
    private var tokenStorage: SecureTokenStorage {
        SecureTokenStorage(keychainManager: keychain)
    }

    @State private var accessToken = ""
    @State private var refreshToken = ""
    @State private var storedAccess: String?
    @State private var storedRefresh: String?
    @State private var statusMessage = ""

    var body: some View {
        List {
            Section("Save Tokens") {
                TextField("Access Token", text: $accessToken)
                    .textInputAutocapitalization(.never)
                TextField("Refresh Token", text: $refreshToken)
                    .textInputAutocapitalization(.never)

                Button("Save Both Tokens") {
                    saveTokens()
                }
                .disabled(accessToken.isEmpty && refreshToken.isEmpty)
            }

            Section("Stored Tokens") {
                HStack {
                    Text("Access Token")
                    Spacer()
                    Text(storedAccess ?? "(empty)")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Text("Refresh Token")
                    Spacer()
                    Text(storedRefresh ?? "(empty)")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Button("Refresh from Keychain") {
                    loadTokens()
                }
            }

            Section {
                Button("Clear All Tokens", role: .destructive) {
                    tokenStorage.clearTokens()
                    loadTokens()
                    statusMessage = "Tokens cleared"
                }
            }

            if !statusMessage.isEmpty {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Token Storage")
        .onAppear { loadTokens() }
    }

    private func saveTokens() {
        do {
            if !accessToken.isEmpty {
                try tokenStorage.saveAccessToken(accessToken)
            }
            if !refreshToken.isEmpty {
                try tokenStorage.saveRefreshToken(refreshToken)
            }
            loadTokens()
            statusMessage = "Tokens saved"
        } catch {
            statusMessage = "Error: \(error)"
        }
    }

    private func loadTokens() {
        storedAccess = tokenStorage.getAccessToken()
        storedRefresh = tokenStorage.getRefreshToken()
    }
}

#Preview {
    NavigationStack {
        TokenDemoView()
    }
}
