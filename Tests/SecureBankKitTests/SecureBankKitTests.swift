import Foundation
import Testing
@testable import SecureBankKit

/// Whether Keychain is available in the current test runner.
/// SPM test hosts often lack the entitlement needed for Keychain access (-34018).
private let keychainAvailable: Bool = {
    let keychain = KeychainManager(service: "com.securebankkit.tests.probe")
    do {
        try keychain.save(string: "probe", forKey: "probe")
        try keychain.delete(forKey: "probe")
        return true
    } catch {
        return false
    }
}()

// MARK: - Core

@Suite("SecureBankKit Core")
struct SecureBankKitCoreTests {

    @Test func versionIsNotEmpty() {
        #expect(!SecureBankKit.version.isEmpty)
    }

    @Test func versionFollowsSemver() {
        let components = SecureBankKit.version.split(separator: ".")
        #expect(components.count == 3)
        for component in components {
            #expect(Int(component) != nil)
        }
    }
}

// MARK: - KeychainManager

@Suite("KeychainManager",
       .enabled(if: keychainAvailable, "Keychain requires entitlements not present in this test runner"))
struct KeychainManagerTests {

    private func makeKeychain() -> KeychainManager {
        KeychainManager(service: "com.securebankkit.tests.\(UUID().uuidString)")
    }

    // Save & Read

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

    // Read

    @Test func readNonExistentKeyReturnsNil() throws {
        let keychain = makeKeychain()
        let value = try keychain.readString(forKey: "noSuchKey")
        #expect(value == nil)
    }

    @Test func readDataNonExistentKeyReturnsNil() throws {
        let keychain = makeKeychain()
        let value = try keychain.readData(forKey: "noSuchKey")
        #expect(value == nil)
    }

    // Delete

    @Test func deleteSingleKey() throws {
        let keychain = makeKeychain()
        defer { try? keychain.deleteAll() }

        try keychain.save(string: "val", forKey: "delKey")
        try keychain.delete(forKey: "delKey")
        let value = try keychain.readString(forKey: "delKey")
        #expect(value == nil)
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

    // Service scoping

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

    // Init properties

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

// MARK: - KeychainError

@Suite("KeychainError")
struct KeychainErrorTests {

    @Test func unhandledErrorCarriesStatus() {
        let error = KeychainError.unhandledError(status: -25300)
        if case .unhandledError(let status) = error {
            #expect(status == -25300)
        } else {
            Issue.record("Expected unhandledError case")
        }
    }

    @Test func allCasesAreDistinct() {
        let cases: [KeychainError] = [
            .unhandledError(status: 0),
            .itemNotFound,
            .duplicateItem,
            .encodingError,
        ]
        // Verify they're all different by pattern matching
        for (i, a) in cases.enumerated() {
            for (j, b) in cases.enumerated() where i != j {
                switch (a, b) {
                case (.unhandledError, .unhandledError),
                     (.itemNotFound, .itemNotFound),
                     (.duplicateItem, .duplicateItem),
                     (.encodingError, .encodingError):
                    Issue.record("Cases at index \(i) and \(j) should be distinct")
                default:
                    break
                }
            }
        }
    }

    @Test func conformsToError() {
        let error: any Error = KeychainError.encodingError
        #expect(error is KeychainError)
    }
}

// MARK: - SecureTokenStorage

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

        // Overwriting one doesn't affect the other
        try storage.saveAccessToken("newAccess")
        #expect(storage.getRefreshToken() == "refresh")
    }
}

// MARK: - TokenExpiryManager

@Suite("TokenExpiryManager")
struct TokenExpiryManagerTests {

    @Test func initialStateHasNilExpiry() {
        let manager = TokenExpiryManager()
        #expect(manager.expiryDate == nil)
    }

    @Test func defaultBufferIntervalIs60() {
        let manager = TokenExpiryManager()
        #expect(manager.refreshBufferInterval == 60)
    }

