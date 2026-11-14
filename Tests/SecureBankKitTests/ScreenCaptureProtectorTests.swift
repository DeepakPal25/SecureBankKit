import Testing
import UIKit
@testable import SecureBankKit

@MainActor
@Suite("ScreenCaptureProtector")
struct ScreenCaptureProtectorTests {

    @Test func initialCaptureStateReflectsScreen() {
        let protector = ScreenCaptureProtector()
        #expect(protector.isCaptured == UIScreen.main.isCaptured)
    }

    @Test func startAndStopAreIdempotent() {
        let protector = ScreenCaptureProtector()
        protector.startMonitoring()
        protector.startMonitoring()
        protector.stopMonitoring()
        protector.stopMonitoring()
        #expect(protector.isCaptured == UIScreen.main.isCaptured)
    }
}
