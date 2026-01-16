import SwiftUI
import SecureBankKit

struct SessionDemoView: View {
    @State private var sessionManager: SessionManager?
    @State private var isActive = false
    @State private var timeoutSeconds: Double = 30
    @State private var statusLog: [String] = []

    private let keychain = KeychainManager(service: "com.securebankkit.demo.session")
    private let expiryManager = TokenExpiryManager()

    var body: some View {
        List {
            Section("Session Config") {
                HStack {
                    Text("Timeout")
                    Slider(value: $timeoutSeconds, in: 5...120, step: 5)
                    Text("\(Int(timeoutSeconds))s")
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }

            Section("Controls") {
                Button("Start Session") {
                    startSession()
                }
                .disabled(isActive)

                Button("Record Activity") {
                    sessionManager?.recordActivity()
                    log("Activity recorded")
                }
                .disabled(!isActive)

                Button("Check Validity") {
                    if let valid = sessionManager?.checkSessionValidity() {
                        log("Session valid: \(valid)")
                    }
                }

                Button("End Session", role: .destructive) {
                    sessionManager?.endSession()
                    isActive = false
                    log("Session ended manually")
                }
                .disabled(!isActive)
            }

            Section("Status") {
                HStack {
                    Circle()
                        .fill(isActive ? .green : .red)
                        .frame(width: 10, height: 10)
                    Text(isActive ? "Session Active" : "Session Inactive")
                }
            }

            if !statusLog.isEmpty {
                Section("Log") {
                    ForEach(statusLog.reversed(), id: \.self) { entry in
                        Text(entry)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Session Manager")
    }

    private func startSession() {
        let tokenStorage = SecureTokenStorage(keychainManager: keychain)
        expiryManager.setExpiry(Date().addingTimeInterval(3600))

        let manager = SessionManager(
            tokenStorage: tokenStorage,
            tokenExpiryManager: expiryManager,
            sessionTimeout: timeoutSeconds
        )

        manager.onSessionExpired = {
            isActive = false
            log("Session expired (timeout)")
        }

        manager.startSession()
        sessionManager = manager
        isActive = true
        log("Session started (timeout: \(Int(timeoutSeconds))s)")
    }

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        statusLog.append("[\(formatter.string(from: Date()))] \(message)")
    }
}

#Preview {
    NavigationStack {
        SessionDemoView()
    }
}