    @Test func customBufferInterval() {
        let manager = TokenExpiryManager(refreshBufferInterval: 120)
        #expect(manager.refreshBufferInterval == 120)
    }

    @Test func setExpirySetsDate() {
        let manager = TokenExpiryManager()
        let date = Date().addingTimeInterval(3600)
        manager.setExpiry(date)
        #expect(manager.expiryDate == date)
    }

    @Test func setExpiryOverwritesPrevious() {
        let manager = TokenExpiryManager()
        let first = Date().addingTimeInterval(100)
        let second = Date().addingTimeInterval(200)
        manager.setExpiry(first)
        manager.setExpiry(second)
        #expect(manager.expiryDate == second)
    }

    @Test func noExpiryMeansExpired() {
        let manager = TokenExpiryManager()
        #expect(manager.isTokenExpired() == true)
    }

    @Test func noExpiryMeansShouldRefresh() {
        let manager = TokenExpiryManager()
        #expect(manager.shouldRefreshToken() == true)
    }

    @Test func pastExpiryIsExpired() {
        let manager = TokenExpiryManager()
        manager.setExpiry(Date().addingTimeInterval(-10))
        #expect(manager.isTokenExpired() == true)
    }

    @Test func futureExpiryIsNotExpired() {
        let manager = TokenExpiryManager()
        manager.setExpiry(Date().addingTimeInterval(3600))
        #expect(manager.isTokenExpired() == false)
    }

    @Test func shouldRefreshWhenWithinBuffer() {
        let manager = TokenExpiryManager(refreshBufferInterval: 120)
        manager.setExpiry(Date().addingTimeInterval(60)) // 60s left, buffer is 120s
        #expect(manager.shouldRefreshToken() == true)
    }

    @Test func shouldNotRefreshWhenOutsideBuffer() {
        let manager = TokenExpiryManager(refreshBufferInterval: 60)
        manager.setExpiry(Date().addingTimeInterval(3600)) // 1h left
        #expect(manager.shouldRefreshToken() == false)
    }

    @Test func shouldRefreshWhenAlreadyExpired() {
        let manager = TokenExpiryManager(refreshBufferInterval: 60)
        manager.setExpiry(Date().addingTimeInterval(-100))
        #expect(manager.shouldRefreshToken() == true)
    }

    @Test func changingBufferIntervalDynamicallyAffectsCheck() {
        let manager = TokenExpiryManager(refreshBufferInterval: 10)
        manager.setExpiry(Date().addingTimeInterval(30)) // 30s left, buffer 10s → no refresh
        #expect(manager.shouldRefreshToken() == false)

        manager.refreshBufferInterval = 60 // now buffer is 60s → should refresh
        #expect(manager.shouldRefreshToken() == true)
    }

    @Test func refreshIfNeededCallsClosureWhenNeeded() async throws {
        let manager = TokenExpiryManager()
        manager.setExpiry(Date().addingTimeInterval(-10)) // already expired

        var closureCalled = false
        let newExpiry = Date().addingTimeInterval(7200)

        try await manager.refreshIfNeeded {
            closureCalled = true
            return newExpiry
        }

        #expect(closureCalled == true)
        #expect(manager.expiryDate == newExpiry)
    }

    @Test func refreshIfNeededSkipsClosureWhenNotNeeded() async throws {
        let manager = TokenExpiryManager(refreshBufferInterval: 60)
        manager.setExpiry(Date().addingTimeInterval(3600)) // far from expiry

        var closureCalled = false

        try await manager.refreshIfNeeded {
            closureCalled = true
            return Date()
        }

        #expect(closureCalled == false)
    }

    @Test func refreshIfNeededPropagatesError() async {
        let manager = TokenExpiryManager()
        // No expiry set → shouldRefresh is true

        struct RefreshError: Error {}

        do {
            try await manager.refreshIfNeeded {
                throw RefreshError()
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is RefreshError)
        }
    }
}

// MARK: - SessionManager

@Suite("SessionManager")
struct SessionManagerTests {

