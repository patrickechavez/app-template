# App Hardening — Design

Date: 2026-08-16
Status: draft (awaiting review)

## Context

The template already covers the security fundamentals that get apps breached:
log redaction (`LoggingInterceptor`), Keychain token storage with
`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, ATS-enforced HTTPS (no
`NSAllowsArbitraryLoads`), gitignored `Secrets.xcconfig`, and a privacy
manifest. This pass adds the **defense-in-depth** measures a pentest commonly
flags, while deliberately keeping them *detect-and-report* rather than *hard
block* where blocking has real costs (false positives, App Store rejection).

**Scope:** four hardening items + one cleanup. **Biometric lock is out of
scope**, and its one leftover in the repo — a dead Face ID usage string — is
removed.

## 1. Certificate pinning

Defends against MITM even when an attacker controls a trusted CA or installs a
proxy cert (the standard Burp/Charles pentest).

- **What is pinned:** the server's **public key (SPKI)**, not the leaf
  certificate. A pinned cert breaks on every renewal; a pinned key survives
  rotation while the key stays the same. Pins are base64 SHA-256 SPKI hashes.
- **Where pins live:** config, not code. Public keys aren't secret, so they go
  in the normal xcconfig, comma-separated to allow pinning the current key and
  the next one during rotation.
  - `Config/*.xcconfig`: `PINNED_PUBLIC_KEY_HASHES` and `CERT_PINNING_ENABLED`.
  - `Config/Info.plist`: expose both keys (existing `$(...)` pattern).
  - `APIConfig.swift`: add `pinnedPublicKeyHashes: [String]` and
    `isCertificatePinningEnabled: Bool`.
- **Enforcement:** a new `URLSessionDelegate` (`CertificatePinner`) that
  implements `urlSession(_:didReceive:completionHandler:)`, resolving the
  `.serverTrust` challenge only if the leaf's SPKI hash matches a pinned hash;
  otherwise cancels with `URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge`.
  Wired into the `URLSession` created in `AppDependencies.urlSession()`.
- **Environment gating:** `CERT_PINNING_ENABLED = YES` in Production, `NO` in
  Development (and Staging) so local proxy inspection still works; the build a
  pentester tests is pinned.
- **Client change (the non-trivial part):** `URLSessionAPIClient.attemptOnce`
  currently uses `session.data(for:)`, which never delivers the server-trust
  challenge to a delegate. It must switch to a delegate-driven `dataTask`
  bridged with `withCheckedThrowingContinuation` so the pinner runs.
- **Failure behavior:** a pin mismatch surfaces as a typed `APIError`
  (`.serverTrustFailed`) and reads as a security/connection failure, not a crash.

## 2. Screen-capture / app-switcher privacy

iOS cannot *prevent* screenshots, but it can hide content from the task
switcher and detect captures.

- **App-switcher privacy:** an opaque `PrivacyShieldView` (brand color / blank)
  that overlays the root content while the app is not `.active`. Driven by the
  existing `@Environment(\.scenePhase)` in `AppTemplateApp`, so the snapshot
  iOS takes when backgrounding shows the shield, not the user's data.
- **Screenshot detection:** a `ScreenshotDetector` that observes
  `UIApplication.userDidTakeScreenshotNotification` and reports to observability
  (analytics flag / log). It cannot undo the capture — it makes them observable.

## 3. Jailbreak detection

- A `JailbreakDetector` protocol with a `DefaultJailbreakDetector` that checks
  common indicators: existence of `Cydia.app`/`Sileo.app`/`/bin/bash`/
  `/usr/sbin/sshd`, and `canOpenURL("cydia://")`/`"sileo://"`.
- **Behavior: detect + report, not block.** The result is sent to observability
  at launch; whether to restrict features or block is a per-app product decision
  the template must not make for you.
- Honest limitation (documented in README): the check is heuristic and bypassable;
  it exists to flag tampered/rooted devices in analytics, not as a security boundary.

## 4. Anti-debug / obfuscation

- A `DebuggerDetector` using `sysctl(KERN_PROC, P_TRACED)` (and optionally the
  `getppid` check) to report whether a debugger is attached. **Report-only** —
  deliberately avoiding `ptrace(PT_DENY_ATTACH)`, which risks App Store rejection.
- **Obfuscation is a non-goal.** Compiled Swift is already stripped in Release
  (`DEAD_CODE_STRIPPING`, `STRIP_INSTALLED_PRODUCT` are standard); meaningful
  string obfuscation is low-ROI for a template. This is documented in the README,
  not coded.

## 5. Biometric cleanup

Remove the dead `NSFaceIDUsageDescription` key/value from `Config/Info.plist`.
There is no biometric code in the app, so this is the only remnant. (The
Keychain `AfterFirstUnlockThisDeviceOnly` setting is unrelated to Face ID and
stays.)

## Files

New, under `AppTemplate/Core/Security/`:

- `CertificatePinner.swift` — `URLSessionDelegate` server-trust validation
- `JailbreakDetector.swift` — protocol + default heuristic detector
- `DebuggerDetector.swift` — `sysctl` debugger-attachment check
- `ScreenshotDetector.swift` — screenshot-notification observer → observability

New, under `AppTemplate/Components/`:

- `PrivacyShieldView.swift` — opaque overlay for backgrounding

Modified:

- `Config/Development.xcconfig`, `Staging.xcconfig`, `Production.xcconfig` — pinning keys
- `Config/Info.plist` — expose pinning keys; remove `NSFaceIDUsageDescription`
- `AppTemplate/Core/Networking/APIConfig.swift` — pinning accessors
- `AppTemplate/Core/Networking/APIClient.swift` — delegate-driven data task
- `AppTemplate/App/AppDependencies.swift` — wire pinner into `URLSession`; launch-time jailbreak/debugger reporting
- `AppTemplate/App/AppTemplateApp.swift` — privacy shield on `scenePhase`
- `README.md` — "Hardening" section (pinning setup + `openssl` hash command, and the honest limitations of jailbreak/anti-debug)

## Verification

- **Pinning:** with `PINNED_PUBLIC_KEY_HASHES` set to a wrong value, an API call
  fails with `APIError.serverTrustFailed`; with the correct hash it succeeds.
- **Privacy shield:** backgrounding the app shows the shield in the task-switcher
  snapshot, not app content.
- **Jailbreak / debugger:** on a normal simulator both report clean; the
  report-to-observability path is exercised (log line appears at launch).
- **Cleanup:** build succeeds with `NSFaceIDUsageDescription` gone.
- **Regression:** `xcodebuild build` (and `xcodebuild test`, once the unit-test
  target from the separate tests spec lands) still pass.
