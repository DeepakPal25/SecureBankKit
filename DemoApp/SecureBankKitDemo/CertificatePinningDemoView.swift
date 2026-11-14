import SwiftUI
import SecureBankKit

struct CertificatePinningDemoView: View {
    @State private var host = "https://example.com"
    @State private var pinHash = ""
    @State private var result = ""
    @State private var isLoading = false

    var body: some View {
        List {
            Section("Pinned Request") {
                TextField("URL", text: $host)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Pinned SHA-256 (base64)", text: $pinHash)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Send Request") {
                    Task { await sendRequest() }
                }
                .disabled(isLoading || pinHash.isEmpty)
            }

            if isLoading {
                Section { ProgressView() }
            }

            if !result.isEmpty {
                Section("Result") {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("A correct pin lets the request through; a wrong pin cancels the TLS handshake, blocking man-in-the-middle proxies.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Certificate Pinning")
    }

    private func sendRequest() async {
        guard let url = URL(string: host) else {
            result = "Invalid URL"
            return
        }
        isLoading = true
        result = ""

        let pinner = CertificatePinner(pinnedHashes: [pinHash])
        let session = pinner.makeSession()
        defer { session.finishTasksAndInvalidate() }

        do {
            let (_, response) = try await session.data(from: url)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            result = "✅ Pin matched — HTTP \(code)"
        } catch {
            result = "❌ Request failed (pin mismatch or network error)"
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        CertificatePinningDemoView()
    }
}
