import Foundation
import Testing
@testable import SecureBankKit

@Suite("SecureTokenStorage",
       .enabled(if: keychainAvailable, "Keychain requires entitlements not present in this test runner"))
struct SecureTokenStorageTests {

    private func makeStorage() -> (SecureTokenStorage, KeychainManager) {
        let keychain = KeychainManager(service: "com.securebankkit.tests.tokens.\(UUID().uuidString)")
        return (SecureTokenStorage(keychainManager: keychain), keychain)
    }

    @Test func saveAndRetrieveAccessToken() throws {
        let (storage, keychain) = makeStorage()
        defer { try? keychain.deleteAll() }

        try storage.saveAccessToken("access123")
        #expect(storage.getAccessToken() == "access123")
    }

    @Test func saveAndRetrieveRefreshToken() throws {
        let (storage, keychain) = makeStorage()
        defer { try? keychain.deleteAll() }

        try storage.saveRefreshToken("refresh456")
        #expect(storage.getRefreshToken() == "refresh456")
    }

    @Test func getAccessTokenWhenNoneSavedReturnsNil() {
        let (storage, _) = makeStorage()
        #expect(storage.getAccessToken() == nil)
    }

    @Test func getRefreshTokenWhenNoneSavedReturnsNil() {
        let (storage, _) = makeStorage()
        #expect(storage.getRefreshToken() == nil)
    }

    @Test func clearTokensRemovesBoth() throws {
        let (storage, keychain) = makeStorage()
        defer { try? keychain.deleteAll() }

        try storage.saveAccessToken("access")
        try storage.saveRefreshToken("refresh")
        storage.clearTokens()

        #expect(storage.getAccessToken() == nil)
        #expect(storage.getRefreshToken() == nil)
    }

    @Test func clearTokensWhenNoneExistDoesNotCrash() {
        let (storage, _) = makeStorage()
        storage.clearTokens()
    }

    @Test func overwriteAccessToken() throws {
        let (storage, keychain) = makeStorage()
        defer { try? keychain.deleteAll() }

        try storage.saveAccessToken("old")
        try storage.saveAccessToken("new")
        #expect(storage.getAccessToken() == "new")
    }

    @Test func overwriteRefreshToken() throws {
        let (storage, keychain) = makeStorage()
        defer { try? keychain.deleteAll() }

        try storage.saveRefreshToken("old")
        try storage.saveRefreshToken("new")
        #expect(storage.getRefreshToken() == "new")
    }

    @Test func tokensAreIndependent() throws {
        let (storage, keychain) = makeStorage()
        defer { try? keychain.deleteAll() }

        try storage.saveAccessToken("access")
        try storage.saveRefreshToken("refresh")

        try storage.saveAccessToken("newAccess")
        #expect(storage.getRefreshToken() == "refresh")
    }
}