    private func makeDependencies() -> (SecureTokenStorage, TokenExpiryManager, KeychainManager) {
        let keychain = KeychainManager(service: "com.securebankkit.tests.session.\(UUID().uuidString)")
        let tokenStorage = SecureTokenStorage(keychainManager: keychain)
        let expiryManager = TokenExpiryManager()
        return (tokenStorage, expiryManager, keychain)
    }

    @Test @MainActor func defaultTimeoutIs300() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        let session = SessionManager(tokenStorage: tokenStorage, tokenExpiryManager: expiryManager)
        #expect(session.sessionTimeout == 300)
    }

    @Test @MainActor func customTimeout() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        let session = SessionManager(
            tokenStorage: tokenStorage,
            tokenExpiryManager: expiryManager,
            sessionTimeout: 120
        )
        #expect(session.sessionTimeout == 120)
    }

    @Test @MainActor func initialStateIsNotActive() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        let session = SessionManager(tokenStorage: tokenStorage, tokenExpiryManager: expiryManager)
        #expect(session.isSessionActive == false)
    }

    @Test @MainActor func startSessionSetsActive() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        let session = SessionManager(tokenStorage: tokenStorage, tokenExpiryManager: expiryManager)
        session.startSession()
        #expect(session.isSessionActive == true)
    }

    @Test @MainActor func endSessionSetsInactive() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        let session = SessionManager(tokenStorage: tokenStorage, tokenExpiryManager: expiryManager)
        session.startSession()
        session.endSession()
        #expect(session.isSessionActive == false)
    }

    @Test @MainActor func endSessionCanBeCalledWithoutStart() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        let session = SessionManager(tokenStorage: tokenStorage, tokenExpiryManager: expiryManager)
        session.endSession() // should not crash
        #expect(session.isSessionActive == false)
    }

    @Test @MainActor func checkValidityReturnsFalseWhenNotStarted() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        let session = SessionManager(tokenStorage: tokenStorage, tokenExpiryManager: expiryManager)
        #expect(session.checkSessionValidity() == false)
    }

    @Test @MainActor func checkValidityReturnsTrueWhenActiveAndTokenValid() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        expiryManager.setExpiry(Date().addingTimeInterval(3600))
        let session = SessionManager(
            tokenStorage: tokenStorage,
            tokenExpiryManager: expiryManager,
            sessionTimeout: 300
        )
        session.startSession()
        #expect(session.checkSessionValidity() == true)
    }

    @Test @MainActor func checkValidityReturnsFalseWhenTokenExpired() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        expiryManager.setExpiry(Date().addingTimeInterval(-10))
        let session = SessionManager(
            tokenStorage: tokenStorage,
            tokenExpiryManager: expiryManager,
            sessionTimeout: 300
        )
        session.startSession()
        #expect(session.checkSessionValidity() == false)
        // Should also deactivate the session
        #expect(session.isSessionActive == false)
    }

    @Test @MainActor func checkValidityCallsOnSessionExpiredWhenTokenExpired() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        expiryManager.setExpiry(Date().addingTimeInterval(-10))
        let session = SessionManager(
            tokenStorage: tokenStorage,
            tokenExpiryManager: expiryManager,
            sessionTimeout: 300
        )

        var expiredCalled = false
        session.onSessionExpired = { expiredCalled = true }
        session.startSession()

        _ = session.checkSessionValidity()
        #expect(expiredCalled == true)
    }

    @Test @MainActor func checkValidityReturnsFalseAfterInactivityTimeout() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        expiryManager.setExpiry(Date().addingTimeInterval(3600))
        let session = SessionManager(
            tokenStorage: tokenStorage,
            tokenExpiryManager: expiryManager,
            sessionTimeout: 0 // timeout immediately
        )
        session.startSession()

        // Even a tiny delay exceeds 0-second timeout
        Thread.sleep(forTimeInterval: 0.01)
        #expect(session.checkSessionValidity() == false)
    }

    @Test @MainActor func recordActivityDoesNotCrash() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        let session = SessionManager(tokenStorage: tokenStorage, tokenExpiryManager: expiryManager)
        session.startSession()
        session.recordActivity()
        // Just verify no crash
    }

    @Test @MainActor func sessionTimeoutCanBeModified() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        let session = SessionManager(tokenStorage: tokenStorage, tokenExpiryManager: expiryManager)
        session.sessionTimeout = 600
        #expect(session.sessionTimeout == 600)
    }

    @Test @MainActor func startSessionCanBeCalledMultipleTimes() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        let session = SessionManager(tokenStorage: tokenStorage, tokenExpiryManager: expiryManager)
        session.startSession()
        session.startSession()
        #expect(session.isSessionActive == true)
    }

    @Test @MainActor func endSessionAfterExpiredCheckDoesNotDoubleCallback() {
        let (tokenStorage, expiryManager, _) = makeDependencies()
        expiryManager.setExpiry(Date().addingTimeInterval(-10))
        let session = SessionManager(
            tokenStorage: tokenStorage,
            tokenExpiryManager: expiryManager,
            sessionTimeout: 300
        )

        var callCount = 0
        session.onSessionExpired = { callCount += 1 }
        session.startSession()

        _ = session.checkSessionValidity() // triggers expiry
        session.endSession() // manual end after automatic expiry

        #expect(callCount == 1) // callback should only fire once (from checkSessionValidity)
    }
}

