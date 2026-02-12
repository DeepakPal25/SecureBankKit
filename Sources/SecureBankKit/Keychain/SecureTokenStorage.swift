import Foundation

/// High-level token storage built on top of ``KeychainManager``.
///
/// Provides a focused API for persisting access and refresh tokens
/// without exposing low-level keychain details.
///
/// ```swift
/// let keychain = KeychainManager(service: "com.myapp.auth")
/// let tokenStorage = SecureTokenStorage(keychainManager: keychain)
/// try tokenStorage.saveAccessToken("eyJhbGci...")
/// let token = tokenStorage.getAccessToken()
/// ```
public final class SecureTokenStorage: Sendable {

    // MARK: - Keys

    private enum Keys {
        static let accessToken  = "com.securebankkit.accessToken"
        static let refreshToken = "com.securebankkit.refreshToken"
    }

    // MARK: - Properties

    private let keychainManager: KeychainManager

    // MARK: - Init

    /// Creates a new token storage backed by the given keychain manager.
    ///
    /// - Parameter keychainManager: The ``KeychainManager`` instance to use for persistence.
    public init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
    }

    // MARK: - Access Token

    /// Persists an access token in the keychain.
    ///
    /// - Parameter token: The access token string.
    public func saveAccessToken(_ token: String) throws {
        try keychainManager.save(string: token, forKey: Keys.accessToken)
    }

    /// Retrieves the stored access token, if any.
    ///
    /// - Returns: The access token string, or `nil` if none is stored.
    public func getAccessToken() -> String? {
        try? keychainManager.readString(forKey: Keys.accessToken)
    }

    // MARK: - Refresh Token

    /// Persists a refresh token in the keychain.
    ///
    /// - Parameter token: The refresh token string.
    public func saveRefreshToken(_ token: String) throws {
        try keychainManager.save(string: token, forKey: Keys.refreshToken)
    }

    /// Retrieves the stored refresh token, if any.
    ///
    /// - Returns: The refresh token string, or `nil` if none is stored.
    public func getRefreshToken() -> String? {
        try? keychainManager.readString(forKey: Keys.refreshToken)
    }

    // MARK: - Clear

    /// Removes both access and refresh tokens from the keychain.
    public func clearTokens() {
        try? keychainManager.delete(forKey: Keys.accessToken)
        try? keychainManager.delete(forKey: Keys.refreshToken)
    }
}
