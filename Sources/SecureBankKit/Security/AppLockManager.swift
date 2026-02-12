import Foundation
import UIKit

/// Locks the app when it enters the background and requires biometric re-authentication on foreground.
///
/// ```swift
/// let lockManager = AppLockManager(biometricManager: BiometricAuthManager())
/// lockManager.onLockStatusChanged = { isLocked in
///     print(isLocked ? "App locked" : "App unlocked")
/// }
/// lockManager.enable()
/// ```
@MainActor
public final class AppLockManager {

    // MARK: - Properties

    /// Delay in seconds after backgrounding before locking (default 0 = immediate).
    public var lockDelay: TimeInterval

    /// Called whenever the lock status changes. `true` means the app is locked.
    public var onLockStatusChanged: ((_ isLocked: Bool) -> Void)?

    /// Whether the app is currently in a locked state.
    public private(set) var isLocked: Bool = false

    private let biometricManager: BiometricAuthManager
    private var backgroundTimestamp: Date?
    private var isEnabled: Bool = false

    // MARK: - Init

    /// Creates an app lock manager.
    ///
    /// - Parameters:
    ///   - biometricManager: The ``BiometricAuthManager`` used for re-authentication.
    ///   - lockDelay: Seconds after backgrounding before lock engages (default 0).
    public init(biometricManager: BiometricAuthManager, lockDelay: TimeInterval = 0) {
        self.biometricManager = biometricManager
        self.lockDelay = lockDelay
    }

    // MARK: - Public API

    /// Starts observing app lifecycle notifications to manage locking.
    public func enable() {
        guard !isEnabled else { return }
        isEnabled = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        SecureLogger.info("AppLockManager enabled")
    }

    /// Stops observing lifecycle notifications and unlocks the app.
    public func disable() {
        isEnabled = false
        NotificationCenter.default.removeObserver(self)
        setLocked(false)
        SecureLogger.info("AppLockManager disabled")
    }

    // MARK: - Notifications

    @objc private func appDidEnterBackground() {
        backgroundTimestamp = Date()
        SecureLogger.info("App entered background")
    }

    @objc private func appWillEnterForeground() {
        guard isEnabled else { return }

        if shouldLock() {
            setLocked(true)
            Task {
                await attemptUnlock()
            }
        }

        backgroundTimestamp = nil
    }

    // MARK: - Private

    private func shouldLock() -> Bool {
        guard let backgroundTimestamp else { return true }
        let elapsed = Date().timeIntervalSince(backgroundTimestamp)
        return elapsed >= lockDelay
    }

    private func setLocked(_ locked: Bool) {
        guard isLocked != locked else { return }
        isLocked = locked
        onLockStatusChanged?(locked)
    }

    private func attemptUnlock() async {
        do {
            let success = try await biometricManager.authenticate(reason: "Unlock SecureBankKit")
            if success {
                setLocked(false)
                SecureLogger.info("App unlocked via biometrics")
            }
        } catch {
            SecureLogger.error("Biometric unlock failed: \(error.localizedDescription)")
        }
    }
}
