import Foundation
import UIKit
import UniformTypeIdentifiers

/// Copies sensitive values (account numbers, OTPs, card numbers) to the system
/// pasteboard with an automatic expiry and without syncing to other devices.
///
/// ```swift
/// PasteboardProtector.copySensitive("4111 1111 1111 1111", expiresAfter: 30)
/// // ... later, or on logout:
/// PasteboardProtector.clear()
/// ```
public enum PasteboardProtector {

    /// Copies a sensitive string to the general pasteboard with an expiry.
    ///
    /// - Parameters:
    ///   - string: The value to copy.
    ///   - interval: Seconds until the pasteboard contents expire (default 60).
    ///   - localOnly: When `true`, the value is not shared via Handoff / Universal
    ///     Clipboard to other devices (default `true`).
    @MainActor
    public static func copySensitive(
        _ string: String,
        expiresAfter interval: TimeInterval = 60,
        localOnly: Bool = true
    ) {
        var options: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(interval)
        ]
        if localOnly {
            options[.localOnly] = true
        }

        let item: [String: Any] = [UTType.utf8PlainText.identifier: string]
        UIPasteboard.general.setItems([item], options: options)

        SecureLogger.info("Copied sensitive value to pasteboard (expires in \(Int(interval))s)")
    }

    /// Immediately clears the general pasteboard.
    @MainActor
    public static func clear() {
        UIPasteboard.general.items = []
        SecureLogger.info("Pasteboard cleared")
    }
}
