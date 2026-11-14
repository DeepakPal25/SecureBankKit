import SwiftUI
import SecureBankKit

struct ScreenCaptureDemoView: View {
    @State private var protector = ScreenCaptureProtector()
    @State private var isCaptured = false
    @State private var isMonitoring = false
    @State private var screenshotCount = 0

    var body: some View {
        List {
            Section("Screen Capture") {
                Toggle("Monitor Capture", isOn: $isMonitoring)
                    .onChange(of: isMonitoring) { _, enabled in
                        if enabled {
                            protector.onCaptureStatusChanged = { captured in
                                isCaptured = captured
                            }
                            protector.onScreenshotTaken = {
                                screenshotCount += 1
                            }
                            protector.startMonitoring()
                            isCaptured = protector.isCaptured
                        } else {
                            protector.stopMonitoring()
                        }
                    }

                HStack {
                    Image(systemName: isCaptured ? "record.circle.fill" : "record.circle")
                        .foregroundStyle(isCaptured ? .red : .secondary)
                    Text(isCaptured ? "Screen is being captured" : "No capture detected")
                }

                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text("Screenshots taken")
                    Spacer()
                    Text("\(screenshotCount)")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("Start a screen recording or mirror the device to see the capture status change. Take a screenshot to increment the counter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Screen Capture")
    }
}

#Preview {
    NavigationStack {
        ScreenCaptureDemoView()
    }
}
