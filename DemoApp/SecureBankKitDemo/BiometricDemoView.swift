import SwiftUI
import SecureBankKit

struct BiometricDemoView: View {
    private let biometricManager = BiometricAuthManager()
    @State private var biometricType: BiometricType = .none
    @State private var authResult: String = ""
    @State private var isAuthenticating = false

    var body: some View {
        List {
            Section("Device Capability") {
                HStack {
                    Text("Biometric Type")
                    Spacer()
                    Text(biometricLabel)
                        .foregroundStyle(.secondary)
                }

                Button("Check Biometrics") {
                    biometricType = biometricManager.canEvaluateBiometrics()
                }
            }

            Section("Authentication") {
                Button {
                    authenticate()
                } label: {
                    HStack {
                        Text("Authenticate")
                        if isAuthenticating {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isAuthenticating)

                if !authResult.isEmpty {
                    Text(authResult)
                        .foregroundStyle(authResult.contains("Success") ? .green : .red)
                }
            }
        }
        .navigationTitle("Biometric Auth")
        .onAppear {
            biometricType = biometricManager.canEvaluateBiometrics()
        }
    }

    private var biometricLabel: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "Not Available"
        }
    }

    private func authenticate() {
        isAuthenticating = true
        authResult = ""
        Task {
            do {
                let success = try await biometricManager.authenticate(reason: "Verify your identity")
                authResult = success ? "Success - Authenticated!" : "Failed"
            } catch {
                authResult = "Error: \(error.localizedDescription)"
            }
            isAuthenticating = false
        }
    }
}

#Preview {
    NavigationStack {
        BiometricDemoView()
    }
}
