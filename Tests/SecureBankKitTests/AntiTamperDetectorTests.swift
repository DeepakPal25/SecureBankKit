import Testing
@testable import SecureBankKit

@Suite("AntiTamperDetector")
struct AntiTamperDetectorTests {

    @Test func debuggerCheckIsConsistent() {
        let first = AntiTamperDetector.isDebuggerAttached()
        let second = AntiTamperDetector.isDebuggerAttached()
        #expect(first == second)
    }

    @Test func noInjectedLibrariesInTestEnvironment() {
        #expect(AntiTamperDetector.hasInjectedLibraries() == false)
    }

    @Test func isTamperedMatchesIndividualChecks() {
        let expected = AntiTamperDetector.isDebuggerAttached()
            || AntiTamperDetector.hasInjectedLibraries()
        #expect(AntiTamperDetector.isTampered() == expected)
    }
}
