import Testing
@testable import SecureBankKit

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