// MARK: - AppLockManager

@Suite("AppLockManager")
struct AppLockManagerTests {

    @Test @MainActor func initialStateIsUnlocked() {
        let manager = AppLockManager(biometricManager: BiometricAuthManager())
        #expect(manager.isLocked == false)
    }

    @Test @MainActor func defaultLockDelayIsZero() {
        let manager = AppLockManager(biometricManager: BiometricAuthManager())
        #expect(manager.lockDelay == 0)
    }

    @Test @MainActor func customLockDelay() {
        let manager = AppLockManager(biometricManager: BiometricAuthManager(), lockDelay: 5)
        #expect(manager.lockDelay == 5)
    }

    @Test @MainActor func enableDoesNotCrash() {
        let manager = AppLockManager(biometricManager: BiometricAuthManager())
        manager.enable()
        manager.disable()
    }

    @Test @MainActor func doubleEnableIsIdempotent() {
        let manager = AppLockManager(biometricManager: BiometricAuthManager())
        manager.enable()
        manager.enable() // should not register duplicate observers
        manager.disable()
    }

    @Test @MainActor func disableUnlocks() {
        let manager = AppLockManager(biometricManager: BiometricAuthManager())
        manager.enable()
        manager.disable()
        #expect(manager.isLocked == false)
    }

    @Test @MainActor func disableWithoutEnableDoesNotCrash() {
        let manager = AppLockManager(biometricManager: BiometricAuthManager())
        manager.disable()
        #expect(manager.isLocked == false)
    }

    @Test @MainActor func lockDelayCanBeModified() {
        let manager = AppLockManager(biometricManager: BiometricAuthManager())
        manager.lockDelay = 10
        #expect(manager.lockDelay == 10)
    }
}

// MARK: - BiometricAuthManager

@Suite("BiometricAuthManager")
struct BiometricAuthManagerTests {

    @Test func initDoesNotCrash() {
        _ = BiometricAuthManager()
    }

    @Test func canEvaluateBiometricsReturnsAValue() {
        let manager = BiometricAuthManager()
        let type = manager.canEvaluateBiometrics()
        // On simulator, biometrics are generally not available
        #expect(type == .faceID || type == .touchID || type == .none)
    }

    @Test func canEvaluateBiometricsIsConsistent() {
        let manager = BiometricAuthManager()
        let first = manager.canEvaluateBiometrics()
        let second = manager.canEvaluateBiometrics()
        #expect(first == second)
    }
}

// MARK: - BiometricType

@Suite("BiometricType")
struct BiometricTypeTests {

