import Foundation
import UIKit

/// Monitors screen recording / mirroring and screenshot events so sensitive screens
/// can respond (e.g. by hiding content or warning the user).
///
/// ```swift
/// let protector = ScreenCaptureProtector()
/// protector.onCaptureStatusChanged = { isCaptured in
///     // blur sensitive content while the screen is being recorded
/// }
/// protector.onScreenshotTaken = {
///     // log or warn that a screenshot was captured
/// }
/// protector.startMonitoring()
/// ```
@MainActor
public final class ScreenCaptureProtector {

    // MARK: - Properties

    /// Whether the screen is currently being captured (recorded or mirrored).
    public private(set) var isCaptured: Bool = UIScreen.main.isCaptured

    /// Called whenever the capture status changes. `true` means capture is active.
    public var onCaptureStatusChanged: ((_ isCaptured: Bool) -> Void)?

    /// Called when the user takes a screenshot.
    public var onScreenshotTaken: (() -> Void)?

    private var isMonitoring = false

    // MARK: - Init

    public init() {}

    // MARK: - Public API

    /// Starts observing screen capture and screenshot notifications.
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        isCaptured = UIScreen.main.isCaptured

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(captureDidChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )

        SecureLogger.info("ScreenCaptureProtector started")
    }

    /// Stops observing capture and screenshot notifications.
    public func stopMonitoring() {
        isMonitoring = false
        NotificationCenter.default.removeObserver(self)
        SecureLogger.info("ScreenCaptureProtector stopped")
    }

    // MARK: - Notifications

    @objc private func captureDidChange() {
        let captured = UIScreen.main.isCaptured
        guard captured != isCaptured else { return }
        isCaptured = captured
        onCaptureStatusChanged?(captured)
        SecureLogger.warning(captured ? "Screen capture started" : "Screen capture stopped")
    }

    @objc private func screenshotTaken() {
        onScreenshotTaken?()
        SecureLogger.warning("Screenshot taken")
    }
}
