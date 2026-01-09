import Foundation

/// Tracks token expiry and provides a hook for automatic refresh.
///
/// ```swift
/// let expiryManager = TokenExpiryManager()
/// expiryManager.setExpiry(Date().addingTimeInterval(3600))
///
/// if expiryManager.shouldRefreshToken() {
///     try await expiryManager.refreshIfNeeded {
///         // call your refresh endpoint
///         return Date().addingTimeInterval(3600)
///     }
/// }
/// ```
public final class TokenExpiryManager {

    /// The date at which the current token expires.
    public private(set) var expiryDate: Date?

    /// How many seconds before the actual expiry we should proactively refresh.
    public var refreshBufferInterval: TimeInterval

    /// Creates a new expiry manager.
    ///
    /// - Parameter refreshBufferInterval: Buffer in seconds before expiry to trigger refresh (default 60).
    public init(refreshBufferInterval: TimeInterval = 60) {
        self.refreshBufferInterval = refreshBufferInterval
    }

    /// Sets the token expiry date.
    ///
    /// - Parameter date: The date when the token expires.
    public func setExpiry(_ date: Date) {
        self.expiryDate = date
    }

    /// Returns `true` if the token has already expired.
    public func isTokenExpired() -> Bool {
        guard let expiryDate else { return true }
        return Date() >= expiryDate
    }

    /// Returns `true` if the token will expire within the ``refreshBufferInterval``.
    ///
    /// This is useful for proactively refreshing before the token actually expires.
    public func shouldRefreshToken() -> Bool {
        guard let expiryDate else { return true }
        return Date() >= expiryDate.addingTimeInterval(-refreshBufferInterval)
    }

    /// Refreshes the token if it is within the buffer window, using the provided closure.
    ///
    /// The closure should perform the actual network refresh and return the new expiry date.
    ///
    /// - Parameter refreshAction: An async throwing closure that refreshes the token and returns the new expiry.
    public func refreshIfNeeded(using refreshAction: () async throws -> Date) async throws {
        guard shouldRefreshToken() else { return }
        let newExpiry = try await refreshAction()
        setExpiry(newExpiry)
    }
}
