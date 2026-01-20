import Foundation
import Testing
@testable import SecureBankKit

@Suite("TokenExpiryManager")
struct TokenExpiryManagerTests {

    @Test func initialStateHasNilExpiry() {
        let manager = TokenExpiryManager()
        #expect(manager.expiryDate == nil)
    }

    @Test func defaultBufferIntervalIs60() {
        let manager = TokenExpiryManager()
        #expect(manager.refreshBufferInterval == 60)
    }

    @Test func customBufferInterval() {
        let manager = TokenExpiryManager(refreshBufferInterval: 120)
        #expect(manager.refreshBufferInterval == 120)
    }

    @Test func setExpirySetsDate() {
        let manager = TokenExpiryManager()
        let date = Date().addingTimeInterval(3600)
        manager.setExpiry(date)
        #expect(manager.expiryDate == date)
    }

    @Test func setExpiryOverwritesPrevious() {
        let manager = TokenExpiryManager()
        let first = Date().addingTimeInterval(100)
        let second = Date().addingTimeInterval(200)
        manager.setExpiry(first)
        manager.setExpiry(second)
        #expect(manager.expiryDate == second)
    }

    @Test func noExpiryMeansExpired() {
        let manager = TokenExpiryManager()
        #expect(manager.isTokenExpired() == true)
    }

    @Test func noExpiryMeansShouldRefresh() {
        let manager = TokenExpiryManager()
        #expect(manager.shouldRefreshToken() == true)
    }

    @Test func pastExpiryIsExpired() {
        let manager = TokenExpiryManager()
        manager.setExpiry(Date().addingTimeInterval(-10))
        #expect(manager.isTokenExpired() == true)
    }

    @Test func futureExpiryIsNotExpired() {
        let manager = TokenExpiryManager()
        manager.setExpiry(Date().addingTimeInterval(3600))
        #expect(manager.isTokenExpired() == false)
    }

    @Test func shouldRefreshWhenWithinBuffer() {
        let manager = TokenExpiryManager(refreshBufferInterval: 120)
        manager.setExpiry(Date().addingTimeInterval(60))
        #expect(manager.shouldRefreshToken() == true)
    }

    @Test func shouldNotRefreshWhenOutsideBuffer() {
        let manager = TokenExpiryManager(refreshBufferInterval: 60)
        manager.setExpiry(Date().addingTimeInterval(3600))
        #expect(manager.shouldRefreshToken() == false)
    }

    @Test func shouldRefreshWhenAlreadyExpired() {
        let manager = TokenExpiryManager(refreshBufferInterval: 60)
        manager.setExpiry(Date().addingTimeInterval(-100))
        #expect(manager.shouldRefreshToken() == true)
    }

    @Test func changingBufferIntervalDynamicallyAffectsCheck() {
        let manager = TokenExpiryManager(refreshBufferInterval: 10)
        manager.setExpiry(Date().addingTimeInterval(30))
        #expect(manager.shouldRefreshToken() == false)

        manager.refreshBufferInterval = 60
        #expect(manager.shouldRefreshToken() == true)
    }

    @Test func refreshIfNeededCallsClosureWhenNeeded() async throws {
        let manager = TokenExpiryManager()
        manager.setExpiry(Date().addingTimeInterval(-10))

        var closureCalled = false
        let newExpiry = Date().addingTimeInterval(7200)

        try await manager.refreshIfNeeded {
            closureCalled = true
            return newExpiry
        }

        #expect(closureCalled == true)
        #expect(manager.expiryDate == newExpiry)
    }

    @Test func refreshIfNeededSkipsClosureWhenNotNeeded() async throws {
        let manager = TokenExpiryManager(refreshBufferInterval: 60)
        manager.setExpiry(Date().addingTimeInterval(3600))

        var closureCalled = false

        try await manager.refreshIfNeeded {
            closureCalled = true
            return Date()
        }

        #expect(closureCalled == false)
    }

    @Test func refreshIfNeededPropagatesError() async {
        let manager = TokenExpiryManager()

        struct RefreshError: Error {}

        do {
            try await manager.refreshIfNeeded {
                throw RefreshError()
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is RefreshError)
        }
    }
}
