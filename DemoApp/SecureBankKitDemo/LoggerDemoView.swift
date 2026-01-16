import SwiftUI
import SecureBankKit

struct LoggerDemoView: View {
    @State private var logMessage = "User logged in"
    @State private var sensitiveInput = "4111111111111111"
    @State private var redactedOutput = ""
    @State private var visibleCount: Double = 4

    var body: some View {
        List {
            Section("Log Messages") {
                TextField("Message", text: $logMessage)

                Button("Log Info") {
                    SecureLogger.info(logMessage)
                }
                Button("Log Warning") {
                    SecureLogger.warning(logMessage)
                }
                Button("Log Error") {
                    SecureLogger.error(logMessage)
                }

                Text("Check Xcode console for output")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Data Redaction") {
                TextField("Sensitive Data", text: $sensitiveInput)
                    .textInputAutocapitalization(.never)

                HStack {
                    Text("Visible Chars")
                    Slider(value: $visibleCount, in: 0...10, step: 1)
                    Text("\(Int(visibleCount))")
                        .monospacedDigit()
                        .frame(width: 24)
                }

                Button("Redact") {
                    redactedOutput = SecureLogger.redact(sensitiveInput, visibleCount: Int(visibleCount))
                }

                if !redactedOutput.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Original:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(sensitiveInput)
                            .font(.system(.body, design: .monospaced))

                        Text("Redacted:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        Text(redactedOutput)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Secure Logger")
    }
}

#Preview {
    NavigationStack {
        LoggerDemoView()
    }
}
