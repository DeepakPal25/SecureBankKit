import Testing
import Foundation
@testable import SecureBankKit

@Suite("CertificatePinner")
struct CertificatePinnerTests {

    @Test func storesPinnedHashesAndMode() {
        let hashes: Set<String> = ["abc123=", "def456="]
        let pinner = CertificatePinner(pinnedHashes: hashes, mode: .certificate)
        #expect(pinner.pinnedHashes == hashes)
        #expect(pinner.mode == .certificate)
    }

    @Test func defaultModeIsPublicKey() {
        let pinner = CertificatePinner(pinnedHashes: ["abc="])
        #expect(pinner.mode == .publicKey)
    }

    @Test func makeSessionUsesPinnerAsDelegate() {
        let pinner = CertificatePinner(pinnedHashes: ["abc="])
        let session = pinner.makeSession()
        #expect((session.delegate as? CertificatePinner) === pinner)
        session.invalidateAndCancel()
    }
}
