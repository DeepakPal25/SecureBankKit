import Foundation
import LocalAuthentication

/// The type of biometric authentication available on the device.
public enum BiometricType: Sendable {
    case faceID
    case touchID
    case none
}

/// Wraps the LocalAuthentication framework for Face ID / Touch ID evaluation.
///
/// ```swift
/// let bioManager = BiometricAuthManager()
/// let type = bioManager.canEvaluateBiometrics()
/// if type != .none {
///     let success = try await bioManager.authenticate(reason: "Confirm your identity")
/// }
/// ```
public final class BiometricAuthManager: Sendable {

    public init() {}

    /// Checks which biometric type is available on the current device.
    ///
    /// - Returns: A ``BiometricType`` indicating Face ID, Touch ID, or none.
    public func canEvaluateBiometrics() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .none
        @unknown default:
            return .none
        }
    }

    /// Performs biometric authentication with a fallback to device passcode.
    ///
    /// - Parameter reason: A user-facing string explaining why authentication is needed.
    /// - Returns: `true` if authentication succeeded.
    /// - Throws: An `NSError` from LocalAuthentication on failure.
    public func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        return try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        )
    }
}
