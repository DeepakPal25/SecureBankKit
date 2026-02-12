import Foundation
@testable import SecureBankKit

/// Whether Keychain is available in the current test runner.
/// SPM test hosts often lack the entitlement needed for Keychain access (-34018).
let keychainAvailable: Bool = {
    let keychain = KeychainManager(service: "com.securebankkit.tests.probe")
    do {
        try keychain.save(string: "probe", forKey: "probe")
        try keychain.delete(forKey: "probe")
        return true
    } catch {
        return false
    }
}()
