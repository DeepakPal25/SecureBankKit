# Why Every Banking iOS App Needs a Security Toolkit

Building a banking or fintech iOS app? Security isn't a feature — it's the foundation. Yet most teams end up copy-pasting the same boilerplate security code across projects: keychain wrappers, biometric checks, session timers, jailbreak detectors. Each time, subtle bugs creep in. Each time, something gets missed.

That's why I built **SecureBankKit** — a drop-in Swift Package that handles the security fundamentals so you can focus on building your product.

## The Problem: Security Is Hard to Get Right

Here are the pain points I kept running into while building banking-style apps:

### 1. Keychain Is Painful to Use Directly

Apple's Security framework is powerful but its C-style API is hostile to Swift developers. A simple "save a string" operation requires building `CFDictionary` queries, handling `OSStatus` codes, and managing `kSecAttrAccessible` flags. Get one parameter wrong and data silently fails to persist — or worse, gets stored with the wrong access level.

**What goes wrong:**
- Tokens stored with `.afterFirstUnlockThisDeviceOnly` get lost after device restore
- Missing `kSecReturnData` in queries returns `nil` even when data exists
- Duplicate item errors crash the app because developers forget to delete-before-add

**SecureBankKit's solution:**
```swift
let keychain = KeychainManager(service: "com.myapp.auth")
try keychain.save(string: token, forKey: "access-token")
let token = try keychain.readString(forKey: "access-token")
```

One line. Type-safe. Configurable accessibility. Automatic overwrite handling.

### 2. Biometric Auth Has Too Many Edge Cases

Face ID and Touch ID seem simple until you handle:
- Devices with no biometrics at all
- Users who haven't enrolled biometrics
- The fallback to device passcode
- The difference between `.deviceOwnerAuthenticationWithBiometrics` and `.deviceOwnerAuthentication`
- The `NSFaceIDUsageDescription` Info.plist requirement that causes silent failures when missing

**SecureBankKit's solution:**
```swift
let bio = BiometricAuthManager()

switch bio.canEvaluateBiometrics() {
case .faceID:  // show Face ID UI
case .touchID: // show Touch ID UI
case .none:    // fall back to PIN
}

let success = try await bio.authenticate(reason: "Confirm transfer")
```

Clean enum. Async/await. Automatic passcode fallback.

### 3. Session Management Is Always an Afterthought

Banking regulators require automatic session timeout. But implementing it properly means:
- Tracking user activity across the entire app
- Coordinating between inactivity timers and token expiry
- Cleaning up tokens when sessions end
- Notifying the UI to show a lock screen

Most teams bolt this on late in development and it's always buggy.

**SecureBankKit's solution:**
```swift
let session = SessionManager(
    tokenStorage: tokenStorage,
    tokenExpiryManager: expiryManager,
    sessionTimeout: 300
)

session.onSessionExpired = {
    // navigate to login screen
}

session.startSession()
session.recordActivity() // call on user interaction
```

### 4. Token Refresh Logic Is Error-Prone

Access tokens expire. Refresh tokens need to be used before the access token dies. The timing window between "token is technically valid" and "token will expire mid-request" causes intermittent 401 errors that are impossible to reproduce in testing.

**SecureBankKit's solution:**
```swift
let expiryManager = TokenExpiryManager(refreshBufferInterval: 60)

// Proactively refreshes 60 seconds BEFORE expiry
try await expiryManager.refreshIfNeeded {
    let newExpiry = try await authService.refreshToken()
    return newExpiry
}
```

The buffer interval prevents that "expired mid-flight" race condition.

### 5. Jailbreak Detection Is Security Theater — Unless Done Right

A single `FileManager.fileExists(atPath: "/Applications/Cydia.app")` check is trivially bypassed. Real jailbreak detection needs multiple independent signals:

- File system checks (Cydia, sshd, apt, bash)
- Write access to protected directories
- URL scheme checks
- Dynamic library inspection

**SecureBankKit runs all four checks** and skips them on the simulator to avoid false positives during development.

### 6. Background Lock Is a Compliance Requirement

Banking apps must lock when backgrounded. But implementing it requires:
- Observing `UIApplication` lifecycle notifications
- Tracking how long the app was backgrounded
- Re-authenticating with biometrics on foreground
- Configurable grace periods (lock immediately vs. after 30 seconds)

**SecureBankKit's solution:**
```swift
let lockManager = AppLockManager(
    biometricManager: BiometricAuthManager(),
    lockDelay: 5
)
lockManager.enable()
```

Three lines. Handles everything.

### 7. Debug Logging Leaks Secrets

`print(token)` in a debug session becomes a security audit finding when it ships to production. Every team learns this the hard way.

**SecureBankKit's solution:**
```swift
SecureLogger.info("Token: \(SecureLogger.redact(token))")
// Output in DEBUG: [SecureBankKit] [INFO] Token: ************a1b2
// Output in RELEASE: (nothing — compiled away)
```

`#if DEBUG` wrapping with built-in redaction.

## Why a Package Instead of Copy-Paste?

1. **Tested** — 96 unit tests across all components
2. **Maintained** — Fix a bug once, every app gets the update
3. **Consistent** — Same security baseline across all your projects
4. **Reviewed** — Open source means more eyes on the code
5. **Fast** — Add one SPM dependency instead of writing 1,500 lines of boilerplate

## Get Started

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/DeepakPal25/SecureBankKit.git", from: "1.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies** and paste the URL.

Check out the [Demo App](../DemoApp/) to see every feature in action, or read the full [API documentation](../README.md).

## What's Next

SecureBankKit is open source under the MIT License. Contributions are welcome:
- Certificate pinning
- Encryption helpers (AES-256-GCM)
- Secure clipboard management
- Anti-screenshot/screen recording
- Device binding

**Star the repo** if this is useful to you: [github.com/DeepakPal25/SecureBankKit](https://github.com/DeepakPal25/SecureBankKit)

---

*Built by [DeepakPal25](https://github.com/DeepakPal25). Have questions or feedback? Open an issue on GitHub.*
