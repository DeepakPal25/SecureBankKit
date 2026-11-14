import SwiftUI
import SecureBankKit

struct PasteboardDemoView: View {
    @State private var value = "4111 1111 1111 1111"
    @State private var status = ""

    var body: some View {
        List {
            Section("Sensitive Value") {
                TextField("Value to copy", text: $value)

                Button("Copy (expires in 30s)") {
                    PasteboardProtector.copySensitive(value, expiresAfter: 30)
                    status = "Copied — will auto-expire in 30 seconds"
                }

                Button("Clear Pasteboard", role: .destructive) {
                    PasteboardProtector.clear()
                    status = "Pasteboard cleared"
                }
            }

            if !status.isEmpty {
                Section {
                    Label(status, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("Copied values are local-only (no Universal Clipboard) and expire automatically so sensitive data does not linger on the pasteboard.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Pasteboard")
    }
}

#Preview {
    NavigationStack {
        PasteboardDemoView()
    }
}
