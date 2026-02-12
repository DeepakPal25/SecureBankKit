import SwiftUI
import SecureBankKit

struct JailbreakDemoView: View {
    @State private var isJailbroken: Bool?
    @State private var hasChecked = false

    var body: some View {
        List {
            Section("Jailbreak Detection") {
                Button("Run Check") {
                    isJailbroken = JailbreakDetector.isJailbroken()
                    hasChecked = true
                }

                if hasChecked, let isJailbroken {
                    HStack {
                        Image(systemName: isJailbroken ? "xmark.shield.fill" : "checkmark.shield.fill")
                            .foregroundStyle(isJailbroken ? .red : .green)
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text(isJailbroken ? "Jailbreak Detected" : "Device is Clean")
                                .font(.headline)
                            Text(isJailbroken
                                 ? "This device shows signs of being jailbroken."
                                 : "No jailbreak indicators found.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("What It Checks") {
                Label("Suspicious file paths (Cydia, sshd, etc.)", systemImage: "folder.badge.questionmark")
                Label("Writable system directories", systemImage: "pencil.and.outline")
                Label("Cydia URL scheme", systemImage: "link")
                Label("Suspicious dyld images", systemImage: "cpu")
            }

            Section {
                Text("On the iOS Simulator, the detector always returns false to avoid false positives.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Jailbreak Detection")
    }
}

#Preview {
    NavigationStack {
        JailbreakDemoView()
    }
}
