import Foundation
import MachO

/// Detects common signs of a jailbroken iOS device.
///
/// All checks are skipped on the iOS Simulator to avoid false positives.
///
/// ```swift
/// if JailbreakDetector.isJailbroken() {
///     // restrict functionality or alert the user
/// }
/// ```
public enum JailbreakDetector {

    /// Returns `true` if jailbreak indicators are detected on the device.
    ///
    /// On the simulator this always returns `false`.
    public static func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkSuspiciousFiles()
            || checkWritableSystemPaths()
            || checkJailbreakApps()
            || checkDyldImages()
        #endif
    }

    // MARK: - Internal Checks

    /// Checks for the existence of common jailbreak-related file paths.
    private static func checkSuspiciousFiles() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/usr/bin/ssh",
            "/private/var/lib/apt/",
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    /// Attempts to write to a system directory that should be read-only.
    private static func checkWritableSystemPaths() -> Bool {
        let testPath = "/private/jailbreak_test"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    /// Checks for the presence of known jailbreak package manager apps.
    ///
    /// Uses file-based detection so it remains safe to call from app extensions
    /// (which cannot access `UIApplication.shared` to probe URL schemes).
    private static func checkJailbreakApps() -> Bool {
        let paths = [
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Applications/Cydia.app",
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    /// Scans loaded dyld images for known jailbreak libraries.
    private static func checkDyldImages() -> Bool {
        let suspiciousLibraries = [
            "MobileSubstrate",
            "libhooker",
            "SubstrateLoader",
            "TweakInject",
        ]

        let imageCount = _dyld_image_count()
        for i in 0..<imageCount {
            guard let imageName = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageName)
            for library in suspiciousLibraries {
                if name.contains(library) { return true }
            }
        }
        return false
    }
}