    @Test func allCasesExist() {
        let cases: [BiometricType] = [.faceID, .touchID, .none]
        #expect(cases.count == 3)
    }

    @Test func equalityWorks() {
        #expect(BiometricType.faceID == BiometricType.faceID)
        #expect(BiometricType.touchID == BiometricType.touchID)
        #expect(BiometricType.none == BiometricType.none)
        #expect(BiometricType.faceID != BiometricType.touchID)
        #expect(BiometricType.faceID != BiometricType.none)
        #expect(BiometricType.touchID != BiometricType.none)
    }
}

// MARK: - JailbreakDetector

@Suite("JailbreakDetector")
struct JailbreakDetectorTests {

    @Test func returnsFalseOnSimulator() {
        #expect(JailbreakDetector.isJailbroken() == false)
    }

    @Test func resultIsConsistentAcrossCalls() {
        let first = JailbreakDetector.isJailbroken()
        let second = JailbreakDetector.isJailbroken()
        #expect(first == second)
    }
}

// MARK: - SecureLogger

@Suite("SecureLogger")
struct SecureLoggerTests {

    // Log levels

    @Test func levelRawValues() {
        #expect(SecureLogger.Level.info.rawValue == "INFO")
        #expect(SecureLogger.Level.warning.rawValue == "WARNING")
        #expect(SecureLogger.Level.error.rawValue == "ERROR")
    }

    // Logging (no crash verification)

    @Test func infoDoesNotCrash() {
        SecureLogger.info("Test info")
    }

    @Test func warningDoesNotCrash() {
        SecureLogger.warning("Test warning")
    }

    @Test func errorDoesNotCrash() {
        SecureLogger.error("Test error")
    }

    @Test func logWithExplicitLevelDoesNotCrash() {
        SecureLogger.log("explicit info", level: .info)
        SecureLogger.log("explicit warning", level: .warning)
        SecureLogger.log("explicit error", level: .error)
    }

    @Test func logWithDefaultLevelDoesNotCrash() {
        SecureLogger.log("default level") // defaults to .info
    }

    @Test func logWithEmptyMessageDoesNotCrash() {
        SecureLogger.log("")
        SecureLogger.info("")
        SecureLogger.warning("")
        SecureLogger.error("")
    }

    @Test func logWithSpecialCharacters() {
        SecureLogger.info("emoji: 🔐 unicode: ñ newline:\n tab:\t")
    }

    // Redaction

    @Test func redactLongString() {
        #expect(SecureLogger.redact("1234567890") == "******7890")
    }

    @Test func redactExactlyVisibleCount() {
        #expect(SecureLogger.redact("abcd") == "****")
    }

    @Test func redactShorterThanVisibleCount() {
        #expect(SecureLogger.redact("ab") == "**")
    }

    @Test func redactOneCharLongerThanDefault() {
        #expect(SecureLogger.redact("abcde") == "*bcde")
    }

    @Test func redactEmptyString() {
        #expect(SecureLogger.redact("") == "")
    }

    @Test func redactSingleCharacter() {
        #expect(SecureLogger.redact("X") == "*")
    }

    @Test func redactWithCustomVisibleCount() {
        #expect(SecureLogger.redact("1234567890", visibleCount: 2) == "********90")
        #expect(SecureLogger.redact("1234567890", visibleCount: 0) == "**********")
        #expect(SecureLogger.redact("1234567890", visibleCount: 10) == "**********")
        #expect(SecureLogger.redact("1234567890", visibleCount: 11) == "**********")
    }

    @Test func redactPreservesLength() {
        let input = "mysecretpassword"
        let redacted = SecureLogger.redact(input)
        #expect(redacted.count == input.count)
    }

    @Test func redactWithVisibleCountZero() {
        #expect(SecureLogger.redact("secret", visibleCount: 0) == "******")
    }

    @Test func redactUnicodeString() {
        // "🔐🏦AB" has 4 characters
        let result = SecureLogger.redact("🔐🏦AB", visibleCount: 2)
        #expect(result == "**AB")
    }
}
