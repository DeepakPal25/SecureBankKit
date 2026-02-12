import Testing
@testable import SecureBankKit

@Suite("SecureLogger")
struct SecureLoggerTests {

    // MARK: - Log Levels

    @Test func levelRawValues() {
        #expect(SecureLogger.Level.info.rawValue == "INFO")
        #expect(SecureLogger.Level.warning.rawValue == "WARNING")
        #expect(SecureLogger.Level.error.rawValue == "ERROR")
    }

    // MARK: - Logging (no crash verification)

    @Test func infoDoesNotCrash() {
        SecureLogger.info("Test info")
    }

    @Test func warningDoesNotCrash() {
        SecureLogger.warning("Test warning")
    }

    @Test func errorDoesNotCrash() {
        SecureLogger.error("Test error")
    }

    @Test func logWithExplicitLevelDoesNotCrash() {
        SecureLogger.log("explicit info", level: .info)
        SecureLogger.log("explicit warning", level: .warning)
        SecureLogger.log("explicit error", level: .error)
    }

    @Test func logWithDefaultLevelDoesNotCrash() {
        SecureLogger.log("default level")
    }

    @Test func logWithEmptyMessageDoesNotCrash() {
        SecureLogger.log("")
        SecureLogger.info("")
        SecureLogger.warning("")
        SecureLogger.error("")
    }

    @Test func logWithSpecialCharacters() {
        SecureLogger.info("emoji: 🔐 unicode: ñ newline:\n tab:\t")
    }

    // MARK: - Redaction

    @Test func redactLongString() {
        #expect(SecureLogger.redact("1234567890") == "******7890")
    }

    @Test func redactExactlyVisibleCount() {
        #expect(SecureLogger.redact("abcd") == "****")
    }

    @Test func redactShorterThanVisibleCount() {
        #expect(SecureLogger.redact("ab") == "**")
    }

    @Test func redactOneCharLongerThanDefault() {
        #expect(SecureLogger.redact("abcde") == "*bcde")
    }

    @Test func redactEmptyString() {
        #expect(SecureLogger.redact("") == "")
    }

    @Test func redactSingleCharacter() {
        #expect(SecureLogger.redact("X") == "*")
    }

    @Test func redactWithCustomVisibleCount() {
        #expect(SecureLogger.redact("1234567890", visibleCount: 2) == "********90")
        #expect(SecureLogger.redact("1234567890", visibleCount: 0) == "**********")
        #expect(SecureLogger.redact("1234567890", visibleCount: 10) == "**********")
        #expect(SecureLogger.redact("1234567890", visibleCount: 11) == "**********")
    }

    @Test func redactPreservesLength() {
        let input = "mysecretpassword"
        let redacted = SecureLogger.redact(input)
        #expect(redacted.count == input.count)
    }

    @Test func redactWithVisibleCountZero() {
        #expect(SecureLogger.redact("secret", visibleCount: 0) == "******")
    }

    @Test func redactUnicodeString() {
        let result = SecureLogger.redact("🔐🏦AB", visibleCount: 2)
        #expect(result == "**AB")
    }
}
