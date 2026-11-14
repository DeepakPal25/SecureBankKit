import Foundation
import Darwin

/// Detects runtime tampering such as an attached debugger or injected dynamic libraries.
///
/// These checks complement ``JailbreakDetector`` by focusing on the running process
/// rather than the device file system.
///
/// ```swift
/// if AntiTamperDetector.isTampered() {
///     // refuse to run sensitive flows
/// }
/// ```
public enum AntiTamperDetector {

    /// Returns `true` if a debugger is currently attached to this process.
    ///
    /// Uses `sysctl` to read the process flags and check for the `P_TRACED` bit.
    public static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        let result = mib.withUnsafeMutableBufferPointer { pointer -> Int32 in
            sysctl(pointer.baseAddress, u_int(pointer.count), &info, &size, nil, 0)
        }

        guard result == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    /// Returns `true` if dynamic libraries were injected via `DYLD_INSERT_LIBRARIES`.
    ///
    /// Library injection is a common vector for runtime hooking frameworks.
    public static func hasInjectedLibraries() -> Bool {
        guard let raw = getenv("DYLD_INSERT_LIBRARIES") else { return false }
        return !String(cString: raw).isEmpty
    }

    /// Aggregate check that returns `true` if any tampering indicator is present.
    public static func isTampered() -> Bool {
        isDebuggerAttached() || hasInjectedLibraries()
    }

    /// Asks the kernel to deny debugger attachment to this process.
    ///
    /// Call this once, early in app launch, ideally guarded by `#if !DEBUG` so it does
    /// not interfere with your own development builds. Once denied, any subsequent
    /// attempt to attach a debugger will terminate the process.
    ///
    /// - Returns: `true` if the request succeeded.
    @discardableResult
    public static func denyDebuggerAttachment() -> Bool {
        // `ptrace` is not exposed in the iOS SDK headers, so resolve it at runtime.
        typealias PtraceFunction = @convention(c) (Int32, pid_t, UnsafeMutableRawPointer?, Int32) -> Int32

        guard let handle = dlopen(nil, RTLD_NOW),
              let symbol = dlsym(handle, "ptrace") else {
            return false
        }

        let ptrace = unsafeBitCast(symbol, to: PtraceFunction.self)
        // PT_DENY_ATTACH is request 31; passing it to ptrace prevents tracing.
        let ptDenyAttach: Int32 = 31
        return ptrace(ptDenyAttach, 0, nil, 0) == 0
    }
}
