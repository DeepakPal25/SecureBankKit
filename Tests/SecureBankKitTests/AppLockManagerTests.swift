import Testing
@testable import SecureBankKit

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
        manager.enable()
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
