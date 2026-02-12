import Foundation
import Security
import Testing
@testable import SecureBankKit

@Suite("KeychainManager",
       .enabled(if: keychainAvailable, "Keychain requires entitlements not present in this test runner"))
struct KeychainManagerTests {

    private func makeKeychain() -> KeychainManager {
        KeychainManager(service: "com.securebankkit.tests.\(UUID().uuidString)")
    }

    // MARK: - Save & Read

    @Test func saveAndReadString() throws {
        let keychain = makeKeychain()
        defer { try? keychain.deleteAll() }

        try keychain.save(string: "hello", forKey: "key1")
        let value = try keychain.readString(forKey: "key1")
        #expect(value == "hello")
    }

    @Test func saveAndReadData() throws {
        let keychain = makeKeychain()
        defer { try? keychain.deleteAll() }

        let data = Data([0x00, 0x01, 0xFF, 0xFE])
        try keychain.save(data: data, forKey: "binKey")
        let result = try keychain.readData(forKey: "binKey")
        #expect(result == data)
    }

    @Test func saveEmptyString() throws {
        let keychain = makeKeychain()
        defer { try? keychain.deleteAll() }

        try keychain.save(string: "", forKey: "emptyStr")
        let value = try keychain.readString(forKey: "emptyStr")
        #expect(value == "")
    }

    @Test func saveEmptyData() throws {
        let keychain = makeKeychain()
        defer { try? keychain.deleteAll() }

        try keychain.save(data: Data(), forKey: "emptyData")
        let result = try keychain.readData(forKey: "emptyData")
        #expect(result == Data())
    }

    @Test func saveLongString() throws {
        let keychain = makeKeychain()
        defer { try? keychain.deleteAll() }

        let longString = String(repeating: "A", count: 10_000)
        try keychain.save(string: longString, forKey: "longKey")
        let value = try keychain.readString(forKey: "longKey")
        #expect(value == longString)
    }

    @Test func saveSpecialCharacters() throws {
        let keychain = makeKeychain()
        defer { try? keychain.deleteAll() }

        let special = "emoji: 🔐🏦 unicode: ñ ü ç 日本語"
        try keychain.save(string: special, forKey: "specialKey")
        let value = try keychain.readString(forKey: "specialKey")
        #expect(value == special)
    }

    @Test func overwriteExistingValue() throws {
        let keychain = makeKeychain()
        defer { try? keychain.deleteAll() }

        try keychain.save(string: "first", forKey: "key")
        try keychain.save(string: "second", forKey: "key")
        let value = try keychain.readString(forKey: "key")
        #expect(value == "second")
    }

    // MARK: - Read

    @Test func readNonExistentKeyReturnsNil() throws {
        let keychain = makeKeychain()
        #expect(try keychain.readString(forKey: "noSuchKey") == nil)
    }

    @Test func readDataNonExistentKeyReturnsNil() throws {
        let keychain = makeKeychain()
        #expect(try keychain.readData(forKey: "noSuchKey") == nil)
    }

    // MARK: - Delete

    @Test func deleteSingleKey() throws {
        let keychain = makeKeychain()
        defer { try? keychain.deleteAll() }

        try keychain.save(string: "val", forKey: "delKey")
        try keychain.delete(forKey: "delKey")
        #expect(try keychain.readString(forKey: "delKey") == nil)
    }

    @Test func deleteNonExistentKeyDoesNotThrow() throws {
        let keychain = makeKeychain()
        try keychain.delete(forKey: "neverSaved")
    }

    @Test func deleteOnlyAffectsTargetKey() throws {
        let keychain = makeKeychain()
        defer { try? keychain.deleteAll() }

        try keychain.save(string: "a", forKey: "keep")
        try keychain.save(string: "b", forKey: "remove")
        try keychain.delete(forKey: "remove")

        #expect(try keychain.readString(forKey: "keep") == "a")
        #expect(try keychain.readString(forKey: "remove") == nil)
    }

    @Test func deleteAll() throws {
        let keychain = makeKeychain()

        try keychain.save(string: "a", forKey: "k1")
        try keychain.save(string: "b", forKey: "k2")
        try keychain.save(string: "c", forKey: "k3")
        try keychain.deleteAll()

        #expect(try keychain.readString(forKey: "k1") == nil)
        #expect(try keychain.readString(forKey: "k2") == nil)
        #expect(try keychain.readString(forKey: "k3") == nil)
    }

    @Test func deleteAllWhenEmptyDoesNotThrow() throws {
        let keychain = makeKeychain()
        try keychain.deleteAll()
    }

    // MARK: - Service Scoping

    @Test func differentServicesDoNotCollide() throws {
        let keychainA = KeychainManager(service: "com.securebankkit.tests.scopeA.\(UUID().uuidString)")
        let keychainB = KeychainManager(service: "com.securebankkit.tests.scopeB.\(UUID().uuidString)")
        defer {
            try? keychainA.deleteAll()
            try? keychainB.deleteAll()
        }

        try keychainA.save(string: "valueA", forKey: "shared")
        try keychainB.save(string: "valueB", forKey: "shared")

        #expect(try keychainA.readString(forKey: "shared") == "valueA")
        #expect(try keychainB.readString(forKey: "shared") == "valueB")
    }

    // MARK: - Init Properties

    @Test func servicePropertyIsSet() {
        let keychain = KeychainManager(service: "com.test.service")
        #expect(keychain.service == "com.test.service")
    }

    @Test func defaultAccessibility() {
        let keychain = KeychainManager(service: "com.test")
        #expect(keychain.accessibility == kSecAttrAccessibleAfterFirstUnlock)
    }

    @Test func customAccessibility() {
        let keychain = KeychainManager(
            service: "com.test",
            accessibility: kSecAttrAccessibleWhenUnlocked
        )
        #expect(keychain.accessibility == kSecAttrAccessibleWhenUnlocked)
    }
}
