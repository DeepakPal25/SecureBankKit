import Foundation
import Testing
@testable import SecureBankKit

@Suite("SessionManager")
struct SessionManagerTests {

    private func makeDependencies() -> (SecureTokenStorage, TokenExpiryManager, KeychainManager) {
        let keychain = KeychainManager(service: "com.securebankkit.tests.session.\(UUID().uuidString)")
        let tokenStorage = SecureTokenStorage(keychainManager: keychain)
        let expiryManager = TokenExpiryManager()
        return (tokenStorage, expiryManager, keychain)
    }

    @Test @MainActor func defaultTimeoutIs300() {
        let (ts, em, _) = makeDependencies()
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em)
        #expect(session.sessionTimeout == 300)
    }

    @Test @MainActor func customTimeout() {
        let (ts, em, _) = makeDependencies()
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em, sessionTimeout: 120)
        #expect(session.sessionTimeout == 120)
    }

    @Test @MainActor func initialStateIsNotActive() {
        let (ts, em, _) = makeDependencies()
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em)
        #expect(session.isSessionActive == false)
    }

    @Test @MainActor func startSessionSetsActive() {
        let (ts, em, _) = makeDependencies()
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em)
        session.startSession()
        #expect(session.isSessionActive == true)
    }

    @Test @MainActor func endSessionSetsInactive() {
        let (ts, em, _) = makeDependencies()
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em)
        session.startSession()
        session.endSession()
        #expect(session.isSessionActive == false)
    }

    @Test @MainActor func endSessionCanBeCalledWithoutStart() {
        let (ts, em, _) = makeDependencies()
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em)
        session.endSession()
        #expect(session.isSessionActive == false)
    }

    @Test @MainActor func checkValidityReturnsFalseWhenNotStarted() {
        let (ts, em, _) = makeDependencies()
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em)
        #expect(session.checkSessionValidity() == false)
    }

    @Test @MainActor func checkValidityReturnsTrueWhenActiveAndTokenValid() {
        let (ts, em, _) = makeDependencies()
        em.setExpiry(Date().addingTimeInterval(3600))
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em, sessionTimeout: 300)
        session.startSession()
        #expect(session.checkSessionValidity() == true)
    }

    @Test @MainActor func checkValidityReturnsFalseWhenTokenExpired() {
        let (ts, em, _) = makeDependencies()
        em.setExpiry(Date().addingTimeInterval(-10))
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em, sessionTimeout: 300)
        session.startSession()
        #expect(session.checkSessionValidity() == false)
        #expect(session.isSessionActive == false)
    }

    @Test @MainActor func checkValidityCallsOnSessionExpiredWhenTokenExpired() {
        let (ts, em, _) = makeDependencies()
        em.setExpiry(Date().addingTimeInterval(-10))
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em, sessionTimeout: 300)

        var expiredCalled = false
        session.onSessionExpired = { expiredCalled = true }
        session.startSession()

        _ = session.checkSessionValidity()
        #expect(expiredCalled == true)
    }

    @Test @MainActor func checkValidityReturnsFalseAfterInactivityTimeout() {
        let (ts, em, _) = makeDependencies()
        em.setExpiry(Date().addingTimeInterval(3600))
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em, sessionTimeout: 0)
        session.startSession()

        Thread.sleep(forTimeInterval: 0.01)
        #expect(session.checkSessionValidity() == false)
    }

    @Test @MainActor func recordActivityDoesNotCrash() {
        let (ts, em, _) = makeDependencies()
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em)
        session.startSession()
        session.recordActivity()
    }

    @Test @MainActor func sessionTimeoutCanBeModified() {
        let (ts, em, _) = makeDependencies()
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em)
        session.sessionTimeout = 600
        #expect(session.sessionTimeout == 600)
    }

    @Test @MainActor func startSessionCanBeCalledMultipleTimes() {
        let (ts, em, _) = makeDependencies()
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em)
        session.startSession()
        session.startSession()
        #expect(session.isSessionActive == true)
    }

    @Test @MainActor func endSessionAfterExpiredCheckDoesNotDoubleCallback() {
        let (ts, em, _) = makeDependencies()
        em.setExpiry(Date().addingTimeInterval(-10))
        let session = SessionManager(tokenStorage: ts, tokenExpiryManager: em, sessionTimeout: 300)

        var callCount = 0
        session.onSessionExpired = { callCount += 1 }
        session.startSession()

        _ = session.checkSessionValidity()
        session.endSession()

        #expect(callCount == 1)
    }
}
