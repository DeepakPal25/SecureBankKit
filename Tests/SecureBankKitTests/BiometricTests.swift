import Testing
@testable import SecureBankKit

@Suite("BiometricAuthManager")
struct BiometricAuthManagerTests {

    @Test func initDoesNotCrash() {
        _ = BiometricAuthManager()
    }

    @Test func canEvaluateBiometricsReturnsAValue() {
        let manager = BiometricAuthManager()
        let type = manager.canEvaluateBiometrics()
        #expect(type == .faceID || type == .touchID || type == .none)
    }

    @Test func canEvaluateBiometricsIsConsistent() {
        let manager = BiometricAuthManager()
        let first = manager.canEvaluateBiometrics()
        let second = manager.canEvaluateBiometrics()
        #expect(first == second)
    }
}

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
