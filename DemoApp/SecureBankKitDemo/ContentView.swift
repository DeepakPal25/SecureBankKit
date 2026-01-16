import SwiftUI
import SecureBankKit

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("SecureBankKit")
                            .font(.headline)
                        Spacer()
                        Text("v\(SecureBankKit.version)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Security Features") {
                    NavigationLink {
                        BiometricDemoView()
                    } label: {
                        Label("Biometric Auth", systemImage: "faceid")
                    }

                    NavigationLink {
                        KeychainDemoView()
                    } label: {
                        Label("Keychain Storage", systemImage: "key.fill")
                    }

                    NavigationLink {
                        TokenDemoView()
                    } label: {
                        Label("Token Storage", systemImage: "lock.shield.fill")
                    }

                    NavigationLink {
                        SessionDemoView()
                    } label: {
                        Label("Session Manager", systemImage: "timer")
                    }

                    NavigationLink {
                        JailbreakDemoView()
                    } label: {
                        Label("Jailbreak Detection", systemImage: "exclamationmark.shield.fill")
                    }

                    NavigationLink {
                        LoggerDemoView()
                    } label: {
                        Label("Secure Logger", systemImage: "doc.text.magnifyingglass")
                    }
                }
            }
            .navigationTitle("SecureBankKit Demo")
        }
    }
}

#Preview {
    ContentView()
}
