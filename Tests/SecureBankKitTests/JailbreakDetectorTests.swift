import Testing
@testable import SecureBankKit

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
