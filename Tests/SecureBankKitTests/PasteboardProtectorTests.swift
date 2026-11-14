import Testing
import UIKit
@testable import SecureBankKit

@MainActor
@Suite("PasteboardProtector")
struct PasteboardProtectorTests {

    @Test func copyThenReadReturnsValue() {
        PasteboardProtector.copySensitive("secret-123", expiresAfter: 60)
        #expect(UIPasteboard.general.string == "secret-123")
    }

    @Test func clearRemovesContents() {
        PasteboardProtector.copySensitive("to-be-cleared")
        PasteboardProtector.clear()
        #expect(UIPasteboard.general.string == nil)
    }
}
