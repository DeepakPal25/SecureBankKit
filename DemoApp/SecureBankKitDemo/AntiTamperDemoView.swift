import SwiftUI
import SecureBankKit

struct AntiTamperDemoView: View {
    @State private var debuggerAttached: Bool?
    @State private var injectedLibraries: Bool?
    @State private var hasChecked = false

    var body: some View {
        List {
            Section("Anti-Tamper Detection") {
                Button("Run Check") {
                    debuggerAttached = AntiTamperDetector.isDebuggerAttached()
                    injectedLibraries = AntiTamperDetector.hasInjectedLibraries()
                    hasChecked = true
                }

                if hasChecked {
                    resultRow(
                        title: "Debugger Attached",
                        flagged: debuggerAttached ?? false
                    )
                    resultRow(
                        title: "Injected Libraries",
                        flagged: injectedLibraries ?? false
                    )
                }
            }

            Section("What It Checks") {
                Label("Attached debugger (P_TRACED via sysctl)", systemImage: "ladybug")
                Label("DYLD_INSERT_LIBRARIES injection", systemImage: "arrow.down.doc")
            }

            Section {
                Text("Call denyDebuggerAttachment() once at launch in release builds to terminate the app if a debugger attaches.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Anti-Tamper")
    }

    private func resultRow(title: String, flagged: Bool) -> some View {
        HStack {
            Image(systemName: flagged ? "xmark.shield.fill" : "checkmark.shield.fill")
                .foregroundStyle(flagged ? .red : .green)
            Text(title)
            Spacer()
            Text(flagged ? "Detected" : "Clean")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        AntiTamperDemoView()
    }
}
