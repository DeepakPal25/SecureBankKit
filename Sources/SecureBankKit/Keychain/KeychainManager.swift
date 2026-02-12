import Foundation
import Security

/// Errors thrown by ``KeychainManager``.
public enum KeychainError: Error, Sendable {
    /// The operation returned an unexpected OSStatus code.
    case unhandledError(status: OSStatus)
    /// The requested item was not found.
    case itemNotFound
    /// A duplicate item already exists (used internally; save overwrites by default).
    case duplicateItem
    /// The provided data could not be encoded or decoded.
    case encodingError
}

/// Low-level Keychain CRUD wrapper using the Security framework.
///
/// Each instance is scoped to a `service` identifier so different subsystems
/// can store data without key collisions.
///
/// ```swift
/// let keychain = KeychainManager(service: "com.myapp.auth")
/// try keychain.save(string: "secret", forKey: "api-key")
/// let value = try keychain.readString(forKey: "api-key")
/// ```
public final class KeychainManager: Sendable {

    /// The service identifier used to scope keychain items.
    public let service: String

    /// The accessibility level for stored items.
    public nonisolated(unsafe) let accessibility: CFString

    /// Creates a new manager scoped to the given service.
    ///
    /// - Parameters:
    ///   - service: A reverse-DNS style identifier (e.g. `"com.myapp.auth"`).
    ///   - accessibility: The `kSecAttrAccessible` value (default: `afterFirstUnlock`).
    public init(service: String, accessibility: CFString = kSecAttrAccessibleAfterFirstUnlock) {
        self.service = service
        self.accessibility = accessibility
    }

    // MARK: - Save

    /// Saves raw data to the keychain under the specified key.
    ///
    /// If an item with the same key already exists it will be overwritten.
    ///
    /// - Parameters:
    ///   - data: The data to store.
    ///   - key: The key to store it under.
    public func save(data: Data, forKey key: String) throws {
        let query = baseQuery(forKey: key)

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = accessibility

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Saves a UTF-8 string to the keychain under the specified key.
    ///
    /// - Parameters:
    ///   - string: The string value to store.
    ///   - key: The key to store it under.
    public func save(string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        try save(data: data, forKey: key)
    }

    // MARK: - Read

    /// Reads raw data from the keychain for the given key.
    ///
    /// - Parameter key: The key to look up.
    /// - Returns: The stored `Data`, or `nil` if not found.
    public func readData(forKey key: String) throws -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Reads a UTF-8 string from the keychain for the given key.
    ///
    /// - Parameter key: The key to look up.
    /// - Returns: The stored string, or `nil` if not found.
    public func readString(forKey key: String) throws -> String? {
        guard let data = try readData(forKey: key) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.encodingError
        }
        return string
    }

    // MARK: - Delete

    /// Deletes the item stored under the given key.
    ///
    /// - Parameter key: The key to delete.
    public func delete(forKey key: String) throws {
        let query = baseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Deletes all items stored under this manager's service.
    public func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: - Private

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
