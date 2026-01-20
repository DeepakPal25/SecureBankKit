import Testing
@testable import SecureBankKit

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
