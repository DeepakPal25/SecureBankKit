# CLAUDE.md — SecureBankKit

This file provides context for Claude Code and other AI assistants working with this repository.

## Project Overview

SecureBankKit is a Swift Package that provides production-ready security modules for iOS banking and fintech apps. It has zero external dependencies and targets iOS 15+ with Swift 6.2 strict concurrency.

## Repository Layout

```
Sources/SecureBankKit/
  Core/SecureBankKit.swift              — Version constant (1.0.0)
  Biometrics/BiometricAuthManager.swift — Face ID / Touch ID with passcode fallback
  Keychain/KeychainManager.swift        — Low-level Keychain CRUD (delete-then-add pattern)
  Keychain/SecureTokenStorage.swift     — High-level access/refresh token facade
  Session/SessionManager.swift          — Inactivity timeout + credential cleanup (@MainActor)
  Session/TokenExpiryManager.swift      — Token expiry tracking with refresh buffer
  Security/AppLockManager.swift         — Background lock + biometric re-auth (@MainActor)
  Security/JailbreakDetector.swift      — 4-signal jailbreak detection
  Utils/SecureLogger.swift              — #if DEBUG compile-time safe logging + redaction

Tests/SecureBankKitTests/               — 96 unit tests across 11 files (SRP-based)
DemoApp/SecureBankKitDemo/              — SwiftUI demo app showcasing all modules
```

## Build & Test Commands

```bash
# Build
swift build

# Run all tests
swift test

# Build and test in one step
swift build && swift test
```

The demo app requires Xcode: open `DemoApp/SecureBankKitDemo.xcodeproj` and run on a simulator.

## Architecture & Design Decisions

### Concurrency Model
- **Sendable classes** (immutable, thread-safe): `KeychainManager`, `SecureTokenStorage`, `BiometricAuthManager`
- **@MainActor classes** (mutable state): `SessionManager`, `AppLockManager`
- **async/await**: Biometric auth and token refresh — no completion handlers

### Key Patterns
- **Delete-then-add** in `KeychainManager`: avoids `errSecDuplicateItem` crashes
- **Refresh buffer interval** in `TokenExpiryManager`: triggers refresh 60s before actual expiry to prevent mid-request token expiry race conditions
- **Fail-secure defaults**: `nil` expiry date = token considered expired
- **Compile-time log removal**: `SecureLogger` uses `#if DEBUG`, not runtime checks
- **Simulator guard**: `JailbreakDetector` returns `false` on simulator via `#if targetEnvironment(simulator)`
- **Dependency injection**: All managers accept dependencies via `init()` for testability

### Module Dependencies (internal wiring)
```
SessionManager → SecureTokenStorage (clears tokens on expiry)
SessionManager → TokenExpiryManager (checks token freshness)
AppLockManager → BiometricAuthManager (re-authentication)
SecureTokenStorage → KeychainManager (storage backend)
```

## Coding Conventions

- Swift 6.2 strict concurrency — no warnings allowed
- All public types have `public` access control
- Enums used for namespacing (`SecureBankKit`, `JailbreakDetector`, `SecureLogger`)
- `final class` for all concrete classes
- `Sendable` conformance on all thread-safe types
- Test files follow Single Responsibility Principle — one test file per component
- Test helpers in `TestHelpers.swift` for shared mock/stub utilities

## Common Tasks

### Adding a new security module
1. Create a new directory under `Sources/SecureBankKit/` (e.g., `Encryption/`)
2. Add the Swift file with `public` types
3. Create a corresponding test file in `Tests/SecureBankKitTests/`
4. Follow existing patterns: `final class`, `Sendable` or `@MainActor`, dependency injection

### Modifying existing modules
- Run `swift test` after every change — 96 tests must pass
- Maintain `Sendable`/`@MainActor` annotations correctly
- Keep zero external dependencies

## Important Notes

- **No external dependencies** — this is intentional; do not add third-party packages
- **iOS 15+ minimum** — do not use APIs requiring iOS 16+
- **MIT Licensed** — all contributions must be compatible
- Version is defined in `Sources/SecureBankKit/Core/SecureBankKit.swift`
