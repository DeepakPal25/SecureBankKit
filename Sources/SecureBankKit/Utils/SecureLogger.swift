import Foundation

/// Debug-only logging utility for SecureBankKit.
///
/// All output is compiled away in release builds via `#if DEBUG`.
/// Use ``redact(_:visibleCount:)`` to mask sensitive values before logging.
public enum SecureLogger {

    /// Log severity levels.
    public enum Level: String, Sendable {
        case info    = "INFO"
        case warning = "WARNING"
        case error   = "ERROR"
    }

    /// Logs a message at the given level. Output is only emitted in DEBUG builds.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - level: The severity level (defaults to `.info`).
    public static func log(_ message: String, level: Level = .info) {
        #if DEBUG
        print("[SecureBankKit] [\(level.rawValue)] \(message)")
        #endif
    }

    /// Convenience for `.info` level.
    public static func info(_ message: String) {
        log(message, level: .info)
    }

    /// Convenience for `.warning` level.
    public static func warning(_ message: String) {
        log(message, level: .warning)
    }

    /// Convenience for `.error` level.
    public static func error(_ message: String) {
        log(message, level: .error)
    }

    /// Masks a sensitive string, keeping only the last `visibleCount` characters.
    ///
    /// - Parameters:
    ///   - value: The sensitive string to redact.
    ///   - visibleCount: Number of trailing characters to leave visible (default 4).
    /// - Returns: A redacted string such as `"****abcd"`.
    public static func redact(_ value: String, visibleCount: Int = 4) -> String {
        guard value.count > visibleCount else {
            return String(repeating: "*", count: value.count)
        }
        let masked = String(repeating: "*", count: value.count - visibleCount)
        let visible = value.suffix(visibleCount)
        return masked + visible
    }
}
