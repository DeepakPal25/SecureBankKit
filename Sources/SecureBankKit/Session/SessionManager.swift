import Foundation

/// Manages user session lifecycle including inactivity timeout.
///
/// Integrates with ``SecureTokenStorage`` for token cleanup and
/// ``TokenExpiryManager`` for token validity checks.
///
/// ```swift
/// let session = SessionManager(
///     tokenStorage: tokenStorage,
///     tokenExpiryManager: expiryManager,
///     sessionTimeout: 300
/// )
/// session.onSessionExpired = { print("Session timed out") }
/// session.startSession()
/// session.recordActivity()
/// ```
@MainActor
public final class SessionManager {

    // MARK: - Properties

    /// The inactivity timeout interval in seconds (default 300 = 5 minutes).
    public var sessionTimeout: TimeInterval

    /// Whether a session is currently active.
    public private(set) var isSessionActive: Bool = false

    /// Called when the session expires due to inactivity or token expiry.
    public var onSessionExpired: (() -> Void)?

    private let tokenStorage: SecureTokenStorage
    private let tokenExpiryManager: TokenExpiryManager
    private var inactivityTimer: Timer?
    private var lastActivityDate: Date = Date()

    // MARK: - Init

    /// Creates a session manager.
    ///
    /// - Parameters:
    ///   - tokenStorage: The token storage used to clear tokens on session end.
    ///   - tokenExpiryManager: The expiry manager used to validate token freshness.
    ///   - sessionTimeout: Inactivity timeout in seconds (default 300).
    public init(
        tokenStorage: SecureTokenStorage,
        tokenExpiryManager: TokenExpiryManager,
        sessionTimeout: TimeInterval = 300
    ) {
        self.tokenStorage = tokenStorage
        self.tokenExpiryManager = tokenExpiryManager
        self.sessionTimeout = sessionTimeout
    }

    // MARK: - Session Lifecycle

    /// Starts a new session and begins the inactivity timer.
    public func startSession() {
        isSessionActive = true
        lastActivityDate = Date()
        startInactivityTimer()
        SecureLogger.info("Session started")
    }

    /// Ends the current session, clears tokens, and stops timers.
    public func endSession() {
        isSessionActive = false
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        tokenStorage.clearTokens()
        SecureLogger.info("Session ended")
    }

    /// Records user activity and resets the inactivity timer.
    ///
    /// Call this on meaningful user interactions (e.g. taps, navigation).
    public func recordActivity() {
        lastActivityDate = Date()
        startInactivityTimer()
    }

    /// Checks whether the session is still valid (not timed out, token not expired).
    ///
    /// - Returns: `true` if the session is active and the token has not expired.
    public func checkSessionValidity() -> Bool {
        guard isSessionActive else { return false }

        if tokenExpiryManager.isTokenExpired() {
            handleSessionExpiry()
            return false
        }

        let elapsed = Date().timeIntervalSince(lastActivityDate)
        if elapsed >= sessionTimeout {
            handleSessionExpiry()
            return false
        }

        return true
    }

    // MARK: - Private

    private func startInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(
            withTimeInterval: sessionTimeout,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSessionExpiry()
            }
        }
    }

    private func handleSessionExpiry() {
        SecureLogger.warning("Session expired")
        endSession()
        onSessionExpired?()
    }
}
