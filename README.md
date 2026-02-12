# SecureBankKit

A reusable Swift Package security toolkit for banking-style iOS apps.

## Features

- **Biometric Authentication** — Face ID / Touch ID wrapper with passcode fallback
- **Keychain Storage** — Low-level Keychain CRUD and high-level token storage
- **Session Management** — Inactivity timeout and token expiry tracking with auto-refresh
- **App Lock** — Automatic lock on background with biometric re-authentication
- **Jailbreak Detection** — Multiple heuristic checks for compromised devices
- **Secure Logging** — Debug-only logging with sensitive data redaction

## Requirements

- iOS 15.0+
- Swift 6.2+
- Xcode 16+

## Installation

Add SecureBankKit to your project using Swift Package Manager.

### In Xcode

1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL
3. Select your version rules and add the package

### In `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SecureBankKit.git", from: "1.0.0")
]
```

Then add `"SecureBankKit"` as a dependency of your target.

## Usage

### Biometric Authentication

```swift
import SecureBankKit

let bioManager = BiometricAuthManager()

switch bioManager.canEvaluateBiometrics() {
case .faceID:  print("Face ID available")
case .touchID: print("Touch ID available")
case .none:    print("No biometrics available")
}

let success = try await bioManager.authenticate(reason: "Confirm your identity")
```

### Keychain Storage

```swift
let keychain = KeychainManager(service: "com.myapp.auth")
try keychain.save(string: "my-secret", forKey: "api-key")
let secret = try keychain.readString(forKey: "api-key")
```

### Token Storage

```swift
let tokenStorage = SecureTokenStorage(keychainManager: keychain)
try tokenStorage.saveAccessToken("eyJhbGci...")
try tokenStorage.saveRefreshToken("dGhpcyBp...")

let accessToken = tokenStorage.getAccessToken()
```

### Token Expiry Management

```swift
let expiryManager = TokenExpiryManager(refreshBufferInterval: 60)
expiryManager.setExpiry(Date().addingTimeInterval(3600))

if expiryManager.shouldRefreshToken() {
    try await expiryManager.refreshIfNeeded {
        // Call your refresh endpoint
        return Date().addingTimeInterval(3600)
    }
}
```

### Session Management

```swift
let session = SessionManager(
    tokenStorage: tokenStorage,
    tokenExpiryManager: expiryManager,
    sessionTimeout: 300
)

session.onSessionExpired = {
    print("Session expired — show login screen")
}

session.startSession()
session.recordActivity() // Call on user interaction
```

### App Lock

```swift
let lockManager = AppLockManager(
    biometricManager: BiometricAuthManager(),
    lockDelay: 5 // Lock after 5 seconds in background
)

lockManager.onLockStatusChanged = { isLocked in
    print(isLocked ? "App locked" : "App unlocked")
}

lockManager.enable()
```

### Jailbreak Detection

```swift
if JailbreakDetector.isJailbroken() {
    // Restrict functionality or alert the user
}
```

### Secure Logging

```swift
SecureLogger.info("User logged in")
SecureLogger.warning("Token expiring soon")
SecureLogger.error("Authentication failed")

let masked = SecureLogger.redact("4111111111111111") // "************1111"
```

## Architecture

```
Sources/SecureBankKit/
├── Core/           → Namespace and version
├── Biometrics/     → Face ID / Touch ID
├── Keychain/       → Keychain CRUD + Token Storage
├── Session/        → Session lifecycle + Token expiry
├── Security/       → App lock + Jailbreak detection
└── Utils/          → Debug logging
```

## License

This project is available under the MIT License.
