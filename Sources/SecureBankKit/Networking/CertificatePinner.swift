import Foundation
import Security
import CryptoKit

/// A `URLSessionDelegate` that pins the server's public key (or certificate) to
/// defeat man-in-the-middle attacks using rogue or user-installed certificate authorities.
///
/// Public-key pinning (the default) is recommended because the pin survives certificate
/// renewal as long as the key pair is reused.
///
/// Generate a public-key pin from a PEM certificate:
/// ```sh
/// openssl x509 -in cert.pem -pubkey -noout \
///   | openssl pkey -pubin -outform der \
///   | openssl dgst -sha256 -binary | base64
/// ```
///
/// ```swift
/// let pinner = CertificatePinner(pinnedHashes: ["base64-sha256-of-spki"])
/// let session = pinner.makeSession()
/// let (data, _) = try await session.data(from: url)
/// ```
public final class CertificatePinner: NSObject, URLSessionDelegate, @unchecked Sendable {

    /// What is hashed and compared against the pinned set.
    public enum Mode: Sendable, Equatable {
        /// SHA-256 of the SubjectPublicKeyInfo (recommended).
        case publicKey
        /// SHA-256 of the full DER-encoded certificate.
        case certificate
    }

    /// Base64-encoded SHA-256 hashes that the server must match.
    public let pinnedHashes: Set<String>

    /// Whether public keys or whole certificates are pinned.
    public let mode: Mode

    /// Creates a certificate pinner.
    ///
    /// - Parameters:
    ///   - pinnedHashes: Base64-encoded SHA-256 hashes of the pinned keys/certificates.
    ///   - mode: Whether to pin the public key (default) or the full certificate.
    public init(pinnedHashes: Set<String>, mode: Mode = .publicKey) {
        self.pinnedHashes = pinnedHashes
        self.mode = mode
    }

    /// Builds a `URLSession` that uses this pinner as its delegate.
    public func makeSession(configuration: URLSessionConfiguration = .ephemeral) -> URLSession {
        URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    // MARK: - URLSessionDelegate

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Validate the chain, expiry, and hostname before checking the pin.
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            SecureLogger.error("TLS trust evaluation failed")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        if isPinned(serverTrust) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            SecureLogger.error("Certificate pin mismatch — rejecting connection")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    // MARK: - Pin Validation

    /// Returns `true` if any certificate in the chain matches a pinned hash.
    func isPinned(_ trust: SecTrust) -> Bool {
        for certificate in Self.certificateChain(trust) {
            let hash: String?
            switch mode {
            case .publicKey:  hash = Self.publicKeyHash(for: certificate)
            case .certificate: hash = Self.certificateHash(for: certificate)
            }
            if let hash, pinnedHashes.contains(hash) {
                return true
            }
        }
        return false
    }

    private static func certificateChain(_ trust: SecTrust) -> [SecCertificate] {
        (SecTrustCopyCertificateChain(trust) as? [SecCertificate]) ?? []
    }

    /// SHA-256 (base64) of the full DER-encoded certificate.
    static func certificateHash(for certificate: SecCertificate) -> String {
        let der = SecCertificateCopyData(certificate) as Data
        return Data(SHA256.hash(data: der)).base64EncodedString()
    }

    /// SHA-256 (base64) of the SubjectPublicKeyInfo for the certificate's key.
    static func publicKeyHash(for certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate),
              let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?,
              let header = asn1Header(for: publicKey) else {
            return nil
        }
        var spki = Data(header)
        spki.append(keyData)
        return Data(SHA256.hash(data: spki)).base64EncodedString()
    }

    /// Returns the ASN.1 SubjectPublicKeyInfo header for the key, used to rebuild the
    /// full SPKI from the raw key bytes returned by `SecKeyCopyExternalRepresentation`.
    private static func asn1Header(for key: SecKey) -> [UInt8]? {
        guard let attributes = SecKeyCopyAttributes(key) as? [CFString: Any],
              let type = attributes[kSecAttrKeyType] as? String,
              let size = attributes[kSecAttrKeySizeInBits] as? Int else {
            return nil
        }

        if type == (kSecAttrKeyTypeRSA as String) {
            switch size {
            case 2048: return rsa2048Header
            case 4096: return rsa4096Header
            default:   return nil
            }
        } else if type == (kSecAttrKeyTypeECSECPrimeRandom as String) {
            switch size {
            case 256: return ecSecp256r1Header
            case 384: return ecSecp384r1Header
            default:  return nil
            }
        }
        return nil
    }

    private static let rsa2048Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00,
    ]

    private static let rsa4096Header: [UInt8] = [
        0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00,
    ]

    private static let ecSecp256r1Header: [UInt8] = [
        0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
        0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
        0x42, 0x00,
    ]

    private static let ecSecp384r1Header: [UInt8] = [
        0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
        0x01, 0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00,
    ]
}
